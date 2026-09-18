# frozen_string_literal: true

require "minitest/mock"
require_relative "test_helper"
require_relative "support/test_feature"

# A feature whose snapshot section fails to read, as a buggy query or a result off its schema would.
module BrokenSectionFeature
  def self.install(registry)
    feature = registry.feature("test.broken", :contract_version => 1)
    feature.query("test.broken.read", :description => "Always fails.", :params => { "type" => "object" },
                                      :result => { "type" => "object" }) { |_request| raise "section bug" }
    feature.snapshot_section("test.broken.section", :query => "test.broken.read")
  end
end

# The panel as one client of the public interface: the dialog's lifecycle, the snapshot it shows, the
# mutations it sends on the user's behalf, and what it refuses to do (planning/refactor/phase-zero/
# phases/phase-04-panel-units.md, work items 2 and 6).
class PanelTest < PhComposerTestCase
  Panel = PhComposer::Panel
  PART = "test.fixture.part"

  def setup
    super
    PhComposer::Registry.install([TestFeature])
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
  end

  # ------------------------------------------------------------------ opening

  def test_the_extensions_menu_opens_the_panel_and_a_second_open_brings_it_forward
    PhComposer::Commands.install
    submenu = UI.menu("Extensions").entries.last
    command = submenu.entries.first

    assert_equal ["PH-Composer", "Open PH-Composer"], [submenu.name, command.menu_text]
    command.call
    dialog = Panel.show

    assert_equal Panel::PAGE, dialog.file
    assert File.exist?(Panel::PAGE), "the page ships beside the Ruby"
    assert_equal 1, dialog.bring_to_front_count
    assert dialog.visible?
  end

  def test_ready_publishes_the_shown_models_snapshot_with_every_registered_section
    dialog = open_panel

    snapshot = messages(dialog, "panel.snapshot").last
    assert_equal [@session.id, @session.revision], snapshot.values_at("session", "revision")
    assert_equal %w[PH-Composer 0.1.0-dev], snapshot.values_at("product", "version")
    assert_equal "completed", snapshot.dig("sections", "test.fixture.parts", "status")
    assert_equal({ "unit_system" => "SI", "dimension_formats" => {} },
                 snapshot.fetch("preferences").slice("unit_system", "dimension_formats"))
    assert_equal [], snapshot.fetch("edit_path")
  end

  def test_the_edit_path_names_what_the_user_has_opened
    group = @model.entities.add_group
    group.name = "Level 1"
    @model.active_path = [group]
    dialog = open_panel

    assert_equal ["Level 1"], messages(dialog, "panel.snapshot").last.fetch("edit_path")
  end

  # ------------------------------------------------------------------ mutations

  def test_an_action_uses_the_panels_own_caller_and_answers_after_the_authoritative_snapshot
    dialog = open_panel
    before = dialog.scripts.length

    send_message(dialog, "action.invoke", "request_id" => "a:create:1", "session" => @session.id,
                                          "name" => "test.fixture.create", "params" => parts(1),
                                          "expected_revision" => @session.revision)

    published = dialog.scripts.drop(before).map { |script| decode(script).fetch("type") }
    result = messages(dialog, "action.result").last
    assert_equal %w[panel.snapshot action.result], published
    assert_equal ["a:create:1", @session.id], result.values_at("request_id", "session")
    assert_equal %w[completed committed], result.fetch("outcome").values_at("status", "effect")
    assert_equal result.dig("outcome", "revision"), messages(dialog, "panel.snapshot").last.fetch("revision")
    assert_equal 1, @session.callers.count, "one panel caller for the session"
  end

  def test_each_panel_mutation_takes_the_next_sequence_so_none_is_mistaken_for_a_retry
    dialog = open_panel
    create(dialog, "r1")
    create(dialog, "r2")

    statuses = messages(dialog, "action.result").map { |result| result.dig("outcome", "status") }
    assert_equal %w[completed completed], statuses
    assert_equal 2, PhComposer::Records::Engine.new(@model, PhComposer::Registry.current.catalog).ids(PART).length
  end

  def test_an_action_against_an_older_revision_is_refused_and_writes_nothing
    dialog = open_panel
    stale = @session.revision
    create(dialog, "r1")
    operations = @model.operations.length

    send_message(dialog, "action.invoke", "request_id" => "r2", "session" => @session.id,
                                          "name" => "test.fixture.create", "params" => parts(1),
                                          "expected_revision" => stale)

    outcome = messages(dialog, "action.result").last.fetch("outcome")
    assert_equal %w[refused revision.stale none], outcome.values_at("status", "code", "effect")
    assert_equal operations, @model.operations.length
  end

  def test_an_action_for_a_model_the_panel_no_longer_shows_is_refused_and_writes_nothing
    dialog = open_panel
    other = Sketchup::Model.new
    Sketchup.active_model = other
    other_session = PhComposer::Sessions.for(other)
    operations = @model.operations.length

    send_message(dialog, "action.invoke", "request_id" => "r1", "session" => @session.id,
                                          "name" => "test.fixture.create", "params" => parts(1),
                                          "expected_revision" => @session.revision)

    result = messages(dialog, "action.result").last
    assert_equal @session.id, result.fetch("session")
    assert_equal %w[refused session.inactive none], result.fetch("outcome").values_at("status", "code", "effect")
    assert_match(/Nothing was written\.\z/, result.dig("outcome", "message"))
    assert_equal operations, @model.operations.length
    assert_equal other_session.id, messages(dialog, "panel.snapshot").last.fetch("session"),
                 "the page is brought up to the Model it should show"
    assert_equal ["warning", other_session.id], messages(dialog, "panel.notice").last.values_at("tone", "session"),
                 "and told why its change was not applied"
  end

  def test_a_new_model_that_becomes_active_repaints_the_panel_without_an_activation_event
    dialog = open_panel
    other = Sketchup::Model.new
    Sketchup.active_model = other
    other_session = PhComposer::Sessions.for(other)

    UI.run_timers
    assert_equal other_session.id, messages(dialog, "panel.snapshot").last.fetch("session")
  end

  # ------------------------------------------------------------------ failures while answering

  def test_a_section_that_fails_to_read_reports_itself_and_the_action_result_still_arrives
    PhComposer::Registry.install([BrokenSectionFeature])
    dialog = open_panel
    create(dialog, "r1")

    snapshot = messages(dialog, "panel.snapshot").last
    assert_equal "failed", snapshot.dig("sections", "test.broken.section", "status")
    assert_equal "completed", snapshot.dig("sections", "test.fixture.parts", "status"), "other sections unaffected"
    assert_equal %w[r1 completed], messages(dialog, "action.result").last.then { |result|
      [result.fetch("request_id"), result.dig("outcome", "status")]
    }
  end

  def test_an_unexpected_error_still_answers_the_request_that_is_waiting
    dialog = open_panel
    PhComposer::API.stub(:invoke, ->(**) { raise "dispatcher bug" }) { create(dialog, "r1") }
    PhComposer::Preferences.stub(:set, ->(*, **) { raise IOError, "store unavailable" }) do
      send_message(dialog, "preferences.set", "request_id" => "p1", "key" => "unit_system", "value" => "IP")
    end

    outcome = messages(dialog, "action.result").last
    assert_equal ["r1", "failed", "unknown"], [outcome.fetch("request_id")] + outcome.fetch("outcome").values_at(
      "status", "effect"
    ), "a failure the panel cannot account for never claims the Model is unchanged"
    assert_equal %w[p1 failed], messages(dialog, "preferences.result").last.values_at("request_id", "status")
  end

  def test_a_missing_development_script_does_not_keep_the_first_snapshot_from_the_page
    Panel.add_development_script("/nonexistent/editor.js")
    dialog = open_panel

    assert_equal 1, messages(dialog, "panel.snapshot").length
  end

  # ------------------------------------------------------------------ lifecycle

  def test_a_closed_panels_page_is_ignored_and_reopening_starts_a_new_page
    dialog = open_panel
    dialog.close
    refute Panel.open?

    dialog.fire("ph_composer_message", envelope("action.invoke", "request_id" => "late", "session" => @session.id,
                                                                 "name" => "test.fixture.create", "params" => parts(1),
                                                                 "expected_revision" => @session.revision))
    reopened = open_panel

    refute_same dialog, reopened
    assert_empty messages(dialog, "action.result"), "nothing reaches a closed page"
    assert_equal 0, PhComposer::Records::Engine.new(@model, PhComposer::Registry.current.catalog).ids(PART).length
  end

  def test_a_host_change_refreshes_the_open_panel_once_the_coalesced_timer_runs
    dialog = open_panel
    before = messages(dialog, "panel.snapshot").length
    @model.start_operation("External", true)
    @model.commit_operation

    UI.run_timers
    snapshots = messages(dialog, "panel.snapshot")
    assert_equal before + 1, snapshots.length
    assert_equal @session.revision, snapshots.last.fetch("revision")
  end

  def test_a_notice_never_opens_the_panel_and_waits_for_it_to_show_that_model
    @session.notice("Checked 4 parts.", :tone => :info)
    refute Panel.open?

    dialog = open_panel
    assert_equal [{ "session" => @session.id, "message" => "Checked 4 parts.", "tone" => "info" }],
                 messages(dialog, "panel.notice")
  end

  def test_a_malformed_message_is_answered_with_a_failure_and_changes_nothing
    dialog = open_panel
    dialog.fire("ph_composer_message", "{not json")
    dialog.fire("ph_composer_message", envelope("action.invoke", "surprise" => true))

    assert_equal ["The panel message is not JSON.", "The action.invoke payload carries surprise."],
                 messages(dialog, "panel.failure").map { |failure| failure.fetch("message") }
  end

  # ------------------------------------------------------------------ preferences

  def test_a_display_preference_is_remembered_without_touching_the_model
    dialog = open_panel
    @model.instance_variable_set(:@modified, false)
    revision = @session.revision
    operations = @model.operations.length

    send_message(dialog, "preferences.set", "request_id" => "p1", "key" => "unit_system", "value" => "IP")
    send_message(dialog, "preferences.set", "request_id" => "p2", "key" => "dimension_format", "value" => "ft-in",
                                            "scope" => "test.fixture.editor", "system" => "IP")

    results = messages(dialog, "preferences.result")
    assert_equal %w[completed completed], results.map { |result| result.fetch("status") }
    assert_equal "IP", results.last.dig("preferences", "unit_system")
    assert_equal({ "test.fixture.editor" => { "SI" => "mm", "IP" => "ft-in" } },
                 results.last.dig("preferences", "dimension_formats"))
    refute @model.modified?, "a preference never dirties the SKP"
    assert_equal [revision, operations], [@session.revision, @model.operations.length]
  end

  def test_an_invalid_preference_is_refused_with_its_reason
    dialog = open_panel
    send_message(dialog, "preferences.set", "request_id" => "p1", "key" => "unit_system", "value" => "metric")
    send_message(dialog, "preferences.set", "request_id" => "p2", "key" => "dimension_format", "value" => "mm",
                                            "scope" => "test.fixture.editor", "system" => "IP")

    assert_equal [["refused", "Display units must be SI or IP."], ["refused", "Choose a valid IP dimension format."]],
                 messages(dialog, "preferences.result").map { |result| result.values_at("status", "message") }
    assert_equal "SI", PhComposer::Preferences.unit_system
  end

  private

  def open_panel
    dialog = Panel.show
    dialog.fire("ph_composer_message", envelope("panel.ready", {}))
    dialog
  end

  def create(dialog, request_id)
    send_message(dialog, "action.invoke", "request_id" => request_id, "session" => @session.id,
                                          "name" => "test.fixture.create", "params" => parts(1),
                                          "expected_revision" => @session.revision)
  end

  def parts(count)
    { "parts" => Array.new(count) { |index| { "label" => "Part #{index}", "length_mm" => 100.0 + index } } }
  end

  def send_message(dialog, type, payload)
    dialog.fire("ph_composer_message", envelope(type, payload))
  end

  def envelope(type, payload)
    JSON.generate("type" => type, "payload" => payload)
  end

  def messages(dialog, type)
    dialog.scripts.map { |script| decode(script) }.select { |item| item.fetch("type") == type }
                  .map { |item| item.fetch("payload") }
  end

  def decode(script)
    JSON.parse(script[/receive\((.*)\)\z/m, 1])
  end
end
