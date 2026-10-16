# frozen_string_literal: true

module PhComposer
  module Spaces
    # The Mark floor tool's public face: its state, read by the panel's Weighting factor column, and the two
    # view commands that start and stop it. Neither changes a record, so neither is an action.
    module MarkToolRegistration
      STATE = Shapes.object({
        "active" => { "type" => "boolean", "description" => "Whether the Mark floor tool has the viewport." },
        "weighting_factor" => { "type" => "number", "minimum" => 0, "maximum" => 1,
                                "description" => "The factor the tool marks Floor Segments with." },
        "gesture_limit" => Shapes::COUNT.merge("description" => "The most Faces one Mark floor gesture may mark.")
      }).freeze
      START_PARAMS = Shapes.object({
        "weighting_factor" => Schema.factor("The factor to mark Floor Segments with, 0 to 1.")
      }).freeze

      module_function

      def install(feature)
        feature.query("#{FEATURE_ID}.mark_tool.state",
                      :description => "The Mark floor tool: whether it is active and the factor it marks with.",
                      :refuses => [], :params => Shapes::NONE, :result => STATE, :examples => [{}]) do |request|
          state(request.session)
        end
        feature.snapshot_section("#{FEATURE_ID}.mark_tool", :query => "#{FEATURE_ID}.mark_tool.state")
        feature.view_command("#{FEATURE_ID}.mark_tool.start",
                             :description => "Give the viewport to the Mark floor tool with one weighting factor, " \
                                             "and colour the Model by weighting factor.",
                             :refuses => %w[validation.failed], :params => START_PARAMS, :result => STATE,
                             :examples => [{ "weighting_factor" => 1.0 }]) do |request|
          Spaces.mark_tool(request.session).start(request.params.fetch("weighting_factor"))
          state(request.session)
        end
        feature.view_command("#{FEATURE_ID}.mark_tool.stop",
                             :description => "Give the viewport back to whatever tool the user had.",
                             :refuses => [], :params => Shapes::NONE, :result => STATE,
                             :examples => [{}]) do |request|
          Spaces.mark_tool(request.session).stop
          state(request.session)
        end
      end

      def state(session)
        Spaces.mark_tool(session).state.merge("gesture_limit" => Spaces.floor_gesture_limit)
      end
    end
  end
end
