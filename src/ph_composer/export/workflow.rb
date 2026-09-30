# frozen_string_literal: true

module PhComposer
  module Export
    # Native destination and explicit preflight repairs. The read-only task starts only afterward.
    module Workflow
      TITLE = "Export HBJSON"
      CANCELLED = "Export cancelled. Nothing was written."

      module_function

      # The outcome of one Export command for `session`'s Model.
      def start(session, context:, repairs: [], request:)
        preflight = checked_preflight(session, context)
        return preflight unless preflight["status"] == "completed"

        declared = preflight.fetch("value").fetch("repairs")
        unless repairs.is_a?(Array) && (repairs - declared.map { |repair| repair.fetch("id") }).empty?
          return Outcome.refused("params.invalid", "Choose only declared preflight repairs.",
                                 :revision => session.revision)
        end
        model = session.model
        directory = model.path.to_s.empty? ? nil : File.dirname(model.path)
        destination = UI.savepanel(TITLE, directory, "#{default_name(model)}.hbjson")
        if destination.nil?
          return Outcome.build("cancelled", "export.cancelled", CANCELLED, "none", session.revision)
        end

        replace = [destination, ArtifactPair.report_path(destination)].any? { |path| File.exist?(path) }
        if replace && UI.messagebox("Replace the existing HBJSON and Export report beside it?", MB_YESNO) != IDYES
          return Outcome.build("cancelled", "export.cancelled", CANCELLED, "none", session.revision)
        end
        # A native dialog may admit Model switches or changes. Re-read both preflight and repair targets.
        unless Sketchup.active_model.equal?(model) && session.valid? && session.revision == preflight["revision"]
          return Outcome.refused("export.model_changed", "The Model changed while choosing a destination. Try again.",
                                 :revision => session.revision)
        end
        declared.select { |repair| repairs.include?(repair.fetch("id")) }.each do |repair|
          outcome = API.invoke(:context => context, :name => repair.fetch("action"), :params => repair.fetch("params"),
                               :request => request.call)
          return outcome unless outcome["status"] == "completed"
        end
        revalidated = checked_preflight(session, context)
        return revalidated unless revalidated["status"] == "completed"

        API.start_export(:context => context, :destination => destination, :replace => replace)
      end

      def checked_preflight(session, context)
        outcome = API.export_preflight(:context => context)
        return outcome unless outcome["status"] == "completed"

        findings = outcome.fetch("value").fetch("findings")
        return outcome unless findings.any? { |finding| finding["blocks_export"] }

        Outcome.refused("export.blocked", "Resolve the blocking findings before exporting.",
                        :revision => session.revision, :findings => findings)
      end
      private_class_method :checked_preflight

      def default_name(model)
        name = File.basename(model.path.to_s, ".skp")
        name.empty? ? "model" : name
      end
    end
  end
end
