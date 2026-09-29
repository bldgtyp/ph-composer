# frozen_string_literal: true

module PhComposer
  module ColourBy
    # Visibility belongs to an occurrence, not to its leaf entity: two instances may share a Face
    # while only one is hidden. Cache parent paths and entity lookup for one drawing rebuild only.
    class OccurrenceVisibility
      def initialize(model)
        @resolved = { [] => [model, true] }
        @children = {}
      end

      def visible?(path, entity)
        return true if path.nil? # Older projections provide only the leaf's visibility.
        return false unless path.is_a?(Array) && !path.empty?

        resolved, visible = resolve(path)
        resolved.equal?(entity) && visible
      end

      private

      def resolve(path)
        return @resolved[path] if @resolved.key?(path)

        parent, visible = resolve(path[0...-1])
        entity = parent && children(parent)[path.last]
        @resolved[path] = [entity, visible && entity && !Tessellation.skipped?(entity)]
      end

      def children(parent)
        @children[parent] ||= begin
          entities = parent.respond_to?(:entities) ? parent.entities : Tessellation.child_entities(parent)
          Array(entities&.to_a).to_h { |entity| [entity.persistent_id, entity] }
        end
      end
    end

    # World-space triangles and outline segments for whatever entity a mode's projection hands over.
    # The service caches what this returns; nothing here reads a record, so a mode may colour any
    # entity kind without the shared service learning about it.
    #
    # A projection's transform maps that entity's own contents to world: a Face's vertices, or the
    # entities inside a Group. That is what `Zones::FaceOccurrence` and `ZoneOccurrence` already carry.
    module Tessellation
      # SketchUp coordinates are inches. The stripe planes are anchored in world space, so a Face's
      # mesh diagonals do not restart the pattern at each triangle. Large meshes widen the spacing
      # as a whole rather than drawing an arbitrarily truncated hatch.
      HATCH_SPACING = 6.0
      MAX_HATCH_SEGMENTS = 8_192
      HATCH_EPSILON = 1.0e-8
      HatchTriangle = Struct.new(:vertices, :coordinates, :minimum, :maximum, keyword_init: true)
      module_function

      def call(entity, transform)
        triangles = []
        segments = []
        transform ||= Geom::Transformation.new
        return [triangles, segments] if skipped?(entity)

        if entity.is_a?(Sketchup::Face)
          add_face(entity, transform, triangles, segments)
        else
          child_entities(entity)&.each { |child| collect(child, transform, triangles, segments) }
        end
        [triangles, segments]
      end

      # `transform` here is the parent's content transform, so a container multiplies in its own.
      def collect(entity, transform, triangles, segments)
        return if skipped?(entity)

        if entity.is_a?(Sketchup::Face)
          add_face(entity, transform, triangles, segments)
        else
          # Edges and other drawing entities are not instances and have no transformation.
          # Resolve the children before reading a container's instance transform.
          children = child_entities(entity)
          return unless children

          inner = transform * entity.transformation
          children.each { |child| collect(child, inner, triangles, segments) }
        end
      end

      def child_entities(entity)
        if entity.is_a?(Sketchup::Group)
          entity.entities
        elsif entity.respond_to?(:definition)
          entity.definition.entities
        end
      end

      # Hidden geometry and geometry on a hidden tag are not painted. Tag visibility does not advance
      # the session revision, so the service also invalidates on `tags_changed`.
      def skipped?(entity)
        return true if entity.respond_to?(:hidden?) && entity.hidden?

        layer = entity.respond_to?(:layer) ? entity.layer : nil
        layer.respond_to?(:visible?) && !layer.visible?
      end

      def add_face(face, transform, triangles, segments)
        mesh = face.mesh(0)
        mesh.polygons.each do |polygon|
          polygon.each { |index| triangles << mesh.point_at(index.abs).transform(transform) }
        end
        face.loops.each do |loop|
          points = loop.vertices.map { |vertex| vertex.position.transform(transform) }
          points.each_index { |index| segments << points[index] << points[(index + 1) % points.length] }
        end
      end

      # Intersect global diagonal stripe planes with the already transformed triangles. The mesh is
      # the clipping authority: SketchUp's Face mesh excludes holes and concave exterior regions.
      # Every two returned points form one GL_LINES segment. This reads no Model or Face.
      def hatch(triangles)
        prepared = triangles.each_slice(3).filter_map do |vertices|
          next unless vertices.length == 3

          across = hatch_across(vertices)
          next unless across

          coordinates = vertices.map { |point| dot(point, across) }
          HatchTriangle.new(:vertices => vertices, :coordinates => coordinates,
                            :minimum => coordinates.min, :maximum => coordinates.max)
        end
        spacing = HATCH_SPACING
        # A stripe crosses a triangle in at most one segment. The count omits vertex-only tangencies
        # that would clip to zero length, so they cannot erase real hatch by widening the spacing.
        while prepared.sum { |triangle| stripe_count(triangle, spacing) } > MAX_HATCH_SEGMENTS
          spacing *= 2.0
        end
        hatch_at_spacing(prepared, spacing)
      end

      def stripe_range(triangle, spacing)
        first = ((triangle.minimum / spacing) - 0.5).ceil
        last = ((triangle.maximum / spacing) - 0.5).floor
        first..last
      end

      def stripe_count(triangle, spacing)
        range = stripe_range(triangle, spacing)
        count = range.end - range.begin + 1
        return 0 if count <= 0

        first_level = (range.begin + 0.5) * spacing
        last_level = (range.end + 0.5) * spacing
        count -= 1 if zero_length_extremum?(triangle, first_level, triangle.minimum)
        count -= 1 if range.end != range.begin && zero_length_extremum?(triangle, last_level, triangle.maximum)
        count
      end

      def zero_length_extremum?(triangle, level, extreme)
        return false if (level - extreme).abs > HATCH_EPSILON

        # A near-tangent can still span a real line on a long skinny triangle. Use the same edge
        # fractions as clipping, but keep only numeric coordinates here, without Point3d allocation.
        first_hit = nil
        3.times do |edge|
          following = (edge + 1) % 3
          start_distance = triangle.coordinates[edge] - level
          end_distance = triangle.coordinates[following] - level
          next if start_distance * end_distance > 0
          next if (start_distance - end_distance).abs < HATCH_EPSILON

          fraction = start_distance / (start_distance - end_distance)
          next if fraction < -HATCH_EPSILON || fraction > 1 + HATCH_EPSILON

          start_point = triangle.vertices[edge]
          end_point = triangle.vertices[following]
          hit = [start_point.x + (fraction * (end_point.x - start_point.x)),
                 start_point.y + (fraction * (end_point.y - start_point.y)),
                 start_point.z + (fraction * (end_point.z - start_point.z))]
          if first_hit
            distance = first_hit.zip(hit).sum { |start_value, end_value| (start_value - end_value)**2 }
            return false if distance >= HATCH_EPSILON**2
          else
            first_hit = hit
          end
        end
        true
      end

      def hatch_at_spacing(prepared, spacing)
        segments = []
        prepared.each do |triangle|
          vertices = triangle.vertices
          coordinates = triangle.coordinates
          stripe_range(triangle, spacing).each do |index|
            level = (index + 0.5) * spacing
            hits = []
            3.times do |edge|
              following = (edge + 1) % 3
              start_distance = coordinates[edge] - level
              end_distance = coordinates[following] - level
              next if start_distance * end_distance > 0
              next if (start_distance - end_distance).abs < HATCH_EPSILON

              fraction = start_distance / (start_distance - end_distance)
              next if fraction < -HATCH_EPSILON || fraction > 1 + HATCH_EPSILON

              start_point = vertices[edge]
              end_point = vertices[following]
              hit = Geom::Point3d.new(start_point.x + (fraction * (end_point.x - start_point.x)),
                                      start_point.y + (fraction * (end_point.y - start_point.y)),
                                      start_point.z + (fraction * (end_point.z - start_point.z)))
              hits << hit unless hits.any? { |point| squared_distance(point, hit) < HATCH_EPSILON**2 }
            end
            next unless hits.length == 2
            next if squared_distance(hits[0], hits[1]) < HATCH_EPSILON**2

            segments.concat(hits)
          end
        end
        segments
      end

      def hatch_across(vertices)
        first, second, third = vertices
        edge_a = [second.x - first.x, second.y - first.y, second.z - first.z]
        edge_b = [third.x - first.x, third.y - first.y, third.z - first.z]
        normal = [edge_a[1] * edge_b[2] - edge_a[2] * edge_b[1],
                  edge_a[2] * edge_b[0] - edge_a[0] * edge_b[2],
                  edge_a[0] * edge_b[1] - edge_a[1] * edge_b[0]]
        length = Math.sqrt(normal.sum { |component| component**2 })
        return nil if length < HATCH_EPSILON

        normal.map! { |component| component / length }
        across = projected_axis([1.0, 1.0, 1.0], normal)
        across = projected_axis([1.0, -1.0, 0.0], normal) if across.nil?
        across
      end

      def projected_axis(axis, normal)
        projection = axis.zip(normal).sum { |component, other| component * other }
        result = axis.zip(normal).map { |component, other| component - (projection * other) }
        length = Math.sqrt(result.sum { |component| component**2 })
        return nil if length < HATCH_EPSILON

        result.map { |component| component / length }
      end

      def dot(point, vector)
        (point.x * vector[0]) + (point.y * vector[1]) + (point.z * vector[2])
      end

      def squared_distance(first, second)
        ((first.x - second.x)**2) + ((first.y - second.y)**2) + ((first.z - second.z)**2)
      end

      # The same points, lifted toward the camera by about `pixels` screen pixels.
      #
      # A fill drawn exactly on the Face it colours z-fights with that Face, and the host blinks
      # between the Face's own colour and the fill as the camera moves; at anything but a close
      # zoom the fill is not reliably visible at all. Measured on 26.1.188, 2026-09-20.
      #
      # The lift is toward the eye rather than along the Face normal, so it is correct whichever
      # side the Face is seen from, and it is scaled from the view, so it stays one or two pixels at
      # every zoom and never separates visibly from the Face it belongs to.
      def lift(points, view, pixels = 2.0)
        return points unless view.respond_to?(:camera) && view.respond_to?(:pixels_to_model)

        eye = view.camera.eye
        points.map do |point|
          direction = eye - point
          direction.length.to_f.zero? ? point : point.offset(direction, view.pixels_to_model(pixels, point))
        end
      end

      private_class_method :collect, :add_face, :stripe_range, :stripe_count, :zero_length_extremum?,
                           :hatch_at_spacing, :hatch_across, :projected_axis, :dot, :squared_distance
    end
  end
end
