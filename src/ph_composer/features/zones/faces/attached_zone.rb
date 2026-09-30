# frozen_string_literal: true

module PhComposer
  module Zones
    module Faces
      # A named unconditioned space outside the envelope: a garage, an attic, a crawlspace. One
      # temperature reduction factor stands for honeybee-ph's four PHPP factors, which stay unexposed.
      #
      # Phius guidebook 6.9.1 makes 0.95 the lowest factor allowed without further evidence, so a
      # lower value is accepted with a warning naming the Phius estimator rather than refused. An
      # occupied, always-conditioned neighbour is To neighbour, not an Attached zone.
      module AttachedZone
        KIND_ID = "ph_composer.face_assignment.attached_zone"
        KINDS = %w[garage attic crawlspace stairwell other].freeze
        DEFAULT_FACTOR = 0.95
        PHIUS_FACTOR_FLOOR = 0.95

        R = Records

        RECORD_KIND = R::RecordKind.new(
          :id => KIND_ID, :label => "Attached zone", :schema_version => 1, :id_prefix => "atz",
          :fields => [
            R::Field.new(:key => "name", :schema => { "type" => "string", "minLength" => 1 }, :required => true),
            R::Field.new(:key => "kind", :schema => { "type" => "string", "enum" => KINDS }, :required => true),
            R::Field.new(:key => "temperature_reduction_factor",
                         :schema => { "type" => "number", "minimum" => 0, "maximum" => 1 }, :required => true),
            R::Field.new(:key => "notes", :schema => { "type" => "string" }, :required => false),
            R::Field.new(:key => "datasheet_links",
                         :schema => { "type" => "array", "items" => { "type" => "string" } }, :required => false)
          ],
          :validate => lambda do |values|
            factor = values["temperature_reduction_factor"]
            next [] unless factor.is_a?(Numeric) && factor.finite? == false

            ["temperature_reduction_factor must be a finite number"]
          end
        )

        module_function

        # The advisory rows a valid record can still carry. These are findings, never refusals: the
        # factor below the Phius floor is a documented, evidenced choice, not invalid data.
        def findings(record)
          factor = record.dig("values", "temperature_reduction_factor") || record["temperature_reduction_factor"]
          return [] unless factor.is_a?(Numeric) && factor < PHIUS_FACTOR_FLOOR

          [{ "code" => "attached_zone.factor_below_phius_floor", "severity" => "warning",
             "id" => record.fetch("id"),
             "message" => "A factor below #{PHIUS_FACTOR_FLOOR} needs the Phius Temperature Reduction Factor and " \
                          "Auxiliary Space Heating Estimator output linked as a datasheet." }]
        end

        # How one Face's AttachedZone reference stands. The distinct states are what the export matrix
        # blocks on separately, so they never collapse into one "incomplete" word.
        def reference_state(engine, record)
          return nil unless record && record["boundary_condition"] == "AttachedZone"

          id = record["attached_zone_id"]
          return "absent" if id.to_s.empty?

          begin
            engine.find(KIND_ID, id)
            "resolved"
          rescue CodedError => error
            error.code == "record.unreadable" ? "invalid" : "dangling"
          end
        end
      end
    end
  end
end
