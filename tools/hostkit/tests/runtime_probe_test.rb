# frozen_string_literal: true

# The development runtime probe against the stub host: the page's reports drive the verdict, and
# teardown reports what it released rather than inferring it.
class RuntimeProbeTest < PhComposerTestCase
  Probe = PhComposerRuntimeProbe

  def setup
    super
    Probe.instance_variable_set(:@panel_started, nil)
    Probe.instance_variable_set(:@panel_ready_at, nil)
  end

  def teardown
    Probe.teardown
    super
  end

  def test_two_probes_share_one_boot_and_pass_the_manifest_gates
    status = Probe.start
    dialog = Probe.runtime.instance_variable_get(:@dialog)
    assert_equal "pending", status.fetch("verdict")

    page_says(dialog, "runtime.ready", {})
    Probe::REQUESTS.each do |id|
      page_says(dialog, "runtime.result", "request_id" => id, "boot_count" => 1, "stack_loaded" => [],
                                          "cold_boot_ms" => 2100, "warm_round_trip_ms" => 1.5)
    end

    status = Probe.status
    assert_equal "PASS", status.fetch("verdict"), status.inspect
    assert_equal 2, dialog.scripts.count { |script| script.include?("runtime.probe") }
  end

  def test_a_slow_boot_fails_the_verdict
    Probe.start
    dialog = Probe.runtime.instance_variable_get(:@dialog)
    page_says(dialog, "runtime.ready", {})
    Probe::REQUESTS.each do |id|
      page_says(dialog, "runtime.result", "request_id" => id, "boot_count" => 1, "stack_loaded" => [],
                                          "cold_boot_ms" => 9000, "warm_round_trip_ms" => 1.5)
    end

    assert_equal false, Probe.status.dig("checks", "cold_boot_within_ceiling")
  end

  def test_cancelling_mid_boot_reports_what_it_stopped
    Probe.start

    report = Probe.cancel

    assert_equal "loading", report.fetch("state_at_stop")
    assert_equal 1, report.dig("before", "dialog")
    assert report.fetch("released")
    assert_equal 0, report.fetch("live_runtime_dialogs")
    assert_raises(ArgumentError) { Probe.start(:session_id => nil) }
  end

  def test_a_second_probe_waits_for_the_first_to_be_torn_down
    first = Probe.start.fetch("run")

    assert_raises(ArgumentError) { Probe.start }
    Probe.teardown
    second = Probe.start
    assert_equal "loading", second.fetch("state")
    assert_match(/\A\h{12}\z/, first)
    refute_equal first, second.fetch("run"), "each run has its own id, so a wait on one cannot be met by the next"
  end

  def test_panel_ready_times_the_open_until_the_page_reports_ready
    assert_equal({ "opened" => true }, Probe.panel_ready)
    assert_equal({ "verdict" => "pending" }, Probe.panel_ready)

    PhComposer::Panel.instance_variable_get(:@dialog).fire("ph_composer_message", '{"type":"panel.ready"}')

    timing = Probe.panel_ready
    assert_operator timing.fetch("panel_ready_ms"), :>=, 0
    assert timing.fetch("within_ceiling")
  end

  private

  def page_says(dialog, type, payload)
    dialog.fire(PhComposer::RuntimeHost::CALLBACK,
                JSON.generate("type" => type, "payload" => payload.merge("session" => Probe.runtime.session_id)))
  end
end
