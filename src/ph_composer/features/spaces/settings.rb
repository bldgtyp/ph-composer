# frozen_string_literal: true

require_relative "../../core/model_settings"

module PhComposer
  module Spaces
    # The last height the user entered in this Model, which a new Space takes as its default height;
    # until one is entered, DEFAULT_HEIGHT_M.
    module Settings
      DEFAULTS = { "last_height_m" => nil }.freeze
      VALUES = SchemaShapes.object({
        "last_height_m" => {
          "type" => %w[number null], "exclusiveMinimum" => 0, "x-unit" => "m",
          "description" => "The last average clear ceiling height entered; null " \
                           "until one is."
        }
      }).freeze
      SERVICE = ModelSettings.new(:dictionary => "ph_composer.spaces_settings", :defaults => DEFAULTS,
                                  :schema => VALUES, :label => "Spaces", :step_name => "update_spaces_settings",
                                  :affected => [{ "kind" => "spaces_settings", "id" => FEATURE_ID,
                                                  "change" => "updated" }])

      module_function

      def read(model)
        SERVICE.read(model)
      end

      # The height a new Space starts with.
      def default_height_m(model)
        read(model).fetch("last_height_m") || DEFAULT_HEIGHT_M
      end

      def propose(request, proposal, values:, expected_values:)
        SERVICE.propose(request.model, proposal, :values => values, :expected_values => expected_values)
      end

      def install(feature)
        feature.query("#{FEATURE_ID}.settings.get",
                      :description => "The Model's last-entered height, which new Spaces take.",
                      :refuses => %w[record.unreadable], :params => Shapes::NONE, :result => VALUES,
                      :examples => [{}]) { |request| read(request.model) }
        feature.action("#{FEATURE_ID}.settings.update",
                       :description => "Set the Model's last-entered height, guarded by the value last read.",
                       :refuses => %w[record.unreadable target.changed validation.failed],
                       :params => Shapes.object({ "values" => Shapes.described(VALUES, "The complete new settings."),
                                                  "expected_values" => Shapes.described(
                                                    VALUES, "The settings last read; a change refuses."
                                                  ) }),
                       :result => VALUES, :undo_name => "Change Spaces Height",
                       :side_effects => "Stores the height in this SKP.",
                       :examples => [{ "values" => { "last_height_m" => 2.7 },
                                       "expected_values" => DEFAULTS }]) do |request, proposal|
          propose(request, proposal, :values => request.params.fetch("values"),
                                     :expected_values => request.params.fetch("expected_values"))
        end
      end
    end
  end
end
