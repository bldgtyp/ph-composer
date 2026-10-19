# frozen_string_literal: true

require_relative "test_helper"

class DiagnosticsTest < PhComposerTestCase
  Diagnostics = PhComposer::Diagnostics

  # No field takes free text: a path where a status belongs is refused, never written.
  def test_logs_allowed_fields_and_refuses_a_path_as_a_status
    Dir.mktmpdir("ph-composer-log") do |directory|
      path = File.join(directory, "diagnostics.log")
      Diagnostics.path_override = path
      Diagnostics.strict = false
      Diagnostics.log(
        "test",
        "status" => "/Users/ed/secret/model.skp",
        "sketchup_version" => "22.0.353"
      )
      payload = JSON.parse(File.read(path))
      assert_equal "[INVALID]", payload.fetch("status")
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

  # Forms a review once found passing: Ruby's own Windows spelling, a share, a home path, and a path
  # after punctuation. A web address and a ratio are not paths.
  def test_finds_paths_in_other_spellings_and_after_punctuation
    ["C:/Users/example/model.skp", "\\\\server\\share\\model.skp", "~/Desktop/model.skp",
     "(/Users/example/x)", "path=/Users/example/x", "saved to:/Users/example/x"].each do |text|
      assert Diagnostics.absolute_path?(text), text
    end
    ["https://example.com/a/b", "3:1 ratio", "Type A/B", "Roof /2"].each do |text|
      refute Diagnostics.absolute_path?(text), text
    end
  end

  def test_keeps_a_slash_used_inside_a_name
    assert_equal "Wall /exterior", Diagnostics.redact("Wall /exterior")
    assert_equal "Roof /2", Diagnostics.redact("Roof /2")
    assert_equal "Type A /B", Diagnostics.redact("Type A /B")
    assert_equal "file / name", Diagnostics.redact("file / name")
  end

  # An error raised by extension code, so its frames are the extension's.
  def raised
    yield
    flunk "expected an error"
  rescue PhComposer::Error => error
    error
  end

  def test_redacts_file_urls
    assert_equal "[REDACTED_PATH]", Diagnostics.redact("file:///x")
  end

  # REVIEW F01: two RuntimeErrors with different messages and backtraces logged equal records.
  def test_two_failures_are_told_apart_by_their_frames_never_their_messages
    first = raised { PhComposer::Preferences.set("unit_system", "Zone North at /Users/example/model.skp") }
    second = raised { PhComposer::Preferences.set("zone_north", "x") }

    records = [first, second].map { |error| Diagnostics.exception("probe_failed", error) }

    refute_equal records.first.fetch("frames"), records.last.fetch("frames")
    frame = records.first.fetch("frames").first
    assert_equal "ph_composer/shell/preferences.rb", frame.fetch("file")
    assert_kind_of Integer, frame.fetch("line")
    text = Diagnostics.tail.join
    refute_includes text, "Zone North"
    refute_includes text, "/Users/"
    assert_equal [1, "PhComposer::UserError", "error"], records.first.values_at("schema", "error_class", "severity")
  end

  def test_an_incident_reference_names_the_record_it_wrote
    reference = Diagnostics.incident("probe_failed", raised { PhComposer::Preferences.set("x", "y") })

    assert_match(/\APHC-[0-9A-F]{6}\z/, reference)
    assert_equal reference, JSON.parse(Diagnostics.tail.last).fetch("incident")
  end

  def test_every_event_carries_the_build_and_the_context_it_was_served_in
    Diagnostics.with_context("session" => "ses_1", "request" => "ses_1:form:3") do
      Diagnostics.log("served", "operation" => "example.create")
    end
    Diagnostics.log("after")

    served, after = Diagnostics.tail.last(2).map { |line| JSON.parse(line) }
    assert_equal ["development", "ses_1", "ses_1:form:3"], served.values_at("build", "session", "request")
    assert_nil after["session"], "the context ends with its block"
  end

  # Names come from declarations; a value that does not look like one is refused, never echoed.
  def test_a_value_its_field_does_not_accept_is_refused_in_strict_mode_and_replaced_otherwise
    assert_raises(ArgumentError) { Diagnostics.log("probe", "operation" => "Zone North") }

    Diagnostics.strict = false
    Diagnostics.log("probe", "operation" => "Zone North", "frames" => [{ "file" => "/Users/x.rb" }], "Bad Key" => 1)
    logged, dropped = Diagnostics.tail.last(2).map { |line| JSON.parse(line) }
    assert_equal %w[[INVALID] [INVALID]], logged.values_at("operation", "frames")
    assert_equal "[INVALID]", dropped.fetch("status"), "a dropped key that is not a field name is not echoed"
  end

  # Only files the extension ships: another plugin beside it, a traversal or a missing file is not a frame.
  def test_a_frame_must_name_a_file_the_extension_ships
    owned = { "file" => "html/panel.js", "line" => 3, "method" => "render" }
    assert Diagnostics.valid_frame?(owned)
    assert Diagnostics.valid_frame?(owned.merge("file" => "ph_composer/shell/panel.rb"))
    assert Diagnostics.valid_frame?(owned.merge("file" => "ph_composer_translation/entry.py"))
    ["other_plugin/client_name.rb", "html/../../Users/client/secret.js", "html/client_private.js",
     "ph_composer_translation/client_secret.py", "/Users/example/x.rb"].each do |file|
      refute Diagnostics.valid_frame?(owned.merge("file" => file)), file
    end
  end

  def test_an_error_class_too_long_to_be_one_is_refused
    Diagnostics.strict = false

    Diagnostics.log("probe", "error_class" => "A" * 10_000)

    assert_equal "[INVALID]", JSON.parse(Diagnostics.tail.last).fetch("error_class")
  end

  def test_a_dropped_key_never_makes_a_line_over_its_bound
    Diagnostics.strict = false

    Diagnostics.log("probe", ("k" * 10_000) => 1)

    dropped = Diagnostics.tail.last
    assert_operator dropped.bytesize, :<=, Diagnostics::MAX_EVENT_BYTES
    assert_equal "[INVALID]", JSON.parse(dropped).fetch("status")
  end

  # Every field is bounded, so even the largest event the log accepts fits in one line's bound.
  def test_the_largest_accepted_event_stays_within_its_bound
    frames = Array.new(Diagnostics::MAX_FRAMES) do |index|
      { "file" => "ph_composer/shell/panel.rb", "line" => index, "method" => "m" * 96 }
    end
    name = Array.new(24) { "abc" }.join(".")

    Diagnostics.log(name, "frames" => frames, "operation" => name, "stage" => name, "code" => name,
                          "error_class" => "A#{'b' * 95}", "status" => name)

    line = Diagnostics.tail.last
    assert_operator line.bytesize, :<=, Diagnostics::MAX_EVENT_BYTES
    assert_equal frames, JSON.parse(line).fetch("frames")
  end

  def test_a_failed_write_is_kept_as_the_logs_health_and_in_the_tail
    Dir.mktmpdir("ph-composer-log") do |directory|
      blocked = File.join(directory, "file")
      File.write(blocked, "")
      Diagnostics.path_override = File.join(blocked, "logs", "ph-composer.log")

      Diagnostics.log("unwritten")

      refute Diagnostics.health.fetch("writing")
      assert_match(/\AErrno::/, Diagnostics.health.fetch("last_error"))
      assert_equal "unwritten", JSON.parse(Diagnostics.tail.last).fetch("event")
      Diagnostics.path_override = File.join(directory, "ph-composer.log")
      Diagnostics.log("written")
      assert_equal({ "writing" => true, "last_error" => nil }, Diagnostics.health)
    end
  end

  def test_prune_keeps_seven_days_and_drops_an_older_archive
    Dir.mktmpdir("ph-composer-log") do |directory|
      path = File.join(directory, "ph-composer.log")
      Diagnostics.path_override = path
      now = Time.utc(2026, 10, 19, 12)
      old = JSON.generate("timestamp" => (now - (8 * 86_400)).iso8601, "event" => "old")
      recent = JSON.generate("timestamp" => (now - 86_400).iso8601, "event" => "recent")
      File.write(path, "#{old}\n#{recent}\nnot json\n")
      File.write(path + ".1", "#{old}\n#{recent}\n")

      Diagnostics.prune(now)

      assert_equal ["recent"], File.readlines(path).map { |line| JSON.parse(line).fetch("event") }
      assert_equal ["recent"], File.readlines(path + ".1").map { |line| JSON.parse(line).fetch("event") },
                   "an archive with recent events still loses its old ones"
      File.write(path + ".1", "#{old}\n")
      Diagnostics.prune(now)
      refute File.exist?(path + ".1")
    end
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
