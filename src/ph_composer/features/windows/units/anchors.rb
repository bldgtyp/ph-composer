# frozen_string_literal: true

require_relative "definition_plan"

module PhComposer
  module Windows
    module Units
      # Grid local +X runs right and +Y runs up; its origin is the opening's head-left corner.
      module Anchors
        FRACTIONS = {
          "sill_left" => [0.0, 1.0].freeze, "sill_center" => [0.5, 1.0].freeze, "sill_right" => [1.0, 1.0].freeze,
          "center_left" => [0.0, 0.5].freeze, "center" => [0.5, 0.5].freeze, "center_right" => [1.0, 0.5].freeze,
          "head_left" => [0.0, 0.0].freeze, "head_center" => [0.5, 0.0].freeze, "head_right" => [1.0, 0.0].freeze
        }.freeze
        ALL = FRACTIONS.keys.freeze
        DEFAULT = "sill_center".freeze

        module_function

        def validate!(anchor)
          return anchor if FRACTIONS.key?(anchor)

          raise CodedError.new("params.invalid", "Choose one of the nine Window anchors. Nothing was written.")
        end

        def point(anchor = DEFAULT, width_m:, height_m:)
          validate!(anchor)
          unless DefinitionPlan.positive_dimension?(width_m) && DefinitionPlan.positive_dimension?(height_m)
            raise CodedError.new("validation.failed",
              "Anchor dimensions must be finite and positive. Nothing was written.")
          end
          x, y = FRACTIONS.fetch(anchor)
          [width_m * x, -height_m * y, 0.0].freeze
        end

        # Translate in definition-local metres by old minus new; the caller applies its instance plane axes.
        def resize_delta(anchor = DEFAULT, before:, after:)
          old = point(anchor, :width_m => before.width_m, :height_m => before.height_m)
          fresh = point(anchor, :width_m => after.width_m, :height_m => after.height_m)
          old.zip(fresh).map { |left, right| left - right }.freeze
        end
      end
    end
  end
end
