# frozen_string_literal: true

module PhComposer
  module Zones
    # The Zone handlers the declarations register: reads, Make, Edit and the repairs. Each only reads
    # and proposes; the dispatcher owns the native operation.
    module_function

    def reference_entries(model)
      Occurrences.zones(model).map do |zone|
        Records::ReferenceEntry.new(:kind => REFERENCE_KIND, :key => zone.path, :record => zone.record)
      end
    end

    def repair_split_face(request, proposal, zone:, face_id:, zones:, retaining_entity_path: nil)
      plan = SplitIdentityRepair.plan(request, :zone => zone, :face_id => face_id, :zones => zones,
                                               :retaining_entity_path => retaining_entity_path)
      scopes = plan.fetch(:scope_paths).map { |path| Operations::EntityScope.new(path) }
      proposal.add_step(SplitIdentityRepair::Step.new(plan), :scopes => scopes)
      plan.fetch(:value)
    end

    def repair_identity(request, proposal, zone_path:)
      zone = Repair.occurrence_at(request.model, zone_path)
      plan = Repair.identity_plan(request.model, zone, request.revision, request.registry.catalog, request.engine)
      proposal.add_step(RepairIdentityStep.new(:reference => zone.reference, :plan => plan),
                        :scopes => [Operations::EntityScope.new(zone.path[0...-1])])
      retired = plan.fetch(:faces).count { |face| face.fetch(:before)&.fetch("boundary_condition", nil) == "Surface" }
      { "zone_id" => plan.fetch(:record).fetch("id"), "retired_pairs" => retired }
    end

    def restore(request, proposal, parent_path:, zone_id:)
      record, offer = Repair.restore_plan(request.model, parent_path, zone_id)
      parent_path = Occurrences.integer_path(parent_path)
      step = MakeZoneStep.new(:parent_path => parent_path, :entity_ids => offer.fetch("entity_ids"),
                              :record => record)
      proposal.add_step(step, :scopes => [Operations::EntityScope.new(parent_path)])
      proposal.add_finding(
        "code" => "zone.restore_is_limited", "severity" => "info",
        "message" => "Restore recovers the Zone id, Building-Segment and Level. " \
                     "#{offer.fetch('unrecoverable').join(', ')} went with the Group and are not recovered."
      )
      { "zone_id" => record.fetch("id"), "member_count" => offer.fetch("member_count"),
        "unrecoverable" => offer.fetch("unrecoverable") }
    end

    # One page of Zone occurrences in path order, filtered by id or path; `fields` projects each row to
    # its identity, state and the named values. The Make Zone target and the restorable Zones are
    # small and whole on every page.
    def list(request)
      params = request.params
      zones = Occurrences.zones(request.model)
      duplicates = duplicate_ids(zones)
      zones = zones.select { |zone| params["ids"].include?(zone.record.fetch("id")) } if params.key?("ids")
      zones = zones.select { |zone| params["paths"].include?(zone.path) } if params.key?("paths")
      zones = zones.sort_by(&:path)
      page, next_cursor = Pages.slice(request, "#{FEATURE_ID}.list", zones, :key => :path.to_proc)
      rows = page.map do |zone|
        row = zone_view(zone, duplicates.include?(zone.record.fetch("id")))
        params.key?("fields") ? project_row(row, params["fields"]) : row
      end
      overview(request.model, rows).merge("next_cursor" => next_cursor, "total" => zones.length)
    end

    # Every Zone occurrence, whole: the panel's projection. Scripts page `list` instead.
    def all(request)
      zones = Occurrences.zones(request.model)
      duplicates = duplicate_ids(zones)
      overview(request.model, zones.map { |zone| zone_view(zone, duplicates.include?(zone.record.fetch("id"))) })
    end

    def overview(model, rows)
      { "zones" => rows, "make_zone" => make_target(model), "restorable" => Repair.orphans(model),
        "units" => { "ground_depth_mm" => "mm" } }
    end

    def duplicate_ids(zones)
      zones.group_by { |zone| zone.record.fetch("id") }.select { |_id, rows| rows.length > 1 }.keys
    end

    def project_row(row, fields)
      row.slice("id", "reference", "state").merge("values" => row.fetch("values").slice(*fields))
    end

    # `name` defaults to the next free "Zone N".
    def make(request, proposal, parent_path:, entity_ids:, name: nil)
      parent_path = Occurrences.integer_path(parent_path)
      entity_ids = entity_ids.map { |id| Integer(id) }
      validate_make_target!(request.model, parent_path, entity_ids)
      zone_id = Records::Identity.derived("zon", "model" => request.model.guid, "revision" => request.revision,
                                                "parent_path" => parent_path, "entity_ids" => entity_ids.sort)
      if Occurrences.zones(request.model).any? { |zone| zone.record.fetch("id") == zone_id }
        raise CodedError.new("target.ambiguous", "The proposed Zone identity is already present.")
      end
      name ||= default_name(request.model)
      record = {
        "id" => zone_id, "schema_version" => 1, "name" => name,
        "building_segment" => Occurrences.default_segment(request.model), "level" => nil,
        "ground_depth_mm" => 0.0, "user_data" => {}, "extension_data" => {}
      }
      Schema.validate!(record)
      step = MakeZoneStep.new(:parent_path => parent_path, :entity_ids => entity_ids, :record => record)
      proposal.add_step(step, :scopes => [Operations::EntityScope.new(parent_path)])
      settings = Faces::Settings.read(request.model)
      if settings.fetch("suggest_on_make")
        suggestion = Faces::SuggestMadeZoneStep.new(:zone_id => zone_id, :request => request, :settings => settings)
        proposal.add_step(suggestion,
                          :scopes => [Operations::EntityScope.new(parent_path)])
      end
      { "zone_id" => zone_id }
    end

    def update(request, proposal, reference:, values:, expected_values:)
      occurrence = Occurrences.resolve_zone(request.model, reference, :mutable => true)
      before = occurrence.record
      expected = expected_values
      changed = expected.keys.reject { |key| before[key] == expected[key] }
      unless changed.empty?
        raise CodedError.new("target.changed", "The Zone changed since it was read (#{changed.join(', ')}).")
      end
      after = DeepCopy.call(before)
      values.each { |key, value| after[key] = DeepCopy.call(value) }
      Schema.validate!(after)
      return { "zone_id" => before.fetch("id") } if before == after

      scope = Operations::EntityScope.new(reference.fetch("zone_path")[0...-1])
      proposal.add_step(UpdateZoneStep.new(:reference => reference, :before => before, :after => after),
                        :scopes => [scope])
      { "zone_id" => after.fetch("id") }
    end

    def zone_view(zone, ambiguous)
      Schema.view(zone.record).merge(
        "reference" => zone.reference,
        "state" => zone_state(zone, ambiguous),
        "face_count" => Occurrences.faces(zone).length
      )
    end

    # The native menu's read-only availability check. Submission reads the same target through
    # the public Zone query, which carries the revision required by the Make Zone action.
    def make_target(model)
      selected = model.selection.to_a
      parent_path = Occurrences.active_path(model)
      parent = Occurrences.entities_at(model, parent_path)
      return nil if selected.empty? || selected.any? { |entity| !parent.include?(entity) }

      valid = (selected.length == 1 && selected.first.is_a?(Sketchup::Group)) ||
              selected.all? { |entity| entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Edge) }
      return nil unless valid

      target = { "parent_path" => parent_path, "entity_ids" => selected.map(&:persistent_id) }
      validate_make_target!(model, target.fetch("parent_path"), target.fetch("entity_ids"))
      target
    rescue CodedError
      nil
    end

    def validate_make_target!(model, parent_path, entity_ids)
      unless Occurrences.active_path(model) == parent_path
        raise CodedError.new("target.edit_path_changed", "The active edit path changed before Make Zone.")
      end
      entities = Occurrences.entities_at(model, parent_path)
      selected = entity_ids.map { |id| Occurrences.unique_entity(entities, id) }
      valid = (selected.length == 1 && selected.first.is_a?(Sketchup::Group)) ||
              selected.all? { |entity| entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Edge) }
      raise CodedError.new("target.wrong_kind", "Make Zone accepts one Group or loose Faces and Edges.") unless valid
      if Array(model.active_path).any? { |entity| ZONE_STORE.read(entity) }
        raise CodedError.new("target.wrong_hierarchy", "A Zone cannot be made inside another Zone.")
      end
      selected.each do |entity|
        if entity.is_a?(Sketchup::Group)
          prefix = parent_path + [entity.persistent_id]
          contains_zone = Occurrences.zones(model).any? { |zone| zone.path[0, prefix.length] == prefix }
          if contains_zone
            raise CodedError.new("target.wrong_hierarchy", "The selected Group is already or contains a Zone.")
          end
        end
        if entity.respond_to?(:locked?) && entity.locked?
          raise CodedError.new("target.locked", "The selected Group is locked.")
        end
      end
    end

    def default_name(model)
      used = Occurrences.zones(model).map { |zone| zone.record.fetch("name") }
      number = 1
      number += 1 while used.include?("Zone #{number}")
      "Zone #{number}"
    end

    # A copied Zone is ambiguous and shared at once, and shared storage is reported first: it is the
    # condition that blocks every repair, and it names what the user has to do. Reporting only the
    # ambiguity would point at identity repair, which is the one thing not available here.
    def zone_state(zone, ambiguous)
      return "shared_definition" if zone.shared_definition
      return "ambiguous" if ambiguous
      return "wrong_hierarchy" if zone.nested

      "found"
    end
    private_class_method :zone_view, :validate_make_target!, :zone_state, :overview, :duplicate_ids,
                         :project_row
  end
end
