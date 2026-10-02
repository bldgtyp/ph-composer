# frozen_string_literal: true

require_relative "test_helper"

class ProposalTest < PhComposerTestCase
  class FailingStore < PhComposer::Records::DictionaryStore
    def write(model, record)
      super
      raise IOError, "injected record failure"
    end
  end

  KIND = PhComposer::Records::RecordKind.new(
    :id => "test.geometry.record", :label => "Test record", :schema_version => 1,
    :id_prefix => "tgr", :fields => [], :store => FailingStore.new("test.geometry.record")
  )

  class SuccessfulGeometryStep
    attr_reader :affected

    def initialize
      @affected = [{ "kind" => "test_geometry", "id" => "one", "change" => "grouped" }]
    end

    def descriptor
      { "name" => "successful_geometry" }
    end

    def apply(model, _slots)
      model.entities.add_group(model.entities.to_a)
    end
  end

  class FailingGeometryStep
    attr_reader :affected

    def initialize
      @affected = [{ "kind" => "test_geometry", "id" => "one", "change" => "grouped" }]
    end

    def descriptor
      { "name" => "failing_geometry" }
    end

    def apply(model, _slots)
      model.entities.add_group(model.entities.to_a)
      raise IOError, "injected geometry failure"
    end
  end

  module FailingFeature
    module_function

    def install(registry)
      feature = registry.feature("test.geometry", :contract_version => 1)
      feature.record_kind(KIND)
      feature.action("test.geometry.fail", :description => "Fail after a geometry write.",
                                           :params => { "type" => "object" },
                                           :result => { "type" => "object" },
                                           :undo_name => "Fail geometry",
                                           :side_effects => "Test only.") do |_request, proposal|
        proposal.add_step(FailingGeometryStep.new, :scopes => [PhComposer::Operations::EntityScope.new([])])
        {}
      end
      feature.action("test.geometry.record_fail", :description => "Fail a record write after geometry.",
                                                  :params => { "type" => "object" },
                                                  :result => { "type" => "object" },
                                                  :undo_name => "Fail compound operation",
                                                  :side_effects => "Test only.") do |request, proposal|
        proposal.add_step(SuccessfulGeometryStep.new,
                          :scopes => [PhComposer::Operations::EntityScope.new([])])
        request.engine.propose_create(KIND.id, proposal, :values => {})
        {}
      end
    end
  end

  def setup
    super
    PhComposer::Registry.install([FailingFeature])
    @model = Sketchup.active_model
    @model.entities << Sketchup::Face.new(1)
    @session = PhComposer::Sessions.for(@model)
    @context = PhComposer::API.connect(:session_id => @session.id)
  end

  def test_geometry_failure_aborts_and_verifies_the_declared_scope
    outcome = invoke

    assert_equal %w[failed operation.failed rolled_back], outcome.values_at("status", "code", "effect")
    assert_equal [Sketchup::Face], @model.entities.to_a.map(&:class)
  end

  def test_unverifiable_geometry_abort_reports_unknown
    @model.define_singleton_method(:abort_operation) { true }

    outcome = invoke

    assert_equal %w[failed operation.rollback_unverified unknown], outcome.values_at("status", "code", "effect")
  end

  def test_a_domain_failure_reason_does_not_overstate_unverified_rollback
    reason = PhComposer::CodedError.new("reference.in_use", "A Face is still referenced.", "id" => "fac_held")

    outcome = PhComposer::Outcome.failed(:effect => "unknown", :revision => 1, :reason => reason)

    assert_equal %w[failed operation.rollback_unverified unknown], outcome.values_at("status", "code", "effect")
    assert_equal "reference.in_use", outcome.dig("detail", "cause")
    assert_equal "fac_held", outcome.dig("detail", "detail", "id")
    assert_includes outcome.fetch("message"), reason.message
    assert_includes outcome.fetch("message"), PhComposer::Outcome::UNVERIFIED
    refute_includes outcome.fetch("message"), "No changes were retained."
  end

  def test_record_failure_rolls_back_the_preceding_geometry_and_record_write
    outcome = invoke_compound(2)

    assert_equal %w[failed operation.failed rolled_back], outcome.values_at("status", "code", "effect")
    assert_equal [Sketchup::Face], @model.entities.to_a.map(&:class)
    assert_empty KIND.store.ids(@model)
  end

  def test_unverifiable_compound_abort_reports_unknown
    @model.define_singleton_method(:abort_operation) { true }

    outcome = invoke_compound(3)

    assert_equal %w[failed operation.rollback_unverified unknown], outcome.values_at("status", "code", "effect")
    assert_instance_of Sketchup::Group, @model.entities.to_a.first
    refute_empty KIND.store.ids(@model)
  end

  private

  def invoke
    PhComposer::API.invoke(
      :context => @context, :name => "test.geometry.fail", :params => {},
      :request => { "sequence" => 1, "expected_revision" => @session.revision }
    )
  end

  def invoke_compound(sequence)
    PhComposer::API.invoke(
      :context => @context, :name => "test.geometry.record_fail", :params => {},
      :request => { "sequence" => sequence, "expected_revision" => @session.revision }
    )
  end
end
