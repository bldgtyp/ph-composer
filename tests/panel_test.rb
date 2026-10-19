# frozen_string_literal: true

require "minitest/mock"
require_relative "test_helper"
require_relative "support/test_feature"

# A feature whose snapshot section fails to read, as a buggy query or a result off its schema would.
module BrokenSectionFeature
  def self.install(registry)
    feature = registry.feature("test.broken", :contract_version => 1)
    feature.query("test.broken.read", :description => "Always fails.", :params => { "type" => "object" },
                                      :result => { "type" => "object" }, :refuses => []) do |_request|
      raise "section bug"
    end
    feature.snapshot_section("test.broken.section", :query => "test.broken.read")
  end
end

# The panel as one client of the public interface: the dialog's lifecycle, the snapshot it shows, the
# mutations it sends on the user's behalf, and what it refuses to do.
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

  # REVIEW F04: a reply lost after the commit. Check status answers the retained outcome under the original
  # request id and runs nothing again.
  def test_check_status_answers_a_committed_change_without_running_it_again
    dialog = open_panel
    create(dialog, "r1")
    revision = @session.revision
    before = dialog.scripts.length

    send_message(dialog, "action.status", "request_id" => "r1", "session" => @session.id)

    published = dialog.scripts.drop(before).map { |script| decode(script).fetch("type") }
    assert_equal %w[panel.snapshot action.result], published
    result = messages(dialog, "action.result").last
    assert_equal "r1", result.fetch("request_id")
    assert_equal %w[completed committed], result.fetch("outcome").values_at("status", "effect")
    assert_equal revision, @session.revision
    assert_equal 1, PhComposer::Records::Engine.new(@model, PhComposer::Registry.current.catalog).ids(PART).length
  end

  # A request lost before execution: messages arrive in order, so an id never tracked never ran.
  def test_check_status_for_a_request_the_host_never_received_says_nothing_ran
    dialog = open_panel

    send_message(dialog, "action.status", "request_id" => "lost", "session" => @session.id)

    outcome = messages(dialog, "action.result").last.fetch("outcome")
    assert_equal %w[refused request.not_received none], outcome.values_at("status", "code", "effect")
    assert_equal 0, PhComposer::Records::Engine.new(@model, PhComposer::Registry.current.catalog).ids(PART).length
  end

  # Once an id has been dropped to keep the map bounded, a missing one may have run.
  def test_check_status_after_ids_were_dropped_does_not_claim_nothing_ran
    dialog = open_panel
    (PhComposer::PanelRequests::MAX_TRACKED + 1).times { |index| create(dialog, "r#{index}") }

    send_message(dialog, "action.status", "request_id" => "r0", "session" => @session.id)

    outcome = messages(dialog, "action.result").last.fetch("outcome")
    assert_equal %w[refused request.outcome_unavailable unknown], outcome.values_at("status", "code", "effect")
  end

  # A reopened page numbers its ids from the start again; its first id is not the old page's.
  def test_a_reloaded_page_never_reads_an_earlier_pages_outcome
    dialog = open_panel
    create(dialog, "r1")
    send_message(dialog, "panel.ready", {})

    send_message(dialog, "action.status", "request_id" => "r1", "session" => @session.id,
                                          "expected_revision" => @session.revision)

    outcome = messages(dialog, "action.result").last.fetch("outcome")
    assert_equal %w[refused request.not_received], outcome.values_at("status", "code")
  end

  def test_check_status_after_the_outcome_expired_keeps_the_effect_unknown
    dialog = open_panel
    now = 1000.0
    @session.outcomes.clock = -> { now }
    create(dialog, "r1")
    now += PhComposer::OutcomeStore::LIFETIME_SECONDS + 1

    send_message(dialog, "action.status", "request_id" => "r1", "session" => @session.id)

    outcome = messages(dialog, "action.result").last.fetch("outcome")
    assert_equal %w[refused request.outcome_unavailable unknown], outcome.values_at("status", "code", "effect")
  end

  # A view command carries no expected revision, because it changes no record. The snapshot still
  # follows it, so a section reading what it changed repaints.
  def test_a_query_answers_without_snapshot_or_model_operation_and_rejects_other_sessions
    dialog = open_panel
    before = dialog.scripts.length
    operations = @model.operations.length
    send_message(dialog, "query.invoke", "request_id" => "a:read:1", "session" => @session.id,
                                         "name" => "test.fixture.total_length", "params" => {})
    assert_equal ["query.result"], dialog.scripts.drop(before).map { |script| decode(script).fetch("type") }
    result = messages(dialog, "query.result").last
    assert_equal ["a:read:1", @session.id], result.values_at("request_id", "session")
    assert_equal "completed", result.dig("outcome", "status")
    assert_equal operations, @model.operations.length
    send_message(dialog, "query.invoke", "request_id" => "a:read:2", "session" => "other",
                                         "name" => "test.fixture.total_length", "params" => {})
    assert_equal "session.inactive", messages(dialog, "query.result").last.dig("outcome", "code")
  end

  def test_registered_file_export_uses_export_grant_without_mutating_or_refreshing_model
    feature = Module.new do
      def self.install(registry)
        scope = registry.feature("test.file_export", :contract_version => 1)
        scope.file_export("test.file_export.write",
                          :description => "Synthetic file command.",
                          :params => { "type" => "object", "properties" => {},
                                       "required" => [], "additionalProperties" => false },
                          :result => { "type" => "object", "properties" => {}, "required" => [],
                                       "additionalProperties" => false }, :refuses => []) { |_request| {} }
      end
    end
    PhComposer::Registry.install([feature])
    dialog = open_panel
    before = dialog.scripts.length
    operations = @model.operations.length
    send_message(dialog, "file_export.invoke", "request_id" => "a:file:1", "session" => @session.id,
                                               "name" => "test.file_export.write", "params" => {})
    assert_equal ["file_export.result"], dialog.scripts.drop(before).map { |script| decode(script).fetch("type") }
    result = messages(dialog, "file_export.result").last
    assert_equal ["a:file:1", @session.id], result.values_at("request_id", "session")
    assert_equal "completed", result.dig("outcome", "status")
    assert_equal "none", result.dig("outcome", "effect")
    assert_equal operations, @model.operations.length
    send_message(dialog, "file_export.invoke", "request_id" => "a:file:2", "session" => "other",
                                               "name" => "test.file_export.write", "params" => {})
    assert_equal "session.inactive", messages(dialog, "file_export.result").last.dig("outcome", "code")
  end

  def test_a_view_command_answers_after_the_snapshot_and_leaves_the_revision_alone
    dialog = open_panel
    before = dialog.scripts.length
    revision = @session.revision

    send_message(dialog, "view.invoke", "request_id" => "a:look:1", "session" => @session.id,
                                        "name" => "test.fixture.look", "params" => { "count" => 1 })

    published = dialog.scripts.drop(before).map { |script| decode(script).fetch("type") }
    result = messages(dialog, "view.result").last
    assert_equal %w[panel.snapshot view.result], published
    assert_equal ["a:look:1", @session.id], result.values_at("request_id", "session")
    assert_equal "completed", result.dig("outcome", "status")
    assert_equal revision, @session.revision
  end

  # Changing the selection raises a host event that would schedule a second identical snapshot; one
  # viewport click is one Model read.
  def test_a_view_command_that_changed_the_selection_leaves_no_second_snapshot_queued
    dialog = open_panel
    before = dialog.scripts.length

    send_message(dialog, "view.invoke", "request_id" => "a:look:1", "session" => @session.id,
                                        "name" => "test.fixture.look", "params" => { "count" => 1 })

    refute_predicate @session.refresh, :pending?
    assert_equal 1, dialog.scripts.drop(before).map { |script| decode(script).fetch("type") }
                          .count("panel.snapshot")
  end

  # A section reading through a busy session refuses with the same reason, so republishing would
  # replace every section's good data with that refusal.
  def test_a_refused_view_command_publishes_no_snapshot
    dialog = open_panel
    work = Struct.new(:pending?).new(true)
    @session.feature_state(:api_test) { work }
    before = dialog.scripts.length

    send_message(dialog, "view.invoke", "request_id" => "a:look:1", "session" => @session.id,
                                        "name" => "test.fixture.look", "params" => { "count" => 1 })

    published = dialog.scripts.drop(before).map { |script| decode(script).fetch("type") }
    assert_equal ["view.result"], published
    assert_equal "busy", messages(dialog, "view.result").last.dig("outcome", "status")
  end

  def test_a_view_command_for_a_model_the_panel_no_longer_shows_is_refused
    dialog = open_panel

    send_message(dialog, "view.invoke", "request_id" => "a:look:1", "session" => "another-session",
                                        "name" => "test.fixture.look", "params" => { "count" => 1 })

    assert_equal %w[refused session.inactive],
                 messages(dialog, "view.result").last.fetch("outcome").values_at("status", "code")
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

  # ------------------------------------------------------------------ export

  def test_cancelling_the_export_destination_writes_nothing
    dialog = open_panel

    with_ready_export { send_message(dialog, "export.start", "request_id" => "export:1", "session" => @session.id) }

    assert_equal ["Export HBJSON", nil, "model.hbjson"], UI.last_savepanel
    outcome = messages(dialog, "export.result").last.fetch("outcome")
    assert_equal %w[cancelled export.cancelled none], outcome.values_at("status", "code", "effect")
    assert_equal "Export cancelled. Nothing was written.", outcome.fetch("message")
  end

  # Declining replacement preserves the pair and starts no runtime or task timers. On macOS the Save
  # sheet already asked about the HBJSON, so only another platform asks again.
  def test_declining_replacement_preserves_the_pair_and_starts_no_runtime
    dialog = open_panel
    Sketchup.platform_value = :platform_win
    Dir.mktmpdir("phc-export-destination") do |directory|
      destination = File.join(directory, "existing.hbjson")
      File.write(destination, "prior export")
      File.write(File.join(directory, "existing-export-report.html"), "prior report")
      before = destination_contents(directory)
      timers = UI.timer_count
      UI.selected_save_path = destination
      UI.messagebox_result = IDNO

      PhComposer::AssetServer.stub(:new, ->(*) { flunk "Export started the runtime server" }) do
        with_ready_export { send_message(dialog, "export.start", "request_id" => "export:2", "session" => @session.id) }
      end

      outcome = messages(dialog, "export.result").last
      assert_equal "export:2", outcome.fetch("request_id")
      assert_equal %w[cancelled export.cancelled none],
                   outcome.fetch("outcome").values_at("status", "code", "effect")
      assert_equal ["Replace the existing HBJSON and Export report beside it?"], UI.messages
      assert_equal before, destination_contents(directory)
      assert_equal timers, UI.timer_count
    end
  end

  # A destination the pair would refuse, half a prior pair or a name without .hbjson, is refused as soon
  # as the Save sheet returns: nothing asks to replace it and no runtime starts.
  def test_an_unusable_destination_is_refused_before_any_question
    dialog = open_panel
    Dir.mktmpdir("phc-export-destination") do |directory|
      File.write(File.join(directory, "lone-export-report.html"), "prior report")
      File.write(File.join(directory, "noext-export-report.html"), "prior report")
      before = destination_contents(directory)
      [["lone.hbjson", "Only one destination artifact exists"], ["noext", "must end in .hbjson"]]
        .each_with_index do |(name, message), index|
        UI.selected_save_path = File.join(directory, name)
        PhComposer::AssetServer.stub(:new, ->(*) { flunk "Export started the runtime server" }) do
          with_ready_export do
            send_message(dialog, "export.start", "request_id" => "export:unusable:#{index}", "session" => @session.id)
          end
        end
        outcome = messages(dialog, "export.result").last.fetch("outcome")
        assert_equal %w[refused export.refused none], outcome.values_at("status", "code", "effect")
        assert_includes outcome.fetch("message"), message
      end
      assert_empty UI.messages.to_a
      assert_equal before, destination_contents(directory)
    end
  end

  def test_blocking_preflight_stays_visible_and_opens_no_destination
    dialog = open_panel
    send_message(dialog, "export.start", "request_id" => "export:blocked", "session" => @session.id)
    outcome = messages(dialog, "export.result").last.fetch("outcome")
    assert_equal "export.blocked", outcome.fetch("code")
    assert_equal "zone.none", outcome.fetch("findings").first.fetch("code")
    assert_nil UI.last_savepanel
    assert_empty @model.operations
  end

  def test_preflight_is_repeated_after_selected_solve_before_starting_a_task
    dialog = open_panel
    repair = { "id" => "solve", "action" => "ph_composer.zones.solve_adjacency", "params" => {} }
    before = PhComposer::Outcome.completed(:revision => @session.revision,
                                           :value => { "findings" => [], "repairs" => [repair] })
    after = PhComposer::Outcome.completed(:revision => @session.revision, :value => {
      "repairs" => [], "findings" => [{ "code" => "face.invalid", "blocks_export" => true,
                                        "message" => "Invalid Face after Solve." }]
    })
    preflights = [before, after]
    calls = []
    Dir.mktmpdir("phc-revalidate") do |directory|
      UI.selected_save_path = File.join(directory, "model.hbjson")
      invoke = lambda do |**args|
        calls << args[:name]
        PhComposer::Outcome.completed(:revision => @session.revision)
      end
      PhComposer::API.stub(:export_preflight, ->(**) { preflights.shift }) do
        PhComposer::API.stub(:invoke, invoke) do
          PhComposer::Export::Tasks.stub(:for, ->(*) { flunk "Task started despite post-Solve blocker" }) do
            send_message(dialog, "export.start", "request_id" => "repair", "session" => @session.id,
                                                 "repairs" => ["solve"])
          end
        end
      end
      assert_empty Dir.children(directory)
    end
    assert_empty preflights
    assert_equal ["ph_composer.zones.solve_adjacency"], calls
    outcome = messages(dialog, "export.result").last.fetch("outcome")
    assert_equal "export.blocked", outcome.fetch("code")
    assert_equal "face.invalid", outcome.fetch("findings").first.fetch("code")
  end

  def test_export_for_a_model_the_panel_no_longer_shows_is_refused_without_a_dialog
    dialog = open_panel

    send_message(dialog, "export.start", "request_id" => "export:3", "session" => "another-session")

    assert_nil UI.last_savepanel
    assert_equal "session.inactive", messages(dialog, "export.result").last.dig("outcome", "code")
  end

  def test_an_export_that_fails_to_start_is_answered_as_a_failure_that_wrote_nothing
    dialog = open_panel
    PhComposer::Diagnostics.strict = false

    PhComposer::Export::Workflow.stub(:start, ->(_session, **) { raise IOError, "dialog failed" }) do
      send_message(dialog, "export.start", "request_id" => "export:4", "session" => @session.id)
    end

    outcome = messages(dialog, "export.result").last.fetch("outcome")
    assert_equal %w[failed operation.failed none], outcome.values_at("status", "code", "effect")
  end

  private

  def with_ready_export(&block)
    outcome = PhComposer::Outcome.completed(:revision => @session.revision,
                                            :value => { "findings" => [], "repairs" => [] })
    PhComposer::API.stub(:export_preflight, outcome, &block)
  end

  def destination_contents(directory)
    Dir.children(directory).sort.to_h do |name|
      path = File.join(directory, name)
      [name, [File.binread(path), File.mtime(path)]]
    end
  end

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
