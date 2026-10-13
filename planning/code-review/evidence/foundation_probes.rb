# frozen_string_literal: true

# Review probes against the offline host stub, not production tests or native-host proof.
# Run from the repo: $(rbenv which ruby) planning/code-review/evidence/foundation_probes.rb
require_relative "../../../tests/test_helper"

class ArchitectureReviewProbes < PhComposerTestCase
  OBJECT = { "type" => "object" }.freeze

  def feature(&install)
    Module.new do
      define_singleton_method(:name) { "ArchitectureReviewProbe" }
      define_singleton_method(:install, &install)
    end
  end

  def test_invalid_store_dictionary_leaves_a_partially_published_feature
    store = Struct.new(:dictionary).new("outside.records")
    kind = PhComposer::Records::RecordKind.new(
      :id => "review.atomic.part", :label => "Probe", :schema_version => 1,
      :id_prefix => "rva", :fields => [], :store => store
    )
    contribution = feature do |registry|
      scope = registry.feature("review.atomic", :contract_version => 1)
      scope.record_kind(kind)
      scope.query("review.atomic.read", :description => "Read probe.",
                                        :params => OBJECT, :result => OBJECT, :refuses => []) { {} }
    end
    assert_raises(ArgumentError) { PhComposer::Registry.install([contribution]) }
    assert PhComposer::Registry.installed?("review.atomic")
    assert PhComposer::Registry.current.queries.key?("review.atomic.read")
    assert PhComposer::Registry.current.record_kinds.key?(kind.id)
    assert_nil PhComposer::Registry.current.owner_of(kind.id)
  end

  def test_a_retained_field_schema_changes_validation_after_publication
    schema = { "type" => "number", "minimum" => 0 }
    field = PhComposer::Records::Field.new(:key => "value", :schema => schema, :required => true)
    kind = PhComposer::Records::RecordKind.new(
      :id => "review.mutable.part", :label => "Probe", :schema_version => 1,
      :id_prefix => "rvm", :fields => [field]
    )
    PhComposer::Registry.install([feature do |registry|
      registry.feature("review.mutable", :contract_version => 1).record_kind(kind)
    end])
    record = { "id" => "rvm_Ab12Cd34Ef56", "schema_version" => 1, "value" => 2 }
    assert_empty kind.problems(record)
    schema["minimum"] = 10
    refute_empty PhComposer::Registry.current.record_kinds.fetch(kind.id).problems(record)
  end

  def test_an_undeclared_participant_is_callable_and_a_swallowed_refusal_does_not_poison
    PhComposer::Registry.install([feature do |registry|
      registry.feature("review.provider", :contract_version => 1)
              .proposal_participant("review.provider.reject") do |_request, _proposal|
        raise PhComposer::CodedError.new("validation.failed", "Synthetic refusal.")
      end
      registry.feature("review.consumer", :contract_version => 1)
    end])
    proposal = PhComposer::Operations::Proposal.new
    request = PhComposer::HandlerRequest.for(PhComposer::Sessions.current,
                                             :owner => "review.consumer", :name => "review.consumer.probe",
                                             :proposal => proposal)
    handler = request.participant("review.provider.reject")
    assert_raises(PhComposer::CodedError) { handler.call(request, proposal) }
    assert_nil proposal.refusal
  end

  def test_a_required_entity_extension_has_no_allowlisted_projection_argument
    extension = PhComposer::Records::Extension.new(:namespace => "review.entity.data", :schema_version => 1,
                                                   :export_relevance => "required", :validate => ->(_payload) { [] })
    catalog = PhComposer::Records::Catalog.new(:extensions => [extension])
    reader = PhComposer::Export::RecordReader.new(nil, catalog)
    record = { "id" => "entity_1", "value" => 2,
               "extension_data" => { extension.namespace => extension.envelope("custom" => 3) } }
    error = assert_raises(PhComposer::Export::Blocked) do
      reader.entity_record(record, :fields => ["value"])
    end
    assert_equal "extension.unavailable", error.code
    assert_raises(ArgumentError) do
      reader.entity_record(record, :fields => ["value"], :extensions => { extension.namespace => ["custom"] })
    end
  end

  def test_an_authored_edge_disappears_from_the_shared_export_snapshot_and_overlay
    edge = Sketchup::Edge.new(123, [0, 0, 0], [10, 0, 0])
    PhComposer::Records::EntityStore.new("ph_composer.review.edge").write(edge, "id" => "edge_1")
    Sketchup.active_model.entities << edge
    snapshot = PhComposer::Export::GeometrySnapshot.capture(Sketchup.active_model, :revision => 1)
    assert_empty snapshot.entries
    assert_empty snapshot.records("ph_composer.review.edge")
    triangles, segments = PhComposer::ColourBy::Tessellation.call(edge, Geom::Transformation.new)
    assert_empty triangles
    assert_empty segments
  end

  def test_a_valid_registered_wire_kind_without_name_fails_in_file_provider_sorting
    adapter = PhComposer::Registry.current.library_kinds.values.first.adapter.dup
    adapter.wire_kind = "synthetic_labels"
    adapter.wire_schema = {
      "type" => "object", "additionalProperties" => false, "required" => %w[id label],
      "properties" => { "id" => { "type" => "string" }, "label" => { "type" => "string" } }
    }
    kind = PhComposer::Records::RecordKind.new(
      :id => "review.labels.part", :label => "Probe", :schema_version => 1,
      :id_prefix => "rvl", :fields => []
    )
    PhComposer::Registry.install([feature do |registry|
      scope = registry.feature("review.labels", :contract_version => 1)
      scope.record_kind(kind)
      scope.library_kind("review.labels.adapter", :contract_version => 1, :record_kind => kind.id, :adapter => adapter)
    end])
    document = {
      "format" => "ph-composer.library", "schema_version" => 1,
      "library" => { "id" => "synthetic", "name" => "Synthetic" }, "exported_at" => "2026-10-13T12:00:00Z",
      "kind_schema_versions" => { "synthetic_labels" => 1 },
      "kinds" => { "synthetic_labels" => [{ "id" => "p1", "label" => "Probe" }] }
    }
    text = JSON.generate(document)
    parsed = PhComposer::Library::LibraryFile.parse(text, :adapters => ->(_kind) { adapter })
    assert_equal 1, parsed.fetch("rows").fetch("synthetic_labels").length
    Dir.mktmpdir do |directory|
      path = File.join(directory, "synthetic.json")
      File.write(path, text)
      adapters = ->(_kind) { adapter }
      provider = PhComposer::Library::FileProvider.new(:id => "probe", :label => "Probe", :path => path,
                                                       :kinds => ["synthetic_labels"], :adapters => adapters)
      assert_raises(NoMethodError) { provider.list("synthetic_labels") }
    end
  end
end
