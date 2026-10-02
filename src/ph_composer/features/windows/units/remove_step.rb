# frozen_string_literal: true

require_relative "records"
require_relative "occurrences"
require_relative "native_unit"
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
          item = NativeUnit.resolve!(Occurrences.all(model), @reference, :expected_record => @expected_record)
          Occurrences.assert_leaf!(item)
          @reference["unit_id"] = @expected_record.fetch("id")
          @native_before = NativeUnit.preimage(item)
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
          unless item.record == @expected_record && NativeUnit.preimage(item) == @native_before
            NativeUnit.changed!("The Window record or native state changed after removal preview.")
          end
          entities = PhComposer::Operations::EntityScope.new(item.path[0...-1]).resolve(model)
          unless entities.to_a.include?(item.entity)
            NativeUnit.changed!("The Window no longer belongs to its explicit parent storage.")
          end
          entities.erase_entities(item.entity)
          if entities.to_a.include?(item.entity)
            raise CodedError.new("geometry.failed", "The native Window instance could not be removed.")
          end
        end
      end
    end
  end
end
