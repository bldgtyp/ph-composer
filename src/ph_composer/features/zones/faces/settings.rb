# frozen_string_literal: true

require_relative "../../../core/model_settings"

module PhComposer
  module Zones
    module Faces
      # Authoring choices belong to this SKP, unlike the shell's user-wide display preferences.
      module Settings
        DEFAULTS = { "suggest_on_make" => true, "roof_angle_deg" => 60.0, "floor_angle_deg" => 130.0 }.freeze
        VALUES = {
          "type" => "object", "additionalProperties" => false, "required" => DEFAULTS.keys,
          "properties" => {
            "suggest_on_make" => { "type" => "boolean" },
            "roof_angle_deg" => { "type" => "number", "minimum" => 0, "maximum" => 180 },
            "floor_angle_deg" => { "type" => "number", "minimum" => 0, "maximum" => 180 }
          }
        }.freeze
        DEFINITION = ModelSettings.new(:dictionary => "ph_composer.zones_settings", :defaults => DEFAULTS,
                                       :schema => VALUES, :label => "Zone", :step_name => "update_zone_settings",
                                       :affected => [{ "kind" => "zone_settings", "id" => FEATURE_ID,
                                                       "change" => "updated" }]) do |values|
          values.fetch("roof_angle_deg") >= values.fetch("floor_angle_deg") ?
            ["The roof angle must be less than the floor angle."] : []
        end
        STORE = DEFINITION.store

        module_function

        def read(model)
          DEFINITION.read(model)
        end

        def validate!(values)
          DEFINITION.validate!(values)
        end

        def install(feature)
          feature.query("#{FEATURE_ID}.settings.get",
                        :description => "This Model's classification settings.",
                        :params => Shapes::NONE, :result => VALUES, :examples => [{}]) do |request|
            read(request.model)
          end
          feature.snapshot_section("#{FEATURE_ID}.settings", :query => "#{FEATURE_ID}.settings.get")
          feature.action("#{FEATURE_ID}.settings.update",
                         :description => "Set this Model's classification settings.",
                         :params => Shapes.object({
                           "values" => VALUES.merge("description" => "The complete new settings."),
                           "expected_values" => VALUES.merge("description" => "The settings last read; a change " \
                                                                             "refuses.")
                         }),
                         :result => VALUES, :undo_name => "Change Zone Settings",
                         :examples => [{ "values" => DEFAULTS, "expected_values" => DEFAULTS }],
                         :side_effects => "Stores classification settings in this SKP in one Undo " \
                                          "step.") do |request, proposal|
            DEFINITION.propose(request.model, proposal, :values => request.params.fetch("values"),
                                                        :expected_values => request.params.fetch("expected_values"))
          end
        end
      end
    end
  end
end
