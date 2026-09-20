# frozen_string_literal: true

require_relative "schema"
require_relative "geometry"
require_relative "attached_zone"
require_relative "steps"
require_relative "export"
require_relative "colour_modes"
require_relative "classify_tool"
require_relative "classify_menu"
require_relative "locate"

module PhComposer
  module FaceAssignment
    OBJECT = { "type" => "object" }.freeze
    PATH = Zones::PATH
    FACE_REFERENCE = {
      "type" => "object", "additionalProperties" => false,
      "required" => %w[zone_id zone_path entity_path entity_id],
      "properties" => {
        "zone_id" => { "type" => "string" }, "zone_path" => PATH, "entity_path" => PATH,
        "entity_id" => { "type" => %w[string null] }
      }
    }.freeze
    INTENT = {
      "type" => "object", "additionalProperties" => false, "required" => ["mode"],
      "properties" => {
        "mode" => { "type" => "string", "enum" => %w[keep set clear] },
        "value" => { "type" => ["string", "null"] }
      }
    }.freeze
    CLASSIFY_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => %w[faces intent],
      "properties" => {
        # The ceiling is a feature bound, not a schema bound, so one Face over it refuses with
        # gesture.too_large rather than a generic schema error the palette cannot explain.
        "faces" => { "type" => "array", "items" => FACE_REFERENCE, "minItems" => 1,
                     "description" => "One gesture's deduplicated Face occurrences." },
        "intent" => {
          "type" => "object", "additionalProperties" => false,
          "properties" => { "face_type" => INTENT, "boundary_condition" => INTENT,
                            "attached_zone_id" => INTENT }
        },
        "expected_values" => { "type" => "object" }
      }
    }.freeze
    AUTO_CLASSIFY_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => ["zone"],
      "properties" => { "zone" => Zones::ZONE_REFERENCE }
    }.freeze
    REVERSE_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => ["face"],
      "properties" => { "face" => FACE_REFERENCE }
    }.freeze
    # What the palette lists. Surface is in it and is not assignable: the PRD asks for it to be shown
    # and refused, because a user who looks for it and finds nothing learns nothing about why.
    PALETTE_BOUNDARIES = (ASSIGNABLE_BOUNDARIES + %w[Surface]).freeze
    CHOOSE_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => %w[field value],
      "properties" => {
        "field" => { "type" => "string", "enum" => %w[face_type boundary_condition attached_zone_id] },
        "value" => { "type" => %w[string null],
                     "description" => "The value to set, or null to keep whatever each Face has." }
      }
    }.freeze
    TOOL_STATE = {
      "type" => "object", "required" => %w[active palette],
      "properties" => {
        "active" => { "type" => "boolean", "description" => "Whether the Classify tool has the viewport." },
        "palette" => { "type" => "object", "description" => "The chosen value per field; a field absent is kept." },
        "face_types" => { "type" => "array", "items" => { "type" => "string" } },
        "boundary_conditions" => { "type" => "array", "items" => { "type" => "string" } }
      }
    }.freeze
    LOCATE_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => ["faces"],
      "properties" => {
        "faces" => { "type" => "array", "items" => FACE_REFERENCE, "minItems" => 1,
                     "description" => "The Face occurrences to select and bring into view." }
      }
    }.freeze
    LOCATE_RESULT = {
      "type" => "object", "additionalProperties" => false, "required" => %w[found missing],
      "properties" => {
        "found" => { "type" => "integer", "description" => "How many references still resolved." },
        "missing" => { "type" => "integer", "description" => "How many did not, and were skipped." }
      }
    }.freeze
    ATTACHED_ZONE_SAVE_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => ["values"],
      "properties" => {
        "id" => { "type" => "string", "description" => "The record to edit; absent creates one." },
        "values" => { "type" => "object" }, "user_data" => { "type" => "object" },
        "expected_values" => { "type" => "object" }
      }
    }.freeze
    ATTACHED_ZONE_DELETE_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => %w[id replacement],
      "properties" => {
        "id" => { "type" => "string" },
        # Either another Attached zone every referencing Face moves to, or an explicit boundary
        # condition they are reclassified as. There is no third, silent route.
        "replacement" => {
          "type" => "object", "additionalProperties" => false, "required" => ["mode"],
          "properties" => {
            "mode" => { "type" => "string", "enum" => %w[attached_zone boundary_condition] },
            "attached_zone_id" => { "type" => "string" },
            "boundary_condition" => { "type" => "string", "enum" => %w[Outdoors Ground Adiabatic] }
          }
        }
      }
    }.freeze
    ATTACHED_ZONE_DUPLICATE_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => ["ids"],
      "properties" => { "ids" => { "type" => "array", "items" => { "type" => "string" }, "minItems" => 1 } }
    }.freeze

    module_function

    def install(registry)
      feature = registry.feature(FEATURE_ID, :contract_version => Declarations::CONTRACT_VERSION,
                                  :requires => [Zones::FEATURE_ID])
      ColourModes.install(feature)
      ClassifyMenu.install(feature)
      feature.query("#{FEATURE_ID}.list", :description => "Path-qualified Face occurrences in authored Zones.",
                                              :params => OBJECT, :result => OBJECT) { |request| list(request) }
      feature.action("#{FEATURE_ID}.classify", :description => "Apply explicit keep, set or clear intent to Faces.",
                                                   :params => CLASSIFY_PARAMS, :result => OBJECT,
                                                   :undo_name => "Classify Faces",
                                                   :side_effects => "Writes face assignments and Zone stamps.") do |
                                                     request, proposal|
        classify(request, proposal)
      end
      feature.action("#{FEATURE_ID}.auto_classify",
                     :description => "Suggest a classification for every unrecorded Face in one Zone.",
                     :params => AUTO_CLASSIFY_PARAMS, :result => OBJECT,
                     :undo_name => "Suggest Classification",
                     :side_effects => "Writes suggested values to Faces that have no record yet.") do |
                       request, proposal|
        auto_classify(request, proposal)
      end
      feature.action("#{FEATURE_ID}.reverse",
                     :description => "Reverse one Face and keep its assignment record.",
                     :params => REVERSE_PARAMS, :result => OBJECT, :undo_name => "Reverse Face",
                     :side_effects => "Flips the Face normal; any Surface pair goes stale.") do |request, proposal|
        reverse(request, proposal)
      end
      declare_viewport(feature)
      declare_attached_zones(feature)
      feature.snapshot_section("#{FEATURE_ID}.faces", :query => "#{FEATURE_ID}.list")
      feature.export_contributor(ExportProjection::SECTION, :section_version => 1) do |reader|
        ExportProjection.records(reader)
      end
    end

    # What reaches the viewport rather than the Model: the Classify tool's palette, the tool itself,
    # and Locate. None of them writes a record, so none is an action.
    def declare_viewport(feature)
      feature.query("#{FEATURE_ID}.classify_tool", :description => "The Classify tool's palette and whether it runs.",
                                                   :params => OBJECT, :result => TOOL_STATE) do |request|
        tool_state(request.session)
      end
      feature.snapshot_section("#{FEATURE_ID}.palette", :query => "#{FEATURE_ID}.classify_tool")
      feature.view_command("#{FEATURE_ID}.choose",
                           :description => "Set one Classify palette field and give the tool the viewport.",
                           :params => CHOOSE_PARAMS, :result => TOOL_STATE) do |request|
        classify_tool(request.session).choose(request.params.fetch("field"), request.params.fetch("value"))
        tool_state(request.session)
      end
      feature.view_command("#{FEATURE_ID}.stop_classifying",
                           :description => "Give the viewport back to whatever tool the user had.",
                           :params => OBJECT, :result => TOOL_STATE, :examples => [{}]) do |request|
        classify_tool(request.session).stop
        tool_state(request.session)
      end
      feature.view_command("#{FEATURE_ID}.locate",
                           :description => "Select an explicit set of Faces and bring them into view.",
                           :params => LOCATE_PARAMS, :result => LOCATE_RESULT) do |request|
        locate(request)
      end
    end

    # What the palette shows: what the tool is set to, and what it may be set to. The words each
    # value is shown by belong to whichever surface shows it; the stored honeybee string is the
    # contract (context/UBIQUITOUS_LANGUAGE.md).
    def tool_state(session)
      tool = classify_tool(session)
      {
        "active" => tool.active?,
        "palette" => tool.palette.each_with_object({}) { |(field, intent), chosen| chosen[field] = intent["value"] },
        "face_types" => ASSIGNABLE_FACE_TYPES,
        "boundary_conditions" => PALETTE_BOUNDARIES
      }
    end

    # Locate changes the selection and the camera and nothing else, which is why it is a view command
    # rather than an action: registering it as an action would manufacture an Undo entry for a read
    # (context/AGENT_INTERFACE.md, "explicit selection, reveal and camera operations").
    def locate(request)
      references = request.params.fetch("faces")
      found = Locate.call(request.session, references)
      { "found" => found.length, "missing" => references.length - found.length }
    end

    # Attached zones are read through the foundation's own ph_composer.records.list, so this feature
    # registers only the kind and the writes that need its reference rules.
    def declare_attached_zones(feature)
      feature.record_kind(AttachedZone::RECORD_KIND)
      # Read through the foundation's own records query, so the picker needs no reader of its own.
      feature.snapshot_section("#{AttachedZone::KIND_ID}.list", :query => "ph_composer.records.list",
                                                                :params => { "kind" => AttachedZone::KIND_ID })
      feature.action("#{AttachedZone::KIND_ID}.save",
                     :description => "Create or edit one Attached zone.",
                     :params => ATTACHED_ZONE_SAVE_PARAMS, :result => OBJECT, :undo_name => "Save Attached Zone",
                     :side_effects => "Writes one Attached zone record.") do |request, proposal|
        save_attached_zone(request, proposal)
      end
      feature.action("#{AttachedZone::KIND_ID}.duplicate",
                     :description => "Copy Attached zones without reassigning any Face.",
                     :params => ATTACHED_ZONE_DUPLICATE_PARAMS, :result => OBJECT,
                     :undo_name => "Duplicate Attached Zone",
                     :side_effects => "Creates Attached zone records with fresh ids.") do |request, proposal|
        { "ids" => request.engine.propose_duplicate(AttachedZone::KIND_ID, request.params.fetch("ids"), proposal) }
      end
      feature.action("#{AttachedZone::KIND_ID}.delete",
                     :description => "Delete one Attached zone, moving every Face that names it in the same step.",
                     :params => ATTACHED_ZONE_DELETE_PARAMS, :result => OBJECT,
                     :undo_name => "Delete Attached Zone",
                     :side_effects => "Reassigns or reclassifies referencing Faces and deletes the record.") do |
                       request, proposal|
        delete_attached_zone(request, proposal)
      end
    end

    # One walk for the whole read. Without the index this resolved every Surface Face's counterpart
    # separately, which walked the Model again for each one and made the read quadratic in Faces.
    def list(request)
      index = Zones::Index.new(request.model)
      rows = Zones::Occurrences.zones(request.model, :index => index).flat_map do |zone|
        Zones::Occurrences.faces(zone, :index => index)
                          .map { |face| face_view(request, face, :index => index) }
      end
      { "faces" => rows, "units" => { "area_m2" => "m2" } }
    end

    # One gesture, one step, all or nothing. Targets are deduplicated by occurrence before anything
    # is resolved, so an over-limit gesture refuses without walking the Model once per Face.
    def classify(request, proposal)
      intent = request.params.fetch("intent")
      validate_intent!(intent)
      expected = request.params.fetch("expected_values", {})
      references = deduplicate(request.params.fetch("faces"))
      check_limit!(references.length)

      # One walk for the whole gesture. Nothing here changes the Model: the proposal is applied
      # afterwards, by steps that resolve against the live Model themselves.
      index = Zones::Index.new(request.model)
      targets = references.map do |reference|
        occurrence = Zones::Occurrences.resolve_face(
          request.model, reference, :mutable => true, :allow_unassigned => reference["entity_id"].nil?,
          :index => index
        )
        record = FACE_STORE.read(occurrence.entity)
        check_expected!(record, expected)
        [occurrence, record]
      end
      retirements = plan_retirements(request, targets, intent, :index => index)
      check_limit!((targets.map { |occurrence, _record| Zones::Occurrences.key(occurrence.reference) } +
                    retirements.keys).uniq.length)

      updates = classify_updates(request, targets, retirements, intent)
      updates.concat(retirement_only_updates(targets, retirements))
      return { "face_ids" => [] } if updates.empty?

      scopes = updates.map do |update|
        Operations::EntityScope.new(update.fetch("reference").fetch("zone_path")[0...-1])
      end
      proposal.add_step(ClassifyStep.new(:updates => updates), :scopes => scopes)
      { "face_ids" => updates.reject { |update| update.fetch("change") == "retired" }
                             .map { |update| update.fetch("after").fetch("id") } }
    end

    def auto_classify(request, proposal)
      # One walk for the whole batch, so the Zone it resolves is the Zone the index walked and the
      # Faces come back from that same walk.
      index = Zones::Index.new(request.model)
      zone = Zones::Occurrences.resolve_zone(request.model, request.params.fetch("zone"),
                                             :mutable => true, :index => index)
      stamp = Zones::Schema.stamp(zone.record)
      # No gesture ceiling here: Auto-classify is a separate named batch over one Zone the user
      # already owns, not a pointer gesture whose target set the user cannot see (P1-D decision).
      unrecorded = Zones::Occurrences.faces(zone, :index => index)
                                     .reject { |occurrence| FACE_STORE.read(occurrence.entity) }
      updates = unrecorded.map do |occurrence|
        suggested = Geometry.suggested_values(occurrence)
        record = new_record(request, occurrence).merge(suggested)
        { "reference" => occurrence.reference, "before" => nil, "after" => Schema.validate!(record),
          "stamp" => stamp, "change" => "created" }
      end
      unless updates.empty?
        scopes = [Operations::EntityScope.new(zone.path[0...-1])]
        proposal.add_step(ClassifyStep.new(:updates => updates), :scopes => scopes)
      end
      { "classified" => updates.length,
        "kept" => Zones::Occurrences.faces(zone, :index => index).length - updates.length }
    end

    # The one geometry repair this feature owns. The record survives untouched; the changed normal
    # is what makes any Surface pair read stale on the next reconciliation.
    def reverse(request, proposal)
      reference = request.params.fetch("face")
      Zones::Occurrences.resolve_face(request.model, reference, :mutable => true, :allow_unassigned => true)
      scope = Operations::EntityScope.new(reference.fetch("zone_path")[0...-1])
      proposal.add_step(ReverseFaceStep.new(:reference => reference), :scopes => [scope])
      {}
    end

    def save_attached_zone(request, proposal)
      patch = request.params.fetch("values")
      id = request.params["id"]
      if id
        # `values` is a partial patch, so the findings have to read the record the save will leave
        # behind. Reading the patch alone drops the low-factor warning on every edit that does not
        # happen to name the factor.
        values = merged_values(request.engine.kind(AttachedZone::KIND_ID)
                                 .values(request.engine.find(AttachedZone::KIND_ID, id)), patch)
        request.engine.propose_update(AttachedZone::KIND_ID, id, proposal, :values => patch,
                                      :user_data => request.params["user_data"],
                                      :expected_values => request.params.fetch("expected_values", {}))
      else
        values = { "temperature_reduction_factor" => AttachedZone::DEFAULT_FACTOR }.merge(patch)
        id = request.engine.propose_create(AttachedZone::KIND_ID, proposal, :values => values,
                                           :user_data => request.params["user_data"])
      end
      AttachedZone.findings(values.merge("id" => id)).each { |finding| proposal.add_finding(finding) }
      { "id" => id }
    end

    # The engine's own patch rule: a named value replaces, and an explicit nil removes.
    def merged_values(before, patch)
      patch.each_with_object(DeepCopy.call(before)) do |(key, value), after|
        value.nil? ? after.delete(key) : after[key] = DeepCopy.call(value)
      end
    end

    # Delete with replacement, in one proposal: every Face naming the record moves first, then the
    # record goes. Faces are not catalog records, so the engine's reference check cannot see them and
    # this feature owns the scan. A Face the caller cannot reach refuses the whole delete.
    def delete_attached_zone(request, proposal)
      id = request.params.fetch("id")
      request.engine.find(AttachedZone::KIND_ID, id)
      replacement = request.params.fetch("replacement")
      validate_replacement!(request, replacement, id)

      updates = referencing_faces(request.model, id).map do |occurrence, record|
        after = DeepCopy.call(record)
        if replacement.fetch("mode") == "attached_zone"
          after["attached_zone_id"] = replacement.fetch("attached_zone_id")
        else
          after.delete("attached_zone_id")
          after["boundary_condition"] = replacement.fetch("boundary_condition")
        end
        { "reference" => occurrence.reference(record.fetch("id")), "before" => record,
          "after" => Schema.validate!(after), "stamp" => nil, "change" => "updated" }
      end
      unless updates.empty?
        scopes = updates.map do |update|
          Operations::EntityScope.new(update.fetch("reference").fetch("zone_path")[0...-1])
        end
        proposal.add_step(ClassifyStep.new(:updates => updates), :scopes => scopes)
      end
      request.engine.propose_delete(AttachedZone::KIND_ID, id, proposal)
      { "id" => id, "reassigned_faces" => updates.length }
    end

    def validate_replacement!(request, replacement, deleted_id)
      return unless replacement.fetch("mode") == "attached_zone"

      target = replacement["attached_zone_id"]
      if target.to_s.empty?
        raise CodedError.new("params.invalid", "A replacement Attached zone needs attached_zone_id.")
      end
      if target == deleted_id
        raise CodedError.new("params.invalid", "The replacement cannot be the Attached zone being deleted.")
      end

      request.engine.find(AttachedZone::KIND_ID, target)
    end

    def referencing_faces(model, attached_zone_id)
      Zones::Occurrences.zones(model).flat_map { |zone| Zones::Occurrences.faces(zone) }.filter_map do |occurrence|
        record = FACE_STORE.read(occurrence.entity)
        [occurrence, record] if record && record["attached_zone_id"] == attached_zone_id
      end
    end

    def face_view(request, occurrence, index:)
      record = FACE_STORE.read(occurrence.entity)
      Schema.validate!(record) if record
      id = record&.fetch("id", nil)
      view = {
        "reference" => occurrence.reference(id), "zone_name" => occurrence.zone.record.fetch("name"),
        "area_m2" => Geometry.area_m2(occurrence), "values" => record ? Schema.values(record) : {},
        "user_data" => record ? DeepCopy.call(record.fetch("user_data", {})) : {},
        "extension_data" => record ? DeepCopy.call(record.fetch("extension_data", {})) : {},
        "suggested" => Geometry.suggested_values(occurrence),
        "attached_zone_state" => AttachedZone.reference_state(request.engine, record),
        "adjacency_state" => Zones::Adjacency.state(request.model, occurrence, record, :index => index)
      }
      view.merge("state" => row_state(view))
    end

    # The three words every surface that shows a Face uses, the same ones a Colour-by legend row
    # carries: no record at all, a record that cannot be exported as it stands, or a complete one.
    # The faces table and the overlay have to agree, so this is derived here and never in a view.
    #
    # It is not the validation register, which owns severities and finding codes and is a later
    # packet. It answers one question: is this row amber (face-assignment PRD, "The faces table").
    def row_state(view)
      values = view.fetch("values")
      return "unclassified" if values.empty?

      incomplete = values["face_type"].nil? || values["boundary_condition"].nil? ||
                   (view["attached_zone_state"] && view["attached_zone_state"] != "resolved") ||
                   (view["adjacency_state"] && view["adjacency_state"] != "current")
      incomplete ? "incomplete" : "classified"
    end

    def deduplicate(references)
      references.uniq { |reference| Zones::Occurrences.key(reference) }
    end

    def check_limit!(count)
      limit = gesture_face_limit
      return if count <= limit

      raise CodedError.new("gesture.too_large",
                           "One gesture affects at most #{limit} Faces; this one affects #{count}.")
    end

    def retiring?(record, intent)
      boundary = intent["boundary_condition"]
      record && record["boundary_condition"] == "Surface" && boundary &&
        !(boundary.fetch("mode") == "keep" ||
          (boundary.fetch("mode") == "set" && boundary["value"] == "Surface"))
    end

    def plan_retirements(request, targets, intent, index:)
      retiring = targets.select { |_occurrence, record| retiring?(record, intent) }
      return {} if retiring.empty?

      request.participant("#{Zones::FEATURE_ID}.retire_pairs").call(request, retiring, index)
    end

    def classify_updates(request, targets, retirements, intent)
      targets.filter_map do |occurrence, record|
        key = Zones::Occurrences.key(occurrence.reference)
        base = retirements.key?(key) ? retirements.fetch(key).fetch(2) : record
        after = patched_record(request, occurrence, base, intent)
        next unless after

        stamp = Zones::Schema.stamp(occurrence.zone.record)
        next if record == after && Zones::STAMP_STORE.read(occurrence.entity) == stamp

        { "reference" => occurrence.reference(record&.fetch("id", nil)), "before" => record, "after" => after,
          "stamp" => stamp, "change" => record ? "updated" : "created" }
      end
    end

    # A counterpart dragged in by retirement that the gesture does not itself classify. It loses its
    # boundary condition and keeps everything else, per the zones packet's Q21.
    def retirement_only_updates(targets, retirements)
      classified = targets.map { |occurrence, _record| Zones::Occurrences.key(occurrence.reference) }
      retirements.reject { |key, _entry| classified.include?(key) }
        .map do |_key, (reference, before, after)|
          { "reference" => reference, "before" => before, "after" => after, "stamp" => nil,
            "change" => "retired" }
        end
    end

    def new_record(request, occurrence)
      {
        "id" => Records::Identity.derived("fac", "model" => request.model.guid, "revision" => request.revision,
                                                 "zone_path" => occurrence.zone.path,
                                                 "entity_path" => occurrence.path),
        "schema_version" => 1, "user_data" => {}, "extension_data" => {}
      }
    end

    def patched_record(request, occurrence, before, intent)
      return nil if before.nil? && intent.values.none? { |operation| operation.fetch("mode") == "set" }

      record = before ? DeepCopy.call(before) : new_record(request, occurrence)
      intent.each do |field, operation|
        case operation.fetch("mode")
        when "keep" then next
        when "clear" then record.delete(field)
        when "set" then record[field] = operation.fetch("value")
        end
      end
      # The reference belongs to the condition. Moving off AttachedZone drops it, so no Face keeps a
      # reference its own condition no longer explains; but a caller asking for the reference
      # without the condition is refused rather than having the value quietly discarded.
      unless record["boundary_condition"] == "AttachedZone"
        if intent.dig("attached_zone_id", "mode") == "set"
          raise CodedError.new("params.invalid",
                               "Setting attached_zone_id needs the AttachedZone boundary condition.")
        end

        record.delete("attached_zone_id")
      end
      Schema.validate!(record)
    end

    def validate_intent!(intent)
      raise CodedError.new("params.invalid", "Classify needs at least one field intent.") if intent.empty?

      intent.each do |field, operation|
        mode = operation.fetch("mode")
        value = operation["value"]
        if mode == "set" && value.nil?
          raise CodedError.new("params.invalid", "Set intent for #{field} needs a value.")
        end
        if field == "face_type" && mode == "set" && !ASSIGNABLE_FACE_TYPES.include?(value)
          raise CodedError.new("params.invalid", "Classify sets Wall, RoofCeiling or Floor.")
        end
        if field == "boundary_condition" && mode == "set" && !ASSIGNABLE_BOUNDARIES.include?(value)
          raise CodedError.new("params.invalid",
                               "Classify sets #{ASSIGNABLE_BOUNDARIES.join(', ')}; Surface is the solver's.")
        end
      end
    end

    def check_expected!(before, expected)
      values = before ? Schema.values(before) : {}
      changed = expected.keys.reject { |key| values[key] == expected[key] }
      return if changed.empty?

      raise CodedError.new("target.changed", "The Face changed since it was read (#{changed.join(', ')}).")
    end
    private_class_method :face_view, :patched_record, :validate_intent!, :check_expected!, :deduplicate,
                         :check_limit!, :retiring?, :plan_retirements, :classify_updates,
                         :retirement_only_updates, :new_record
  end
end
