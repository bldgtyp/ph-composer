# frozen_string_literal: true

require_relative "test_helper"

# Help & Diagnostics: reachable with no Model and no panel, a preview that is exactly what is copied or
# saved, a report that carries nothing private, and recoveries that change only what they name.
class SupportDialogTest < PhComposerTestCase
  SupportDialog = PhComposer::SupportDialog
  Diagnostics = PhComposer::Diagnostics

  def setup
    super
    @directory = Dir.mktmpdir("phc-support-")
    Diagnostics.path_override = File.join(@directory, "logs", "ph-composer.log")
  end

  def teardown
    FileUtils.remove_entry(@directory)
    super
  end

  def test_the_extensions_menu_opens_it_with_no_model_and_no_panel
    PhComposer::Commands.install
    Sketchup.active_model = nil

    item = submenu_item(PhComposer::Commands::HELP)
    item.last.call

    assert SupportDialog.open?
    refute PhComposer::Panel.open?
    state = ready_state
    assert_equal [PhComposer::VERSION, "development", true], state["about"].values_at("version", "build", "development")
    assert_equal({ "writing" => true, "last_error" => nil }, state.dig("about", "log"))
  end

  def test_recent_problems_name_their_incident_and_never_their_details
    reference = Diagnostics.incident("operation_failed", raised { PhComposer::Preferences.set("zone_north", "x") },
                                     "operation" => "example.create")
    SupportDialog.show(:incident => reference)

    state = ready_state
    assert_equal [{ "label" => "An edit or read could not be completed", "incident" => reference }],
                 state["problems"].map { |problem| problem.slice("label", "incident") }
    assert_equal reference, state["incident"]
  end

  def test_an_empty_log_says_nothing_was_recorded_not_that_all_is_well
    SupportDialog.show
    assert_empty ready_state["problems"]

    report = capture
    assert_includes report["text"], "Events: none recorded; an empty log does not show that nothing failed"
  end

  # The preview, the copy (the page's own text) and the saved file are the same bytes.
  def test_the_saved_report_is_the_previewed_bytes_and_a_cancel_writes_nothing
    Diagnostics.log("probe", "status" => "ok")
    report = capture
    destination = File.join(@directory, "report.txt")

    UI.selected_save_path = nil
    send_message("support.save", "capture_id" => report["capture_id"])
    assert_equal "cancelled", last_result["status"]
    refute File.exist?(destination)

    UI.selected_save_path = destination
    send_message("support.save", "capture_id" => report["capture_id"])
    assert_equal "completed", last_result["status"]
    assert_equal report["text"].b, File.binread(destination)
    assert_equal [destination], Dir.glob(File.join(@directory, "report.txt*"))
  end

  def test_an_unwritable_destination_keeps_the_preview_and_leaves_nothing_partial
    report = capture
    UI.selected_save_path = File.join(@directory, "missing", "report.txt")

    send_message("support.save", "capture_id" => report["capture_id"])

    assert_equal %w[support.save failed], last_result.values_at("action", "status")
    assert_equal report["text"], PhComposer::SupportReport.text(report["capture_id"]), "the preview still saves"
    refute Dir.exist?(File.join(@directory, "missing"))
  end

  def test_a_preview_replaced_by_a_refresh_is_not_saved
    first = capture
    capture
    UI.selected_save_path = File.join(@directory, "report.txt")

    send_message("support.save", "capture_id" => first["capture_id"])

    assert_equal "refused", last_result["status"]
    refute File.exist?(File.join(@directory, "report.txt"))
  end

  # Whatever reached the log file, the report copies only fields and values the log accepts.
  def test_the_report_leaves_out_paths_names_tokens_and_payloads_at_every_boundary
    seeded = { "timestamp" => Time.now.utc.iso8601, "event" => "probe", "schema" => 1,
               "status" => "Zone North at /Users/example/Client/model.skp", "operation" => "Project Alpha",
               "token" => "phc_secret_token", "params" => { "label" => "Licensed PHPP row" },
               "error_class" => "RuntimeError", "frames" => [{ "file" => "/Users/example/x.rb", "line" => 1,
                                                               "method" => "m" }] }
    FileUtils.mkdir_p(File.dirname(Diagnostics.path))
    File.write(Diagnostics.path, "#{JSON.generate(seeded)}\nnot json at /Users/example\n")

    text = capture["text"]

    ["/Users/", "Zone North", "Project Alpha", "phc_secret_token", "Licensed PHPP"].each do |secret|
      refute_includes text, secret
    end
    assert_includes text, '"error_class":"RuntimeError"'
    assert_match(/^Omitted: Model geometry and names, file paths/, text)
  end

  def test_a_long_log_is_cut_to_its_newest_lines_with_the_cut_stated
    FileUtils.mkdir_p(File.dirname(Diagnostics.path))
    line = JSON.generate("timestamp" => Time.now.utc.iso8601, "event" => "probe", "status" => "x" * 90) + "\n"
    File.write(Diagnostics.path, line * ((PhComposer::SupportReport::MAX_LOG_BYTES / line.bytesize) + 10))

    text = capture["text"]

    assert_match(/earlier lines left out/, text)
    assert_operator text.bytesize, :<, PhComposer::SupportReport::MAX_LOG_BYTES + 4096
  end

  def test_an_unreadable_log_still_gives_a_partial_report_that_says_so
    Diagnostics.log("in_memory", "status" => "ok")
    FileUtils.rm_f(Diagnostics.path)
    FileUtils.mkdir_p(Diagnostics.path)

    text = capture["text"]

    assert_match(/Events: the log could not be read \(Errno::EISDIR\); showing this session's/, text)
    assert_includes text, '"event":"in_memory"'
  end

  def test_clearing_history_removes_the_log_and_keeps_saved_reports_and_the_model
    Diagnostics.log("probe")
    saved = File.join(@directory, "kept-report.txt")
    File.write(saved, "mine")
    revision = PhComposer::Sessions.for(Sketchup.active_model).revision
    SupportDialog.show

    send_message("support.clear_history", {})

    refute File.exist?(Diagnostics.path)
    assert_equal "mine", File.read(saved)
    assert_equal revision, PhComposer::Sessions.for(Sketchup.active_model).revision
    assert_equal "completed", last_result["status"]
  end

  def test_reset_display_preferences_changes_only_display_preferences
    PhComposer::Preferences.set("unit_system", "IP")
    Sketchup.write_default(PhComposer::EXTENSION_ID, "approved_locations", "kept")
    SupportDialog.show

    send_message("support.reset_preferences", {})

    assert_equal "SI", PhComposer::Preferences.unit_system
    assert_equal "kept", Sketchup.read_default(PhComposer::EXTENSION_ID, "approved_locations")
    assert_equal "completed", last_result["status"]
  end

  def test_reopen_panel_replaces_its_window
    first = PhComposer::Panel.show
    SupportDialog.show

    send_message("support.reopen_panel", {})

    refute first.visible?
    assert PhComposer::Panel.open?
  end

  def test_help_and_report_a_problem_open_their_addresses_and_send_nothing
    SupportDialog.show
    send_message("support.open_help", {})
    send_message("support.report_problem", {})

    assert_equal [SupportDialog::HELP_URL, SupportDialog::ISSUE_URL], UI.opened_urls
  end

  def test_a_page_that_never_answers_falls_back_to_a_message_box
    SupportDialog.show
    UI.run_timer(UI.timer_intervals.key(SupportDialog::FALLBACK_SECONDS))

    refute SupportDialog.open?
    assert_equal [SupportDialog.fallback_text], UI.messages
    assert_includes UI.messages.first, "Build: development"
    assert_includes UI.messages.first, "Help: https://github.com/bldgtyp/ph-composer"
  end

  def test_a_window_that_cannot_be_built_falls_back_to_a_message_box
    UI::HtmlDialog.stub(:new, ->(*) { raise "no dialog" }) { SupportDialog.show }

    assert_equal [SupportDialog.fallback_text], UI.messages
  end

  def test_a_message_it_does_not_accept_is_refused
    SupportDialog.show
    send_message("support.save", "capture_id" => "x", "path" => "/tmp/anywhere")

    assert_equal "refused", last_result["status"]
  end

  def test_the_page_sends_exactly_the_messages_the_dialog_accepts
    page = File.read(File.join(SOURCE_ROOT, "ph_composer", "html", "support", "page.js"))

    sent = page.scan(/send\("(support\.[a-z_]+)"/).flatten
    handled = page.scan(/message\.type === "(support\.[a-z_]+)"/).flatten

    assert_equal SupportDialog::INBOUND.keys.sort, sent.uniq.sort
    assert_equal SupportDialog::OUTBOUND.keys.sort, handled.sort
  end

  def test_the_panel_opens_it_at_an_incident
    dialog = PhComposer::Panel.show
    dialog.fire("ph_composer_message", JSON.generate("type" => "panel.ready", "payload" => {}))
    dialog.fire("ph_composer_message",
                JSON.generate("type" => "panel.support", "payload" => { "incident" => "PHC-ABC123" }))

    assert SupportDialog.open?
    assert_equal "PHC-ABC123", ready_state["incident"]
  end

  private

  def dialog
    SupportDialog.instance_variable_get(:@dialog)
  end

  def send_message(type, payload)
    dialog.fire(SupportDialog::CALLBACK, JSON.generate("type" => type, "payload" => payload))
  end

  def messages(type)
    dialog.scripts.map { |script| JSON.parse(script[/receive\((.*)\)\z/m, 1]) }
          .select { |message| message["type"] == type }.map { |message| message["payload"] }
  end

  def ready_state
    send_message("support.ready", {})
    messages("support.state").last
  end

  def capture
    SupportDialog.show unless SupportDialog.open?
    send_message("support.capture", "purpose" => "save")
    messages("support.capture").last
  end

  def last_result
    messages("support.result").last
  end

  def submenu_item(label)
    submenu = UI.menu("Extensions").entries.find { |entry|
      entry.is_a?(UI::Menu) && entry.name == PhComposer::EXTENSION_NAME
    }
    submenu.entries.find { |entry| entry.is_a?(Array) && entry.first == label }
  end

  def raised
    yield
    flunk "expected an error"
  rescue PhComposer::Error => error
    error
  end
end
