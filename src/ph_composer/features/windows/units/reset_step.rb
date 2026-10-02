# frozen_string_literal: true

require_relative "definition_writer"
require_relative "definition_index"
require_relative "definition_geometry"
require_relative "mutation_scope"
require_relative "world_geometry"
require_relative "native_unit"
require_relative "host_guard"
require_relative "../../../core/vector3"
require_relative "../placement/fit"

module PhComposer
  module Windows
    module Units
      # Explicit repair of known-Type units. All shared users enter the plan before a primary definition is rewritten.
      class ResetStep
        attr_reader :scope, :affected, :findings

        def initialize(model:, type:, items:, expected_records: {}, hosts: {}, outline_inventory_m: {})
          raise CodedError.new("params.invalid", "Choose at least one Window to reset.") if items.empty?

          @type = DeepCopy.call(type)
          verify_type!(model)
          @plan = DefinitionPlan.build(@type)
          @index = DeepCopy.call(DefinitionIndex.read(model))
          @index.each_key { |id| DefinitionIndex.resolve(model, id) unless id == @type.fetch("id") }
          @definition_id = @index[@type.fetch("id")]
          definition = model.definitions.to_a.find { |entry| entry.persistent_id == @definition_id }
          stamp = definition && DEFINITION_STORE.read(definition)
          @rebuild = !definition || !stamp.is_a?(Hash) || stamp["window_type_id"] != @type.fetch("id")
          @rewrite = !@rebuild && !clean?(definition)
          @projected = DeepCopy.call(expected_records)
          occurrences = Occurrences.all(model)
          selected = select_items(occurrences, items)
          canonical = @rewrite ? canonical_items(model, occurrences) : []
          @selected_paths = selected.map(&:path)
          @rows = (selected + canonical).uniq(&:path).map do |item|
            prepare_row(model, item, hosts)
          end
          check_edit_context!(model)
          if needed?
            prepare_outlines!(occurrences, outline_inventory_m)
            check_fit!
          end
          ids = occurrences.map { |item| item.entity.definition.persistent_id }
          ids << definition.persistent_id if definition
          @scope = MutationScope.new(:definition_ids => ids)
          @guard = scope.capture(model, :expected_records => @projected)
          @affected = needed? ? @rows.select { |row| changed_row?(row) }.map { |row| affected_row(row) } : []
          @findings = @rewrite ? [{ "code" => "window.shared_definition_reset",
            "message" => "Reset replaces the edited primary Window definition for all of its units.",
            "unit_count" => @rows.length,
            "references" => @rows.map { |row| DeepCopy.call(row.fetch("reference")) } }] : []
        end

        def needed?
          @rebuild || @rewrite || @rows.any? { |row| changed_row?(row) }
        end

        def descriptor
          DeepCopy.call("name" => "reset_window_units_to_type", "type" => @type, "index_before" => @index,
            "definition_id" => @definition_id, "rebuild" => @rebuild, "rewrite" => @rewrite,
            "native_guard" => @guard, "items" => @rows, "findings" => @findings)
        end

        def temporary_ids
          []
        end

        def apply(model, _slots)
          return unless needed?

          verify_type!(model)
          check_edit_context!(model)
          NativeUnit.changed!("Window native state changed after reset preview.") unless scope.capture(model) == @guard
          current = Occurrences.all(model)
          canonical_items(model, current) if @rewrite
          resolved = @rows.map do |row|
            NativeUnit.unchanged!(current, row.fetch("reference").fetch("entity_path"), row.fetch("record"))
          end
          @rows.zip(resolved).each do |row, item|
            Occurrences.assert_leaf!(item) if changing_definition?(row)
          end
          @rows.zip(resolved).each { |row, item| HostGuard.verify!(item, row["host_geometry"]) }
          check_fit!
          definition = if @rebuild
                         rebuild(model)
                       else
                         DefinitionIndex.resolve(model, @type.fetch("id"))
                       end
          if @rewrite
            DefinitionWriter.rewrite(:model => model, :definition => definition, :type => @type, :plan => @plan)
          end
          unless clean?(definition)
            raise CodedError.new("geometry.failed", "The reset primary definition could not be generated.")
          end

          @rows.zip(resolved).each do |row, item|
            next unless changed_row?(row)

            NativeUnit.replace_definition!(item.entity, definition, row.fetch("after_matrix"))
            next if Units.read(item.entity) == row.fetch("record")

            raise CodedError.new("geometry.failed", "Native reset could not preserve the Window record.")
          end
        end

        private

        def verify_type!(model)
          unless @type.is_a?(Hash) && Types::KIND.problems(@type).empty? &&
                 Types::KIND.store.read(model, @type.fetch("id")) == @type
            raise CodedError.new("window.unknown_type", "Reset requires the unchanged authored Window Type.")
          end
        end

        def select_items(occurrences, items)
          paths = items.map { |input| input.fetch(:reference).fetch("entity_path") }
          raise CodedError.new("params.invalid", "A Window reset repeats an occurrence.") unless paths.uniq == paths

          items.map do |input|
            item = NativeUnit.resolve!(occurrences, input.fetch(:reference))
            record = DeepCopy.call(Units.validate!(input.fetch(:expected_record)))
            if @projected.key?(item.path) && @projected.fetch(item.path) != record
              raise CodedError.new("params.invalid", "The reset supplies conflicting projected Unit records.")
            end
            @projected[item.path] = record
            item
          end
        end

        def canonical_items(model, occurrences)
          all = native_parents(model.entities)
          canonical = occurrences.select { |item| item.entity.definition.persistent_id == @definition_id }
          definition = model.definitions.to_a.find { |entry| entry.persistent_id == @definition_id }
          managed_ids = canonical.map { |item| item.entity.persistent_id }.uniq.sort
          native_ids = definition.instances.map(&:persistent_id).sort
          unless all.keys.sort == canonical.map(&:path).sort && native_ids == managed_ids
            raise CodedError.new("record.unreadable",
              "Every primary Window instance needs a valid Unit record for reset.")
          end
          canonical
        end

        def prepare_row(model, item, hosts)
          Occurrences.mutable!(item)
          record = DeepCopy.call(Units.validate!(@projected.fetch(item.path, item.record)))
          unless record.fetch("window_type_id") == @type.fetch("id")
            raise CodedError.new("reference.invalid", "Reset only units of the supplied authored Window Type.")
          end
          selected = @selected_paths.include?(item.path)
          if selected && WorldGeometry.transform_state(item.transform.to_a).mirrored
            raise CodedError.new("window.mirrored", "Create a new flipped Type to repair a mirrored Window.")
          end
          parent = item.parent_transform
          matrix = item.entity.transformation.to_a
          world = item.transform.to_a
          world_after = selected && inplane_changed?(world) ? normalized_world(world, record) : world
          local_after = world_after == world ? matrix : (parent.inverse * Geom::Transformation.new(world_after)).to_a
          row = { "reference" => { "unit_id" => record.fetch("id"), "entity_path" => item.path.dup },
            "record" => record, "matrix" => matrix, "after_matrix" => local_after,
            "world_matrix" => world, "after_world_matrix" => world_after,
            "definition_id" => item.entity.definition.persistent_id,
            "glued_face_id" => item.entity.glued_to&.persistent_id }
          Occurrences.assert_leaf!(item) if changing_definition?(row)
          capture_host!(row, item, hosts[item.path]) if item.entity.glued_to && changed_row?(row)
          row
        end

        def prepare_outlines!(occurrences, inventory)
          unless inventory.is_a?(Hash) && inventory.keys.sort == occurrences.map(&:path).sort
            raise CodedError.new("window.outlines_required",
              "Supply the complete Window outline inventory keyed by occurrence path.")
          end
          planned_paths = @rows.map { |row| row.fetch("reference").fetch("entity_path") }
          outsiders = inventory.reject { |path, _polygon| planned_paths.include?(path) }.values
          if outsiders.any?(&:nil?)
            raise CodedError.new("window.type_geometry_unknown",
              "Recover the untouched Window geometry before resetting a neighboring Unit.")
          end
          @rows.each { |row| row["other_polygons_m"] = DeepCopy.call(outsiders) if changed_row?(row) }
        end

        def changed_row?(row)
          changing_definition?(row) || row.fetch("matrix") != row.fetch("after_matrix")
        end

        def changing_definition?(row)
          @rebuild || @rewrite || row.fetch("definition_id") != @definition_id
        end

        def affected_row(row)
          { "kind" => REFERENCE_KIND, "id" => row.fetch("record").fetch("id"), "change" => "reset_to_type",
            "reference" => DeepCopy.call(row.fetch("reference")) }
        end

        def inplane_changed?(matrix)
          x, y = matrix.take(3), matrix[4, 3]
          (Vector3.length(x) - 1).abs > WorldGeometry::TOLERANCE ||
            (Vector3.length(y) - 1).abs > WorldGeometry::TOLERANCE || Vector3.dot(x, y).abs > WorldGeometry::TOLERANCE
        end

        def normalized_world(matrix, record)
          degenerate = "The Window in-plane basis is degenerate."
          x = Vector3.normalize(matrix.take(3), :message => degenerate)
          raw_y = matrix[4, 3]
          y = Vector3.normalize(raw_y.zip(x).map { |value, right| value - right * Vector3.dot(raw_y, x) },
            :message => degenerate)
          z = Vector3.cross(x, y)
          fixed = WorldGeometry.anchor(@plan, record.fetch("anchor"), matrix)
          anchor = Anchors.point(record.fetch("anchor"), :width_m => @plan.width_m, :height_m => @plan.height_m)
          origin = 3.times.map { |axis| (fixed[axis] - x[axis] * anchor[0] - y[axis] * anchor[1]) / INCH_TO_M }
          result = x + [0] + y + [0] + z + [0] + origin + [1]
          WorldGeometry.transform_state(result)
          result
        end

        # Reset reads hosts without locating them, so a host in an ambiguous Zone reaches here.
        def capture_host!(row, item, host)
          if host && host.zone_state != "found"
            raise CodedError.new("window.host_required", "Reset requires a host in a unique authored Zone.")
          end
          row["host_geometry"] = HostGuard.capture(item, host)
        end

        def check_fit!
          polygons = @rows.map { |row| WorldGeometry.map(@plan, row.fetch("after_world_matrix")).outer_polygon_m }
          @rows.each_with_index do |row, index|
            next unless changed_row?(row)

            neighbors = polygons.each_with_index.filter_map { |polygon, i| polygon unless i == index }
            HostGuard.fit!(row["host_geometry"], polygons[index], row.fetch("other_polygons_m") + neighbors)
          end
        end

        def rebuild(model)
          definition = DefinitionWriter.create(:model => model, :type => @type, :plan => @plan)
          DefinitionIndex.write(model, @index.merge(@type.fetch("id") => definition.persistent_id), :expected => @index)
          definition
        end

        def clean?(definition)
          DefinitionWriter.configured?(definition.behavior) &&
            definition.name == DefinitionWriter::NAME_PREFIX + @type.fetch("name") &&
            DefinitionGeometry.matches?(definition, :type_id => @type.fetch("id"), :plan => @plan)
        end

        def check_edit_context!(model)
          return unless NativeUnit.editing?(model, @definition_id)

          raise CodedError.new("window.definition_editing", "Close the primary Window definition before reset.")
        end

        def native_parents(entities, path = [], transform = Geom::Transformation.new, ancestors = [])
          entities.each_with_object({}) do |entity, found|
            next unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
            id = entity.definition.persistent_id
            raise CodedError.new("record.unreadable", "Window native storage is recursive.") if ancestors.include?(id)

            current = path + [entity.persistent_id]
            found[current] = transform if entity.is_a?(Sketchup::ComponentInstance) && id == @definition_id
            found.merge!(native_parents(entity.definition.entities, current, transform * entity.transformation,
              ancestors + [id]))
          end
        end
      end
    end
  end
end
