# frozen_string_literal: true

require_relative "definition_writer"
require_relative "definition_index"
require_relative "definition_geometry"
require_relative "mutation_scope"
require_relative "world_geometry"
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
          changed!("Window native state changed after reset preview.") unless scope.capture(model) == @guard
          current = Occurrences.all(model)
          canonical_items(model, current) if @rewrite
          resolved = @rows.map { |row| resolve_row!(current, row) }
          @rows.zip(resolved).each do |row, item|
            Occurrences.assert_leaf!(item) if changing_definition?(row)
          end
          @rows.zip(resolved).each { |row, item| check_host!(row, item) }
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
            write_row!(item.entity, row, definition) if changed_row?(row)
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
            reference = input.fetch(:reference)
            found = occurrences.select { |item| item.path == reference.fetch("entity_path") }
            unless found.length == 1 && found.first.record.fetch("id") == reference.fetch("unit_id")
              changed!("A selected Window reset reference no longer resolves uniquely.")
            end
            record = DeepCopy.call(Units.validate!(input.fetch(:expected_record)))
            if @projected.key?(found.first.path) && @projected.fetch(found.first.path) != record
              raise CodedError.new("params.invalid", "The reset supplies conflicting projected Unit records.")
            end
            @projected[found.first.path] = record
            found.first
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
          mutable!(item)
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
            "world_matrix" => world, "after_world_matrix" => world_after, "parent_matrix" => parent.to_a,
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
          (length(x) - 1).abs > WorldGeometry::TOLERANCE || (length(y) - 1).abs > WorldGeometry::TOLERANCE ||
            dot(x, y).abs > WorldGeometry::TOLERANCE
        end

        def normalized_world(matrix, record)
          x = normalize(matrix.take(3))
          raw_y = matrix[4, 3]
          y = normalize(raw_y.zip(x).map { |value, right| value - right * dot(raw_y, x) })
          z = cross(x, y)
          fixed = WorldGeometry.anchor(@plan, record.fetch("anchor"), matrix)
          anchor = Anchors.point(record.fetch("anchor"), :width_m => @plan.width_m, :height_m => @plan.height_m)
          origin = 3.times.map { |axis| (fixed[axis] - x[axis] * anchor[0] - y[axis] * anchor[1]) / INCH_TO_M }
          result = x + [0] + y + [0] + z + [0] + origin + [1]
          WorldGeometry.transform_state(result)
          result
        end

        def capture_host!(row, item, host)
          unless host && host.parent_path == item.path[0...-1] &&
                 host.entity.persistent_id == row.fetch("glued_face_id") &&
                 host.transform.to_a == row.fetch("parent_matrix")
            raise CodedError.new("window.host_required",
              "Supply the matching public host for every glued reset Window.")
          end
          unless host.zone_state == "found"
            raise CodedError.new("window.host_required", "Reset requires a host in a unique authored Zone.")
          end
          if host.values["boundary_condition"] == "Surface"
            raise CodedError.new("window.surface_host", "A paired Surface Face cannot host a Window unit.")
          end
          row["host_geometry"] = DeepCopy.call(host.geometry.to_h)
          check_host!(row, item)
        end

        def check_host!(row, item)
          return unless row["host_geometry"]

          current = FaceGeometry.capture(item.entity.glued_to, Geom::Transformation.new(row.fetch("parent_matrix")))
          unless current.to_h == row.fetch("host_geometry")
            changed!("The reset Window host geometry changed after preview.")
          end
        end

        def check_fit!
          changing = @rows.select { |row| changed_row?(row) }
          polygons = @rows.map { |row| WorldGeometry.map(@plan, row.fetch("after_world_matrix")).outer_polygon_m }
          changing.each do |row|
            index = @rows.index(row)
            geometry = row["host_geometry"]
            host = if geometry
                     FaceGeometry::Snapshot.new(:loops_m => geometry.fetch("loops_m"),
                       :normal => geometry.fetch("normal"))
                   else
                     a, b, c = polygons[index].take(3)
                     x, y = [b, c].map { |point| point.zip(a).map { |value, origin| value - origin } }
                     FaceGeometry::Snapshot.new(:loops_m => [polygons[index]],
                       :normal => cross(x, y))
                   end
            neighbors = polygons.each_with_index.filter_map { |polygon, i| polygon unless i == index }
            Placement::Fit.check!(host, polygons[index],
              :existing_polygons_m => row.fetch("other_polygons_m") + neighbors)
          end
        end

        def rebuild(model)
          definition = DefinitionWriter.create(:model => model, :type => @type, :plan => @plan)
          DefinitionIndex.write(model, @index.merge(@type.fetch("id") => definition.persistent_id), :expected => @index)
          definition
        end

        def clean?(definition)
          behavior = definition.behavior
          behavior.is2d? && behavior.cuts_opening? && behavior.snapto == SnapTo_Arbitrary &&
            behavior.no_scale_mask? == 127 &&
            definition.name == DefinitionWriter::NAME_PREFIX + @type.fetch("name") &&
            DefinitionGeometry.matches?(definition, :type_id => @type.fetch("id"), :plan => @plan)
        end

        def write_row!(entity, row, definition)
          glue = entity.glued_to
          entity.definition = definition
          entity.transformation = Geom::Transformation.new(row.fetch("after_matrix"))
          entity.glued_to = glue
          unless entity.definition == definition && entity.transformation.to_a == row.fetch("after_matrix") &&
                 entity.glued_to == glue && Units.read(entity) == row.fetch("record")
            raise CodedError.new("geometry.failed",
              "Native reset could not preserve the Window record, transform or glue.")
          end
        end

        def resolve_row!(occurrences, row)
          found = occurrences.select { |item| item.path == row.fetch("reference").fetch("entity_path") }
          changed!("A reset Window record changed after preview.") unless found.length == 1 &&
            found.first.record == row.fetch("record")
          mutable!(found.first)
          found.first
        end

        def mutable!(item)
          if item.shared_storage
            raise CodedError.new("target.shared_definition", "Make the Window parent storage unique before reset.")
          end
          raise CodedError.new("target.locked", "The Window unit or its parent is locked.") if item.locked
        end

        def check_edit_context!(model)
          return unless Array(model.active_path).any? { |entity| entity.definition.persistent_id == @definition_id }

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

        def normalize(vector)
          size = length(vector)
          unless size.positive? && size.finite?
            raise CodedError.new("geometry.invalid", "The Window in-plane basis is degenerate.")
          end
          vector.map { |value| value / size }
        end

        def length(vector)
          Math.hypot(Math.hypot(vector[0], vector[1]), vector[2])
        end

        def dot(a, b)
          a.zip(b).sum { |left, right| left * right }
        end

        def cross(a, b)
          [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
        end

        def changed!(message)
          raise CodedError.new("target.changed", "#{message} Nothing was written.")
        end
      end
    end
  end
end
