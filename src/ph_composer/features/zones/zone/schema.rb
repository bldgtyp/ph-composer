# frozen_string_literal: true

module PhComposer
  module Zones
    FEATURE_ID = "ph_composer.zones"
    REFERENCE_KIND = "#{FEATURE_ID}.zone"
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

    module Schema
      module_function

      def problems(record)
        return ["Zone record must be a JSON object"] unless record.is_a?(Hash)

        allowed = %w[id schema_version name building_segment level ground_depth_mm user_data extension_data]
        found = (record.keys - allowed).map { |key| "Zone record has unknown field #{key}" }
        found << "Zone id is invalid" unless ID_PATTERN.match?(record["id"].to_s)
        found << "Zone schema_version must be 1" unless record["schema_version"] == 1
        values = record.reject { |key, _value| %w[id schema_version user_data extension_data].include?(key) }
        found.concat(JsonSchema.validate(values, ZONE_VALUES))
        found.concat(metadata_problems(record))
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
          "values" => record.reject { |key, _value| %w[id schema_version user_data extension_data].include?(key) },
          "user_data" => DeepCopy.call(record.fetch("user_data", {})),
          "extension_data" => DeepCopy.call(record.fetch("extension_data", {}))
        }
      end

      def stamp(record)
        {
          "schema_version" => 1, "zone_id" => record.fetch("id"),
          "building_segment" => record.fetch("building_segment"), "level" => record.fetch("level")
        }
      end

      # Whether `value` is a membership stamp as `stamp` writes it.
      def stamp?(value)
        value.is_a?(Hash) && ID_PATTERN.match?(value["zone_id"].to_s) &&
          value["building_segment"].is_a?(String) && [String, NilClass].include?(value["level"].class)
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
