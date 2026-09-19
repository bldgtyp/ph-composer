# frozen_string_literal: true

require_relative "test_helper"

# One runtime's lifecycle against the stub dialog and a real loopback server on the shipped payload:
# nothing is sent before the page is ready, results are bound to the runtime's session, and stop
# reports what was running and that nothing still is (planning/refactor/phase-zero/phases/
# phase-05-runtime.md, work item 7).
class RuntimeHostTest < PhComposerTestCase
  RuntimeHost = PhComposer::RuntimeHost

  def setup
    super
    @received = []
    @dialog = UI::HtmlDialog.new
    @runtime = RuntimeHost.new(:session_id => "s1", :dialog_factory => -> { @dialog },
                               :on_message => ->(type, payload) { @received << [type, payload] })
  end

  def teardown
    @runtime.stop
    super
  end

  def test_start_opens_the_runtime_page_on_the_token_server_for_its_session
    @runtime.start

    assert_match(%r{\Ahttp://127\.0\.0\.1:\d+/[0-9a-f]{32}/html/runtime/index\.html\?session=s1\z}, @dialog.url)
    assert @dialog.visible?
    assert_equal "loading", @runtime.state
    assert_equal 1, @runtime.resources.fetch("socket")
  end

  def test_a_probe_waits_for_the_page_and_is_delivered_once_it_is_ready
    @runtime.start
    @runtime.probe("p1", :deadline_ms => 900)
    assert_empty @dialog.scripts

    page_says("runtime.ready", "session" => "s1", "cross_origin_isolated" => true)

    assert_equal "ready", @runtime.state
    assert_equal 1, @dialog.scripts.length
    assert_includes @dialog.scripts.first, '"type":"runtime.probe"'
    assert_includes @dialog.scripts.first, '"request_id":"p1","deadline_ms":900'
    @runtime.probe("p2")
    assert_includes @dialog.scripts.last, '"deadline_ms":15000', "the manifest's boot deadline by default"
  end

  def test_results_are_kept_only_for_this_runtimes_session
    @runtime.start
    page_says("runtime.ready", "session" => "s1")
    page_says("runtime.result", "session" => "s1", "request_id" => "p1", "cold_boot_ms" => 3000)
    page_says("runtime.result", "session" => "old", "request_id" => "p0")
    page_says("panel.snapshot", "session" => "s1")
    @dialog.fire(RuntimeHost::CALLBACK, "not json")

    assert_equal [{ "session" => "s1", "request_id" => "p1", "cold_boot_ms" => 3000 }], @runtime.results
    assert_equal %w[runtime.ready runtime.result], @received.map(&:first)
  end

  def test_stop_releases_the_dialog_server_timer_and_connections_and_says_so
    @runtime.start
    page_says("runtime.ready", "session" => "s1")

    report = @runtime.stop

    assert_equal "ready", report.fetch("state_at_stop")
    assert_equal 1, report.dig("before", "dialog")
    assert_equal 1, report.dig("before", "socket")
    assert(report.fetch("after").values.all?(&:zero?), report.inspect)
    refute report.fetch("dialog_open")
    refute @dialog.visible?
    assert_includes @dialog.scripts.last, '"type":"runtime.stop"'
    assert_equal 0, UI.timer_count
    assert_same report, @runtime.stop, "a second stop changes nothing and reports the first"
  end

  def test_a_window_that_fails_to_close_still_releases_the_server_and_is_reported_open
    PhComposer::Diagnostics.strict = false
    @runtime.start
    @dialog.define_singleton_method(:execute_script) { |_script| raise IOError, "page gone" }
    @dialog.define_singleton_method(:close) { raise IOError, "window busy" }

    report = @runtime.stop

    assert report.fetch("dialog_open"), "the window never closed, and the report says so"
    assert_equal 1, report.dig("after", "dialog")
    assert_equal({ "timer" => 0, "acceptor" => 0, "clients" => 0, "socket" => 0 },
                 report.fetch("after").reject { |key, _value| key == "dialog" })
  end

  def test_a_runtime_starts_once
    @runtime.start

    assert_raises(ArgumentError) { @runtime.start }
  end

  def test_closing_the_runtime_window_stops_it
    @runtime.start

    @dialog.close

    assert @runtime.stopped?
    assert(@runtime.resources.values.all?(&:zero?))
    page_says("runtime.result", "session" => "s1", "request_id" => "late")
    assert_empty @runtime.results, "a message after stop is ignored"
  end

  def test_a_payload_that_differs_from_its_manifest_is_refused_before_anything_starts
    Dir.mktmpdir("phc-runtime-host") do |root|
      FileUtils.mkdir_p(File.join(root, "html", "runtime"))
      FileUtils.mkdir_p(File.join(root, "vendor"))
      File.write(File.join(root, "html", "runtime", "index.html"), "tampered")
      entry = { "bytes" => 8, "sha256" => "0" * 64, "mime" => "text/html; charset=utf-8" }
      File.write(File.join(root, "vendor", "manifest.json"),
                 JSON.generate("schema_version" => 1, "manifest_asset" => "vendor/manifest.json",
                               "assets" => { RuntimeHost::PAGE => entry }))
      runtime = RuntimeHost.new(:session_id => "s1", :server => PhComposer::AssetServer.new(root),
                                :dialog_factory => -> { flunk "no dialog opens for a tampered payload" })

      error = assert_raises(PhComposer::RuntimeManifest::Invalid) { runtime.start }

      assert_includes error.message, RuntimeHost::PAGE
      assert(runtime.resources.values.all?(&:zero?))
    end
  end

  # The runtime names its session by id only, so a closed Model is never kept alive through it.
  def test_the_runtime_holds_no_model_or_session_object
    session = PhComposer::Sessions.for(Sketchup.active_model)
    runtime = RuntimeHost.new(:session_id => session.id, :dialog_factory => -> { UI::HtmlDialog.new }).start

    held = runtime.instance_variables.map { |name| runtime.instance_variable_get(name) }
    refute(held.any? { |value| value.is_a?(PhComposer::ModelSession) || value.is_a?(Sketchup::Model) })
  ensure
    runtime&.stop
  end

  def test_the_host_accepts_exactly_the_messages_the_runtime_page_sends
    page = File.read(File.join(SOURCE_ROOT, "ph_composer", "html", "runtime", "runtime.js"))

    assert_equal RuntimeHost::INBOUND.sort, page.scan(/\bsend\("([a-z]+\.[a-z_]+)"/).flatten.uniq.sort
  end

  private

  def page_says(type, payload)
    @dialog.fire(RuntimeHost::CALLBACK, JSON.generate("type" => type, "payload" => payload))
  end
end
