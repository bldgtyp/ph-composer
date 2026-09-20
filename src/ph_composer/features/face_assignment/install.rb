# frozen_string_literal: true

require_relative "schema"
require_relative "geometry"
require_relative "steps"

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
        "faces" => { "type" => "array", "items" => FACE_REFERENCE, "minItems" => 1, "maxItems" => 1,
                     "description" => "P1-B edits one Face; P1-D adds bounded gestures." },
        "intent" => {
          "type" => "object", "additionalProperties" => false,
          "properties" => { "face_type" => INTENT, "boundary_condition" => INTENT }
        },
        "expected_values" => { "type" => "object" }
      }
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
      feature.snapshot_section("#{FEATURE_ID}.faces", :query => "#{FEATURE_ID}.list")
    end

    def list(request)
      rows = Zones::Occurrences.zones(request.model).flat_map do |zone|
        Zones::Occurrences.faces(zone).map { |face| face_view(face) }
      end
      { "faces" => rows, "units" => { "area_m2" => "m2" } }
    end

    def classify(request, proposal)
      intent = request.params.fetch("intent")
      validate_intent!(intent)
      expected = request.params.fetch("expected_values", {})
      changed = []
      request.params.fetch("faces").each do |reference|
        occurrence = Zones::Occurrences.resolve_face(
          request.model, reference, :mutable => true, :allow_unassigned => reference["entity_id"].nil?
        )
        before = FACE_STORE.read(occurrence.entity)
        check_expected!(before, expected)
        after = patched_record(request, occurrence, before, intent)
        next unless after

        stamp = Zones::Schema.stamp(occurrence.zone.record)
        next if before == after && Zones::STAMP_STORE.read(occurrence.entity) == stamp

        step = ClassifyStep.new(:reference => reference, :before => before, :after => after,
                                :stamp => stamp)
        scope = Operations::EntityScope.new(reference.fetch("zone_path")[0...-1])
        proposal.add_step(step, :scopes => [scope])
        changed << after.fetch("id")
      end
      { "face_ids" => changed }
    end

    def face_view(occurrence)
      record = FACE_STORE.read(occurrence.entity)
      Schema.validate!(record) if record
      id = record&.fetch("id", nil)
      {
        "reference" => occurrence.reference(id), "zone_name" => occurrence.zone.record.fetch("name"),
        "area_m2" => Geometry.area_m2(occurrence), "values" => record ? Schema.values(record) : {},
        "user_data" => record ? DeepCopy.call(record.fetch("user_data", {})) : {},
        "extension_data" => record ? DeepCopy.call(record.fetch("extension_data", {})) : {},
        "suggested" => Geometry.suggested_values(occurrence)
      }
    end

    def patched_record(request, occurrence, before, intent)
      return nil if before.nil? && intent.values.none? { |operation| operation.fetch("mode") == "set" }

      record = before ? DeepCopy.call(before) : {
        "id" => Records::Identity.derived("fac", "model" => request.model.guid, "revision" => request.revision,
                                                 "zone_path" => occurrence.zone.path,
                                                 "entity_path" => occurrence.path),
        "schema_version" => 1, "user_data" => {}, "extension_data" => {}
      }
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
        if field == "face_type" && mode == "set" && !P1_B_FACE_TYPES.include?(value)
          raise CodedError.new("params.invalid", "P1-B can set Wall, RoofCeiling or Floor.")
        end
        if field == "boundary_condition" && mode == "set" && !P1_B_BOUNDARIES.include?(value)
          raise CodedError.new("params.invalid", "P1-B can set Outdoors, Ground or Adiabatic.")
        end
      end
    end

    def check_expected!(before, expected)
      values = before ? Schema.values(before) : {}
      changed = expected.keys.reject { |key| values[key] == expected[key] }
      return if changed.empty?

      raise CodedError.new("target.changed", "The Face changed since it was read (#{changed.join(', ')}).")
    end
    private_class_method :face_view, :patched_record, :validate_intent!, :check_expected!
  end
end
