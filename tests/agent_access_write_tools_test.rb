# frozen_string_literal: true

require "tmpdir"
require_relative "test_helper"
require_relative "support/test_feature"

# The write tools of the agent connection (context/AGENT_INTERFACE.md, "User-controlled local access"):
# each needs the capability dispatch enforces, `invoke` takes the sequence the connection assigns and an
# optional idempotency key, and a lost reply is recovered by reading state, never by applying twice.
class AgentAccessWriteToolsTest < PhComposerTestCase
  AgentAccess = PhComposer::AgentAccess
  CREATE = "test.fixture.create"
  PARTS = { "parts" => [{ "label" => "Sill", "length_mm" => 1200.0 }] }.freeze

  def setup
    super
    PhComposer::Registry.install([TestFeature])
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @executor = AgentAccess::Executor.new(:tools => AgentAccess::Tools::TABLE)
    @writer = token(%w[read view model_write setup export])
  end

  def token(capabilities)
    issued = AgentAccess::Tokens.issue(:capabilities => capabilities)
    AgentAccess::Tokens.snapshot.fetch(AgentAccess::Tokens.digest(issued.fetch("token")))
  end

  def call(name, arguments = {}, row = @writer)
    result = @executor.call(row, name, { "session" => @session.id }.merge(arguments))
    refute result["isError"], result.inspect
    result.fetch("structuredContent")
  end

  def invoke(arguments = {})
    call("invoke", { "name" => CREATE, "params" => PARTS, "expected_revision" => @session.revision }.merge(arguments))
  end

  def test_each_tool_needs_its_capability_and_tools_list_shows_only_those_held
    reader = token(%w[read])
    listed = ->(row) { AgentAccess::MCP.tools_for(row).map { |tool| tool.fetch("name") } }

    assert_equal %w[discover describe query preview context export_preflight], listed.call(reader)
    assert_equal AgentAccess::Tools::TABLE.keys, listed.call(@writer)
    assert @executor.call(reader, "invoke", "session" => @session.id)["isError"]
    assert_equal({ "invoke" => "model_write", "outcome" => "model_write", "view" => "view", "setup" => "setup",
                   "export_file" => "export", "start_export" => "export", "latest_export" => "export" },
                 AgentAccess::Tools::TABLE.slice(*%w[invoke outcome view setup export_file start_export
                                                     latest_export]).transform_values(&:capability))
  end

  def test_invoke_assigns_the_next_sequence_and_every_result_carries_it
    first = invoke
    second = invoke

    assert_equal [1, 2], [first, second].map { |outcome| outcome["sequence"] }
    assert_equal %w[committed committed], [first, second].map { |outcome| outcome["effect"] }
    assert_equal [], PhComposer::JsonSchema.validate(first, PhComposer::Outcome::SCHEMA)
  end

  def test_a_repeated_key_replays_its_first_outcome_and_another_request_under_it_conflicts
    before = @model.operations.length
    first = invoke("idempotency_key" => "add-sill")
    again = invoke("idempotency_key" => "add-sill", "expected_revision" => first["revision"] - 1)
    other = invoke("idempotency_key" => "add-sill", "params" => { "parts" => [] })

    assert_equal 1, @model.operations.length - before, "applied once"
    assert_equal first.fetch("value"), again.fetch("value")
    assert_equal [1, 1, 1], [first, again, other].map { |outcome| outcome["sequence"] }
    assert_equal "request.sequence_conflict", other["code"]
    assert_equal 2, invoke["sequence"]
  end

  def test_a_lost_invoke_reply_is_read_back_by_key_or_sequence_and_an_expired_one_is_unavailable
    sent = invoke("idempotency_key" => "add-sill")

    by_key = call("outcome", "idempotency_key" => "add-sill")
    by_sequence = call("outcome", "sequence" => sent["sequence"])
    unknown = call("outcome", "idempotency_key" => "never-sent")
    @session.outcomes.clock = -> { Float::INFINITY }
    expired = call("outcome", "idempotency_key" => "add-sill")
    resent = invoke("idempotency_key" => "add-sill")

    assert_equal [sent.fetch("value")] * 2, [by_key, by_sequence].map { |outcome| outcome["value"] }
    assert_equal [1, 1], [by_key, by_sequence].map { |outcome| outcome["sequence"] }
    assert_equal %w[request.outcome_unavailable] * 3, [unknown, expired, resent].map { |outcome| outcome["code"] }
    assert_equal 1, resent["sequence"], "an expired key is never given a new sequence"
  end

  def test_view_and_setup_run_their_commands_and_a_lost_setup_reply_is_read_back_from_its_state
    Dir.mktmpdir("phc-agent-") do |directory|
      path = File.join(directory, "tags.json")
      File.write(path, "{}")
      PhComposer::Library::Setup.add_file(:id => "synthetic.file", :label => "Synthetic", :path => path)
      looked = call("view", "name" => "test.fixture.look", "params" => { "count" => 1 })
      removed = call("setup", "name" => "ph_composer.library.providers.remove",
                              "params" => { "provider_id" => "synthetic.file" })
      providers = call("query", "name" => "ph_composer.library.providers", "params" => {})

      assert_equal %w[completed completed], [looked, removed].map { |outcome| outcome["status"] }
      refute_includes JSON.generate(providers.fetch("value")), "synthetic.file"
    end
  end

  def test_a_lost_start_export_reply_is_found_with_latest_export
    Dir.mktmpdir("phc-agent-") do |directory|
      PhComposer::ApprovedLocations.approve(:kind => "save_file", :path => File.join(directory, "model.hbjson"))
      location = call("query", "name" => "ph_composer.locations.list", "params" => {})
                 .dig("value", "locations").find { |row| row["kind"] == "save_file" }
      started = call("start_export", "location" => { "id" => location.fetch("id") })
      latest = call("latest_export")
      status = call("export_status", "task_id" => started.dig("value", "task_id"))
      cancelled = call("cancel_export", "task_id" => started.dig("value", "task_id"))

      assert_equal started.dig("value", "task_id"), latest.dig("value", "task_id")
      assert_equal %w[completed completed], [status, cancelled].map { |outcome| outcome["status"] }
    end
  end
end
