# frozen_string_literal: true

module PhComposer
  module Zones
    FEATURE_ID = "ph_composer.zones"
    REFERENCE_KIND = "#{FEATURE_ID}.zone"
    # Emitted when a Zone occurrence becomes independent, by the action or the copy watcher's follow-up.
    # The description is `zone_path`, `old_zone_id`, `new_zone_id`, `mapping` (every old id to its new
    # one) and `revision` (context/CONTRACTS.md, "Compound proposals").
    TRANSITION = "#{FEATURE_ID}.occurrence_independent"
    ZONE_DICTIONARY = "ph_composer.zone"
    STAMP_DICTIONARY = "ph_composer.zone_stamp"
    ZONE_STORE = Records::EntityStore.new(ZONE_DICTIONARY)
    STAMP_STORE = Records::EntityStore.new(STAMP_DICTIONARY)
    ID_PATTERN = Records::Identity.pattern("zon")

    PATH = { "type" => "array", "items" => { "type" => "integer" } }.freeze
    ZONE_REFERENCE = {
      "type" => "object", "additionalProperties" => false, "required" => %w[zone_id zone_path],
      "properties" => { "zone_id" => { "type" => "string" }, "zone_path" => PATH }
    }.freeze

    ZONE_VALUES = {
      "type" => "object", "additionalProperties" => false,
      "required" => %w[name building_segment level ground_depth_mm],
      "properties" => {
        "name" => { "type" => "string", "minLength" => 1 },
        "building_segment" => { "type" => "string", "minLength" => 1 },
        "level" => { "type" => %w[string null] },
        "ground_depth_mm" => { "type" => "number", "x-unit" => "mm" }
      }
    }.freeze

    MANAGED_VALUES = {
      "type" => "object", "additionalProperties" => false,
      "required" => %w[name building_segment_id level_id ground_depth_mm],
      "properties" => {
        "name" => { "type" => "string", "minLength" => 1 },
        "building_segment_id" => { "type" => "string", "minLength" => 1 },
        "level_id" => { "type" => %w[string null] },
        "ground_depth_mm" => { "type" => "number", "x-unit" => "mm" }
      }
    }.freeze
    # Public inputs describe both supported versions; the owner checks complete version shapes.
    INPUT_VALUES = {
      "type" => "object", "additionalProperties" => false, "required" => %w[name ground_depth_mm],
      "properties" => ZONE_VALUES.fetch("properties").merge(MANAGED_VALUES.fetch("properties"))
    }.freeze

    module Schema
      module_function

      def problems(record)
        return ["Zone record must be a JSON object"] unless record.is_a?(Hash)

        version = record["schema_version"]
        schema = version == 2 ? MANAGED_VALUES : ZONE_VALUES
        allowed = %w[id schema_version user_data extension_data] + schema.fetch("properties").keys
        allowed << "choice_evidence" if version == 2
        found = (record.keys - allowed).map { |key| "Zone record has unknown field #{key}" }
        found << "Zone id is invalid" unless ID_PATTERN.match?(record["id"].to_s)
        found << "Zone schema_version must be 1 or 2" unless [1, 2].include?(version)
        values = record.reject { |key, _value|
          %w[id schema_version user_data extension_data choice_evidence].include?(key)
        }
        found.concat(JsonSchema.validate(values, schema))
        found.concat(metadata_problems(record))
        if version == 2
          found.concat(evidence_problems(record["choice_evidence"]))
          found << "Zone choice evidence does not match its assignments" unless evidence_matches?(record)
        end
        found
      end

      def validate!(record)
        found = problems(record)
        return record if found.empty?

        raise CodedError.new("validation.failed", "Zone #{record['id']} is not valid: #{found.first}.",
                             "findings" => found)
      end

      def view(record)
        {
          "id" => record.fetch("id"), "schema_version" => record.fetch("schema_version"),
          "values" => record.reject { |key, _value|
                        %w[id schema_version user_data extension_data choice_evidence].include?(key)
                      },
          "user_data" => DeepCopy.call(record.fetch("user_data", {})),
          "extension_data" => DeepCopy.call(record.fetch("extension_data", {}))
        }
      end

      def stamp(record)
        if record.fetch("schema_version") == 2
          { "schema_version" => 2, "zone_id" => record.fetch("id"),
            "building_segment_id" => record.fetch("building_segment_id"), "level_id" => record.fetch("level_id"),
            "choice_evidence" => DeepCopy.call(record.fetch("choice_evidence")) }
        else
          { "schema_version" => 1, "zone_id" => record.fetch("id"),
            "building_segment" => record.fetch("building_segment"), "level" => record.fetch("level") }
        end
      end

      def stamp?(value)
        return false unless value.is_a?(Hash) && ID_PATTERN.match?(value["zone_id"].to_s)

        if value["schema_version"] == 2
          value.keys.sort == %w[building_segment_id choice_evidence level_id schema_version zone_id].sort &&
            value["building_segment_id"].is_a?(String) && [String, NilClass].include?(value["level_id"].class) &&
            evidence_problems(value["choice_evidence"]).empty? && evidence_matches?(value)
        else
          value["schema_version"] == 1 && value["building_segment"].is_a?(String) &&
            !value["building_segment"].strip.empty? && [String, NilClass].include?(value["level"].class)
        end
      end

      def evidence_matches?(record)
        evidence = record["choice_evidence"]
        return false unless evidence.is_a?(Hash) && evidence["building_segment"].is_a?(Hash) &&
                            (evidence["level"].nil? || evidence["level"].is_a?(Hash))

        evidence.dig("building_segment", "id") == record["building_segment_id"] &&
          evidence.dig("level", "id") == record["level_id"]
      end

      def evidence_problems(evidence)
        return ["Zone choice evidence is missing or invalid"] unless evidence.is_a?(Hash) &&
                                                                     evidence.keys.sort == %w[building_segment level
                                                                                              source_model_id].sort &&
                                                                     evidence["source_model_id"].is_a?(String)

        found = Options::SEGMENTS.problems(evidence["building_segment"])
        found.concat(Options::LEVELS.problems(evidence["level"])) if evidence["level"]
        found
      end

      def metadata_problems(record)
        %w[user_data extension_data].flat_map do |key|
          next [] unless record.key?(key)

          value = record[key]
          if value.is_a?(Hash)
            JsonValue.problems(value).map { |problem| "#{key} #{problem}" }
          else
            ["#{key} must be an object"]
          end
        end
      end
      private_class_method :metadata_problems
    end
  end
end
