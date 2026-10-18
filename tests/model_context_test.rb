# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/test_feature"

# What a caller can learn before it acts (context/AGENT_INTERFACE.md, "Model context"): the capability
# each operation needs, as dispatch enforces it; the declared terms describe publishes; the envelope
# schemas; and the context read of one Model session.
class ModelContextTest < PhComposerTestCase
  API = PhComposer::API
  READ = PhComposer::ContextCommands::READ

  def setup
    super
    PhComposer::Registry.install([TestFeature])
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
  end

  # ------------------------------------------------------------------ capabilities

  def test_every_operation_is_refused_without_the_capability_it_describes_and_admitted_with_it
    registry = PhComposer::Registry.current
    calls = { "query" => [registry.queries, ->(c, n) { API.query(:context => c, :name => n, :params => {}) }],
              "view_command" => [registry.view_commands,
                                 ->(c, n) { API.view(:context => c, :name => n, :params => {}) }],
              "setup_command" => [registry.setup_commands,
                                  ->(c, n) { API.setup(:context => c, :name => n, :params => {}) }],
              "file_export" => [registry.file_exports,
                                ->(c, n) { API.export_file(:context => c, :name => n, :params => {}) }],
              "action" => [registry.actions, lambda do |c, n|
                API.invoke(:context => c, :name => n, :params => {}, :request => { "sequence" => 1,
                                                                                   "expected_revision" => 1 })
              end] }

    wrong = calls.flat_map do |kind, (declarations, call)|
      declarations.keys.flat_map do |name|
        needed = API.describe(:name => name).fetch("capability")
        without = API.connect(:session_id => @session.id, :capabilities => %w[read view model_write setup export] -
                                                                           [needed] | ["read"])
        with = API.connect(:session_id => @session.id, :capabilities => [needed, "read"].uniq)
        denied = needed != "read" && call.call(without, name)["code"] != "request.capability_denied"
        admitted = call.call(with, name)["code"] == "request.capability_denied"
        [("#{kind} #{name} ran without #{needed}" if denied), ("#{kind} #{name} refused with #{needed}" if admitted)]
      end
    end.compact

    assert_empty wrong
  end

  def test_an_action_describes_its_preview_capability_and_preview_needs_only_read
    reader = API.connect(:session_id => @session.id, :capabilities => %w[read])
    described = API.describe(:name => "test.fixture.create")

    assert_equal %w[model_write read], described.values_at("capability", "preview_capability")
    refute_equal "request.capability_denied",
                 API.preview(:context => reader, :name => "test.fixture.create", :params => {})["code"]
  end

  # ------------------------------------------------------------------ declared terms

  def test_side_effects_preconditions_and_response_are_published_and_checked_at_registration
    unbounded = API.describe(:name => "ph_composer.zones.all")

    assert_equal({ "bounded" => false, "prefer" => "ph_composer.zones.list" }, unbounded.fetch("response"))
    refute API.describe(:name => "ph_composer.zones.list").key?("response")
    [{ :side_effects => "" }, { :preconditions => ["ok", " "] }].each do |terms|
      assert_raises(PhComposer::RegistrationError) { install_view("bad.view", **terms) }
    end
    [{ "bounded" => false, "prefer" => "x" }, { "bounded" => false, :prefer => "ph_composer.zones.list" },
     { "bounded" => false, "prefer" => "ph_composer.zones.all" }].each do |response|
      assert_raises(PhComposer::RegistrationError) { install_query("bad.query", response) }
    end
  end

  def test_two_reads_cannot_name_each_other_as_the_bounded_one
    feature_module = Module.new
    feature_module.define_singleton_method(:install) do |registry|
      feature = registry.feature("loop.reads", :contract_version => PhComposer::Declarations::CONTRACT_VERSION)
      %w[first second].zip(%w[second first]).each do |name, other|
        response = { "bounded" => false, "prefer" => "loop.reads.#{other}" }
        feature.query("loop.reads.#{name}", :description => "Probe.", :params => { "type" => "object" },
                                            :result => { "type" => "object" }, :refuses => [],
                                            :response => response) { {} }
      end
    end

    assert_raises(PhComposer::RegistrationError) { PhComposer::Registry.install([feature_module]) }
  end

  def test_published_terms_are_owned_copies_of_what_a_contributor_passed
    response = { "bounded" => false, "prefer" => "ph_composer.zones.list" }
    preconditions = [String.new("A Zone is open.")]
    install_query("owned.query", response)
    install_view("owned.view", :preconditions => preconditions)

    response["prefer"] = "nowhere"
    preconditions.first.replace("Changed.")
    preconditions << "Added."

    assert_equal "ph_composer.zones.list", API.describe(:name => "owned.query.all").dig("response", "prefer")
    assert_equal ["A Zone is open."], API.describe(:name => "owned.view.go").fetch("preconditions")
  end

  def test_a_view_commands_side_effects_and_preconditions_reach_describe
    install_view("probe.view", :side_effects => "Leaving a Volume locks it.", :preconditions => ["A Zone is open."])

    described = API.describe(:name => "probe.view.go")

    assert_equal ["Leaving a Volume locks it.", ["A Zone is open."], "view"],
                 described.values_at("side_effects", "preconditions", "capability")
  end

  # ------------------------------------------------------------------ envelope schemas

  def test_outcomes_of_every_status_meet_the_published_schema
    schemas = API.discover.fetch("schemas")
    outcomes = [PhComposer::Outcome.completed(:revision => 1, :value => { "x" => 1 }),
                PhComposer::Outcome.refused("params.invalid", "No.", :revision => 1),
                PhComposer::Outcome.refused("session.busy", "Busy.", :status => "busy", :revision => nil),
                PhComposer::Outcome.refused("request.pending", "Running.", :status => "pending", :revision => 2),
                PhComposer::Outcome.refused("request.cancelled", "Cancelled.", :status => "cancelled", :revision => 2),
                PhComposer::Outcome.failed(:effect => "unknown", :revision => 3)]

    assert_empty(outcomes.flat_map { |outcome| PhComposer::JsonSchema.validate(outcome, schemas.fetch("outcome")) })
    reader = API.connect(:session_id => @session.id, :capabilities => %w[read])
    refusal = API.query(:context => reader, :name => "ph_composer.records.list", :params => { "kind" => 7 })
    assert_equal "params.invalid", refusal["code"]
    assert_empty PhComposer::JsonSchema.validate(refusal, schemas.fetch("outcome"))
    request = schemas.fetch("request")
    assert_empty PhComposer::JsonSchema.validate({ "sequence" => 1, "expected_revision" => 1 }, request)
    assert_empty PhComposer::JsonSchema.validate({ "sequence" => 1, "expected_revision" => 1,
                                                   "proposal_digest" => nil }, request)
    refute_empty PhComposer::JsonSchema.validate({ "sequence" => 0, "expected_revision" => 1 }, request)
  end

  # ------------------------------------------------------------------ the context read

  def test_the_context_names_the_model_by_file_and_path_so_equal_basenames_differ
    @model.path = "/projects/a/house.skp"
    other = Sketchup::Model.new
    other.path = "/projects/b/house.skp"
    second = PhComposer::Sessions.for(other)

    first_read, second_read = [@session, second].map { |session| context(session).dig("value", "session") }

    assert_equal %w[house.skp house.skp], [first_read, second_read].map { |read| read["file_name"] }
    refute_equal first_read["path"], second_read["path"]
    assert_equal [true, false], [first_read, second_read].map { |read| read["active"] }
  end

  def test_the_edit_path_and_selection_read_without_moving_anything
    group = @model.entities.add_group
    face = group.entities.add_face([[0, 0, 0], [1, 0, 0], [1, 1, 0]].map { |xyz| Geom::Point3d.new(*xyz) })
    @model.active_path = [group]
    @model.selection.add(face)

    value = context.fetch("value")

    assert_equal [[group.persistent_id, "Group"]],
                 value["edit_path"].map { |row| row.values_at("persistent_id", "type") }
    assert_equal [face.persistent_id], value.dig("selection", "entities").map { |row| row["persistent_id"] }
    assert_equal [[group], [face]], [@model.active_path, @model.selection.to_a]
    assert_equal({ "busy" => false, "reason" => nil }, value["readiness"].slice("busy", "reason"))
  end

  def test_a_selection_change_advances_the_view_generation_not_the_revision_and_expires_a_page
    faces = Array.new(3) do |index|
      @model.entities.add_face([[index, 0, 0], [index + 1, 0, 0], [index, 1, 0]].map { |xyz| Geom::Point3d.new(*xyz) })
    end
    faces.each { |face| @model.selection.add(face) }
    first = context(@session, "limit" => 2).fetch("value")
    revision = @session.revision

    @session.host_event(:selection_changed)
    later = context(@session, "limit" => 2, "cursor" => first.dig("selection", "next_cursor"))

    assert_equal revision, @session.revision
    assert_equal first.dig("session", "view_generation") + 1, @session.view_generation
    assert_equal "query.cursor_expired", later["code"]
  end

  def test_a_large_selection_pages_within_the_entity_and_byte_bounds
    groups = Array.new(250) do |index|
      @model.entities.add_group.tap { |group| group.name = "Room #{index} #{'x' * 40}" }
    end
    groups.each { |group| @model.selection.add(group) }

    pages = [context(@session, "limit" => 200).fetch("value")]
    while (cursor = pages.last.dig("selection", "next_cursor"))
      pages << context(@session, "limit" => 200, "cursor" => cursor).fetch("value")
    end

    sizes = pages.map { |page| JSON.generate(page.dig("selection", "entities")).bytesize }
    assert_operator sizes.max, :<=, PhComposer::Pages::MAX_PAGE_BYTES
    assert_equal 250, pages.sum { |page| page.dig("selection", "entities").length }
    assert_equal "params.invalid", context(@session, "limit" => 201)["code"]
  end

  def test_an_agent_tool_error_carries_the_published_envelope
    token = PhComposer::AgentAccess::Tokens.issue.fetch("row")
    executor = PhComposer::AgentAccess::Executor.new(:tools => PhComposer::AgentAccess::Tools::TABLE)

    errors = [executor.call(token, "nope", {}), executor.call(token, "discover", { "stray" => 1 })]

    assert(errors.all? { |error| error["isError"] })
    schema = API.discover.dig("schemas", "outcome")
    assert_empty(errors.flat_map { |error| PhComposer::JsonSchema.validate(error["structuredContent"], schema) })
  end

  def test_the_context_answers_while_the_session_is_busy_and_record_reads_do_not
    @session.feature_state(:probe_deferred) { Struct.new(:pending?).new(true) }
    reader = API.connect(:session_id => @session.id, :capabilities => %w[read])

    read = context
    records = API.query(:context => reader, :name => "ph_composer.zones.list", :params => {})

    assert_equal [true, "This Model has deferred work that has not finished."],
                 read.dig("value", "readiness").values_at("busy", "reason")
    assert_equal "session.busy", records["code"]
    assert API.describe(:name => READ).fetch("while_busy")
  end

  private

  def context(session = @session, params = {})
    reader = API.connect(:session_id => session.id, :capabilities => %w[read])
    API.query(:context => reader, :name => READ, :params => params)
  end

  def install_view(id, **terms)
    feature_module = Module.new
    feature_module.define_singleton_method(:install) do |registry|
      feature = registry.feature(id, :contract_version => PhComposer::Declarations::CONTRACT_VERSION)
      feature.view_command("#{id}.go", :description => "Probe.", :params => { "type" => "object" },
                                       :result => { "type" => "object" }, :refuses => [], **terms) { |_request| {} }
    end
    PhComposer::Registry.install([feature_module])
  end

  def install_query(id, response)
    feature_module = Module.new
    feature_module.define_singleton_method(:install) do |registry|
      feature = registry.feature(id, :contract_version => PhComposer::Declarations::CONTRACT_VERSION)
      feature.query("#{id}.all", :description => "Probe.", :params => { "type" => "object" },
                                 :result => { "type" => "object" }, :refuses => [], :response => response) { |_r| {} }
    end
    PhComposer::Registry.install([feature_module])
  end
end
