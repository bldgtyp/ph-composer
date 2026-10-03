# frozen_string_literal: true

module PhComposer
  module Export
    # Native destination and explicit preflight repairs. The read-only task starts only afterward.
    module Workflow
      TITLE = "Export HBJSON"
      CANCELLED = "Export cancelled. Nothing was written."
      REPLACE_QUESTION = "Replace the existing HBJSON and Export report beside it?"

      module_function

      # The outcome of one Export command for `session`'s Model, in stages: the preflight, the repairs
      # the user chose from it, the native destination and replacement consent, a check that the Model
      # did not change behind the dialogs, the repairs themselves, a second preflight, then the task.
      # Each stage that stops the command answers with the outcome it stopped on.
      def start(session, context:, request:, repairs: [])
        preflight = checked_preflight(session, context)
        return preflight unless preflight["status"] == "completed"

        chosen = chosen_repairs(preflight, repairs)
        return Outcome.refused("params.invalid", "Choose only declared preflight repairs.",
                               :revision => session.revision) unless chosen

        destination, refused = consent(session)
        return refused if refused
        return Outcome.build("cancelled", "export.cancelled", CANCELLED, "none", session.revision) unless destination
        return model_changed(session) unless unchanged?(session, preflight)

        failed = run_repairs(chosen, context, request)
        return failed if failed

        revalidated = checked_preflight(session, context)
        return revalidated unless revalidated["status"] == "completed"

        replace = [destination, ArtifactPair.report_path(destination)].any? { |path| File.exist?(path) }
        API.start_export(:context => context, :destination => destination, :replace => replace)
      end

      # The declared repairs the caller picked by id, or nil when it named one the preflight did not offer.
      def chosen_repairs(preflight, repairs)
        declared = preflight.fetch("value").fetch("repairs")
        return nil unless repairs.is_a?(Array) && (repairs - declared.map { |repair| repair.fetch("id") }).empty?

        declared.select { |repair| repairs.include?(repair.fetch("id")) }
      end

      # [destination, nil] from the native dialogs, nil when the user cancelled either, or [nil, refusal]
      # when the pair would refuse the destination, checked before anything asks to replace it.
      def consent(session)
        model = session.model
        directory = model.path.to_s.empty? ? nil : File.dirname(model.path)
        destination = UI.savepanel(TITLE, directory, "#{default_name(model)}.hbjson")
        return nil if destination.nil?

        problem = ArtifactPair.destination_problem(destination)
        return [nil, Outcome.refused("export.refused", problem, :revision => session.revision)] if problem
        return nil unless NativeApproval.confirm_replace(destination, REPLACE_QUESTION)

        [destination, nil]
      end

      # A native dialog may admit Model switches or changes, so the preflight's revision must still hold.
      def unchanged?(session, preflight)
        Sketchup.active_model.equal?(session.model) && session.valid? && session.revision == preflight["revision"]
      end

      def model_changed(session)
        Outcome.refused("export.model_changed", "The Model changed while choosing a destination. Try again.",
                        :revision => session.revision)
      end

      # Each chosen repair through its owner's public action, in order; the first that does not complete
      # is the outcome, and nil means every one did.
      def run_repairs(repairs, context, request)
        repairs.each do |repair|
          outcome = API.invoke(:context => context, :name => repair.fetch("action"), :params => repair.fetch("params"),
                               :request => request.call)
          return outcome unless outcome["status"] == "completed"
        end
        nil
      end

      def checked_preflight(session, context)
        outcome = API.export_preflight(:context => context)
        return outcome unless outcome["status"] == "completed"

        findings = outcome.fetch("value").fetch("findings")
        return outcome unless findings.any? { |finding| finding["blocks_export"] }

        Outcome.refused("export.blocked", "Resolve the blocking findings before exporting.",
                        :revision => session.revision, :findings => findings)
      end
      private_class_method :checked_preflight, :chosen_repairs, :consent, :unchanged?, :model_changed, :run_repairs

      def default_name(model)
        name = File.basename(model.path.to_s, ".skp")
        name.empty? ? "model" : name
      end
    end
  end
end
