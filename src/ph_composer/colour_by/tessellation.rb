# frozen_string_literal: true

module PhComposer
  module ColourBy
    # World-space triangles and outline segments for whatever entity a mode's projection hands over.
    # The service caches what this returns; nothing here reads a record, so a mode may colour any
    # entity kind without the shared service learning about it.
    #
    # A projection's transform maps that entity's own contents to world: a Face's vertices, or the
    # entities inside a Group. That is what `Zones::FaceOccurrence` and `ZoneOccurrence` already carry.
    module Tessellation
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

      private_class_method :collect, :child_entities, :skipped?, :add_face
    end
  end
end
