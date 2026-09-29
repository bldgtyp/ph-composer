# frozen_string_literal: true

require_relative "schema"
require_relative "occurrences"
require_relative "index"
require_relative "steps"
require_relative "overlap"
require_relative "adjacency"
require_relative "face_split"
require_relative "adjacency_steps"
require_relative "repair"
require_relative "export"
require_relative "colour_modes"

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
    # The resolved mutation set, whatever produced it: the selected Zones, or every Zone when the
    # caller is the export preflight. One Zone is allowed; it simply pairs with nothing.
    SOLVE_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => ["zones"],
      "properties" => { "zones" => { "type" => "array", "items" => ZONE_REFERENCE, "minItems" => 1 } }
    }.freeze
    RETIRE_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => ["face"],
      "properties" => { "face" => { "type" => "object" } }
    }.freeze
    # The copy is named by path, not by id: its id is the ambiguous thing being repaired.
    REPAIR_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => ["zone_path"],
      "properties" => { "zone_path" => PATH }
    }.freeze
    RESTORE_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => %w[parent_path zone_id],
      "properties" => { "parent_path" => PATH, "zone_id" => { "type" => "string" } }
    }.freeze

    module_function

    def install(registry)
      feature = registry.feature(FEATURE_ID, :contract_version => Declarations::CONTRACT_VERSION)
      ColourModes.install(feature)
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
      declare_repairs(feature)
      feature.snapshot_section("#{FEATURE_ID}.overview", :query => "#{FEATURE_ID}.list")
      feature.on_host_event(:selection_changed) { |session| session.request_refresh }
    end

    def declare_adjacency(feature)
      feature.action("#{FEATURE_ID}.solve_adjacency",
                     :description => "Reconcile and pair shared Faces within an explicit Zone scope.",
                     :params => SOLVE_PARAMS, :result => OBJECT, :undo_name => "Solve Zone Adjacency",
                     :side_effects => "Retires old Surface pairs and writes current endpoints.") do |request, proposal|
        solve_adjacency(request, proposal)
      end
      feature.action("#{FEATURE_ID}.retire_adjacency", :description => "Retire one reciprocal Surface pair.",
                     :params => RETIRE_PARAMS, :result => OBJECT, :undo_name => "Retire Zone Adjacency",
                     :side_effects => "Removes both endpoints and leaves their boundary condition unassigned.") do |
                       request, proposal|
        retire_adjacency(request, proposal)
      end
      feature.proposal_participant("#{FEATURE_ID}.retire_pairs") do |request, targets, index = nil|
        retire_pairs(request, targets, index)
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

    def declare_repairs(feature)
      feature.action("#{FEATURE_ID}.repair_identity",
                     :description => "Give one copied Zone occurrence an identity of its own.",
                     :params => REPAIR_PARAMS, :result => OBJECT, :undo_name => "Repair Zone Identity",
                     :side_effects => "Reidentifies the named occurrence and its Faces; the original is " \
                                      "left untouched.") do |request, proposal|
        repair_identity(request, proposal)
      end
      feature.action("#{FEATURE_ID}.restore",
                     :description => "Regroup the stamped members of an exploded Zone, recovering only their stamp.",
                     :params => RESTORE_PARAMS, :result => OBJECT, :undo_name => "Restore Zone",
                     :side_effects => "Groups stamped Faces in one parent context and writes a Zone record.") do |
                       request, proposal|
        restore(request, proposal)
      end
    end

    def repair_identity(request, proposal)
      zone = Repair.occurrence_at(request.model, request.params.fetch("zone_path"))
      plan = Repair.identity_plan(request.model, zone, request.revision, request.registry.catalog, request.engine)
      proposal.add_step(RepairIdentityStep.new(:reference => zone.reference, :plan => plan),
                        :scopes => [Operations::EntityScope.new(zone.path[0...-1])])
      retired = plan.fetch(:faces).count { |face| face.fetch(:before)&.fetch("boundary_condition", nil) == "Surface" }
      { "zone_id" => plan.fetch(:record).fetch("id"), "retired_pairs" => retired }
    end

    def restore(request, proposal)
      record, offer = Repair.restore_plan(request.model, request.params.fetch("parent_path"),
                                          request.params.fetch("zone_id"), request.revision)
      parent_path = Occurrences.integer_path(request.params.fetch("parent_path"))
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

    def list(request)
      zones = Occurrences.zones(request.model)
      duplicates = zones.group_by { |zone| zone.record.fetch("id") }.select { |_id, rows| rows.length > 1 }.keys
      {
        "zones" => zones.map { |zone| zone_view(zone, duplicates.include?(zone.record.fetch("id"))) },
        "make_zone" => make_target(request.model),
        "restorable" => Repair.orphans(request.model),
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
      plan = Adjacency.plan(request.model, request.params.fetch("zones"))
      plan.findings.each { |finding| proposal.add_finding(finding) }
      unless plan.retirements.empty?
        scopes = plan.retirements.map do |reference, _before, _after|
          Operations::EntityScope.new(reference.fetch("zone_path")[0...-1])
        end
        proposal.add_step(FaceRecordStep.new(:updates => plan.retirements, :change => "retired"), :scopes => scopes)
      end
      full, partial = plan.matches.partition { |match| match.fetch(:overlap).kind == :full }
      pair_ids = full.map { |match| pair_match(proposal, match) }
      pair_ids.concat(partial.map { |match| split_match(request, proposal, match) })
      { "pair_ids" => pair_ids.compact.sort, "reported" => proposal.findings.length }
    end

    # A partial overlap is cut on both sides and paired in one step, because the pair's endpoints
    # do not exist until both Faces have been cut.
    def split_match(request, proposal, match)
      overlap = match.fetch(:overlap)
      check_unpaired!(match)
      pair_id = Records::Identity.derived(
        "adj", "faces" => [:left, :right].map { |side| match.fetch(side).fetch(:record).fetch("id") }.sort
      )
      sides = [:left, :right].map do |name|
        side_plan(request, match.fetch(name), overlap, name == :left ? :left : :right)
      end
      scopes = sides.map { |side| Operations::EntityScope.new(side.fetch("reference").fetch("zone_path")) }
      proposal.add_step(
        SplitAndPairStep.new(:left => sides.fetch(0), :right => sides.fetch(1),
                             :polygon_m => overlap.polygon_m, :pair_id => pair_id),
        :scopes => scopes
      )
      pair_id
    end

    # The plan must retire an old Surface pair before proposing a cut, including its surviving
    # counterpart. Refuse an inconsistent plan rather than silently dropping one end of a pair.
    def check_unpaired!(match)
      paired = [:left, :right].select { |name| match.fetch(name).fetch(:record)["boundary_condition"] == "Surface" }
      return if paired.empty?

      raise CodedError.new("adjacency.stale",
                           "A Face that would be cut still holds a Surface pair. Retire it before solving again.")
    end

    # Ids for every piece the cut may need, allocated now so the preview digest is stable. Which
    # piece keeps the original id is the host's answer and is not known until it has cut.
    def side_plan(request, side, overlap, which)
      occurrence = side.fetch(:occurrence)
      record = side.fetch(:record)
      remainders = which == :left ? overlap.left_remainders_m : overlap.right_remainders_m
      fresh = (remainders.length + 1).times.map do |index|
        Records::Identity.derived("fac", "model" => request.model.guid, "revision" => request.revision,
                                         "zone_path" => occurrence.zone.path, "entity_path" => occurrence.path,
                                         "piece" => index)
      end
      copies = {}
      unless remainders.empty?
        data = record.fetch("extension_data", {})
        catalog = request.registry.catalog
        Records::Extension.check_copy_rules!(data, catalog, "Face", record.fetch("id"))
        fresh.each do |id|
          copies[id] = Records::Extension.copy_data(data, catalog, "Face", record.fetch("id"),
                                                    { record.fetch("id") => id }, :engine => request.engine)
        end
      end
      { "reference" => occurrence.reference(record.fetch("id")), "before" => record,
        "persistent_id" => occurrence.entity.persistent_id, "fresh_ids" => fresh,
        "remainder_count" => remainders.length, "extension_copies" => copies }
    end

    def pair_match(proposal, match)
      left = match.fetch(:left)
      right = match.fetch(:right)
      left_after, right_after, pair_id = Adjacency.pair(left, right)
      return pair_id if left_after == left.fetch(:record) && right_after == right.fetch(:record)

      updates = [left, right].zip([left_after, right_after]).map do |side, after|
        occurrence = side.fetch(:occurrence)
        [occurrence.reference(side.fetch(:record).fetch("id")), side.fetch(:record), after]
      end
      scopes = updates.map do |reference, _before, _after|
        Operations::EntityScope.new(reference.fetch("zone_path")[0...-1])
      end
      proposal.add_step(FaceRecordStep.new(:updates => updates, :change => "updated"), :scopes => scopes)
      pair_id
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
    def retire_pairs(request, targets, index = nil)
      plan = {}
      targets.each do |occurrence, record|
        local_after, counterpart, other, other_after =
          Adjacency.retire_records(request.model, occurrence, record, :index => index)
        add_retirement(plan, occurrence.reference(record.fetch("id")), record, local_after)
        add_retirement(plan, counterpart.reference(other.fetch("id")), other, other_after)
      end
      plan
    end

    def add_retirement(plan, reference, before, after)
      key = Occurrences.key(reference)
      existing = plan[key]
      if existing && existing.fetch(2) != after
        raise CodedError.new("gesture.retirement_conflict",
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

    # A copied Zone is ambiguous and shared at once, and shared storage is reported first: it is the
    # condition that blocks every repair, and it names what the user has to do. Reporting only the
    # ambiguity would point at identity repair, which is the one thing not available here.
    def zone_state(zone, ambiguous)
      return "shared_definition" if zone.shared_definition
      return "ambiguous" if ambiguous
      return "wrong_hierarchy" if zone.nested

      "found"
    end
    private_class_method :pair_match, :split_match, :check_unpaired!, :side_plan
    private_class_method :declare_adjacency, :declare_repairs, :zone_view, :make_target,
                         :validate_make_target!, :zone_state
  end
end
