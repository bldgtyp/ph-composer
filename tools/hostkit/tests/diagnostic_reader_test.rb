# frozen_string_literal: true

require "test_helper"
require "open3"
require "tmpdir"

# The development diagnostic reader against the real log module in strict mode: filters, cursors across
# eviction, clearing and a restarted process, the schema check, bounds, and that a read changes nothing.
class DiagnosticReaderTest < PhComposerTestCase
  Reader = PhComposerDiagnosticReader
  SESSION = "0f8a6c2e-1b3d-4e5f-8a9b-0c1d2e3f4a5b"
  OTHER = "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee"

  def setup
    super
    @directory = Dir.mktmpdir("ph-composer-reader")
    PhComposer::Diagnostics.path_override = File.join(@directory, "ph-composer.log")
  end

  def teardown
    FileUtils.remove_entry(@directory)
    super
  end

  def log(event, fields = {})
    PhComposer::Diagnostics.log(event, fields)
  end

  def test_filters_select_by_session_incident_run_and_least_severity
    log("opened", "session" => SESSION)
    log("export_runtime_failed", "session" => SESSION, "severity" => "error", "run_id" => "export_#{'a' * 24}")
    log("other", "session" => OTHER, "severity" => "warning")
    log("panel_failed", "severity" => "error", "incident" => "PHC-ABC123")

    assert_equal %w[opened export_runtime_failed], events(Reader.read("session" => SESSION))
    assert_equal %w[export_runtime_failed other panel_failed], events(Reader.read("severity" => "warning"))
    assert_equal %w[panel_failed], events(Reader.read("incident" => "PHC-ABC123"))
    assert_equal %w[export_runtime_failed], events(Reader.read("run_id" => "export_#{'a' * 24}"))
  end

  def test_a_cursor_resumes_after_the_last_line_returned
    log("first")
    first = Reader.read
    log("second")
    second = Reader.read("cursor" => first.fetch("next_cursor"))

    assert_equal "start", first.fetch("cursor_state")
    assert_equal %w[second], events(second)
    assert_equal "continued", second.fetch("cursor_state")
    assert_nil second.fetch("gap")
    assert_equal [], events(Reader.read("cursor" => second.fetch("next_cursor")))
  end

  def test_cleared_or_evicted_lines_and_another_process_are_named_not_hidden
    log("seen")
    cursor = Reader.read.fetch("next_cursor")
    log("unseen")
    PhComposer::Diagnostics.clear
    log("after")

    evicted = Reader.read("cursor" => cursor)
    assert_equal "evicted", evicted.fetch("cursor_state")
    assert_equal({ "lines" => 1 }, evicted.fetch("gap"))
    assert_equal %w[after], events(evicted)

    other_process = Reader.process == "00000000" ? "00000001" : "00000000"
    restarted = Reader.read("cursor" => "#{other_process}:#{cursor.split(':').last}")
    assert_equal "process_restarted", restarted.fetch("cursor_state")
    assert_equal "unknown", restarted.fetch("gap")
  end

  def test_a_cursor_from_an_empty_tail_resumes_at_the_first_line_logged
    empty = Reader.read
    log("first_ever")

    assert_equal [], events(empty)
    assert_equal %w[first_ever], events(Reader.read("cursor" => empty.fetch("next_cursor")))
  end

  def test_newest_returns_the_most_recent_matches_without_a_cursor
    12.times { |index| log("warning_#{index}", "severity" => "warning", "session" => SESSION) }
    log("the_failure", "severity" => "error", "session" => SESSION)
    newest = Reader.read("session" => SESSION, "severity" => "warning", "limit" => 10, "newest" => true)

    assert_equal "newest", newest.fetch("cursor_state")
    assert_equal 10, newest.fetch("events").length
    assert_equal "the_failure", newest.fetch("events").last.fetch("event"), "the newest failure is never cut"
    assert newest.fetch("truncated")
    refute newest.key?("next_cursor")
    assert_equal "refused", Reader.read("newest" => true, "cursor" => "#{Reader.process}:0").fetch("status")
  end

  def test_the_helpers_load_without_the_extension_and_a_read_says_it_is_unavailable
    script = "load #{File.expand_path('../host_helpers.rb', __dir__).inspect}; " \
             "puts PhComposerHost.diagnostics.fetch('status')"
    out, status = Open3.capture2e(RbConfig.ruby, "-e", script)

    assert status.success?, out
    assert_equal "unavailable", out.strip
  end

  def test_a_limit_truncates_and_the_cursor_points_past_the_last_line_returned
    5.times { |index| log("line_#{index}") }
    page = Reader.read("limit" => 2)
    rest = Reader.read("cursor" => page.fetch("next_cursor"))

    assert_equal %w[line_0 line_1], events(page)
    assert page.fetch("truncated")
    assert_equal %w[line_2 line_3 line_4], events(rest)
    refute rest.fetch("truncated")
  end

  def test_values_are_the_logs_own_reduction_and_the_read_reports_health_and_build
    log("export_runtime_failed", "severity" => "error", "error_class" => "RuntimeError")
    read = Reader.read

    record = read.fetch("events").first
    allowed = PhComposer::Diagnostics::ALLOWED_FIELDS + %w[timestamp line]
    assert_empty record.keys - allowed, "only the log's own fields, plus the line number"
    assert_equal({ "writing" => true, "last_error" => nil }, read.fetch("health"))
    assert_equal PhComposer::VERSION, read.dig("build", "extension_version")
    assert_equal 1, read.fetch("log_schema")
    assert_match(/acceptance_run\.py/, read.fetch("receipt"))
  end

  def test_unsupported_lines_are_counted_and_an_unsupported_log_schema_is_refused
    log("current")
    PhComposer::Diagnostics.send(:remember, JSON.generate("timestamp" => Time.now.utc.iso8601, "schema" => 2,
                                                          "event" => "future"))
    read = Reader.read
    assert_equal %w[current], events(read)
    assert_equal 1, read.fetch("unsupported_schema")

    with_constant(PhComposer::Diagnostics, :SCHEMA, 2) do
      refused = Reader.read
      assert_equal "refused", refused.fetch("status")
      assert_match(/schema 2/, refused.fetch("error"))
      refute refused.key?("events")
    end
  end

  def test_malformed_filters_are_refused_before_any_read
    { "session" => "'; system('x')", "severity" => "fatal", "cursor" => "../log", "limit" => 1000,
      "path" => "/etc/passwd" }.each do |name, value|
      refused = Reader.read(name => value)
      assert_equal "refused", refused.fetch("status"), name
      refute refused.key?("events"), name
    end
  end

  def test_a_read_changes_neither_the_log_nor_its_tail
    log("one")
    before = [PhComposer::Diagnostics.tail_window, File.read(PhComposer::Diagnostics.path)]
    Reader.read("severity" => "info")
    assert_equal before, [PhComposer::Diagnostics.tail_window, File.read(PhComposer::Diagnostics.path)]
  end

  private

  def events(read)
    read.fetch("events").map { |record| record.fetch("event") }
  end

  def with_constant(owner, name, value)
    original = owner.const_get(name)
    owner.send(:remove_const, name)
    owner.const_set(name, value)
    yield
  ensure
    owner.send(:remove_const, name)
    owner.const_set(name, original)
  end
end
