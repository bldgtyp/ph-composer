# frozen_string_literal: true

module PhComposer
  # SketchUp's own Undo and Redo from the platform shortcut in the panel (`panel.undo`, `panel.redo`), as the
  # model window gives them. The host reports the step through its own Undo or Redo callbacks, which refresh
  # the panel (context/SKETCHUP_HOST_BEHAVIOR.md: `Sketchup.undo` and `Sketchup.redo` step native Undo).
  module PanelHistory
    module_function

    # Only for the Model the page showed, while the panel still shows it and nothing is running or waiting on
    # it: a follow-up queued behind a commit would otherwise write against the undone state.
    def step(type, session_id)
      session = Sessions.current
      return unless session && Panel.showing?(session) && session.id == session_id && session.busy_reason.nil?

      type == "panel.undo" ? Sketchup.undo : Sketchup.redo
    end
  end
end
