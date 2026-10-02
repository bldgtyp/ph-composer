# frozen_string_literal: true

require_relative "definition_writer"
require_relative "definition_index"
require_relative "definition_geometry"
require_relative "mutation_scope"
require_relative "world_geometry"
require_relative "native_unit"
require_relative "host_guard"
require_relative "../placement/host"
require_relative "../placement/fit"

module PhComposer
  module Windows
    module Units
      # The caller supplies validated Types, public-resolved hosts and complete other-unit
      # outlines, then owns the proposal/operation. Only the indexed primary definition changes.
      class TypeChangeStep
        attr_reader :affected, :scope, :findings

        def initialize(model:, before:, after:, expected_records: {}, hosts: {}, other_polygons_m: {})
          @before = DeepCopy.call(before)
          @after = DeepCopy.call(after)
          unless @before.fetch("id") == @after.fetch("id")
            raise CodedError.new("params.invalid", "A Type change must preserve its identity.")
          end
          definition = DefinitionIndex.resolve(model, @before.fetch("id"))
          @definition_id = definition&.persistent_id
          @rows = []
          @affected = []
          @findings = []
          @geometry_changed = @name_changed = false
          occurrences = Occurrences.all(model)
          @unit_count = occurrences.count { |item| item.entity.definition.persistent_id == @definition_id }
          prepare_plans(definition) if definition
          definition_ids = @definition_id ? [@definition_id] : []
          definition_ids += occurrences.map { |item| item.entity.definition.persistent_id } if @geometry_changed
          @scope = MutationScope.new(:definition_ids => definition_ids)
          if needed?
            check_edit_context!(model)
            @rows = prepare_rows(model, occurrences, expected_records, hosts, other_polygons_m)
            if @geometry_changed && !DefinitionGeometry.matches?(definition,
              :type_id => @before.fetch("id"), :plan => @before_plan)
              @findings << { "code" => "window.edited_geometry_replaced",
                "message" => "This Type edit replaces the edited primary Window geometry.",
                "references" => @rows.map { |row| DeepCopy.call(row.fetch("reference")) } }
            end
            check_fit!
            @affected = @rows.map do |row|
              { "kind" => REFERENCE_KIND, "id" => row.fetch("record").fetch("id"),
                "change" => "geometry_updated", "reference" => row.fetch("reference") }
            end if @geometry_changed
          end
          @guard = scope.capture(model, :expected_records => expected_records)
        end

        def needed?
          @definition_id && (@geometry_changed || @name_changed)
        end

        def descriptor
          DeepCopy.call({ "name" => "change_window_type_definition", "before" => @before, "after" => @after,
            "definition_id" => @definition_id, "geometry_changed" => @geometry_changed,
            "native_guard" => @guard, "units" => @rows })
        end

        def apply(model, _slots)
          return unless needed?

          check_edit_context!(model)
          unless scope.capture(model) == @guard
            raise CodedError.new("target.changed", "Window native state changed after preview.")
          end
          definition = DefinitionIndex.resolve(model, @before.fetch("id"))
          current = Occurrences.all(model)
          resolved = @rows.map do |row|
            NativeUnit.unchanged!(current, row.fetch("reference").fetch("entity_path"), row.fetch("record"))
          end
          verify_users!(definition, resolved, :code => "target.changed")
          @rows.zip(resolved).each { |row, item| HostGuard.verify!(item, row["host_geometry"]) }
          DefinitionWriter.rewrite(:model => model, :definition => definition, :type => @after,
            :plan => @after_plan) if @geometry_changed
          definition.name = DefinitionWriter::NAME_PREFIX + @after.fetch("name") if @name_changed
          if @geometry_changed
            @rows.zip(resolved).each do |row, item|
              item.entity.transformation = Geom::Transformation.new(row.fetch("after_matrix"))
            end
          end
        end

        private

        def prepare_plans(definition)
          @before_plan = DefinitionPlan.build(@before)
          @after_plan = DefinitionPlan.build(@after)
          @geometry_changed = @before_plan.signature != @after_plan.signature
          @name_changed = @before.fetch("name") != @after.fetch("name")
          unless DEFINITION_STORE.read(definition)&.fetch("window_type_id", nil) == @before.fetch("id")
            raise CodedError.new("target.changed", "The indexed Window definition no longer matches its Type.")
          end
        end

        def prepare_rows(model, occurrences, expected, hosts, others)
          canonical = occurrences.select { |item| item.entity.definition.persistent_id == @definition_id }
          native = canonical_parents(model.entities)
          unless canonical.map(&:path).sort == native.keys.sort
            raise CodedError.new("record.unreadable", "Every primary Window instance needs a valid Unit record.")
          end
          definition = model.definitions.to_a.find { |entry| entry.persistent_id == @definition_id }
          verify_users!(definition, canonical)
          canonical.map do |item|
            Occurrences.mutable!(item)
            Occurrences.assert_leaf!(item) if @geometry_changed
            record = expected.fetch(item.path, item.record)
            Units.validate!(record)
            unless record.fetch("window_type_id") == @before.fetch("id")
              raise CodedError.new("reference.invalid", "A primary Window instance refers to a different Type.")
            end
            row = instance_row(item, record, native.fetch(item.path))
            capture_host!(row, item, hosts, others) if @geometry_changed && item.entity.glued_to
            row
          end
        end

        def verify_users!(definition, items, code: "record.unreadable")
          unless definition.instances.map(&:persistent_id).sort == items.map { |item|
            item.entity.persistent_id }.uniq.sort
            raise CodedError.new(code, "Every primary Window user must be a reachable authored Unit.")
          end
        end

        def instance_row(item, record, parent)
          matrix = item.entity.transformation.to_a
          changed = @geometry_changed ? WorldGeometry.reanchor(matrix, :before => @before_plan,
            :after => @after_plan, :anchor => record.fetch("anchor")) : matrix
          { "reference" => { "unit_id" => record.fetch("id"), "entity_path" => item.path.dup },
            "record" => DeepCopy.call(record), "matrix" => matrix, "after_matrix" => changed,
            "world_matrix" => item.transform.to_a,
            "after_world_matrix" => (parent * Geom::Transformation.new(changed)).to_a,
            "definition_id" => @definition_id, "glued_face_id" => item.entity.glued_to&.persistent_id }
        end

        def capture_host!(row, item, hosts, others)
          host = hosts[item.path]
          unless host && others.key?(item.path)
            raise CodedError.new("window.host_required",
              "Supply the host and complete other-unit outlines for each glued Window.")
          end
          row["host_geometry"] = HostGuard.capture(item, host)
          row["host_key"] = host.parent_path + [host.entity.persistent_id]
          row["other_polygons_m"] = DeepCopy.call(others.fetch(item.path))
        end

        def check_fit!
          blocked = []
          @rows.each do |row|
            next unless row["host_geometry"]

            neighbors = @rows.reject { |other| other.equal?(row) }
            polygons = row.fetch("other_polygons_m") + neighbors.map { |other| outline(other) }
            begin
              HostGuard.fit!(row.fetch("host_geometry"), outline(row), polygons)
            rescue CodedError => error
              raise unless %w[window.overhang window.overlap].include?(error.code)

              blocked << { "reference" => row.fetch("reference"), "code" => error.code, "message" => error.message }
            end
          end
          return if blocked.empty?

          raise CodedError.new(blocked.first.fetch("code"), "The Type edit does not fit every Window host.",
            "unit_count" => @unit_count, "blocked_units" => blocked)
        end

        def outline(row)
          WorldGeometry.map(@after_plan, row.fetch("after_world_matrix")).outer_polygon_m
        end

        def check_edit_context!(model)
          return unless NativeUnit.editing?(model, @definition_id)

          raise CodedError.new("window.definition_editing",
            "Close the primary Window definition before changing its Type.",
            "unit_count" => @unit_count, "definition_id" => @definition_id)
        end

        # Capture parent bases directly; world * local.inverse introduces cancellation drift in
        # otherwise valid mirrored/scaled host transforms. Also includes unstamped instances.
        def canonical_parents(entities, path = [], transform = Geom::Transformation.new, ancestors = [])
          entities.each_with_object({}) do |entity, found|
            next unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)

            definition = entity.definition
            if ancestors.include?(definition.persistent_id)
              raise CodedError.new("record.unreadable", "Window instance storage is recursive.")
            end
            current = path + [entity.persistent_id]
            found[current] = transform if entity.is_a?(Sketchup::ComponentInstance) &&
                                          definition.persistent_id == @definition_id
            found.merge!(canonical_parents(definition.entities, current, transform * entity.transformation,
              ancestors + [definition.persistent_id]))
          end
        end
      end
    end
  end
end
