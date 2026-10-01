# frozen_string_literal: true

require_relative "test_helper"
require_relative "../src/ph_composer/library/callback_invoker"

class LibraryCallbackInvokerTest < PhComposerTestCase
  OWNER = PhComposer::Assemblies::FEATURE_ID
  KIND = PhComposer::Assemblies::MATERIAL_KIND
  OBJECT = { "type" => "object", "properties" => {}, "additionalProperties" => false }.freeze

  def setup
    super
    @registry = PhComposer::Registry.current
    @engine = PhComposer::Records::Engine.new(Sketchup.active_model, @registry.catalog)
    @proposal = PhComposer::Records::ChangeSet.new
    @request = PhComposer::HandlerRequest.new(:model => Sketchup.active_model, :engine => @engine,
      :registry => @registry, :owner => "ph_composer.library", :proposal => @proposal, :params => {})
    @declaration = PhComposer::Declarations::LibraryKind.new(:owner => OWNER, :record_kind => KIND)
  end

  def invoke(params = {}, result = OBJECT, &handler)
    callback = PhComposer::Declarations::LibraryCallback.new(:params => OBJECT, :result => result, :handler => handler)
    PhComposer::Library::CallbackInvoker.call(@request, @declaration, callback, params)
  end

  def create(request, changes)
    values = PhComposer::Assemblies::Materials::Schema.defaults("name" => "Copied material")
    request.engine.propose_create(KIND, changes, :values => values)
  end

  def test_callbacks_see_the_new_record_in_the_same_projected_proposal
    invoke do |request, changes|
      assert_equal OWNER, request.owner
      id = create(request, changes)
      assert_equal "Copied material", request.engine.find(KIND, id)["name"]
      assert_includes request.engine.ids(KIND), id
      {}
    end
    assert_equal 1, @proposal.writes.length
    assert_empty @engine.ids(KIND)
    assert_nil @proposal.refusal
  end

  def test_invalid_result_poison_is_retained_after_callback_stages_a_copy
    assert_raises(PhComposer::CodedError) do
      invoke { |request, changes| create(request, changes)
 { "unexpected" => true } }
    end
    refute_nil @proposal.refusal
    assert_empty @engine.ids(KIND)
  end

  def test_invalid_input_never_calls_owner_and_poison_is_retained
    called = false
    assert_raises(PhComposer::CodedError) { invoke({ "unexpected" => true }) { called = true
 {} } }
    refute called
    refute_nil @proposal.refusal
  end

  def test_a_rescued_foreign_owner_write_still_refuses_the_proposal
    invoke do |request, changes|
      create(request, changes)
      begin
        request.engine.propose_create("ph_composer.zones.zone", changes, :values => {})
      rescue PhComposer::CodedError
        # The callback cannot recover a partially staged copy into a valid proposal.
      end
      {}
    end
    assert_equal "library.mutation_owner", @proposal.refusal.code
    assert_empty @engine.ids(KIND)
  end

  def test_readonly_callback_sees_projection_but_cannot_stage_a_write
    id = create(@request, @proposal)
    callback = PhComposer::Declarations::LibraryCallback.new(:params => OBJECT, :result => OBJECT,
      :handler => lambda do |request, changes|
        assert_nil changes
        assert_nil request.proposal
        assert_equal "Copied material", request.engine.find(KIND, id)["name"]
        create(request, changes)
        {}
      end)
    error = assert_raises(PhComposer::CodedError) do
      PhComposer::Library::CallbackInvoker.call(@request, @declaration, callback, {}, :readonly => true)
    end
    assert_equal "library.mutation_owner", error.code
    assert_same error, @proposal.refusal
    assert_equal 1, @proposal.writes.length
    assert_empty @engine.ids(KIND)
  end

  def test_plain_callback_failure_poison_is_retained
    assert_raises(RuntimeError) { invoke { |request, changes| create(request, changes)
 raise "assignment failed" } }
    refute_nil @proposal.refusal
    assert_empty @engine.ids(KIND)
  end
end
