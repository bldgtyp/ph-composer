# frozen_string_literal: true

require_relative "definition_index"
require_relative "definition_geometry"
require_relative "definition_writer"
require_relative "native_unit"

module PhComposer
  module Windows
    module Units
      # Clear only the deleted Type's primary pointer. A preceding batch swap may add exactly
      # its chosen target pointer; unmanaged native users keep the old definition alive.
      class TypeCleanupStep
        attr_reader :scope

        def initialize(model:, type_id:, moved_ids: [], target_type: nil)
          @type_id = type_id
          @index = DeepCopy.call(DefinitionIndex.read(model))
          @target = DeepCopy.call(target_type)
          @definition_id = @index[type_id]
          @scope = MutationScope.new(:definition_ids => @definition_id ? [@definition_id] : [])
          definition = DefinitionIndex.resolve(model, type_id)
          @native_before = definition && DefinitionGeometry.capture(definition)
          @remaining_ids = definition ? definition.instances.map(&:persistent_id).sort - moved_ids : []
          check_edit_context!(model)
        end

        def needed?
          !@definition_id.nil?
        end

        def descriptor
          DeepCopy.call("name" => "cleanup_deleted_window_type", "type_id" => @type_id,
            "index_before" => @index, "replacement_type" => @target, "definition_before" => @native_before,
            "remaining_instance_ids" => @remaining_ids)
        end

        def affected
          [{ "kind" => TYPE_KIND, "id" => @type_id, "change" => "definition_released" }]
        end

        def apply(model, _slots)
          return unless needed?

          check_edit_context!(model)
          current = DefinitionIndex.read(model)
          check_index!(model, current)
          definition = DefinitionIndex.resolve(model, @type_id)
          unless definition && DefinitionGeometry.capture(definition) == @native_before &&
                 definition.instances.map(&:persistent_id).sort == @remaining_ids
            NativeUnit.changed!("The deleted Type's native definition or users changed after preview.")
          end
          DefinitionIndex.write(model, current.reject { |id, _| id == @type_id }, :expected => current)
          return unless @remaining_ids.empty?

          model.definitions.remove(definition)
          if model.definitions.any? { |item| item.persistent_id == @definition_id }
            raise CodedError.new("geometry.failed", "The unused Window definition could not be removed.")
          end
        end

        private

        def check_index!(model, current)
          return if current == @index

          id = @target && @target.fetch("id")
          only_added = id && !@index.key?(id) && current.reject { |key, _| key == id } == @index && current.key?(id)
          NativeUnit.changed!("The Window definition index changed after preview.") unless only_added
          definition = DefinitionIndex.resolve(model, id)
          configured = definition && DefinitionWriter.configured?(definition.behavior)
          planned = configured && DefinitionGeometry.matches?(definition, :type_id => id,
                                                                          :plan => DefinitionPlan.build(@target))
          NativeUnit.changed!("The planned replacement definition changed before cleanup.") unless planned
        end

        def check_edit_context!(model)
          return unless NativeUnit.editing?(model, @definition_id)

          raise CodedError.new("window.definition_editing", "Close the deleted Window definition before deletion.")
        end
      end
    end
  end
end
