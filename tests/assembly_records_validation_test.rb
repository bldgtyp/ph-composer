# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/assembly_record_fixtures"

class AssemblyRecordsValidationTest < PhComposerTestCase
  include AssemblyRecordFixtures

  def test_missing_thermal_mass_is_one_condition_per_material_in_each_assembly
    record = fixture_assembly([[100, [[850, "wool"], [150, "wool"]]], [40, [[1000, "wool"]]]])
    findings = Assemblies::Validation.assembly(record, fixture_materials)
    assert_equal ["material.thermal_mass_defaulted"], findings.map { |entry| entry.fetch("code") }
    assert_equal record.fetch("id"), findings.first.fetch("assembly_id")
    assert_equal material_id("wool"), findings.first.fetch("material_id")
    assert Assemblies::Validation.complete?(findings)
    quantities = findings.first.fetch("message_parts").select { |part| part.key?("quantity") }
    assert_equal [{ "quantity" => "density", "value" => 600.0 },
                  { "quantity" => "specific_heat", "value" => 1000.0 }], quantities
  end

  def test_export_blockers_name_conversion_limits_but_not_the_disclosed_mass_default
    record = fixture_assembly([[100, [[850, "wool"], [150, "wool"]]]])
    findings = Assemblies::Validation.assembly(record, fixture_materials)
    assert_empty Assemblies::Validation.export_blockers(record, fixture_materials, findings)
    materials = fixture_materials
    materials[material_id("wool")]["specific_heat_j_kgk"] = 99
    blockers = Assemblies::Validation.export_blockers(record, materials, findings)
    assert_equal ["material.specific_heat_too_low"], blockers.map { |entry| entry.fetch("code") }
    assert_equal record.fetch("id"), blockers.first.fetch("assembly_id")
  end

  def test_missing_conductivity_is_incomplete_but_not_required_for_a_membrane
    materials = fixture_materials
    materials[material_id("wool")].delete("conductivity_w_mk")
    record = fixture_assembly([[100, [[1000, "wool"]]]])
    findings = Assemblies::Validation.assembly(record, materials)
    assert_includes findings.map { |entry| entry["code"] }, "material.conductivity_missing"
    refute Assemblies::Validation.complete?(findings)
    assert_empty Assemblies::Validation.material(materials.fetch(material_id("membrane")))
  end

  def test_mixed_membrane_layer_is_a_condition_and_withholds_thermal_values
    record = fixture_assembly([[100, [[850, "wool"], [150, "membrane"]]]])
    findings = Assemblies::Validation.assembly(record, fixture_materials)
    assert_includes findings.map { |entry| entry["code"] }, "assembly.membrane_in_mixed_layer"
    refute Assemblies::Validation.complete?(findings)
    thermal = Assemblies::Thermal.preview(record, fixture_materials)
    assert_equal ["assembly.membrane_in_mixed_layer"], thermal.fetch("flags")
    assert_nil thermal["u_effective_w_m2k"]
  end

  def test_unreadable_material_and_assembly_are_named_without_repair
    materials = fixture_materials
    materials[material_id("wool")]["unexpected"] = "kept"
    record = fixture_assembly([[100, [[1000, "wool"]]]])
    findings = Assemblies::Validation.assembly(record, materials)
    assert_includes findings.map { |entry| entry["code"] }, "material.invalid"
    thermal = Assemblies::Thermal.preview(record, materials)
    assert_equal ["material.invalid"], thermal.fetch("flags")
    assert_nil thermal["u_effective_w_m2k"]
    record["unexpected"] = "kept"
    unreadable = Assemblies::Validation.assembly(record, materials)
    assert_equal ["assembly.invalid"], unreadable.map { |entry| entry["code"] }
    assert_equal "kept", record["unexpected"]
  end

  def test_all_membrane_condition_has_no_u_value_and_no_invented_severity
    record = fixture_assembly([[1, [[1000, "membrane"]]]])
    findings = Assemblies::Validation.assembly(record, fixture_materials)
    assert_equal ["assembly.no_thermal_layers"], findings.map { |entry| entry["code"] }
    refute findings.first.key?("severity")
    refute Assemblies::Validation.complete?(findings)
    assert_nil Assemblies::Thermal.effective(record, fixture_materials)
  end
end
