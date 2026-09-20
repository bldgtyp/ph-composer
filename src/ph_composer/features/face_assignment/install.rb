# frozen_string_literal: true

require_relative "schema"
require_relative "geometry"
require_relative "steps"
require_relative "export"

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
          "properties" => { "face_type" => INTENT, "boundary_condition" => INTENT }
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

    module_function

    def install(registry)
      feature = registry.feature(FEATURE_ID, :contract_version => Declarations::CONTRACT_VERSION,
                                  :requires => [Zones::FEATURE_ID])
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
      feature.snapshot_section("#{FEATURE_ID}.faces", :query => "#{FEATURE_ID}.list")
      feature.export_contributor(ExportProjection::SECTION, :section_version => 1) do |reader|
        ExportProjection.records(reader)
      end
    end

    def list(request)
      rows = Zones::Occurrences.zones(request.model).flat_map do |zone|
        Zones::Occurrences.faces(zone).map { |face| face_view(request.model, face) }
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

      targets = references.map do |reference|
        occurrence = Zones::Occurrences.resolve_face(
          request.model, reference, :mutable => true, :allow_unassigned => reference["entity_id"].nil?
        )
        record = FACE_STORE.read(occurrence.entity)
        check_expected!(record, expected)
        [occurrence, record]
      end
      retirements = plan_retirements(request, targets, intent)
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
      zone = Zones::Occurrences.resolve_zone(request.model, request.params.fetch("zone"), :mutable => true)
      stamp = Zones::Schema.stamp(zone.record)
      unrecorded = Zones::Occurrences.faces(zone).reject { |occurrence| FACE_STORE.read(occurrence.entity) }
      check_limit!(unrecorded.length)

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
      { "classified" => updates.length, "kept" => Zones::Occurrences.faces(zone).length - updates.length }
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

    def face_view(model, occurrence)
      record = FACE_STORE.read(occurrence.entity)
      Schema.validate!(record) if record
      id = record&.fetch("id", nil)
      {
        "reference" => occurrence.reference(id), "zone_name" => occurrence.zone.record.fetch("name"),
        "area_m2" => Geometry.area_m2(occurrence), "values" => record ? Schema.values(record) : {},
        "user_data" => record ? DeepCopy.call(record.fetch("user_data", {})) : {},
        "extension_data" => record ? DeepCopy.call(record.fetch("extension_data", {})) : {},
        "suggested" => Geometry.suggested_values(occurrence),
        "adjacency_state" => Zones::Adjacency.state(model, occurrence, record)
      }
    end

    def deduplicate(references)
      references.uniq { |reference| Zones::Occurrences.key(reference) }
    end

    def check_limit!(count)
      return if count <= GESTURE_FACE_LIMIT

      raise CodedError.new("gesture.too_large",
                           "One gesture affects at most #{GESTURE_FACE_LIMIT} Faces; this one affects #{count}.")
    end

    def retiring?(record, intent)
      boundary = intent["boundary_condition"]
      record && record["boundary_condition"] == "Surface" && boundary &&
        !(boundary.fetch("mode") == "keep" ||
          (boundary.fetch("mode") == "set" && boundary["value"] == "Surface"))
    end

    def plan_retirements(request, targets, intent)
      retiring = targets.select { |_occurrence, record| retiring?(record, intent) }
      return {} if retiring.empty?

      request.participant("#{Zones::FEATURE_ID}.retire_pairs").call(request, retiring)
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
          raise CodedError.new("params.invalid", "Classify sets Outdoors, Ground or Adiabatic.")
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
