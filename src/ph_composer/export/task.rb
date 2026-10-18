# frozen_string_literal: true

require "securerandom"

module PhComposer
  module Export
    # One read-only export, owned by its Model session rather than by a panel or caller connection.
    # Timer boundaries admit cancellation and recheck content generation; Python returns asynchronously.
    class Task
      PAIR_FAILED = "The HBJSON and Export report could not be written. The destination was left as it was."

      attr_reader :id, :finished_at, :owner

      # `approval` is the NativeApproval::Granted for the destination: from the native Save sheet, or
      # resolved from an approved location, whose id and label the completed outcome names instead of
      # a path.
      def initialize(session, approval:, owner:, runtime_factory: nil)
        @session = session
        @owner = owner
        @id = "export_#{SecureRandom.hex(12)}"
        @destination = File.expand_path(approval.path)
        @location = approval.location_id && { "id" => approval.location_id, "label" => approval.label }
        @pair = ArtifactPair::Transaction.new(@destination, :run_id => id)
        pair_step { @pair.recover }
        @prior = ArtifactPair.state(@destination)
        consent!(approval) if @prior
        @runtime_factory = runtime_factory || ->(&callback) {
          RuntimeHost.new(:session_id => session.id,
                          :on_message => callback)
        }
        @timer = CoalescedTimer.new
        @stage = "queued"
        @count = 0
        @units = Preferences.snapshot.fetch("unit_system")
      end

      def start
        @session.settle
        @generation = @session.export_generation
        @builder = Collection::Builder.new(@session.model, :run_id => id)
        @watchdog = UI.start_timer(0.2, true) { watch }
        schedule
        self
      rescue StandardError => error
        failed(error)
        self
      end

      def terminal?
        !@outcome.nil?
      end

      def snapshot
        DeepCopy.call("task_id" => id, "stage" => @stage, "count" => @count,
                      "cancellable" => !terminal? && @stage != "writing", "outcome" => @outcome)
      end

      def cancel
        return false if terminal? || @stage == "writing"

        finish(Outcome.build("cancelled", "export.cancelled", Workflow::CANCELLED, "none", @session.revision))
        true
      end

      private

      def schedule
        @timer.schedule { tick }
      end

      def tick
        return if terminal?

        coherent!
        @stage = "reading"
        if @builder.advance
          @extraction = @builder.extraction
          @builder = nil
          @stage = "translating"
          @runtime = @runtime_factory.call { |type, payload| received(type, payload) }
          @runtime.start
          @runtime.translate(id, @extraction.document)
        else
          @count = @builder.count
          schedule
        end
      rescue StandardError => error
        failed(error)
      end

      def received(type, payload)
        return if terminal?
        if type == "runtime.closed"
          return failed(Blocked.new("runtime.closed", "The export runtime closed before the run finished."))
        end
        return unless type == "runtime.translation" && payload["request_id"] == id

        coherent!
        if payload["error"]
          raise Blocked.new("runtime.translation_failed", "The export runtime could not translate this Model.")
        end

        @stage = "checking"
        result = payload.fetch("result")
        raise InternalError, "The runtime returned another run." unless result["run_id"] == id

        result.fetch("findings").concat(@extraction.findings.map { |note| note.merge("blocks_export" => false) })
        passed = passed_user_data(result.dig("canonical_model", "hbjson"))
        result.fetch("findings") << passed if passed
        result.fetch("summary")["findings"] = result.fetch("findings").length
        result["state"] = "complete_with_findings" if result["state"] == "complete" && !result["findings"].empty?
        Privacy.validate!(result)
        unless result.dig("summary", "publishable") && result.dig("canonical_model", "hbjson")
          value = { "result" => compact_result(result) }.merge(blocked_report(result))
          return finish(Outcome.build("refused", "export.blocked", "Export not created. Resolve the blocking findings.",
                                      "none", @session.revision, :findings => result.fetch("findings"),
                                                                 :value => value))
        end
        @result = result
        # Writing is a separate tick, so cancellation and queued host mutations are admitted after Python.
        @timer.schedule { commit }
      rescue StandardError => error
        failed(error)
      end

      def commit
        return if terminal?

        coherent!
        if ArtifactPair.state(@destination) != @prior
          raise Blocked.new("export.destination_changed",
                            "The destination pair changed during export. Choose it again.")
        end
        html = Report.render(@result, :display_units => @units)
        coherent!
        return revoked unless still_permitted?

        @stage = "writing"
        pair_step { @pair.commit(@result.fetch("canonical_model").fetch("hbjson"), html) }
        ApprovedLocations.mark_used(@location.fetch("id")) if @location
        value = { "result" => compact_result(@result) }
        value["location"] = @location if @location
        finish(Outcome.build("completed", "export.complete", "HBJSON and Export report created.", "none",
                             @session.revision, :value => value))
      rescue StandardError => error
        failed(error)
      end

      # Status carries counts and diagnostics. Canonical bytes are retrieved explicitly from files,
      # never serialized into every status response or retained once the pair has committed.
      # A blocked run writes no pair, so its report, labelled as from a run that wrote no model, travels in the
      # refused outcome for the panel to show, rendered without the canonical model so no HBJSON travels
      # with it (context/CONTRACTS.md, "Translation sections and artifacts"). A report that cannot render
      # leaves the refusal as it was rather than turning it into a failure.
      def blocked_report(result)
        shown = compact_result(result).tap { |document| document.delete("canonical_model") }
        { "report_html" => Report.render(shown, :display_units => @units, :published => false) }
      rescue StandardError => error
        Diagnostics.exception("export_blocked_report", error)
        {}
      end

      def compact_result(document)
        result = DeepCopy.call(document)
        result["canonical_model"]&.delete("hbjson")
        result
      end

      def coherent!
        raise Blocked.new("session.closed", "The Model closed before export finished.") unless @session.valid?
        if @session.export_generation != @generation
          raise Blocked.new("export.model_changed", "The Model content changed during export. Start again.")
        end
      end

      def watch
        # Reading the sessions detaches a closed Model's session, and detaching cancels this task.
        Sessions.find(@session.id)
        coherent! unless terminal?
      rescue StandardError => error
        failed(error) unless terminal?
      end

      # A pair error can carry the filesystem's own message, which names the destination; the outcome
      # says what failed in fixed words and the log keeps the error class. Half a prior pair keeps its
      # own fixed message, since the user must act on it.
      def pair_step
        yield
      rescue ArtifactPair::IncompletePriorPairError
        raise
      rescue ArtifactPair::PairError => error
        Diagnostics.exception("export_pair", error)
        raise Blocked.new("export.failed", PAIR_FAILED), :cause => nil
      end

      # Replacing a pair needs consent. The native Save sheet gives it against the pair as it is now; an
      # approved location gives it against the state export_preflight reported.
      def consent!(approval)
        unless approval.replace
          raise Blocked.new("export.replace_required", "Confirm replacement of the existing HBJSON/report pair.")
        end
        return unless approval.location_id

        unless approval.state
          raise Blocked.new("export.replace_required", "Replacing the pair at an approved location needs the " \
                                                       "expected_destination export_preflight reported.")
        end
        return if approval.state == @prior

        raise Blocked.new("export.destination_changed", "The destination pair changed after review. Preflight again.")
      end

      # Immediately before the pair is written, the access that started the task and the approved location
      # it named are checked again: a revocation acknowledged before this point writes nothing.
      def still_permitted?
        return false unless @owner.live.call
        return true unless @location

        File.expand_path(ApprovedLocations.resolve(@location.fetch("id"), :kind => "save_file")) == @destination
      rescue CodedError => error
        @revocation = error
        false
      end

      def revoked
        error = @revocation
        code, message = if error
                          [error.code, error.message]
                        else
                          ["export.revoked", "The access that started this export was revoked before it wrote " \
                                             "anything. No files were written."]
                        end
        finish(Outcome.build("refused", code, message, "none", @session.revision))
      end

      def failed(error)
        Diagnostics.exception("export_task", error) unless error.is_a?(UserError)
        code = error.is_a?(CodedError) ? error.code : "export.failed"
        message = error.is_a?(UserError) ? error.message : "Export could not finish. No new pair was created."
        finish(Outcome.build("failed", code, message, "none", @session.revision))
      end

      def finish(outcome)
        @outcome = outcome
        @finished_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @stage = "finished"
        @timer.cancel
        CoalescedTimer.stop(@watchdog)
        @watchdog = nil
        @runtime&.stop
        @runtime = @builder = @extraction = @result = nil
        @session.request_refresh if @session.valid?
      end

      # One finding counting the HBJSON objects that carry a user's passed-through user_data, or nil.
      def passed_user_data(hbjson)
        return nil unless hbjson.is_a?(String)

        counts = HbjsonMetadata.passed(hbjson, Privacy.user_data_keys)
        return nil if counts.empty?

        listed = counts.sort.map { |type, count| "#{count} #{type}#{count == 1 ? '' : 's'}" }.join(", ")
        { "code" => "export.user_data_passed", "section" => "canonical_model", "object_id" => nil,
          "message" => "User data passed through to the HBJSON on #{listed}.", "blocks_export" => false }
      end
    end
  end
end
