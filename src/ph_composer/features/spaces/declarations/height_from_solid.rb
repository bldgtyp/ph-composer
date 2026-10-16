# frozen_string_literal: true

module PhComposer
  module Spaces
    # Height from solid's public face: a query that says what the action would write, and the action.
    module HeightFromSolidRegistration
      PARAMS = Shapes.object({
        "volume" => OperationRegistration::VOLUME_PARAM,
        "solid" => PATH.merge("description" => "The closed Group or component's " \
                                               "root-to-entity path.")
      }).freeze
      NUMBERS = {
        "height_m" => { "type" => "number", "x-unit" => "m", "description" => "The height it gives." },
        "solid_volume_m3" => { "type" => "number", "x-unit" => "m3", "description" => "The solid's world volume." },
        "net_floor_area_m2" => { "type" => "number", "x-unit" => "m2", "description" => "The Volume's net floor area." }
      }.freeze
      REFUSES = (OperationRegistration::TARGET + %w[space.net_area_zero space.solid_invalid target.wrong_kind]).uniq
      EXAMPLE = { "volume" => OperationRegistration::EXAMPLE_VOLUME, "solid" => [1201, 1300, 1400] }.freeze
      ACTION_EXAMPLE = EXAMPLE.merge("expected_values" => { "avg_ceiling_height_m" => 2.5 }).freeze

      module_function

      def install(feature)
        feature.query("#{FEATURE_ID}.volumes.height_from_solid_preview",
                      :description => "The height a solid would give a Volume: the solid's volume over the " \
                                      "Volume's net floor area. Writes nothing.",
                      :refuses => REFUSES, :params => PARAMS,
                      :result => Shapes.object(NUMBERS.merge("current_height_m" => {
                        "type" => %w[number null], "x-unit" => "m",
                        "description" => "The height now; null when unset."
                      })),
                      :examples => [EXAMPLE]) do |request|
          HeightFromSolid.preview(request, :volume => request.params.fetch("volume"),
                                           :solid => request.params.fetch("solid"))
        end
        feature.action("#{FEATURE_ID}.volumes.height_from_solid",
                       :description => "Set a Volume's average clear ceiling height from a closed solid: its " \
                                       "volume over the Volume's net floor area. The solid is left as it was.",
                       :refuses => REFUSES,
                       :params => Shapes.object(PARAMS.fetch("properties").merge(
                         "expected_values" => Shapes.object({
                           "avg_ceiling_height_m" => { "type" => %w[number null],
                                                       "description" => "The height as last read; null when unset." }
                         }).merge("description" => "The Volume's height as last read; a changed one refuses.")
                       )),
                       :result => Shapes.object(NUMBERS.merge("volume_id" => Shapes::TEXT)),
                       :undo_name => "Height from Solid", :side_effects => "Writes the Volume's height.",
                       :examples => [ACTION_EXAMPLE]) do |request, proposal|
          HeightFromSolid.apply(request, proposal, :volume => request.params.fetch("volume"),
                                                   :solid => request.params.fetch("solid"),
                                                   :expected_values => request.params.fetch("expected_values"))
        end
      end
    end
  end
end
