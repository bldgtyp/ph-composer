# frozen_string_literal: true

require_relative "definition_writer"
require_relative "definition_index"
require_relative "definition_geometry"
require_relative "mutation_scope"
require_relative "world_geometry"
require_relative "native_unit"
require_relative "host_guard"
require_relative "../types/grid_operations"
require_relative "../placement/fit"

module PhComposer
  module Windows
    module Units
      # Horizontal grid flip plus a local reflection preserves every physical pane. The caller writes the new Type.
      class FlipStep
        attr_reader :scope, :affected, :findings

        def initialize(model:, source_type:, target_type:, reference:, expected_record:, other_polygons_m:,
                       expected_records: {}, host: nil)
          @source, @target = DeepCopy.call(source_type), DeepCopy.call(target_type)
          @reference = DeepCopy.call(reference)
          @before = DeepCopy.call(Units.validate!(expected_record))
          verify_source!(model)
          @source_plan, @target_plan = [@source, @target].map { |type| DefinitionPlan.build(type) }
          @index = DeepCopy.call(DefinitionIndex.read(model))
          @index.each_key { |id| DefinitionIndex.resolve(model, id) }
          target_absent!(model)
          validate_flip!
          item = Occurrences.resolve(model, reference, :mutable => true)
          @reference["unit_id"] = @before.fetch("id")
          unless @before.fetch("window_type_id") == @source.fetch("id")
            raise CodedError.new("reference.invalid", "The mirrored Window must refer to the supplied source Type.")
          end
          @definition_id = item.entity.definition.persistent_id
          @matrix, @world_matrix = item.entity.transformation.to_a, item.transform.to_a
          unless WorldGeometry.transform_state(@world_matrix).mirrored
            raise CodedError.new("window.not_mirrored", "Choose a mirrored Window for a new flipped Type.")
          end
          @after = @before.merge("window_type_id" => @target.fetch("id"),
            "anchor" => flipped_anchor(@before.fetch("anchor")))
          @after_matrix = (Geom::Transformation.new(@matrix) * reflection).to_a
          @after_world = (item.parent_transform * Geom::Transformation.new(@after_matrix)).to_a
          @others = DeepCopy.call(other_polygons_m)
          @host_geometry = HostGuard.capture(item, host) if item.entity.glued_to
          verify_geometry!(model, item.entity.definition)
          check_fit!
          definition_ids = Occurrences.all(model).map { |row| row.entity.definition.persistent_id }
          @scope = MutationScope.new(:definition_ids => definition_ids)
          @guard = scope.capture(model, :expected_records => projected_records(expected_records, item.path))
          @affected = [{ "kind" => REFERENCE_KIND, "id" => @after.fetch("id"), "change" => "flipped_type_created",
            "reference" => DeepCopy.call(@reference) }]
          @findings = remaining_findings
        end

        def descriptor
          DeepCopy.call("name" => "new_flipped_window_type", "source_type" => @source, "target_type" => @target,
            "reference" => @reference, "before" => @before, "after" => @after, "native_guard" => @guard,
            "index_before" => @index, "matrix" => @matrix, "after_matrix" => @after_matrix,
            "world_matrix" => @world_matrix, "after_world_matrix" => @after_world,
            "host_geometry" => @host_geometry, "other_polygons_m" => @others)
        end

        def temporary_ids
          [@target.fetch("id")] + @target.fetch("elements").map { |cell| cell.fetch("id") }
        end

        def reference_entries
          [Records::ReferenceEntry.new(:kind => REFERENCE_KIND, :key => @reference.fetch("entity_path").dup,
            :record => DeepCopy.call(@after))]
        end

        def reference_plan
          Records::ReferencePlan.new(:entries => reference_entries)
        end

        def apply(model, _slots)
          verify_source!(model)
          target_absent!(model)
          NativeUnit.changed!("Window native state changed after flip preview.") unless scope.capture(model) == @guard
          item = Occurrences.resolve(model, @reference, :mutable => true)
          NativeUnit.changed!("The mirrored Window record changed after preview.") unless item.record == @before
          verify_geometry!(model, item.entity.definition)
          HostGuard.verify!(item, @host_geometry)
          check_fit!
          definition = DefinitionWriter.create(:model => model, :type => @target, :plan => @target_plan)
          unless DefinitionGeometry.matches?(definition, :type_id => @target.fetch("id"), :plan => @target_plan)
            raise CodedError.new("geometry.failed", "The flipped Window definition could not be generated.")
          end
          next_index = @index.merge(@target.fetch("id") => definition.persistent_id)
          DefinitionIndex.write(model, next_index, :expected => @index)
          NativeUnit.replace_definition!(item.entity, definition, @after_matrix)
          Units.write(item.entity, @after)
        end

        private

        def verify_source!(model)
          unless @source.is_a?(Hash) && Types::KIND.problems(@source).empty? &&
                 Types::KIND.store.read(model, @source.fetch("id")) == @source
            NativeUnit.changed!("Supply the unchanged authored source Window Type.")
          end
          unless @target.is_a?(Hash) && Types::KIND.problems(@target).empty?
            raise CodedError.new("validation.failed", "Supply a valid new flipped Window Type.")
          end
        end

        def target_absent!(model)
          id = @target.fetch("id")
          if Types::KIND.store.ids(model).include?(id) || DefinitionIndex.read(model).key?(id)
            NativeUnit.changed!("The new flipped Type identity is already in use.")
          end
        end

        def validate_flip!
          expected = GridOperations.flip(@source)
          source_ids = @source.fetch("elements").map { |cell| cell.fetch("id") }
          target_ids = @target.fetch("elements").map { |cell| cell.fetch("id") }
          same_grid = %w[rows_m columns_m].all? { |key| expected.fetch(key) == @target.fetch(key) }
          cells = lambda do |type|
            type.fetch("elements").map { |cell| cell.reject { |key, _value| key == "id" } }
              .sort_by { |cell| cell.fetch("row_span") + cell.fetch("column_span") }
          end
          unless same_grid && cells.call(expected) == cells.call(@target) && (source_ids & target_ids).empty?
            raise CodedError.new("validation.failed",
              "The new Type must be the horizontal grid flip with fresh element ids.")
          end
        end

        def reflection
          Geom::Transformation.new([-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, @source_plan.width_m / INCH_TO_M, 0, 0, 1])
        end

        def flipped_anchor(anchor)
          return anchor.sub("left", "right") if anchor.end_with?("left")
          anchor.sub("right", "left")
        end

        def projected_records(records, path)
          if records.key?(path) && records.fetch(path) != @before
            raise CodedError.new("params.invalid", "The flip supplies conflicting projected Unit records.")
          end
          records.merge(path => @before)
        end

        def verify_geometry!(model, definition)
          check_edit_context!(model, definition)
          unless DefinitionGeometry.matches?(definition, :type_id => @source.fetch("id"), :plan => @source_plan)
            raise CodedError.new("window.definition_changed",
              "Reset edited Window geometry before creating a flipped Type.")
          end
          old = WorldGeometry.map(@source_plan, @world_matrix)
          fresh = WorldGeometry.map(@target_plan, @after_world)
          unless same_panes?(old, fresh) && !WorldGeometry.transform_state(@after_world).mirrored
            raise CodedError.new("geometry.invalid", "The new flipped Type would change the physical Window panes.")
          end
        end

        def same_panes?(before, after)
          remaining = after.panes.map(&:polygon_m)
          before.panes.all? do |pane|
            index = remaining.index { |polygon| same_points?(pane.polygon_m, polygon) }
            index && remaining.delete_at(index)
          end && remaining.empty?
        end

        def same_points?(before, after)
          remaining = after.dup
          before.all? do |point|
            index = remaining.index do |other|
              point.zip(other).all? { |a, b| (a - b).abs <= FaceGeometry::QUANTUM_M }
            end
            index && remaining.delete_at(index)
          end && remaining.empty?
        end

        def check_fit!
          HostGuard.fit!(@host_geometry, WorldGeometry.map(@target_plan, @after_world).outer_polygon_m, @others)
        end

        def remaining_findings
          state = WorldGeometry.transform_state(@after_world)
          conditions = { "window.scaled" => state.scaled, "window.sheared" => state.sheared }
          conditions.select { |_code, present| present }.keys.map do |code|
            { "code" => code,
              "message" => "The flipped Window retains #{code.delete_prefix('window.')} geometry; Reset to Type " \
                           "remains available.",
              "reference" => DeepCopy.call(@reference) }
          end
        end

        def check_edit_context!(model, definition)
          return unless NativeUnit.editing?(model, definition.persistent_id)

          raise CodedError.new("window.definition_editing",
            "Close the source Window definition before creating a flipped Type.")
        end
      end
    end
  end
end
