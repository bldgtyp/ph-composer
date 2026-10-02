# frozen_string_literal: true

require_relative "records"
require_relative "occurrences"
require_relative "definition_geometry"
require_relative "../../../core/operations/entity_scope"

module PhComposer
  module Windows
    module Units
      # Erase one explicit occurrence; the caller owns identity repair, reference projection and the native operation.
      class RemoveStep
        attr_reader :affected

        def initialize(model:, reference:, expected_record:)
          @reference = DeepCopy.call(reference)
          @expected_record = DeepCopy.call(Units.validate!(expected_record))
          items = Occurrences.all(model).select { |item| item.path == @reference.fetch("entity_path") }
          unless items.length == 1 && [items.first.record.fetch("id"), @expected_record.fetch("id")].include?(
            @reference.fetch("unit_id"))
            changed!("The Window removal occurrence no longer resolves uniquely.")
          end
          item = items.first
          mutable!(item)
          Occurrences.assert_leaf!(item)
          @reference["unit_id"] = @expected_record.fetch("id")
          @native_before = native(item)
          @affected = [{ "kind" => REFERENCE_KIND, "id" => @expected_record.fetch("id"), "change" => "removed",
            "reference" => DeepCopy.call(@reference) }]
        end

        def descriptor
          DeepCopy.call("name" => "remove_window_unit", "reference" => @reference,
            "expected_record" => @expected_record, "native_before" => @native_before)
        end

        def temporary_ids
          []
        end

        # The inventory preimage may precede a planned IdentityStep. Never replace this with a UUID-wide removal.
        def removal(before_record:)
          Records::ReferenceRemoval.new(:kind => REFERENCE_KIND, :key => @reference.fetch("entity_path").dup,
            :before => DeepCopy.call(Units.validate!(before_record)))
        end

        def apply(model, _slots)
          item = Occurrences.resolve(model, @reference, :mutable => true)
          unless item.record == @expected_record && native(item) == @native_before
            changed!("The Window record or native state changed after removal preview.")
          end
          entities = PhComposer::Operations::EntityScope.new(item.path[0...-1]).resolve(model)
          unless entities.to_a.include?(item.entity)
            changed!("The Window no longer belongs to its explicit parent storage.")
          end
          entities.erase_entities(item.entity)
          if entities.to_a.include?(item.entity)
            raise CodedError.new("geometry.failed", "The native Window instance could not be removed.")
          end
        end

        private

        def native(item)
          entity = item.entity
          { "matrix" => entity.transformation.to_a, "world_matrix" => item.transform.to_a,
            "definition_id" => entity.definition.persistent_id,
            "definition_before" => DefinitionGeometry.capture(entity.definition),
            "glued_face_id" => entity.glued_to&.persistent_id }
        end

        def mutable!(item)
          if item.shared_storage
            raise CodedError.new("target.shared_definition", "Make the Window parent storage unique before removal.")
          end
          raise CodedError.new("target.locked", "The Window unit or its parent is locked.") if item.locked
        end

        def changed!(message)
          raise CodedError.new("target.changed", "#{message} Nothing was written.")
        end
      end
    end
  end
end
