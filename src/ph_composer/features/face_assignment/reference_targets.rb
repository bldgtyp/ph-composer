# frozen_string_literal: true

module PhComposer
  module FaceAssignment
    REFERENCE_KIND = "#{FEATURE_ID}.face"

    # Includes orphan records and every placement of shared component storage. Restricting this
    # inventory to Zones would silently admit UUID ambiguity outside the authoring scope.
    module ReferenceTargets
      module_function

      def entries(model)
        walk(model.entities, [], [])
      end

      def walk(entities, path, found)
        entities.each do |entity|
          current = path + [entity.persistent_id]
          if entity.is_a?(Sketchup::Face)
            record = FACE_STORE.read(entity)
            if record
              found << Records::ReferenceEntry.new(:kind => REFERENCE_KIND, :key => current, :record => record)
            end
          elsif entity.is_a?(Sketchup::Group)
            walk(entity.entities, current, found)
          elsif entity.is_a?(Sketchup::ComponentInstance)
            walk(entity.definition.entities, current, found)
          end
        end
        found
      end
      private_class_method :walk
    end
  end
end
