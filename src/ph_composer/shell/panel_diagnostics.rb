# frozen_string_literal: true

module PhComposer
  # A failure the panel page reported (`panel.diagnostic`): a section that failed to render, an uncaught
  # error or a rejected promise. Only the fixed events are recorded, and only the values the log accepts
  # from a client, so a page can neither choose an event name nor put free text in the log.
  module PanelDiagnostics
    EVENTS = %w[panel_render_failed panel_uncaught_error panel_unhandled_rejection].freeze

    module_function

    def record(payload)
      return unless EVENTS.include?(payload["event"])

      reported = Diagnostics.accepted("stage" => payload["section"], "error_class" => payload["error_class"],
                                      "frames" => payload["frames"])
      Diagnostics.log(payload["event"], { "severity" => "error", "status" => "failed" }.merge(reported))
    end
  end
end
