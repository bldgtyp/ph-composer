# frozen_string_literal: true

module PhComposer
  module Export
    # The Export command as the foundation ships it: the user can choose a destination, and nothing is
    # written. No exporter is installed yet, so accepting a destination answers that export is
    # unavailable without touching the chosen path, and cancelling answers that it was cancelled.
    # Neither reads the Model, starts the runtime or writes a file (CONTRACTS.md C6).
    module Workflow
      TITLE = "Export HBJSON"
      CANCELLED = "Export cancelled. Nothing was written."
      UNAVAILABLE = "No exporter is installed in this build, so nothing was written."

      module_function

      # The outcome of one Export command for `session`'s Model.
      def start(session)
        model = session.model
        directory = model.path.to_s.empty? ? nil : File.dirname(model.path)
        destination = UI.savepanel(TITLE, directory, "#{default_name(model)}.hbjson")
        if destination.nil?
          return Outcome.build("cancelled", "export.cancelled", CANCELLED, "none", session.revision)
        end

        Outcome.refused("export.unavailable", UNAVAILABLE, :revision => session.revision)
      end

      def default_name(model)
        name = File.basename(model.path.to_s, ".skp")
        name.empty? ? "model" : name
      end
    end
  end
end
