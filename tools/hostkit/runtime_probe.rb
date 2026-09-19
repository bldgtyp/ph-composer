# frozen_string_literal: true

# The development runtime probe (planning/archive/phase-zero/phases/phase-05-runtime.md, work item 7).
# Never shipped. Load it through the bridge after PH-Composer, then drive it one eval at a time, reading
# state in a call of its own so the runtime's UI timers and the page can run in between:
#
#   load "<repo>/tools/hostkit/runtime_probe.rb"
#   PhComposerRuntimeProbe.start          # opens the runtime window and asks for two probes at once
#   PhComposerRuntimeProbe.status         # results so far, server activity and held resources
#   PhComposerRuntimeProbe.teardown       # stops everything and reports what stopped
#   PhComposerRuntimeProbe.cancel         # the same stop, named for use while the boot is in flight
#   PhComposerRuntimeProbe.panel_ready    # opens the panel and times it until the page says ready
#
# Every verdict comes from the runtime's own report of what it holds, never from a timeout.
module PhComposerRuntimeProbe
  REQUESTS = %w[probe-one probe-two].freeze

  class << self
    attr_reader :runtime

    def start(session_id: PhComposer::Sessions.current&.id)
      raise ArgumentError, "No open Model session." unless session_id
      raise ArgumentError, "A probe is already running; tear it down first." if @runtime && !@runtime.stopped?

      @started_at = clock
      @runtime = PhComposer::RuntimeHost.new(:session_id => session_id).start
      REQUESTS.each { |id| @runtime.probe(id) }
      status
    end

    def status
      return { "state" => "none" } unless @runtime

      server = @runtime.server_snapshot
      {
        "state" => @runtime.state, "session" => @runtime.session_id, "results" => @runtime.results,
        "elapsed_ms" => ((clock - @started_at) * 1000).round, "resources" => @runtime.resources,
        "requests" => server.fetch("request_count"), "max_pump_ms" => server.fetch("max_pump_ms"),
        "refused" => server.fetch("request_ledger").reject { |row| row.fetch("status") == 200 }
      }.merge(verdict)
    end

    def teardown
      return { "state" => "none" } unless @runtime

      report = @runtime.stop
      report.merge("released" => report.fetch("after").values.all?(&:zero?) && !report.fetch("dialog_open"),
                   "live_runtime_dialogs" => live_runtime_dialogs)
    end
    alias cancel teardown

    # First call: opens the closed panel and starts the clock. Later calls: the time from `show` until the
    # page's `panel.ready` reached Ruby, once it has.
    def panel_ready
      if @panel_started
        return { "verdict" => "pending" } unless @panel_ready_at

        ms = ((@panel_ready_at - @panel_started) * 1000).round
        ceiling = PhComposer::RuntimeGate.fetch("panel_ready_ceiling_ms")
        return { "panel_ready_ms" => ms, "within_ceiling" => ms <= ceiling }
      end
      return { "note" => "close the panel first to time a fresh open" } if PhComposer::Panel.open?

      @panel_started = clock
      PhComposer::Panel.show
      { "opened" => true }
    end

    def mark_panel_ready
      @panel_ready_at ||= clock if @panel_started
    end

    private

    # Whether the two results meet the manifest's gates. Pending until both arrive.
    def verdict
      results = @runtime.results.select { |result| REQUESTS.include?(result["request_id"]) }
      return { "verdict" => "pending" } if results.length < REQUESTS.length

      gates = PhComposer::RuntimeGate
      checks = {
        "no_errors" => results.none? { |result| result.key?("error") },
        "single_flight_boot" => results.all? { |result| result["boot_count"] == 1 },
        "stack_not_loaded" => results.all? { |result| result["stack_loaded"] == [] },
        "cold_boot_within_ceiling" => results.all? do |result|
          result["cold_boot_ms"].to_i <= gates.fetch("cold_boot_ceiling_ms")
        end,
        "warm_round_trip_within_ceiling" => results.all? do |result|
          result["warm_round_trip_ms"].to_f <= gates.fetch("warm_round_trip_ceiling_ms")
        end
      }
      { "verdict" => checks.values.all? ? "PASS" : "FAIL", "checks" => checks }
    end

    def live_runtime_dialogs
      ObjectSpace.each_object(PhComposer::RuntimeHost).count { |host| !host.stopped? }
    end

    def clock
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end

# Development only: notes when the panel's page reports ready, for `panel_ready`.
module PhComposerRuntimeProbePanelClock
  private

  def ready
    PhComposerRuntimeProbe.mark_panel_ready
    super
  end
end
unless PhComposer::Panel.singleton_class.include?(PhComposerRuntimeProbePanelClock)
  PhComposer::Panel.singleton_class.prepend(PhComposerRuntimeProbePanelClock)
end
