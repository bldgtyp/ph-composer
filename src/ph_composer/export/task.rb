# frozen_string_literal: true

require "securerandom"

module PhComposer
  module Export
    # One read-only export, owned by its Model session rather than by a panel or caller connection.
    # Timer boundaries admit cancellation and recheck content generation; Python returns asynchronously.
    class Task
      attr_reader :id, :finished_at

      # `approval` is the NativeApproval::Granted for the destination: from the native Save sheet, or
      # resolved from an approved location, whose id and label the completed outcome names instead of
      # a path.
      def initialize(session, approval:, runtime_factory: nil)
        @session = session
        @id = "export_#{SecureRandom.hex(12)}"
        @destination = File.expand_path(approval.path)
        @location = approval.location_id && { "id" => approval.location_id, "label" => approval.label }
        @pair = ArtifactPair::Transaction.new(@destination, :run_id => id)
        @pair.recover
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

        finish(Outcome.build("cancelled", "export.cancelled", "Export cancelled. Nothing was written.",
                             "none", @session.revision))
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
        result.fetch("summary")["findings"] = result.fetch("findings").length
        result["state"] = "complete_with_findings" if result["state"] == "complete" && !result["findings"].empty?
        Privacy.validate!(result)
        unless result.dig("summary", "publishable") && result.dig("canonical_model", "hbjson")
          return finish(Outcome.build("refused", "export.blocked", "Export not created. Resolve the blocking findings.",
                                      "none", @session.revision, :findings => result.fetch("findings"),
                                                                 :value => { "result" => compact_result(result) }))
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
        @stage = "writing"
        @pair.commit(@result.fetch("canonical_model").fetch("hbjson"), html)
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
        Sessions.find(@session.id)
        coherent! unless terminal?
      rescue StandardError => error
        failed(error) unless terminal?
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
    end
  end
end
