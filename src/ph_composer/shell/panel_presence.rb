# frozen_string_literal: true

module PhComposer
  # What the panel says when the Model it showed is gone. Closing the active document with others open fires
  # no Ruby callback and leaves no active Model (context/SKETCHUP_HOST_BEHAVIOR.md), so the panel learns it
  # from the next thing it hears, a request or its window gaining focus, and then shows that no Model is
  # active instead of the closed Model's last snapshot.
  module PanelPresence
    CLOSED = "That Model is closed. Click a document window to show it here."

    module_function

    # Why a request for a Model the panel no longer shows was refused: it closed, or another is shown now.
    def inactive_message
      Sessions.current ? Panel::SESSION_CHANGED : CLOSED
    end

    # A snapshot of no Model, with the keys `panel.snapshot` declares; the page shows its no-Model state.
    def empty_snapshot
      { "product" => EXTENSION_NAME, "version" => VERSION, "session" => nil, "revision" => nil, "file_name" => nil,
        "edit_path" => [], "preferences" => Preferences.snapshot, "sections" => {} }
    end

    # The session whose snapshot the panel last published.
    def shown(session_id)
      @shown = session_id
    end

    # Before the panel handles any message: once no Model is active, show none, once; when its window gains
    # focus (`panel.focus`) and another Model is active than the one shown, show that one.
    def catch_up(type, publish, publish_snapshot)
      current = Sessions.current
      if current.nil?
        return unless @shown

        @shown = nil
        publish.call("panel.snapshot", empty_snapshot)
      elsif type == "panel.focus" && current.id != @shown
        publish_snapshot.call(current)
      end
    end

    def reset
      @shown = nil
    end
  end

  on_reset("panel_presence") { PanelPresence.reset }
end
