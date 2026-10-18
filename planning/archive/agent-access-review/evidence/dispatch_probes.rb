# frozen_string_literal: true

require_relative '../../../../tests/test_helper'
require_relative '../../../../tests/support/test_feature'

class DispatchReviewProbes < PhComposerTestCase
  API = PhComposer::API

  def setup
    super
    PhComposer::Registry.install([TestFeature])
    @session = PhComposer::Sessions.for(Sketchup.active_model)
    @context = API.connect(session_id: @session.id)
  end

  def teardown
    TestFeature.reentry = nil
    super
  end

  def test_capability_input_alias_changes_the_grant_after_connect
    capability = String.new('read')
    context = API.connect(session_id: @session.id, capabilities: [capability])
    capability.replace('model_write')
    result = API.invoke(context: context, name: 'test.fixture.create',
                        params: { 'parts' => [{ 'label' => 'probe', 'length_mm' => 1200.0 }] },
                        request: { 'sequence' => 1, 'expected_revision' => 1 })
    puts "CAPABILITY_ALIAS #{result.values_at('status', 'code', 'effect').inspect}"
    assert_equal 'request.capability_denied', result.fetch('code')
  end

  def test_context_session_id_is_aliased_to_session_authority
    previous = @session.id.dup
    @context.session_id.replace('caller-edited-id')
    puts "SESSION_ID_ALIAS old=#{previous} current=#{@session.id}"
    assert_equal previous, @session.id
  end

  def test_different_pending_payload_refuses_sequence_conflict
    TestFeature.reentry = { context: @context, name: 'test.fixture.reenter', params: { 'different' => true },
                            request: { 'sequence' => 1, 'expected_revision' => 1 } }
    result = API.invoke(context: @context, name: 'test.fixture.reenter', params: {},
                        request: { 'sequence' => 1, 'expected_revision' => 1 })
    puts "PENDING_CHANGED_PAYLOAD #{result.dig('value', 'inner').values_at('status', 'code').inspect}"
    assert_equal 'request.sequence_conflict', result.dig('value', 'inner', 'code')
  end

  def test_worker_thread_is_not_guarded_at_dispatch
    result = Thread.new do
      API.invoke(context: @context, name: 'test.fixture.create',
                 params: { 'parts' => [{ 'label' => 'probe', 'length_mm' => 1200.0 }] },
                 request: { 'sequence' => 1, 'expected_revision' => 1 })
    end.value
    puts "WORKER_THREAD #{result.values_at('status', 'code', 'effect').inspect}"
    assert_equal 'completed', result.fetch('status')
  end
end
