# frozen_string_literal: true

require_relative "definition_writer"
require_relative "definition_index"
require_relative "definition_geometry"
require_relative "generated_geometry"
require_relative "world_geometry"
require_relative "native_unit"
require_relative "host_guard"
require_relative "../placement/host"
require_relative "../placement/fit"

module PhComposer
  module Windows
    module Units
      # One batch creates/resolves the target primary once. The caller owns identity repair,
      # public host reads, complete nonswapped outlines and the enclosing proposal/operation.
      class SwapStep
        attr_reader :scope, :affected

        def initialize(model:, target_type:, items:, expected_records: {})
          raise CodedError.new("params.invalid", "Choose at least one Window to swap.") if items.empty?

          @target = DeepCopy.call(target_type)
          @target_plan = DefinitionPlan.build(@target)
          @types = {}
          @missing_types = []
          admit_type!(model, @target)
          @index = DeepCopy.call(DefinitionIndex.read(model))
          @index.each_key { |id| DefinitionIndex.resolve(model, id) }
          target = DefinitionIndex.resolve(model, @target.fetch("id"))
          @target_definition_id = target&.persistent_id
          check_target!(target)
          check_edit_context!(model)
          occurrences = Occurrences.all(model)
          @rows = items.map { |item| prepare_item(model, occurrences, item, expected_records) }
          keys = @rows.map { |row| row.fetch("reference").fetch("entity_path") }
          raise CodedError.new("params.invalid", "A Window swap repeats an occurrence.") unless keys.uniq == keys

          ids = occurrences.map { |item| item.entity.definition.persistent_id }
          ids << @target_definition_id if @target_definition_id
          @scope = MutationScope.new(:definition_ids => ids)
          @guard = scope.capture(model, :expected_records => expected_records)
          check_fit!
          @affected = @rows.select { |row| native_change?(row) }.map do |row|
            { "kind" => REFERENCE_KIND, "id" => row.fetch("after").fetch("id"), "change" => "type_swapped",
              "reference" => DeepCopy.call(row.fetch("reference")) }
          end
        end

        def needed?
          @rows.any? { |row| native_change?(row) }
        end

        def descriptor
          DeepCopy.call("name" => "swap_window_unit_types", "target" => @target, "types" => @types,
            "missing_source_types" => @missing_types.uniq.sort,
            "index_before" => @index, "target_definition_id" => @target_definition_id,
            "native_guard" => @guard, "items" => @rows)
        end

        def reference_entries
          @rows.map do |row|
            Records::ReferenceEntry.new(:kind => REFERENCE_KIND,
              :key => row.fetch("reference").fetch("entity_path").dup, :record => DeepCopy.call(row.fetch("after")))
          end
        end

        def reference_plan
          Records::ReferencePlan.new(:entries => reference_entries)
        end

        def apply(model, _slots)
          return unless needed?

          verify_types!(model)
          check_edit_context!(model)
          NativeUnit.changed!("Window native state changed after preview.") unless scope.capture(model) == @guard
          occurrences = Occurrences.all(model)
          resolved = @rows.map do |row|
            NativeUnit.unchanged!(occurrences, row.fetch("reference").fetch("entity_path"), row.fetch("before"))
          end
          @rows.zip(resolved).each { |row, item| HostGuard.verify!(item, row["host_geometry"]) }
          target = DefinitionIndex.resolve(model, @target.fetch("id"))
          check_target!(target)
          check_fit!
          target ||= create_target(model)
          @rows.zip(resolved).each do |row, item|
            next unless native_change?(row)

            NativeUnit.replace_definition!(item.entity, target, row.fetch("after_matrix"))
            Units.write(item.entity, row.fetch("after"))
          end
        end

        private

        def native_change?(row)
          row.fetch("before") != row.fetch("after") || row.fetch("definition_id") != @target_definition_id ||
            row.fetch("matrix") != row.fetch("after_matrix")
        end

        def admit_type!(model, type, source: false)
          unless type.is_a?(Hash) && Types::KIND.problems(type).empty?
            raise CodedError.new(source ? "window.unknown_type" : "validation.failed",
              "Choose a valid authored Window Type.")
          end
          stored = Types::KIND.store.read(model, type.fetch("id"))
          if source && stored.nil?
            raise CodedError.new("window.unknown_type", "The source Window Type is unavailable.")
          end
          NativeUnit.changed!("An authored Window Type no longer matches the supplied baseline.") unless stored == type
          if @types.key?(type.fetch("id")) && @types.fetch(type.fetch("id")) != type
            raise CodedError.new("params.invalid", "The batch supplies conflicting Type baselines.")
          end
          @types[type.fetch("id")] = DeepCopy.call(type)
        end

        def prepare_item(model, occurrences, input, expected)
          item = NativeUnit.resolve!(occurrences, input.fetch(:reference))
          Occurrences.assert_leaf!(item)
          record = DeepCopy.call(Units.validate!(input.fetch(:expected_record)))
          NativeUnit.changed!("A Window record differs from the planned identity repair.") unless
            record == expected.fetch(item.path, item.record)
          from_type = input.fetch(:from_type)
          old_plan = source_plan(model, item, record, from_type)
          row = instance_row(item, record, old_plan)
          row["other_polygons_m"] = DeepCopy.call(input.fetch(:other_polygons_m))
          row["host_geometry"] = HostGuard.capture(item, input[:host]) if item.entity.glued_to
          row
        end

        def source_plan(model, item, record, from_type)
          type_id = record.fetch("window_type_id")
          if from_type.nil?
            unless source_absent?(model, type_id)
              raise CodedError.new("window.unknown_type", "Supply the existing authored source Type for this Window.")
            end
            @missing_types << type_id
            return GeneratedGeometry.plan(item.entity.definition, :type_id => type_id)
          end
          admit_type!(model, from_type, :source => true)
          unless from_type.fetch("id") == type_id
            raise CodedError.new("window.unknown_type", "Supply the authored source Type for this Window.")
          end
          DefinitionPlan.build(from_type)
        end

        def source_absent?(model, type_id)
          !Types::KIND.store.ids(model).include?(type_id)
        end

        def instance_row(item, record, old_plan)
          matrix = item.entity.transformation.to_a
          changed = WorldGeometry.reanchor(matrix, :before => old_plan, :after => @target_plan,
            :anchor => record.fetch("anchor"))
          { "reference" => { "unit_id" => record.fetch("id"), "entity_path" => item.path.dup },
            "before" => record, "after" => record.merge("window_type_id" => @target.fetch("id")),
            "definition_id" => item.entity.definition.persistent_id, "matrix" => matrix,
            "glued_face_id" => item.entity.glued_to&.persistent_id, "after_matrix" => changed,
            "world_matrix" => item.transform.to_a,
            "after_world_matrix" => (item.parent_transform * Geom::Transformation.new(changed)).to_a }
        end

        def check_fit!
          polygons = @rows.map do |row|
            WorldGeometry.map(@target_plan, row.fetch("after_world_matrix")).outer_polygon_m
          end
          @rows.each_with_index do |row, index|
            others = polygons.each_with_index.filter_map { |polygon, i| polygon unless i == index }
            HostGuard.fit!(row["host_geometry"], polygons[index], row.fetch("other_polygons_m") + others)
          end
        end

        def verify_types!(model)
          @missing_types.uniq.each do |id|
            NativeUnit.changed!("The missing source Window Type reappeared after preview.") unless
              source_absent?(model, id)
          end
          @types.each_value do |type|
            NativeUnit.changed!("An authored Window Type changed after preview.") unless
              Types::KIND.store.read(model, type.fetch("id")) == type
          end
        end

        def check_edit_context!(model)
          return unless NativeUnit.editing?(model, @target_definition_id)

          raise CodedError.new("window.definition_editing", "Close the target Window definition before swapping.")
        end

        def check_target!(definition, code: "window.definition_changed")
          return unless definition

          return if DefinitionWriter.configured?(definition.behavior) &&
                    DefinitionGeometry.matches?(definition, :type_id => @target.fetch("id"), :plan => @target_plan)

          raise CodedError.new(code, "The target Window definition geometry or behavior differs from its Type.")
        end

        def create_target(model)
          definition = DefinitionWriter.create(:model => model, :type => @target, :plan => @target_plan)
          check_target!(definition, :code => "geometry.failed")
          DefinitionIndex.write(model, @index.merge(@target.fetch("id") => definition.persistent_id),
            :expected => @index)
          definition
        end
      end
    end
  end
end
