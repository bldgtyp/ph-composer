# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/test_feature"

class FeatureCompositionTest < PhComposerTestCase
  R = PhComposer::Records
  OBJECT = TestFeature::OBJECT
  KIND = "test.fixture.definition"

  def feature(&install)
    Module.new do
      define_singleton_method(:install) { |registry| install.call(registry) }
      define_singleton_method(:name) { "CompositionProbe" }
    end
  end

  def setup
    super
    PhComposer::Registry.install([TestFeature])
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = PhComposer::API.connect(:session_id => @session.id)
  end

  def read(name, params = {})
    PhComposer::API.query(:context => @context, :name => name, :params => params)
  end

  def test_handler_read_uses_declared_dependency_and_validates_nested_params
    PhComposer::Registry.install([feature do |registry|
      scope = registry.feature("test.consumer", :contract_version => 1, :requires => [TestFeature::ID])
      scope.query("test.consumer.read", :description => "Read dependency.", :params => OBJECT,
                                        :result => OBJECT) { |request| request.query("test.fixture.total_length") }
      scope.query("test.consumer.invalid", :description => "Invalid dependency read.", :params => OBJECT,
                                           :result => OBJECT) { |request| request.query("test.fixture.look") }
    end])
    assert_equal({ "total_length_mm" => 0 }, read("test.consumer.read").fetch("value"))
    assert_equal "operation.query_missing", read("test.consumer.invalid").fetch("code")
    assert_empty @model.operations
  end

  def test_handler_read_refuses_undeclared_dependency_and_recursive_read
    PhComposer::Registry.install([feature do |registry|
      scope = registry.feature("test.stranger", :contract_version => 1)
      scope.query("test.stranger.read", :description => "Read dependency.", :params => OBJECT,
                                        :result => OBJECT) { |request| request.query("test.fixture.total_length") }
      scope.query("test.stranger.cycle", :description => "Recursive read.", :params => OBJECT,
                                         :result => OBJECT) { |request| request.query("test.stranger.cycle") }
    end])
    assert_equal "operation.dependency_missing", read("test.stranger.read").fetch("code")
    assert_equal "operation.query_cycle", read("test.stranger.cycle").fetch("code")
  end

  def test_nested_reference_protects_target_and_duplicate_remaps_actual_references
    reference = R::Reference.new(:key => "layers[].segments[].definition_id", :target_kind => KIND,
                                 :cardinality => "one")
    layers = { "type" => "array", "items" => { "type" => "object", "required" => ["segments"],
      "additionalProperties" => false, "properties" => { "segments" => { "type" => "array", "items" => {
        "type" => "object", "required" => ["definition_id"], "additionalProperties" => false,
        "properties" => { "definition_id" => { "type" => "string" } }
      } } } } }
    kind = R::RecordKind.new(:id => "test.consumer.layered", :label => "Layered", :schema_version => 1,
                            :id_prefix => "lay", :fields => [R::Field.new(:key => "layers", :schema => layers)],
                            :references => [reference])
    PhComposer::Registry.install([feature do |registry|
      scope = registry.feature("test.consumer", :contract_version => 1, :requires => [TestFeature::ID])
      scope.record_kind(kind)
    end])
    engine = R::Engine.new(@model, PhComposer::Registry.current.catalog)
    changes = R::ChangeSet.new
    target = engine.propose_create(KIND, changes, :values => { "label" => "Target" })
    values = { "layers" => [{ "segments" => [{ "definition_id" => target }] }] }
    source = engine.propose_create(kind.id, changes, :values => values)
    engine.apply(changes)
    assert_equal [source], engine.incoming_references(KIND, target).map { |entry| entry.record.fetch("id") }
    error = assert_raises(PhComposer::CodedError) { engine.propose_delete(KIND, target, R::ChangeSet.new) }
    assert_equal "reference.in_use", error.code
    remapped = reference.remap(values, target => "tdf_BBBBBBBBBBBB")
    assert_equal ["tdf_BBBBBBBBBBBB"], reference.ids(remapped)
    assert_equal [target], reference.ids(values)
    invalid = { "layers" => [{ "segments" => [{ "definition_id" => 7 }] }] }
    error = assert_raises(PhComposer::CodedError) {
 engine.propose_create(kind.id, R::ChangeSet.new, :values => invalid) }
    assert_equal "validation.failed", error.code
  end

  def test_entity_reference_dependency_registers_and_reverse_requirement_refuses_cycle
    target = R::ReferenceTarget.new(:id => "test.consumer.entity", :label => "Entity", :records => ->(_model) { [] },
      :validate => ->(_record) { [] }, :references => [R::Reference.new(:key => "definition_id", :target_kind => KIND,
                                                                     :cardinality => "one")])
    PhComposer::Registry.install([feature do |registry|
      registry.feature("test.consumer", :contract_version => 1, :requires => [TestFeature::ID]).reference_target(target)
    end])
    assert PhComposer::Registry.current.reference_targets.key?(target.id)
    PhComposer::Registry.reset
    error = assert_raises(PhComposer::RegistrationError) do
      PhComposer::Registry.install([feature do |registry|
        registry.feature("test.lower", :contract_version => 1, :requires => ["test.upper"])
        registry.feature("test.upper", :contract_version => 1, :requires => ["test.lower"])
      end])
    end
    assert_includes error.diagnostics.map(&:code), "registration.cycle"
  end

  def test_retargeter_joins_delete_proposal
    calls = []
    PhComposer::Registry.install([feature do |registry|
      scope = registry.feature("test.consumer", :contract_version => 1, :requires => [TestFeature::ID])
      scope.reference_retargeter("test.consumer.retarget", :target_kind => KIND) do |request, proposal, from:, to:|
        calls << [request.revision, from, to]
        proposal.add_finding("code" => "test.retarget", "message" => "Planned")
        R::ReferencePlan.new(:entries => [])
      end
      scope.action("test.consumer.delete", :description => "Delete with retargeting.", :params => OBJECT,
        :result => OBJECT, :undo_name => "Delete", :side_effects => "Deletes definitions.") do |request, proposal|
        plan = request.retarget_references(KIND, :from => request.params.fetch("id"), :to => nil)
        request.engine.propose_delete(KIND, request.params.fetch("id"), proposal, :reference_plan => plan)
        {}
      end
    end])
    engine = R::Engine.new(@model, PhComposer::Registry.current.catalog)
    changes = R::ChangeSet.new
    id = engine.propose_create(KIND, changes, :values => { "label" => "Target" })
    engine.apply(changes)
    revision = @session.revision
    outcome = PhComposer::API.invoke(:context => @context, :name => "test.consumer.delete", :params => { "id" => id },
                                     :request => { "sequence" => 1, "expected_revision" => @session.revision })
    assert_equal "completed", outcome.fetch("status")
    assert_equal [[revision, id, nil]], calls
    assert_empty engine.ids(KIND)
  end
  class RetargetStep
    def initialize(entity_id, record)
      @entity_id = entity_id
      @record = record
    end

    def apply(model, _slots)
      entity = model.entities.to_a.find { |item| item.persistent_id == @entity_id }
      entity.set_attribute("ph_composer.test_retarget", "record", JSON.generate(@record))
    end

    def descriptor
      { "entity_id" => @entity_id, "record" => @record }
    end

    def affected
      [{ "kind" => "test.consumer.entity", "id" => @record.fetch("id"), "change" => "updated" }]
    end
  end

  class RemoveReferenceStep < RetargetStep
    def apply(model, _slots)
      entity = model.entities.to_a.find { |item| item.persistent_id == @entity_id }
      entity.delete_attribute("ph_composer.test_retarget", "record")
    end

    def affected
      []
    end
  end

  def removal_plan(proposal, entries, foreign)
    removals = entries.map do |entry|
      proposal.add_step(RemoveReferenceStep.new(entry.key.first, entry.record),
                        :scopes => [PhComposer::Operations::EntityScope.new([])])
      R::ReferenceRemoval.new(:kind => foreign ? "ph_composer.zones.zone" : entry.kind,
        :key => entry.key, :before => entry.record)
    end
    R::ReferencePlan.new(:entries => [], :removals => removals)
  end

  def install_entity_retargeter(refuse: false, foreign: false, remove: false)
    reference = R::Reference.new(:key => "definition_id", :target_kind => KIND, :cardinality => "one")
    target = R::ReferenceTarget.new(:id => "test.consumer.entity", :label => "Entity", :validate => ->(_record) { [] },
      :references => [reference], :records => lambda do |model|
        model.entities.to_a.filter_map do |entity|
          text = entity.get_attribute("ph_composer.test_retarget", "record")
          R::ReferenceEntry.new(:kind => "test.consumer.entity", :key => [entity.persistent_id],
                                :record => JSON.parse(text)) if text
        end
      end)
    PhComposer::Registry.install([feature do |registry|
      scope = registry.feature("test.consumer", :contract_version => 1, :requires => [TestFeature::ID])
      scope.reference_target(target)
      scope.reference_retargeter("test.consumer.retarget", :target_kind => KIND) do |request, proposal, from:, to:|
        entries = target.entries(request.model).select { |entry| entry.record["definition_id"] == from }
        next removal_plan(proposal, entries, foreign) if remove
        final = entries.map do |entry|
          record = entry.record.merge("definition_id" => to)
          proposal.add_step(RetargetStep.new(entry.key.first, record),
                            :scopes => [PhComposer::Operations::EntityScope.new([])])
          R::ReferenceEntry.new(:kind => foreign ? "ph_composer.zones.zone" : entry.kind,
                               :key => entry.key, :record => record)
        end
        raise PhComposer::CodedError.new("target.locked", "Referrer is locked.") if refuse

        R::ReferencePlan.new(:entries => final)
      end
      owner = registry.feature("test.deleting", :contract_version => 1, :requires => [TestFeature::ID])
      owner.action("test.deleting.delete", :description => "Delete definition.", :params => OBJECT,
        :result => OBJECT, :undo_name => "Delete definition",
        :side_effects => "Retarget and delete.") do |request, proposal|
        begin
          plan = request.retarget_references(KIND, :from => request.params.fetch("id"),
                                             :to => request.params["replacement"])
          request.engine.propose_delete(KIND, request.params.fetch("id"), proposal, :reference_plan => plan)
        rescue StandardError
          # A careless caller cannot turn a refused participant into a partial commit.
          nil
        end
        {}
      end
    end])
  end

  def retarget_seed
    engine = R::Engine.new(@model, PhComposer::Registry.current.catalog)
    changes = R::ChangeSet.new
    ids = 2.times.map { |index| engine.propose_create(KIND, changes, :values => { "label" => "Target #{index}" }) }
    engine.apply(changes)
    entity = Sketchup::Group.new(200)
    @model.entities << entity
    record = { "id" => "entity_original", "definition_id" => ids.first }
    entity.set_attribute("ph_composer.test_retarget", "record", JSON.generate(record))
    [engine, ids, entity, record]
  end

  def retarget_invoke(ids)
    PhComposer::API.invoke(:context => @context, :name => "test.deleting.delete",
                          :params => { "id" => ids.first, "replacement" => ids.last },
                          :request => { "sequence" => 1, "expected_revision" => @session.revision })
  end

  def test_owned_removal_composes_with_catalog_delete_and_native_undo
    install_entity_retargeter(:remove => true)
    engine, ids, entity, record = retarget_seed
    result = retarget_invoke(ids)
    assert_equal "completed", result.fetch("status")
    assert_nil entity.get_attribute("ph_composer.test_retarget", "record")
    assert_equal [ids.last], engine.ids(KIND)
    @model.undo
    restored = @model.entities.to_a.find { |item| item.persistent_id == entity.persistent_id }
    assert_equal record, JSON.parse(restored.get_attribute("ph_composer.test_retarget", "record"))
    assert_equal ids.sort, engine.ids(KIND).sort
  end

  def test_foreign_removal_is_refused_before_host_or_catalog_writes
    install_entity_retargeter(:remove => true, :foreign => true)
    engine, ids, entity, record = retarget_seed
    result = retarget_invoke(ids)
    assert_equal "operation.failed", result.fetch("code")
    assert_equal record, JSON.parse(entity.get_attribute("ph_composer.test_retarget", "record"))
    assert_equal ids.sort, engine.ids(KIND).sort
    assert_empty @model.operations
  end

  def test_entity_retarget_and_delete_commit_in_one_operation_without_owner_naming_referrer
    install_entity_retargeter
    engine, ids, entity, = retarget_seed
    before = @model.operations.length
    outcome = retarget_invoke(ids)
    assert_equal "completed", outcome.fetch("status"), outcome.inspect
    assert_equal [ids.last], engine.ids(KIND)
    stored = JSON.parse(entity.get_attribute("ph_composer.test_retarget", "record"))
    assert_equal ids.last, stored.fetch("definition_id")
    assert_equal 1, @model.operations.length - before
  end

  def test_refusing_retargeter_refuses_all_steps_even_when_caller_rescues
    install_entity_retargeter(:refuse => true)
    engine, ids, entity, record = retarget_seed
    before = @model.operations.length
    outcome = retarget_invoke(ids)
    assert_equal "target.locked", outcome.fetch("code")
    assert_equal ids.sort, engine.ids(KIND).sort
    assert_equal record, JSON.parse(entity.get_attribute("ph_composer.test_retarget", "record"))
    assert_equal before, @model.operations.length
  end

  def test_nested_reference_registration_rejects_unreachable_path
    reference = R::Reference.new(:key => "layers[].missing.id", :target_kind => KIND, :cardinality => "one")
    kind = R::RecordKind.new(:id => "test.consumer.bad", :label => "Bad", :schema_version => 1, :id_prefix => "bad",
      :fields => [R::Field.new(:key => "layers", :schema => { "type" => "array", "items" => {
        "type" => "object", "properties" => {} } })], :references => [reference])
    error = assert_raises(PhComposer::RegistrationError) do
      PhComposer::Registry.install([feature do |registry|
        registry.feature("test.consumer", :contract_version => 1, :requires => [TestFeature::ID]).record_kind(kind)
      end])
    end
    assert_includes error.diagnostics.map(&:code), "registration.schema_invalid"
    refute PhComposer::Registry.installed?("test.consumer")
  end

  def test_nested_self_references_duplicate_through_engine_without_remapping_metadata
    reference = R::Reference.new(:key => "links[].peer_id", :target_kind => "test.consumer.linked",
                                 :cardinality => "one")
    kind = R::RecordKind.new(:id => "test.consumer.linked", :label => "Linked", :schema_version => 1,
      :id_prefix => "lnk", :references => [reference], :fields => [R::Field.new(:key => "links", :schema => {
        "type" => "array", "items" => { "type" => "object", "additionalProperties" => false,
          "properties" => { "peer_id" => { "type" => "string" } } } })])
    PhComposer::Registry.install([feature do |registry|
      registry.feature("test.consumer", :contract_version => 1).record_kind(kind)
    end])
    engine = R::Engine.new(@model, PhComposer::Registry.current.catalog)
    a = "lnk_AAAAAAAAAAAA"
    b = "lnk_BBBBBBBBBBBB"
    [a, b].each do |id|
      kind.store.write(@model, "id" => id, "schema_version" => 1, "links" => [{ "peer_id" => a }],
                              "user_data" => { "test.provenance" => { "text" => a } })
    end
    proposal = R::ChangeSet.new
    mapping = engine.propose_duplicate(kind.id, [a, b], proposal)
    engine.apply(proposal)
    mapping.each_value do |id|
      copy = engine.find(kind.id, id)
      assert_equal [mapping.fetch(a)], reference.ids(copy)
      assert_equal a, copy.dig("user_data", "test.provenance", "text")
    end
    assert_equal [a], reference.ids(engine.find(kind.id, b))
  end

  def test_query_from_action_cannot_retarget_through_the_callers_proposal
    PhComposer::Registry.install([feature do |registry|
      scope = registry.feature("test.consumer", :contract_version => 1)
      scope.query("test.consumer.read", :description => "Attempt mutation in read.", :params => OBJECT,
        :result => OBJECT) do |request|
        request.retarget_references(KIND, :from => "tdf_AAAAAAAAAAAA", :to => nil)
        {}
      end
      scope.action("test.consumer.write", :description => "Read from action.", :params => OBJECT,
        :result => OBJECT, :undo_name => "Read", :side_effects => "None.") do |request, _proposal|
        request.query("test.consumer.read")
      end
    end])
    outcome = PhComposer::API.invoke(:context => @context, :name => "test.consumer.write", :params => {},
      :request => { "sequence" => 1, "expected_revision" => @session.revision })
    assert_equal "operation.failed", outcome.fetch("code")
    assert_empty @model.operations
  end

  def test_array_leaf_uses_cardinality_and_cannot_be_declared_as_an_array_step
    field = R::Reference.new(:key => "ids[]", :target_kind => KIND, :cardinality => "one")
    schema = { "type" => "object", "properties" => { "ids" => { "type" => "array",
      "items" => { "type" => "string" } } } }
    refute_empty field.declaration_problems(schema)
    field.key = "ids"
    field.cardinality = "many"
    assert_empty field.declaration_problems(schema)
    assert_equal ["first", "second"], field.ids("ids" => ["first", "second"])
  end

  def test_dependency_read_validates_params_and_result_and_detaches_the_result
    shared = { "items" => ["original"] }
    PhComposer::Registry.install([feature do |registry|
      lower = registry.feature("test.lower", :contract_version => 1)
      schema = { "type" => "object", "properties" => { "count" => { "type" => "integer" } } }
      lower.query("test.lower.read", :description => "Read.", :params => schema, :result => OBJECT) { shared }
      lower.query("test.lower.bad", :description => "Bad result.", :params => OBJECT,
        :result => { "type" => "object", "required" => ["missing"] }) { {} }
      upper = registry.feature("test.upper", :contract_version => 1, :requires => ["test.lower"])
      upper.query("test.upper.read", :description => "Read dependency.", :params => OBJECT,
        :result => OBJECT) do |request|
        result = request.query("test.lower.read", request.params)
        result.fetch("items") << "local"
        result
      end
      upper.query("test.upper.bad", :description => "Read bad result.", :params => OBJECT,
        :result => OBJECT) { |request| request.query("test.lower.bad") }
    end])
    assert_equal ["original", "local"], read("test.upper.read").dig("value", "items")
    assert_equal({ "items" => ["original"] }, shared)
    assert_equal "params.invalid", read("test.upper.read", "count" => "wrong").fetch("code")
    assert_equal "operation.failed", read("test.upper.bad").fetch("code")
    assert_empty @model.operations
  end

  def test_retargeter_cannot_project_another_features_entity_kind
    install_entity_retargeter(:foreign => true)
    engine, ids, entity, record = retarget_seed
    before = @model.operations.length
    outcome = retarget_invoke(ids)
    assert_equal "operation.failed", outcome.fetch("code")
    assert_equal ids.sort, engine.ids(KIND).sort
    assert_equal record, JSON.parse(entity.get_attribute("ph_composer.test_retarget", "record"))
    assert_equal before, @model.operations.length
  end

  def test_duplicate_callback_failure_poisoning_survives_a_rescuing_action
    engine = R::Engine.new(@model, PhComposer::Registry.current.catalog)
    seed = R::ChangeSet.new
    ids = 2.times.map { |i| engine.propose_create(KIND, seed, :values => { "label" => "Original #{i}" }) }
    engine.apply(seed)
    observed = []
    PhComposer::Registry.install([feature do |registry|
      scope = registry.feature("test.consumer", :contract_version => 1, :requires => [TestFeature::ID])
      scope.action("test.consumer.duplicate", :description => "Duplicate with failing transform.", :params => OBJECT,
        :result => OBJECT, :undo_name => "Duplicate", :side_effects => "Duplicates records.") do |request, proposal|
        calls = 0
        begin
          request.engine.propose_duplicate(KIND, ids, proposal) do |values|
            calls += 1
            observed << calls
            raise KeyError, "second transform failed" if calls == 2

            values
          end
        rescue KeyError
          # A caller may handle the exception, but cannot commit the partial collection.
        end
        {}
      end
    end])
    before = @model.operations.length
    outcome = PhComposer::API.invoke(:context => @context, :name => "test.consumer.duplicate", :params => {},
      :request => { "sequence" => 1, "expected_revision" => @session.revision })
    assert_equal [1, 2], observed
    assert_equal "operation.failed", outcome.fetch("code")
    assert_equal ids.sort, engine.ids(KIND).sort
    assert_equal before, @model.operations.length
  end

end
