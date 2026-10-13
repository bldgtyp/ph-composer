# frozen_string_literal: true

require_relative "test_helper"

# `request.participate` (shell/participant_invocation.rb) between two synthetic features: a provider
# that declares participants over its own record kind, and a consumer that requires it and calls them
# from one action. Each test drives the consumer action through the public API, so the dispatcher's
# transaction, refusal and Undo handling are the real ones.
class ParticipantInvocationTest < PhComposerTestCase
  API = PhComposer::API
  OBJECT = { "type" => "object" }.freeze
  ITEM = "probe.provider.item"
  NOTE = "probe.consumer.note"
  ADD = "probe.provider.add"
  ACTION = "probe.consumer.apply"
  LABEL = { "type" => "object", "additionalProperties" => false, "required" => ["label"],
            "properties" => { "label" => { "type" => "string", "minLength" => 1 } } }.freeze
  ADDED = { "type" => "object", "additionalProperties" => false, "required" => %w[id nested],
            "properties" => { "id" => { "type" => "string" }, "nested" => { "type" => "object" } } }.freeze

  # A step that writes nothing, so a test can check a participant cannot remove one.
  class MarkStep
    def descriptor
      { "name" => "mark" }
    end

    def affected
      []
    end

    def apply(_model, _slots); end
  end

  def kind(id, prefix)
    PhComposer::Records::RecordKind.new(
      :id => id, :label => id, :schema_version => 1, :id_prefix => prefix,
      :fields => [PhComposer::Records::Field.new(:key => "label", :schema => { "type" => "string" }, :required => true)]
    )
  end

  # `behaviour` is what the provider's participant does after the foundation's checks; the default
  # stages one item and answers its id.
  def provider(&behaviour)
    test = self
    behaviour ||= ->(request, proposal) { test.add_item(request, proposal) }
    Module.new do
      define_singleton_method(:name) { "Provider" }
      define_singleton_method(:install) do |registry|
        feature = registry.feature("probe.provider", :contract_version => 1)
        feature.record_kind(test.kind(ITEM, "pri"))
        feature.proposal_participant(ADD, :description => "Stage one item.", :params => LABEL, :result => ADDED,
                                          :refuses => ["validation.failed"], :examples => [{ "label" => "One" }],
                                     &behaviour)
      end
    end
  end

  # The consumer's action runs `body` with the request and proposal; by default it calls the participant
  # once with `params["label"]`.
  def consumer(participants: [ADD], refuses: [], &body)
    test = self
    body ||= ->(request, _proposal) { request.participate(ADD, "label" => request.params.fetch("label")) }
    Module.new do
      define_singleton_method(:name) { "Consumer" }
      define_singleton_method(:install) do |registry|
        feature = registry.feature("probe.consumer", :contract_version => 1, :requires => ["probe.provider"])
        feature.record_kind(test.kind(NOTE, "prn"))
        feature.action(ACTION, :description => "Call the provider.", :params => OBJECT, :result => OBJECT,
                               :refuses => refuses, :participants => participants, :undo_name => "Apply",
                               :side_effects => "Test only.", :examples => [{}]) do |request, proposal|
          value = body.call(request, proposal)
          value.is_a?(Hash) ? value.reject { |key, _| key == "nested" } : {}
        end
        feature.query("probe.consumer.read", :description => "Call the provider without a proposal.",
                                             :params => OBJECT, :result => OBJECT, :refuses => [],
                                             :participants => [ADD]) do |request|
          request.participate(ADD, "label" => "x")
        end
      end
    end
  end

  def add_item(request, proposal)
    id = request.engine.propose_create(ITEM, proposal, :values => { "label" => request.params.fetch("label") })
    { "id" => id, "nested" => { "rows" => [1] } }
  end

  def install(provider_module = provider, consumer_module = consumer)
    PhComposer::Registry.install([provider_module, consumer_module])
    @session = PhComposer::Sessions.for(Sketchup.active_model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
  end

  def invoke(params = { "label" => "One" })
    @sequence += 1
    API.invoke(:context => @context, :name => ACTION, :params => params,
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end

  def items
    PhComposer::Records::Engine.new(Sketchup.active_model, PhComposer::Registry.current.catalog).ids(ITEM)
  end

  def expect_refused(result, code)
    assert_equal code, result["code"], result.inspect
    assert_equal "none", result["effect"]
    assert_empty items
  end

  def test_a_declared_participant_stages_its_owners_write_and_the_caller_reads_it_back
    seen = nil
    install(provider, consumer do |request, proposal|
      value = request.participate(ADD, "label" => "One")
      seen = proposal.find(ITEM, value.fetch("id"))&.after&.fetch("label")
      value
    end)
    result = invoke
    assert_equal "committed", result["effect"], result.inspect
    assert_equal "One", seen
    assert_equal 1, items.length
  end

  def test_a_query_has_no_proposal_for_a_participant
    install
    result = API.query(:context => @context, :name => "probe.consumer.read")
    assert_equal "operation.proposal_required", result["code"], result.inspect
  end

  def test_invalid_params_never_reach_the_handler_and_refuse_the_proposal
    called = false
    install(provider { |_request, _proposal| called = true })
    expect_refused(invoke("label" => ""), "params.invalid")
    refute called
  end

  def test_a_result_outside_the_schema_fails_and_writes_nothing
    test = self
    install(provider { |request, proposal| test.add_item(request, proposal).merge("extra" => true) })
    result = invoke
    assert_equal "failed", result["status"], result.inspect
    assert_equal "none", result["effect"]
    assert_empty items
  end

  def test_a_rescued_failure_after_a_staged_write_still_refuses_and_a_later_success_does_not_clear_it
    test = self
    install(provider do |request, proposal|
      test.add_item(request, proposal)
      raise PhComposer::CodedError.new("validation.failed", "Synthetic refusal.") if request.params["label"] == "bad"

      { "id" => "none", "nested" => {} }
    end, consumer do |request, _proposal|
      begin
        request.participate(ADD, "label" => "bad")
      rescue PhComposer::CodedError
        # The caller recovers; the proposal does not.
      end
      request.participate(ADD, "label" => "good")
    end)
    expect_refused(invoke, "validation.failed")
  end

  def test_a_participant_cannot_write_a_kind_its_owner_does_not_own
    install(provider do |request, proposal|
      request.engine.propose_create(NOTE, proposal, :values => { "label" => "stray" })
      { "id" => "none", "nested" => {} }
    end)
    expect_refused(invoke, "proposal.foreign_write")
  end

  def test_a_participant_cannot_remove_an_earlier_step_or_write
    { "step" => ->(proposal) { proposal.steps.pop }, "write" => ->(proposal) { proposal.writes.pop } }
      .each do |label, remove|
      PhComposer::Registry.reset
      install(provider do |_request, proposal|
        remove.call(proposal)
        { "id" => "none", "nested" => {} }
      end, consumer do |request, proposal|
        proposal.add_step(MarkStep.new, :scopes => [])
        request.engine.propose_create(NOTE, proposal, :values => { "label" => "mine" })
        request.participate(ADD, "label" => "One")
      end)
      result = invoke
      assert_equal "proposal.contribution_replaced", result["code"], "#{label}: #{result.inspect}"
    end
  end

  def test_a_caller_editing_the_result_does_not_change_the_next_callers
    answers = []
    install(provider { |_request, _proposal| { "id" => "fixed", "nested" => { "rows" => [1] } } },
            consumer do |request, _proposal|
              2.times do
                value = request.participate(ADD, "label" => "One")
                answers << value.dig("nested", "rows").dup
                value.fetch("nested").fetch("rows") << 2
              end
              {}
            end)
    invoke
    assert_equal [[1], [1]], answers
  end

  def test_an_action_that_does_not_name_the_participant_is_refused
    install(provider, consumer(:participants => [], :refuses => ["operation.participant_missing"]))
    expect_refused(invoke, "operation.participant_missing")
  end

  def test_participants_that_name_each_other_in_a_cycle_are_refused_at_registration
    cyclic = Module.new do
      define_singleton_method(:name) { "Cyclic" }
      define_singleton_method(:install) do |registry|
        feature = registry.feature("probe.cyclic", :contract_version => 1)
        %w[a b].each do |name|
          other = name == "a" ? "b" : "a"
          feature.proposal_participant("probe.cyclic.#{name}", :description => "Cycle.", :params => OBJECT,
                                                               :result => OBJECT, :refuses => [],
                                                               :participants => ["probe.cyclic.#{other}"]) { {} }
        end
      end
    end
    error = assert_raises(PhComposer::RegistrationError) { PhComposer::Registry.install([cyclic]) }
    assert_includes error.diagnostics.map(&:code), "registration.cycle"
  end

  def test_a_projection_derives_only_for_the_change_set_it_reads_through
    engine = PhComposer::Records::Engine.new(Sketchup.active_model, PhComposer::Registry.current.catalog)
    proposal = PhComposer::Operations::Proposal.new
    projected = engine.projected(proposal, :writable_kinds => [], :refusal_code => "proposal.foreign_write")
    nested = projected.projected(proposal, :writable_kinds => [ITEM], :refusal_code => "proposal.foreign_write")
    assert_kind_of PhComposer::Records::ProjectedEngine, nested
    assert_raises(PhComposer::InternalError) do
      projected.projected(PhComposer::Operations::Proposal.new, :writable_kinds => [],
                                                                :refusal_code => "proposal.foreign_write")
    end
  end
end
