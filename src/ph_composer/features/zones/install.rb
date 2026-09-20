# frozen_string_literal: true

require_relative "schema"
require_relative "occurrences"
require_relative "steps"
require_relative "adjacency"
require_relative "adjacency_steps"
require_relative "export"

module PhComposer
  module Zones
    OBJECT = { "type" => "object" }.freeze
    PATH = { "type" => "array", "items" => { "type" => "integer" } }.freeze
    ZONE_REFERENCE = {
      "type" => "object", "additionalProperties" => false, "required" => %w[zone_id zone_path],
      "properties" => { "zone_id" => { "type" => "string" }, "zone_path" => PATH }
    }.freeze
    MAKE_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => %w[parent_path entity_ids],
      "properties" => {
        "parent_path" => PATH,
        "entity_ids" => { "type" => "array", "items" => { "type" => "integer" }, "minItems" => 1 },
        "name" => { "type" => "string", "minLength" => 1 }
      }
    }.freeze
    UPDATE_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => %w[reference values expected_values],
      "properties" => {
        "reference" => ZONE_REFERENCE, "values" => ZONE_VALUES, "expected_values" => ZONE_VALUES
      }
    }.freeze
    SOLVE_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => ["zones"],
      "properties" => { "zones" => { "type" => "array", "items" => ZONE_REFERENCE,
                                      "minItems" => 2, "maxItems" => 2 } }
    }.freeze
    RETIRE_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => ["face"],
      "properties" => { "face" => { "type" => "object" } }
    }.freeze

    module_function

    def install(registry)
      feature = registry.feature(FEATURE_ID, :contract_version => Declarations::CONTRACT_VERSION)
      feature.query("#{FEATURE_ID}.list", :description => "Zone occurrences and the explicit Make Zone target.",
                                               :params => OBJECT, :result => OBJECT) { |request| list(request) }
      feature.action("#{FEATURE_ID}.make", :description => "Make one Zone from explicit entities in one edit context.",
                                              :params => MAKE_PARAMS, :result => OBJECT,
                                              :undo_name => "Make Zone",
                                              :side_effects => "Groups loose geometry when needed and writes a Zone " \
                                                               "record.") do |request, proposal|
        make(request, proposal)
      end
      feature.action("#{FEATURE_ID}.update", :description => "Update one explicit Zone occurrence.",
                                                :params => UPDATE_PARAMS, :result => OBJECT,
                                                :undo_name => "Edit Zone",
                                                :side_effects => "Updates Zone values and membership stamps.") do |
                                                  request, proposal|
        update(request, proposal)
      end
      declare_adjacency(feature)
      feature.snapshot_section("#{FEATURE_ID}.overview", :query => "#{FEATURE_ID}.list")
      feature.on_host_event(:selection_changed) { |session| session.request_refresh }
    end

    def declare_adjacency(feature)
      feature.action("#{FEATURE_ID}.solve_adjacency",
                     :description => "Pair complete shared Faces between two explicit Zones.",
                     :params => SOLVE_PARAMS, :result => OBJECT, :undo_name => "Solve Zone Adjacency",
                     :side_effects => "Writes reciprocal Surface endpoints to matched Faces.") do |request, proposal|
        solve_adjacency(request, proposal)
      end
      feature.action("#{FEATURE_ID}.retire_adjacency", :description => "Retire one reciprocal Surface pair.",
                     :params => RETIRE_PARAMS, :result => OBJECT, :undo_name => "Retire Zone Adjacency",
                     :side_effects => "Removes both endpoints and leaves their boundary condition unassigned.") do |
                       request, proposal|
        retire_adjacency(request, proposal)
      end
      feature.proposal_participant("#{FEATURE_ID}.retire_pairs") do |request, targets|
        retire_pairs(request, targets)
      end
      feature.export_contributor(
        ExportProjection::SECTION, :section_version => 1,
        :result => {
          "canonical_model" => Export::Privacy::Optional.new(
            Export::Privacy.fields(%w[hbjson rooms faces surface_pairs omitted])
          )
        }
      ) { |reader| ExportProjection.records(reader) }
    end

    def list(request)
      zones = Occurrences.zones(request.model)
      duplicates = zones.group_by { |zone| zone.record.fetch("id") }.select { |_id, rows| rows.length > 1 }.keys
      {
        "zones" => zones.map { |zone| zone_view(zone, duplicates.include?(zone.record.fetch("id"))) },
        "make_zone" => make_target(request.model),
        "units" => { "ground_depth_mm" => "mm" }
      }
    end

    def make(request, proposal)
      parent_path = Occurrences.integer_path(request.params.fetch("parent_path"))
      entity_ids = request.params.fetch("entity_ids").map { |id| Integer(id) }
      validate_make_target!(request.model, parent_path, entity_ids)
      zone_id = Records::Identity.derived("zon", "model" => request.model.guid, "revision" => request.revision,
                                                "parent_path" => parent_path, "entity_ids" => entity_ids.sort)
      if Occurrences.zones(request.model).any? { |zone| zone.record.fetch("id") == zone_id }
        raise CodedError.new("target.ambiguous", "The proposed Zone identity is already present.")
      end
      name = request.params.fetch("name", default_name(request.model))
      record = {
        "id" => zone_id, "schema_version" => 1, "name" => name,
        "building_segment" => Occurrences.default_segment(request.model), "level" => nil,
        "ground_depth_mm" => 0.0, "user_data" => {}, "extension_data" => {}
      }
      Schema.validate!(record)
      step = MakeZoneStep.new(:parent_path => parent_path, :entity_ids => entity_ids, :record => record)
      proposal.add_step(step, :scopes => [Operations::EntityScope.new(parent_path)])
      { "zone_id" => zone_id }
    end

    def update(request, proposal)
      reference = request.params.fetch("reference")
      occurrence = Occurrences.resolve_zone(request.model, reference, :mutable => true)
      before = ZONE_STORE.read(occurrence.entity)
      expected = request.params.fetch("expected_values")
      changed = expected.keys.reject { |key| before[key] == expected[key] }
      unless changed.empty?
        raise CodedError.new("target.changed", "The Zone changed since it was read (#{changed.join(', ')}).")
      end
      after = DeepCopy.call(before)
      request.params.fetch("values").each { |key, value| after[key] = DeepCopy.call(value) }
      Schema.validate!(after)
      return { "zone_id" => before.fetch("id") } if before == after

      scope = Operations::EntityScope.new(reference.fetch("zone_path")[0...-1])
      proposal.add_step(UpdateZoneStep.new(:reference => reference, :before => before, :after => after),
                        :scopes => [scope])
      { "zone_id" => after.fetch("id") }
    end

    def solve_adjacency(request, proposal)
      pairs = Adjacency.solve(request.model, request.params.fetch("zones"))
      pair_ids = []
      pairs.each do |left, right|
        left_after, right_after, pair_id = Adjacency.pair(left, right)
        pair_ids << pair_id
        next if left_after == left.fetch(:record) && right_after == right.fetch(:record)

        updates = [left, right].zip([left_after, right_after]).map do |side, after|
          occurrence = side.fetch(:occurrence)
          [occurrence.reference(side.fetch(:record).fetch("id")), side.fetch(:record), after]
        end
        scopes = updates.map do |reference, _before, _after|
          Operations::EntityScope.new(reference.fetch("zone_path")[0...-1])
        end
        proposal.add_step(FaceRecordStep.new(:updates => updates, :change => "updated"), :scopes => scopes)
      end
      { "pair_ids" => pair_ids.sort }
    end

    def retire_adjacency(request, proposal)
      occurrence = Occurrences.resolve_face(request.model, request.params.fetch("face"), :mutable => true)
      record = FaceAssignment::FACE_STORE.read(occurrence.entity)
      pair_id = record&.dig("adjacency", "pair_id")
      retire_pair(request, proposal, occurrence, record)
      { "pair_id" => pair_id }
    end

    def retire_pair(request, proposal, occurrence, record)
      local_after, counterpart, other, other_after = Adjacency.retire_records(request.model, occurrence, record)
      updates = [[occurrence.reference(record.fetch("id")), record, local_after],
                 [counterpart.reference(other.fetch("id")), other, other_after]]
      scopes = updates.map do |reference, _before, _after|
        Operations::EntityScope.new(reference.fetch("zone_path")[0...-1])
      end
      proposal.add_step(FaceRecordStep.new(:updates => updates, :change => "retired"), :scopes => scopes)
      local_after
    end

    # Plans the reciprocal retirement for a whole gesture without writing anything. The caller
    # composes the returned records into its own step, so face assignment never edits an adjacency
    # envelope itself and one Face is written once even when both endpoints are being classified.
    #
    # Returns { occurrence key => [reference, before, after] } covering both targets and the
    # counterparts they drag in.
    def retire_pairs(request, targets)
      plan = {}
      targets.each do |occurrence, record|
        local_after, counterpart, other, other_after = Adjacency.retire_records(request.model, occurrence, record)
        add_retirement(plan, occurrence.reference(record.fetch("id")), record, local_after)
        add_retirement(plan, counterpart.reference(other.fetch("id")), other, other_after)
      end
      plan
    end

    def add_retirement(plan, reference, before, after)
      key = Occurrences.key(reference)
      existing = plan[key]
      if existing && existing.fetch(2) != after
        raise CodedError.new("adjacency.ambiguous",
                             "Face #{before.fetch('id')} would be retired two different ways in one gesture.")
      end

      plan[key] = [reference, before, after]
    end
    private_class_method :add_retirement

    def zone_view(zone, ambiguous)
      Schema.view(zone.record).merge(
        "reference" => zone.reference,
        "state" => zone_state(zone, ambiguous),
        "face_count" => Occurrences.faces(zone).length
      )
    end

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

    def zone_state(zone, ambiguous)
      return "ambiguous" if ambiguous
      return "wrong_hierarchy" if zone.nested
      return "shared_definition" if zone.shared_definition

      "found"
    end
    private_class_method :declare_adjacency, :zone_view, :make_target, :validate_make_target!, :default_name,
                         :zone_state
  end
end
