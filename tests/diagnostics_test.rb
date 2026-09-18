# frozen_string_literal: true

require_relative "test_helper"

class DiagnosticsTest < PhComposerTestCase
  Diagnostics = PhComposer::Diagnostics

  def test_logs_allowed_fields_and_redacts_paths
    Dir.mktmpdir("ph-composer-log") do |directory|
      path = File.join(directory, "diagnostics.log")
      Diagnostics.path_override = path
      Diagnostics.log(
        "test",
        "status" => "/Users/ed/secret/model.skp",
        "sketchup_version" => "22.0.353"
      )
      payload = JSON.parse(File.read(path))
      assert_equal "[REDACTED_PATH]", payload.fetch("status")
      assert_equal "22.0.353", payload.fetch("sketchup_version")
    end
  end

  def test_logs_run_id
    Dir.mktmpdir("ph-composer-log") do |directory|
      path = File.join(directory, "diagnostics.log")
      Diagnostics.path_override = path

      Diagnostics.log("test", "run_id" => "run-123")

      assert_equal "run-123", JSON.parse(File.read(path)).fetch("run_id")
    end
  end

  def test_unknown_field_raises_in_strict_mode
    error = assert_raises(ArgumentError) do
      Diagnostics.log("test", "unknown_field" => "value")
    end

    assert_equal "Diagnostics field unknown_field is not allowed.", error.message
  end

  def test_unknown_field_writes_dropped_field_event_when_not_strict
    Dir.mktmpdir("ph-composer-log") do |directory|
      path = File.join(directory, "diagnostics.log")
      Diagnostics.path_override = path
      Diagnostics.strict = false

      Diagnostics.log("test", "status" => "ok", "unknown_field" => "value")

      lines = File.readlines(path).map { |line| JSON.parse(line) }
      assert_equal 2, lines.length
      assert_equal "test", lines.first.fetch("event")
      assert_equal "ok", lines.first.fetch("status")
      assert_equal "diagnostics_field_dropped", lines.last.fetch("event")
      assert_equal "unknown_field", lines.last.fetch("status")
    end
  end

  def test_reset_for_test_restores_non_strict_mode
    Diagnostics.strict = true

    Diagnostics.reset_for_test

    refute Diagnostics.strict
  end

  def test_redacts_explicit_secrets
    assert_equal "Model [REDACTED]", Diagnostics.redact("Model PrivateName", ["PrivateName"])
  end

  def test_redacts_entire_paths_including_spaces
    assert_equal "[REDACTED_PATH]", Diagnostics.redact("/Users/example/Dropbox/Client Model/model.skp")
    assert_equal "[REDACTED_PATH]", Diagnostics.redact("/tmp/model.skp")
    assert_equal "[REDACTED_PATH]", Diagnostics.redact("C:\\Users\\example\\Client Model\\model.skp")
  end

  # A root path is a path however short. `/Users` and `/tmp` are the two the privacy gate is most
  # likely to meet, and both reached the log unredacted while the matcher required two segments.
  def test_redacts_a_single_segment_root_path
    assert_equal "[REDACTED_PATH]", Diagnostics.redact("/Users")
    assert_equal "[REDACTED_PATH]", Diagnostics.redact("/tmp")
    assert Diagnostics.absolute_path?("/Users"), "the hygiene gate refuses it too"
    assert Diagnostics.absolute_path?("/tmp")
  end

  # The slash after whitespace is the ambiguous one, and it takes two segments to be a path.
  def test_redacts_an_embedded_path_but_not_an_embedded_name
    assert_equal "[REDACTED_PATH]", Diagnostics.redact("opened plan /Users/example")
    assert_equal "moved to /outside", Diagnostics.redact("moved to /outside")
  end

  def test_keeps_a_slash_used_inside_a_name
    assert_equal "Wall /exterior", Diagnostics.redact("Wall /exterior")
    assert_equal "Roof /2", Diagnostics.redact("Roof /2")
    assert_equal "Type A /B", Diagnostics.redact("Type A /B")
    assert_equal "file / name", Diagnostics.redact("file / name")
  end

  def test_redacts_file_urls
    assert_equal "[REDACTED_PATH]", Diagnostics.redact("file:///x")
  end

  def test_rotates_before_exceeding_size_cap
    Dir.mktmpdir("ph-composer-log") do |directory|
      path = File.join(directory, "diagnostics.log")
      Diagnostics.path_override = path
      File.write(path, "x" * Diagnostics::MAX_BYTES)
      Diagnostics.log("rotated", "status" => "ok")
      assert File.exist?(path + ".1")
      assert_operator File.size(path), :<, Diagnostics::MAX_BYTES
    end
  end
end
