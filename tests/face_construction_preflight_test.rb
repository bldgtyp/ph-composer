# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/assembly_assignment_fixtures"
require_relative "support/construction_export_fixtures"

class FaceConstructionPreflightTest < PhComposerTestCase
  include AssemblyAssignmentFixtures
  include ConstructionExportFixtures

  def setup
    super
    assignment_setup
    assignment_zone(800)
    assignment_classify(assignment_faces, "face_type" => { "mode" => "set", "value" => "Wall" },
                                         "boundary_condition" => { "mode" => "set", "value" => "Outdoors" })
  end

  def findings
    assignment_query("#{FACE_PREFIX}.export_preflight").fetch("findings")
  end

  def test_missing_and_incomplete_assembly_block_the_named_face_with_locate
    missing = findings.find { |row| row["code"] == "construction.missing" }
    assert missing.fetch("blocks_export")
    assert_equal assignment_faces.first.fetch("reference"), missing.dig("locate", "params", "faces").first
    id = assignment_assembly("Empty")
    assignment_invoke("#{FACE_PREFIX}.assign_assembly", assignment_params(assignment_faces, id))
    incomplete = findings.find { |row| row["code"] == "construction.incomplete" }
    assert incomplete.fetch("blocks_export")
    assert_includes incomplete.fetch("message"), id
  end

  def test_dangling_and_invalid_references_have_distinct_blocking_rows
    face = @model.entities.to_a.first.entities.to_a.first
    record = STORE.read(face).merge("assembly_id" => "asm_Dangling0001")
    STORE.write(face, record)
    assert_equal ["construction.dangling"], findings.map { |row| row.fetch("code") }
    kind = PhComposer::Assemblies::Assembly::Schema::KIND
    kind.store.write(@model, "id" => record.fetch("assembly_id"), "schema_version" => 1, "name" => 42)
    assert_equal ["construction.invalid"], findings.map { |row| row.fetch("code") }
  end

  def test_no_boundary_omission_has_no_assembly_blocker
    assignment_classify(assignment_faces, "boundary_condition" => { "mode" => "clear" })
    assert_equal ["face.boundary_unassigned"], findings.map { |row| row.fetch("code") }
    refute findings.first.fetch("blocks_export")
  end

  def test_honeybee_translation_constraints_block_only_through_emitted_assignment
    id = seed_export_construction
    assignment_invoke("#{FACE_PREFIX}.assign_assembly", assignment_params(assignment_faces, id))
    assert_empty findings
    kind = PhComposer::Assemblies::Materials::Schema::KIND
    material = kind.store.read(@model, "mat_Wool00000001")
    kind.store.write(@model, material.merge("specific_heat_j_kgk" => 99))
    assert_equal ["construction.incomplete"], findings.map { |row| row.fetch("code") }
    assert_includes findings.first.fetch("message"), "100 J/kgK"
    record_rows = assignment_query("ph_composer.assemblies.export_preflight").fetch("findings")
    refute record_rows.any? { |row| row.fetch("blocks_export") }
    kind.store.write(@model, material)
    assembly_kind = PhComposer::Assemblies::Assembly::Schema::KIND
    assembly = assembly_kind.store.read(@model, id)
    template = assembly.fetch("layers").first
    assembly["layers"] = 10.times.map do |index|
      layer = PhComposer::DeepCopy.call(template)
      layer["id"] = format("lyr_%012d", index)
      layer.fetch("segments").first["id"] = format("seg_%012d", index)
      layer
    end
    assembly_kind.store.write(@model, assembly)
    assert_empty findings
    last = PhComposer::DeepCopy.call(template)
    last["id"] = "lyr_999999999999"
    last.fetch("segments").first["id"] = "seg_999999999999"
    assembly.fetch("layers") << last
    assembly_kind.store.write(@model, assembly)
    assert_equal ["construction.incomplete"], findings.map { |row| row.fetch("code") }
    assert_includes findings.first.fetch("message"), "10 thermal Layers"
    record_rows = assignment_query("ph_composer.assemblies.export_preflight").fetch("findings")
    refute record_rows.any? { |row| row.fetch("blocks_export") }
  end

  def test_stale_surface_omission_has_no_assembly_requirement
    rows = assignment_pair(2000).select { |row| row.dig("values", "boundary_condition") == "Surface" }
    id = assignment_assembly("Empty assigned to omitted Surface")
    assignment_invoke("#{FACE_PREFIX}.assign_assembly", assignment_params(rows, id))
    group = @model.entities.to_a.find { |entity| entity.persistent_id == 2010 }
    group.transformation = Geom::Transformation.translation([10, 0, 0])
    pair_ids = rows.map { |row| row.fetch("reference").fetch("entity_id") }
    pair_findings = findings.select { |row| pair_ids.include?(row.fetch("object_id")) }
    assert_equal ["adjacency.stale"], pair_findings.map { |row| row.fetch("code") }.uniq
    refute pair_findings.any? { |row| row.fetch("blocks_export") }
  end

  def test_complete_assembly_and_explicit_mismatch_are_nonblocking
    fixture = JSON.parse(File.read(File.join(TESTS_ROOT, "fixtures", "assemblies", "authoring.json")))
    fixture.fetch("materials").each { |row| PhComposer::Assemblies::Materials::Schema::KIND.store.write(@model, row) }
    row = fixture.fetch("assemblies").find { |entry| entry["id"] == "asm_Single000001" }
    PhComposer::Assemblies::Assembly::Schema::KIND.store.write(@model, row.merge("type" => "Floor"))
    assignment_invoke("#{FACE_PREFIX}.assign_assembly", assignment_params(assignment_faces, row.fetch("id")))
    assert_equal ["assembly.type_mismatch"], findings.map { |finding| finding.fetch("code") }
    refute findings.first.fetch("blocks_export")
  end
end
