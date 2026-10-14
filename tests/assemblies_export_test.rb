# frozen_string_literal: true

require_relative "test_helper"

class AssembliesExportTest < PhComposerTestCase
  ROOT = File.join(TESTS_ROOT, "fixtures", "assemblies")
  SECTION = "ph_composer.assemblies.export.constructions"
  Assemblies = PhComposer::Assemblies

  def setup
    super
    @model = Sketchup.active_model
    @fixture = JSON.parse(File.read(File.join(ROOT, "authoring.json")))
    @fixture.fetch("materials").each { |row| Assemblies::Materials::Schema::KIND.store.write(@model, row) }
    @fixture.fetch("assemblies").each { |row| Assemblies::Assembly::Schema::KIND.store.write(@model, row) }
    session = PhComposer::Sessions.for(@model)
    @context = PhComposer::API.connect(:session_id => session.id)
  end

  # Assemblies pass their user_data through to the Construction; Materials still leave theirs out.
  def test_shared_extraction_contract_contains_only_declared_fields_and_passes_assembly_user_data
    expected = JSON.parse(File.read(File.join(ROOT, "extraction.json")))
    extracted = PhComposer::Export::Collection.build(@model, :run_id => expected.fetch("run_id"),
                                                             :contributors => [SECTION])
    assert_equal expected, extracted.document
    codes = extracted.findings.map { |finding| finding.fetch("code") }.tally
    assert_equal 1, codes.fetch("export.user_data_passed")
    assert_operator codes.fetch("export.metadata_omitted"), :>=, 1
    wire = JSON.generate(extracted.document)
    %w[air_barrier photo_collections ventilated_cladding exterior_condition notes source].each do |key|
      refute_includes wire, "\"#{key}\""
    end
    materials = extracted.document.dig("sections", SECTION, "records").flat_map { |row| row.fetch("materials") }
    assert(materials.none? { |row| row.key?("user_data") })
  end

  def test_record_preflight_is_nonblocking_for_unused_incomplete_and_names_mass_defaults
    result = PhComposer::API.query(:context => @context, :name => "ph_composer.assemblies.export_preflight")
    assert_equal "completed", result.fetch("status"), result.inspect
    findings = result.fetch("value").fetch("findings")
    assert findings.none? { |finding| finding.fetch("blocks_export") }
    assert_includes findings.map { |finding| finding.fetch("code") }, "assembly.no_thermal_layers"
    assert_includes findings.map { |finding| finding.fetch("code") }, "assembly.membrane_in_mixed_layer"
    defaults = findings.find { |finding| finding.fetch("code") == "material.thermal_mass_defaulted" }
    assert_includes defaults.fetch("message"), "600"
    assert_includes defaults.fetch("message"), "1000"
    assert_includes defaults.fetch("message"), "Synthetic defaults"
    refute_includes defaults.fetch("message"), "mat_"
    assert_empty result.fetch("value").fetch("repairs")
    expected = JSON.parse(File.read(File.join(ROOT, "expected.json")))
    unavailable = findings.select do |finding|
      %w[assembly.no_thermal_layers assembly.membrane_in_mixed_layer].include?(finding.fetch("code"))
    end.map { |finding| finding.fetch("object_id") }
    assert_equal expected.fetch("unavailable").sort, unavailable.sort
  end

  def test_unreadable_record_blocks_even_when_unused
    kind = Assemblies::Materials::Schema::KIND
    kind.store.write(@model, @fixture.fetch("materials").first.merge("density_kg_m3" => "not numeric"))
    result = PhComposer::API.query(:context => @context, :name => "ph_composer.assemblies.export_preflight")
    assert_equal "completed", result.fetch("status"), result.inspect
    assert result.dig("value", "findings").any? { |finding| finding["blocks_export"] }
  end

  def test_construction_metadata_guard_declares_exact_two_keys
    keys = PhComposer::Registry.current.export_contributors.fetch(SECTION).user_data_keys
    assert_equal %w[ph_composer.assembly_id ph_composer.membrane_layers], keys
    allowed = JSON.generate("type" => "OpaqueConstruction", "user_data" => {
      "ph_composer" => { "assembly_id" => "asm_Single000001", "membrane_layers" => [] }
    })
    assert PhComposer::Export::Privacy.validate!(translation_result(allowed))
    foreign = JSON.parse(allowed)
    foreign["user_data"]["ph_composer"]["private_note"] = "must stay local"
    assert_raises(PhComposer::CodedError) do
      PhComposer::Export::Privacy.validate!(translation_result(JSON.generate(foreign)))
    end
  end

  def test_report_lists_each_definition_and_discloses_defaults_membranes_and_local_fields_once
    row = { "assembly_id" => "asm_Single000001", "name" => "<Synthetic>", "thermal_layer_count" => 2,
            "membrane_names" => ["Film"], "defaulted_material_ids" => ["mat_Wool00000001"] }
    plain = row.merge("assembly_id" => "asm_Plain0000001", "name" => "Plain", "membrane_names" => [],
                      "defaulted_material_ids" => [])
    second = row.merge("assembly_id" => "asm_Second000001", "name" => "Second membrane")
    html = Assemblies::ExportProjection.report(view("construction_definitions" => [row, second, plain]), "si").join
    assert_includes html, "&lt;Synthetic&gt;"
    assert_includes html, "<td>Plain</td><td></td>"
    assert_includes html, "Membranes: Film."
    assert_includes html, "600 kg/m3"
    assert_includes html, "1000 J/kgK"
    assert_equal 1, html.scan("Membranes of a used Assembly are carried in HBJSON").length
    assert_includes html, "Only Assemblies that a Face uses are written to the HBJSON"
    assert_equal 1, html.scan("Air barrier, photos").length
    assert_equal 1, html.scan("Honeybee defaults:").length
    assert_includes html, "roughness MediumRough"
    assert_includes html, "thermal absorptance 0.9 when emissivity is absent"
    assert_includes html, "solar and visible absorptance 0.7"
    assert_includes html, "Authored emissivity supplies thermal absorptance when present"
    assert_empty Assemblies::ExportProjection.report(view({}), "si")
  end

  private

  def view(fields)
    contributor = PhComposer::Registry.current.export_contributors.fetch(SECTION)
    PhComposer::Export::ResultView.new({ SECTION => fields }, contributor)
  end

  def translation_result(hbjson)
    { "schema_version" => 1, "run_id" => "run", "state" => "complete",
      "summary" => { "objects" => 1, "unavailable" => 0, "findings" => 0, "publishable" => true },
      "sections" => [], "findings" => [], "failure" => nil,
      "canonical_model" => { "hbjson" => hbjson, "rooms" => 0, "faces" => 0, "surface_pairs" => 0 } }
  end
end
