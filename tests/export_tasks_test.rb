# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"

class ExportTasksTest < PhComposerTestCase
  class Runtime
    attr_reader :document, :stopped

    def initialize(&callback)
      @callback = callback
    end

    def start; end

    def translate(id, document)
      @id = id
      @document = document
    end

    def stop
      @stopped = true
    end

    def blocked(canonical: nil)
      result = {
        "schema_version" => 1, "run_id" => @id, "state" => "complete_with_findings",
        "summary" => { "objects" => 0, "unavailable" => 1, "findings" => 1, "publishable" => false },
        "sections" => [], "failure" => nil,
        "findings" => [{ "code" => "object.unavailable", "section" => "fixture",
                         "object_id" => "zone", "message" => "Choose an authored construction.",
                         "blocks_export" => true }]
      }
      result["canonical_model"] = canonical if canonical
      @callback.call("runtime.translation", "request_id" => @id, "result" => result)
    end

    def close
      @callback.call("runtime.closed", {})
    end

    def success
      @callback.call("runtime.translation", "request_id" => @id, "result" => {
        "schema_version" => 1, "run_id" => @id, "state" => "complete",
        "summary" => { "objects" => 0, "unavailable" => 0, "findings" => 0, "publishable" => true },
        "sections" => [], "failure" => nil, "findings" => [],
        "canonical_model" => { "hbjson" => JSON.generate("type" => "Model", "rooms" => []),
                               "rooms" => 0, "faces" => 0, "surface_pairs" => 0 }
      })
    end
  end

  def setup
    super
    @directory = Dir.mktmpdir("phc-export-task-")
    @session = PhComposer::Sessions.for(Sketchup.active_model)
    @tasks = PhComposer::Export::Tasks.for(@session)
    @factory = ->(&callback) { @runtime = Runtime.new(&callback) }
    @destination = File.join(@directory, "test.hbjson")
  end

  def teardown
    @tasks.detach
    FileUtils.remove_entry(@directory)
    super
  end

  def test_tasks_are_pollable_detached_and_can_cancel_before_collection_without_boot
    task = start
    task["stage"] = "tampered"
    assert_equal "queued", @tasks.status(task.fetch("task_id")).fetch("stage")
    result = @tasks.cancel(task.fetch("task_id"))
    drain

    assert_equal "cancelled", result.dig("outcome", "status")
    assert_nil @runtime
    assert_empty Dir.children(@directory)
  end

  def test_edit_context_and_selection_do_not_invalidate_but_content_changes_do
    task = start
    @session.model.active_path = []
    @session.model.selection.add(Sketchup::Face.new(99))
    drain
    assert_equal "translating", @tasks.status(task.fetch("task_id")).fetch("stage")

    @session.model.start_operation("External edit")
    @session.model.set_attribute("test", "value", 1)
    @session.model.commit_operation
    @runtime.blocked
    assert_equal "export.model_changed", @tasks.status(task.fetch("task_id")).dig("outcome", "code")
    assert @runtime.stopped
    assert_empty Dir.children(@directory)
  end

  def test_native_edit_path_commit_is_navigation_but_the_preceding_content_commit_is_not
    group = Sketchup::Group.new(900, Sketchup::Entities.new([]))
    @session.model.entities << group
    initial = @session.export_generation
    @session.host_event(:transaction_committed)
    assert_equal initial + 1, @session.export_generation
    @session.model.instance_variable_set(:@active_path, [group])
    @session.host_event(:transaction_committed)
    @session.host_event(:active_path_changed)
    assert_equal initial + 1, @session.export_generation
    @session.host_event(:transaction_committed)
    assert_equal initial + 2, @session.export_generation
  end

  def test_blocking_results_keep_findings_and_write_no_pair
    task = start
    drain
    @runtime.blocked
    outcome = @tasks.status(task.fetch("task_id")).fetch("outcome")

    assert_equal %w[refused export.blocked none], outcome.values_at("status", "code", "effect")
    assert_equal "Choose an authored construction.", outcome.dig("findings", 0, "message")
    assert @runtime.stopped
    assert_empty Dir.children(@directory)
    assert_empty @session.model.operations
  end

  def test_a_blocked_run_with_partial_canonical_output_never_returns_bytes_in_status
    task = start
    drain
    @runtime.blocked(:canonical => { "hbjson" => JSON.generate("type" => "Model", "rooms" => []),
                                     "rooms" => 1, "faces" => 6, "surface_pairs" => 0 })
    outcome = @tasks.status(task.fetch("task_id")).fetch("outcome")
    refute outcome.dig("value", "result", "canonical_model").key?("hbjson")
    assert_equal 1, outcome.dig("value", "result", "canonical_model", "rooms")
    assert_equal outcome, @tasks.latest.fetch("outcome")
    assert_equal 1, outcome.fetch("findings").length
    assert_empty Dir.children(@directory)
  end

  def test_runtime_close_finishes_and_model_close_cancels_and_tears_down
    task = start
    drain
    @runtime.close
    assert_equal "runtime.closed", @tasks.status(task.fetch("task_id")).dig("outcome", "code")
    assert @runtime.stopped

    start
    drain
    @session.model.close
    UI.run_timer(UI.timer_intervals.find { |_id, interval| interval == 0.2 }.first)
    drain
    assert @runtime.stopped
    assert_nil @tasks.latest
    assert_empty Dir.children(@directory)
  end

  # Half a prior pair is refused whatever the consent; a whole one needs consent to replace it.
  def test_destination_replacement_and_one_active_task_are_explicit
    File.write(@destination, "prior")
    assert_equal "export.refused", assert_raises(PhComposer::CodedError) { start(:replace => true) }.code
    File.write(PhComposer::Export::ArtifactPair.report_path(@destination), "prior report")
    error = assert_raises(PhComposer::CodedError) { start }
    assert_equal "export.replace_required", error.code
    assert_equal "prior", File.read(@destination)
    File.delete(@destination)
    File.delete(PhComposer::Export::ArtifactPair.report_path(@destination))
    start
    error = assert_raises(PhComposer::CodedError) { start }
    assert_equal "export.busy", error.code
  end

  def test_cancel_between_translation_and_commit_discards_the_result
    task = start
    drain
    @runtime.success
    assert_equal "checking", @tasks.status(task.fetch("task_id")).fetch("stage")
    @tasks.cancel(task.fetch("task_id"))
    drain

    assert_empty Dir.children(@directory)
    assert @runtime.stopped
  end

  def test_success_commits_one_pair_and_polling_does_not_write_or_change_the_model
    task = start
    drain
    @runtime.success
    drain
    result = @tasks.status(task.fetch("task_id"))
    contents = Dir.children(@directory).sort.to_h { |name| [name, File.binread(File.join(@directory, name))] }

    assert_equal %w[completed export.complete none], result.fetch("outcome").values_at("status", "code", "effect")
    assert_equal ["test-export-report.html", "test.hbjson"], contents.keys
    assert_equal result, @tasks.status(task.fetch("task_id"))
    assert_equal result, @tasks.latest
    refute result.dig("outcome", "value", "result", "canonical_model").key?("hbjson")
    assert_equal 0, result.dig("outcome", "value", "result", "canonical_model", "rooms")
    after = Dir.children(@directory).sort.to_h { |name| [name, File.binread(File.join(@directory, name))] }
    assert_equal contents, after
    assert_empty @session.model.operations
    refute @session.model.modified?
    assert @runtime.stopped
  end

  def test_content_and_destination_changes_after_translation_prevent_commit
    task = start
    drain
    @runtime.success
    File.write(@destination, "another writer")
    drain

    assert_equal "export.destination_changed", @tasks.status(task.fetch("task_id")).dig("outcome", "code")
    assert_equal "another writer", File.read(@destination)
    refute File.exist?(PhComposer::Export::ArtifactPair.report_path(@destination))
  end

  def test_public_tasks_require_export_access_and_old_or_cross_model_handles_expire
    api = PhComposer::API
    read = api.connect(:session_id => @session.id, :capabilities => ["read", "model_write"])
    location = { "id" => approved_destination }
    refused = api.start_export(:context => read, :location => location)
    assert_equal "request.capability_denied", refused.fetch("code")
    context = api.connect(:session_id => @session.id, :capabilities => ["export"])
    assert_raises(ArgumentError) { api.start_export(:context => context, :destination => @destination) }
    started = api.start_export(:context => context, :location => location)
    id = started.dig("value", "task_id")
    assert_equal "completed", started.fetch("status")
    assert_equal started.fetch("value"), api.export_status(:context => context, :task_id => id).fetch("value")
    cancelled = api.cancel_export(:context => context, :task_id => id)
    assert_equal "cancelled", cancelled.dig("value", "outcome", "status")

    other = PhComposer::Sessions.for(Sketchup::Model.new)
    second = api.connect(:session_id => other.id, :capabilities => ["export"])
    assert_equal "task.expired", api.export_status(:context => second, :task_id => id).fetch("code")
    assert_equal "request.capability_denied", api.export_status(:context => read, :task_id => id).fetch("code")
    assert_empty Dir.children(@directory)
  end

  # The export task methods describe themselves, and a client built only from those descriptions
  # preflights, starts, polls, cancels and reads the latest task with the panel closed.
  def test_a_client_built_from_the_task_descriptions_runs_the_export_methods
    api = PhComposer::API
    context = api.connect(:session_id => @session.id, :capabilities => %w[read export])
    names = api.discover.dig("tasks", "export").values_at("preflight", "start", "status", "cancel", "latest")
    call = lambda do |name, params|
      description = api.describe(:name => name)
      assert_empty PhComposer::JsonSchema.validate(params, description.fetch("params")), name
      outcome = api.public_send(name.to_sym, :context => context, **params.transform_keys(&:to_sym))
      if outcome.fetch("status") == "completed"
        assert_empty PhComposer::JsonSchema.validate(outcome.fetch("value"), description.fetch("result")), name
      end
      outcome
    end

    assert_equal %w[task task task task task], names.map { |name| api.describe(:name => name).fetch("kind") }
    assert_equal "completed", call.call(names[0], {}).fetch("status")
    location = { "id" => approved_destination }
    started = call.call(names[1], "location" => location)
    id = started.dig("value", "task_id")
    call.call(names[2], "task_id" => id)
    cancelled = call.call(names[3], "task_id" => id)
    latest = call.call(names[4], {})

    assert_equal "cancelled", cancelled.dig("value", "outcome", "status")
    assert_equal id, latest.dig("value", "task_id")
    refute_includes JSON.generate(latest.fetch("value")), "hbjson"
    File.write(@destination, "{}")
    File.write(PhComposer::Export::ArtifactPair.report_path(@destination), "<html></html>")
    assert_equal "export.replace_required", call.call(names[1], "location" => location).fetch("code")
    refute PhComposer::JsonSchema.validate({ "destination" => @destination }, api.describe(:name => names[1])
                                                                                 .fetch("params")).empty?
  end

  # Replacing the pair at an approved destination is consent to the state export_preflight reported;
  # a pair that changed since is refused, and the completed outcome names the location, never a path.
  def test_replacing_an_approved_pair_is_bound_to_the_reviewed_state
    api = PhComposer::API
    context = api.connect(:session_id => @session.id, :capabilities => %w[read export])
    id = approved_destination
    File.write(@destination, "{}")
    File.write(PhComposer::Export::ArtifactPair.report_path(@destination), "<html></html>")
    reviewed = api.export_preflight(:context => context, :location => id).dig("value", "destination")
    assert_equal true, reviewed.fetch("exists")
    stale = { "id" => id, "replace" => true, "expected_destination" => "0" * 64 }
    assert_equal "export.destination_changed", api.start_export(:context => context, :location => stale)["code"]
    no_state = api.start_export(:context => context, :location => { "id" => id, "replace" => true })
    assert_equal "export.replace_required", no_state["code"]
    consented = { "id" => id, "replace" => true, "expected_destination" => reviewed.fetch("state") }
    # What start_export runs, with this test's runtime in place of the translation runtime.
    task = @tasks.start(:location => consented, :runtime_factory => @factory)
    drain
    @runtime.success
    drain
    value = @tasks.status(task.fetch("task_id")).dig("outcome", "value")
    assert_equal({ "id" => id, "label" => "Export destination 1" }, value.fetch("location"))
    refute_includes JSON.generate(value), @directory
    refute_equal "{}", File.read(@destination)
  end

  def test_task_retention_is_bounded_and_old_handles_never_restart_a_write
    ids = 21.times.map do
      task = start
      @tasks.cancel(task.fetch("task_id"))
      task.fetch("task_id")
    end
    error = assert_raises(PhComposer::CodedError) { @tasks.status(ids.first) }
    assert_equal "task.expired", error.code
    assert_equal ids.last, @tasks.latest.fetch("task_id")
    assert_empty Dir.children(@directory)
  end

  def test_terminal_task_expires_after_the_documented_retention_without_repeating_work
    task = start
    id = task.fetch("task_id")
    @tasks.cancel(id)
    now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    Process.stub(:clock_gettime, ->(*) { now + PhComposer::Export::Tasks::RETENTION_SECONDS + 1 }) do
      assert_nil @tasks.latest
      error = assert_raises(PhComposer::CodedError) { @tasks.status(id) }
      assert_equal "task.expired", error.code
    end
    assert_empty Dir.children(@directory)
    assert_nil @runtime
  end

  private

  def drain
    100.times do
      timer = UI.instance_variable_get(:@timers).find { |id, _repeat, _block| UI.timer_intervals[id].zero? }
      return unless timer

      UI.run_timer(timer.first)
    end
    flunk "Collection did not settle within 100 timer slices"
  end

  def start(replace: false)
    approval = PhComposer::NativeApproval::Granted.new(:path => @destination, :replace => replace)
    @tasks.start(:approval => approval, :runtime_factory => @factory)
  end

  def approved_destination
    PhComposer::ApprovedLocations.approve(:kind => "save_file", :path => @destination).fetch("id")
  end
end
