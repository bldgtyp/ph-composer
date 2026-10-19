# frozen_string_literal: true

module PhComposer
  # A failure the panel page reported (`panel.diagnostic`): a section that failed to render, an uncaught
  # error or a rejected promise. Only the fixed events are recorded, the section only as the registered
  # feature that owns it, and frames only in files the extension ships, so a page can neither choose a
  # name nor put its own text in the log.
  module PanelDiagnostics
    EVENTS = %w[panel_render_failed panel_uncaught_error panel_unhandled_rejection].freeze
    # The page names only the language's own error types (html/panel.js); any other value is not kept.
    ERROR_CLASSES = %w[Error TypeError RangeError ReferenceError SyntaxError URIError EvalError NotAnError].freeze

    module_function

    def record(payload)
      return unless EVENTS.include?(payload["event"])

      error_class = ERROR_CLASSES.include?(payload["error_class"]) ? payload["error_class"] : nil
      reported = Diagnostics.accepted("stage" => owner(payload["section"]), "error_class" => error_class,
                                      "frames" => payload["frames"])
      Diagnostics.log(payload["event"], { "severity" => "error", "status" => "failed" }.merge(reported))
    end

    # The registered feature a section belongs to, by the longest feature id it is or starts with; a section
    # no feature owns is not named, since its name came from the page.
    def owner(section)
      return nil unless section.is_a?(String)

      Registry.current.features.keys.select { |id| section == id || section.start_with?("#{id}.") }.max_by(&:length)
    end
  end
end
