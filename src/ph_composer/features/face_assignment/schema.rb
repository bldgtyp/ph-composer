# frozen_string_literal: true

module PhComposer
  module FaceAssignment
    FEATURE_ID = "ph_composer.face_assignment"
    FACE_DICTIONARY = "ph_composer.face_assignment"
    FACE_STORE = Records::EntityStore.new(FACE_DICTIONARY)
    ID_PATTERN = Records::Identity.pattern("fac")
    FACE_TYPES = %w[Wall RoofCeiling Floor AirBoundary].freeze
    # AirBoundary round trips through HBJSON but the Classify tool does not offer it (PRD Q8).
    ASSIGNABLE_FACE_TYPES = %w[Wall RoofCeiling Floor].freeze
    BOUNDARY_CONDITIONS = %w[Outdoors Ground Adiabatic Surface AttachedZone].freeze
    # Surface belongs to Solve adjacencies; AttachedZone waits for its record kind.
    ASSIGNABLE_BOUNDARIES = %w[Outdoors Ground Adiabatic].freeze
    # The proposed ceiling on Face occurrences affected by one gesture, counterparts included.
    # Confirm or revise it against P1-D host measurements before the gesture work closes.
    GESTURE_FACE_LIMIT = 1_000

    module Schema
      module_function

      def problems(record)
        return ["Face assignment must be a JSON object"] unless record.is_a?(Hash)

        allowed = %w[id schema_version face_type boundary_condition attached_zone_id assembly_id adjacency
                     user_data extension_data]
        found = (record.keys - allowed).map { |key| "Face assignment has unknown field #{key}" }
        found << "Face id is invalid" unless ID_PATTERN.match?(record["id"].to_s)
        found << "Face schema_version must be 1" unless record["schema_version"] == 1
        found << "face_type is unknown" if record.key?("face_type") && !FACE_TYPES.include?(record["face_type"])
        if record.key?("boundary_condition") && !BOUNDARY_CONDITIONS.include?(record["boundary_condition"])
          found << "boundary_condition is unknown"
        end
        if record["boundary_condition"] == "AttachedZone" && record["attached_zone_id"].to_s.empty?
          found << "AttachedZone needs attached_zone_id"
        elsif record.key?("attached_zone_id") && record["boundary_condition"] != "AttachedZone"
          found << "attached_zone_id is only valid for AttachedZone"
        end
        if record["boundary_condition"] == "Surface" && !record["adjacency"].is_a?(Hash)
          found << "Surface needs adjacency"
        elsif record.key?("adjacency") && record["boundary_condition"] != "Surface"
          found << "adjacency is only valid for Surface"
        end
        found.concat(Zones::Adjacency.validate_envelope(record["adjacency"])) if record["adjacency"].is_a?(Hash)
        found.concat(metadata_problems(record))
        found
      end

      def validate!(record)
        found = problems(record)
        return record if found.empty?

        raise CodedError.new("validation.failed", "Face #{record['id']} is not valid: #{found.first}.",
                             "findings" => found)
      end

      def values(record)
        record.reject { |key, _value| %w[id schema_version user_data extension_data].include?(key) }
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
