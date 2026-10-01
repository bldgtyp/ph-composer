# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/assembly_record_fixtures"
require_relative "../src/ph_composer/library/callback_invoker"

class MaterialLibraryKindTest < PhComposerTestCase
  include AssemblyRecordFixtures
  Kind = PhComposer::Assemblies::Materials::Schema::KIND
  Mapping = PhComposer::Assemblies::MaterialsLibrary

  def setup
    super
    @model = Sketchup.active_model
    @registry = PhComposer::Registry.current
    @declaration = @registry.library_kinds.fetch(Mapping::NAME)
    @adapter = @declaration.adapter
    @engine = PhComposer::Records::Engine.new(@model, @registry.catalog)
    @proposal = PhComposer::Operations::Proposal.new
    @request = PhComposer::HandlerRequest.new(:model => @model, :engine => @engine, :registry => @registry,
      :owner => "ph_composer.library", :proposal => @proposal, :params => {}, :revision => 0,
      :session => PhComposer::Sessions.for(@model))
  end

  def wire(extra = {})
    { "id" => "vendor-record", "name" => "  Insulation  ", "category" => "Insulation",
      "conductivity_w_mk" => 0.04, "color" => "#ABCDEF" }.merge(extra)
  end

  def invoke(method, params = {})
    PhComposer::Library::CallbackInvoker.call(@request, @declaration, @adapter[method], params)
  end

  def source(snapshot = wire.slice(*Mapping::FIELDS))
    { "kind" => "library", "provider_kind" => "test.file", "library_id" => "synthetic", "record_kind" => "materials",
      "record_id" => "vendor-record", "fingerprint" => @adapter.fingerprint.call(wire), "fingerprint_version" => 1,
      "copied_at" => "2026-10-01T12:00:00Z", "snapshot" => snapshot }
  end

  def test_registration_owns_materials_and_reuses_actual_assignment_contract
    action = @registry.actions.fetch("#{Assemblies::FEATURE_ID}.assemblies.segments.set_material")
    assert_equal Assemblies::FEATURE_ID, @declaration.owner
    assert_equal "materials", @adapter.wire_kind
    assert_equal Kind.id, @declaration.record_kind
    target = PhComposer::DeepCopy.call(action.params)
    target.fetch("properties").delete("material_id")
    target.fetch("required").delete("material_id")
    assert_equal target, @adapter.assign.params.fetch("properties").fetch("target")
    assert_equal %w[target local_id], @adapter.assign.params.fetch("required")
    assert_equal action.result, @adapter.assign.result
  end

  def test_map_normalizes_defaults_and_never_copies_wire_identity_or_metadata
    mapped = @adapter.map.call(wire("source" => { "kind" => "manual" }, "user_data" => { "secret" => true },
                                    "extension_data" => {}, "provider_address" => "private", "token" => "private"))
    assert_equal "Insulation", mapped.fetch("name")
    assert_equal "insulation", mapped.fetch("category")
    assert_equal "#abcdef", mapped.fetch("color")
    assert_equal "", mapped.fetch("notes")
    assert_equal [], mapped.fetch("datasheet_links")
    assert_nil mapped.fetch("density_kg_m3")
    assert_empty PhComposer::JsonSchema.validate(mapped, @adapter.mapped_schema)
    assert_equal Mapping::FIELDS.sort, mapped.keys.sort
  end

  def test_fingerprint_uses_ordered_semantic_fields_and_canonical_numbers_only
    first = wire("density_kg_m3" => 12)
    reordered = first.to_a.reverse.to_h.merge("id" => "other", "density_kg_m3" => 12.0,
      "source" => source, "user_data" => { "note" => 2 }, "provider_label" => "Other", "updated_at" => "later")
    fingerprint = @adapter.fingerprint.call(first)
    assert_match(/\A[0-9a-f]{64}\z/, fingerprint)
    assert_equal fingerprint, @adapter.fingerprint.call(reordered)
    refute_equal fingerprint, @adapter.fingerprint.call(first.merge("conductivity_w_mk" => 0.05))
    assert_equal fingerprint, @adapter.fingerprint.call(@adapter.map.call(first))
  end

  def test_unknown_category_falls_back_locally_but_original_is_legal_only_in_snapshot
    input = wire("category" => "Vendor's new category")
    mapped = @adapter.map.call(input)
    assert_equal "", mapped.fetch("category")
    id = invoke(:create, "values" => mapped.merge("source" => source(input.slice(*Mapping::FIELDS)))).fetch("id")
    record = @proposal.find(Kind.id, id).after
    assert_equal "Vendor's new category", record.dig("source", "snapshot", "category")
    assert_empty Kind.problems(record)
    refute_empty Kind.problems(record.merge("category" => "Vendor's new category"))
    %w[id source user_data extension_data provider_address token].each do |key|
      snapshot = input.slice(*Mapping::FIELDS).merge(key => "private")
      refute_empty Kind.problems(record.merge("source" => source(snapshot))), key
    end
  end

  def test_reverse_exports_declared_wire_fields_and_local_identity_without_provenance
    record = Mapping.map(wire).merge("id" => "mat_000000000001", "schema_version" => 1,
      "source" => source, "user_data" => { "firm.note" => "retain" }, "extension_data" => {})
    result = @adapter.reverse.call(record)
    assert_equal "mat_000000000001", result.fetch("id")
    assert_equal (Mapping::FIELDS + ["id"]).sort, result.keys.sort
    assert_empty PhComposer::JsonSchema.validate(result, @adapter.wire_schema)
    assert_equal Mapping.map(record), result.reject { |key, _value| key == "id" }
  end

  def test_replacement_keeps_identity_references_and_unavailable_extension_payloads
    record = fixture_materials.fetch(material_id("wool"))
    extension = { "schema_version" => 8, "payload" => { "unavailable" => ["keep"] } }
    record.merge!("user_data" => { "firm.note" => ["keep"] }, "extension_data" => { "outside.vendor" => extension })
    Kind.store.write(@model, record)
    assembly = fixture_assembly(reference_layers)
    fixture_materials.each { |id, material| Kind.store.write(@model, material) unless id == record.fetch("id") }
    Assemblies::Assembly::Schema::KIND.store.write(@model, assembly)
    params = { "id" => record.fetch("id"), "expected_values" => { "conductivity_w_mk" => 0.04 },
               "values" => Mapping.map(wire).merge("source" => source) }
    result = invoke(:replace, params)
    assert_equal record.fetch("id"), result.fetch("id")
    assert_equal 1, @proposal.writes.length
    @engine.apply(@proposal.record_changes)
    replaced = @engine.find(Kind.id, record.fetch("id"))
    assert_equal record.fetch("user_data"), replaced.fetch("user_data")
    assert_equal record.fetch("extension_data"), replaced.fetch("extension_data")
    assert_equal source, replaced.fetch("source")
    assert_equal assembly, Assemblies::Assembly::Schema::KIND.store.read(@model, assembly.fetch("id"))
    refusal = assert_raises(PhComposer::CodedError) do
      @engine.propose_delete(Kind.id, record.fetch("id"), PhComposer::Operations::Proposal.new)
    end
    assert_equal "reference.in_use", refusal.code
  end

  def test_local_read_is_detached_and_contains_no_metadata_in_mapped_values
    id = invoke(:create, "values" => Mapping.map(wire).merge("source" => source)).fetch("id")
    rows = invoke(:local_read)
    assert_equal id, rows.first.fetch("id")
    assert_equal source, rows.first.fetch("source")
    assert_equal "#abcdef", rows.first.fetch("expected_values").fetch("color")
    rows.first.fetch("mapped")["notes"] = "changed"
    rows.first.fetch("source").fetch("snapshot")["name"] = "changed"
    assert_equal "", @proposal.find(Kind.id, id).after.fetch("notes")
    assert_equal "  Insulation  ", @proposal.find(Kind.id, id).after.dig("source", "snapshot", "name")
    assert_empty @engine.ids(Kind.id)
  end

  def test_local_read_keeps_raw_case_and_optional_absence_for_expected_value_guards
    record = fixture_materials.fetch(material_id("wool")).merge("color" => "#ABCDEF")
    record.delete("density_kg_m3")
    Kind.store.write(@model, record)
    row = invoke(:local_read).first
    assert_equal "#abcdef", row.fetch("mapped").fetch("color")
    assert_equal "#ABCDEF", row.fetch("expected_values").fetch("color")
    refute row.fetch("expected_values").key?("density_kg_m3")
    assert_nil row.fetch("mapped").fetch("density_kg_m3")
    row.fetch("expected_values")["color"] = "changed"
    assert_equal "#ABCDEF", @engine.find(Kind.id, record.fetch("id")).fetch("color")
  end

  def test_copy_and_assignment_share_projected_material_and_one_proposal
    assembly = fixture_assembly([[100.0, [[600.0, nil]]]])
    Assemblies::Assembly::Schema::KIND.store.write(@model, assembly)
    id = invoke(:create, "values" => Mapping.map(wire).merge("source" => source)).fetch("id")
    layer = assembly.fetch("layers").first
    invoke(:assign, "local_id" => id, "target" => { "id" => assembly.fetch("id"), "layer_id" => layer.fetch("id"),
      "segment_id" => layer.fetch("segments").first.fetch("id"),
      "expected_values" => { "layers" => assembly.fetch("layers") } })
    assert_equal 2, @proposal.writes.length
    assert_empty @engine.ids(Kind.id)
    @engine.apply(@proposal.record_changes)
    current = @engine.find(Assemblies::ASSEMBLY_KIND, assembly.fetch("id"))
    assert_equal id, current.dig("layers", 0, "segments", 0, "material_id")
    assert_equal id, @engine.find(Kind.id, id).fetch("id")
  end

  def test_failed_assignment_poison_keeps_the_staged_copy_out_of_the_model
    id = invoke(:create, "values" => Mapping.map(wire)).fetch("id")
    error = assert_raises(PhComposer::CodedError) do
      invoke(:assign, "local_id" => id, "target" => { "id" => "asm_missing00000", "layer_id" => "lyr_missing00000",
        "segment_id" => "seg_missing00000", "expected_values" => {} })
    end
    assert_same error, @proposal.refusal
    assert_empty @engine.ids(Kind.id)
  end

  def test_malformed_assignment_target_refuses_before_staging_assignment_and_poisons_copy
    id = invoke(:create, "values" => Mapping.map(wire)).fetch("id")
    error = assert_raises(PhComposer::CodedError) do
      invoke(:assign, "local_id" => id, "target" => { "id" => "asm_missing00000", "material_id" => "foreign" })
    end
    assert_equal "params.invalid", error.code
    assert_same error, @proposal.refusal
    assert_equal 1, @proposal.writes.length
    assert_empty @engine.ids(Kind.id)
  end

  def test_replace_refuses_stale_expected_values_and_metadata_parameters
    record = fixture_materials.fetch(material_id("wool"))
    Kind.store.write(@model, record)
    params = { "id" => record.fetch("id"), "values" => Mapping.map(wire),
               "expected_values" => { "conductivity_w_mk" => 0.05 } }
    error = assert_raises(PhComposer::CodedError) { invoke(:replace, params) }
    assert_equal "target.changed", error.code
    assert_empty @proposal.writes
    assert_equal record, @engine.find(Kind.id, record.fetch("id"))
    error = assert_raises(PhComposer::CodedError) { invoke(:replace, params.merge("user_data" => {})) }
    assert_equal "params.invalid", error.code
  end
end
