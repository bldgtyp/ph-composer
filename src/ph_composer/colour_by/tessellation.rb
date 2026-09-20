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
          each_child(entity) { |child| collect(child, transform, triangles, segments) }
        end
        [triangles, segments]
      end

      # `transform` here is the parent's content transform, so a container multiplies in its own.
      def collect(entity, transform, triangles, segments)
        return if skipped?(entity)

        if entity.is_a?(Sketchup::Face)
          add_face(entity, transform, triangles, segments)
        else
          inner = transform * entity.transformation
          each_child(entity) { |child| collect(child, inner, triangles, segments) }
        end
      end

      def each_child(entity, &block)
        entities = if entity.is_a?(Sketchup::Group)
                     entity.entities
                   elsif entity.respond_to?(:definition)
                     entity.definition.entities
                   end
        entities&.each(&block)
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

      private_class_method :collect, :each_child, :skipped?, :add_face
    end
  end
end
