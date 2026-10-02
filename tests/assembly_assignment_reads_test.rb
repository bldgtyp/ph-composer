# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/assembly_assignment_fixtures"

class AssemblyAssignmentReadsTest < PhComposerTestCase
  include AssemblyAssignmentFixtures

  def setup
    super
    assignment_setup
  end

  def test_usage_includes_nested_and_repeated_definition_occurrences_with_gross_area
    id = assignment_assembly("Usage")
    assignment_zone(100, 2)
    group, entities = assignment_zone(200, 1, :nested => true)
    assignment_invoke("#{FACE_PREFIX}.assign_assembly", assignment_params(assignment_faces, id))
    group.entities << Sketchup::Group.new(250, group.entities.to_a.first.entities,
                                         :transformation => Geom::Transformation.scaling(2))
    read = assignment_query("#{FACE_PREFIX}.all")
    rows = read.fetch("faces")
    usage = read.fetch("assembly_usage").first
    assert_equal 4, usage.fetch("face_count")
    assert_in_delta rows.sum { |row| row.fetch("area_m2") }, usage.fetch("gross_area_m2"), 1.0e-9
    assert_in_delta 7 * 0.5 * 100 * 100 * 0.0254**2, usage.fetch("gross_area_m2"), 1.0e-9
    assert_equal rows.map { |row| row.fetch("reference") }, usage.fetch("faces")
    assert_equal read.fetch("assembly_usage"), assignment_query("#{FACE_PREFIX}.assembly_usage").fetch("assemblies")
    refute_nil STORE.read(entities.first)
  end

  def test_nonblocking_type_exterior_and_surface_mismatches_are_named
    rows = assignment_pair(300)
    first = assignment_assembly("First", "type" => "Floor", "exterior_condition" => "Ground")
    second = assignment_assembly("Second", "type" => "Wall", "exterior_condition" => "Outdoors")
    assignment_invoke("#{FACE_PREFIX}.assign_assembly", assignment_params([rows.first], first))
    assignment_invoke("#{FACE_PREFIX}.assign_assembly", assignment_params([assignment_faces.last], second))
    rows = assignment_faces
    assert_equal %w[assembly.type_mismatch assembly.exterior_condition_mismatch assembly.pair_mismatch],
                 rows.first.fetch("findings").map { |finding| finding.fetch("code") }
    assert_equal %w[assembly.exterior_condition_mismatch assembly.pair_mismatch],
                 rows.last.fetch("findings").map { |finding| finding.fetch("code") }
    assert rows.all? { |row| row.fetch("state") == "classified" }
    assert rows.all? { |row| row.fetch("adjacency_state") == "current" }
  end

  def test_one_unassigned_surface_endpoint_has_no_pair_mismatch_warning
    rows = assignment_pair(350)
    id = assignment_assembly("One side")
    assignment_invoke("#{FACE_PREFIX}.assign_assembly", assignment_params([rows.first], id))
    rows = assignment_faces
    assert_empty rows.last.fetch("findings")
    assert_empty rows.first.fetch("findings")
  end

  def test_colour_mode_uses_effective_read_colour_and_marks_absent_and_dangling
    _group, entities = assignment_zone(400, 3)
    id = assignment_assembly("Colour", "color" => "#123456")
    assignment_invoke("#{FACE_PREFIX}.assign_assembly", assignment_params([assignment_faces.first], id))
    STORE.write(entities.last, "id" => "fac_000000000099", "schema_version" => 1,
                              "assembly_id" => "asm_000000000099")
    declaration = PhComposer::Registry.current.colour_modes.fetch("#{FACE_PREFIX}.by_assembly")
    entries = declaration.projection.call(read(declaration))
    assert_equal "Colour", entries.first.label
    assert_equal [18, 52, 86], declaration.colours.call(entries.first.value)
    assert_nil entries[1].value
    assert_nil entries[1].state
    assert_equal :incomplete, entries.last.state
  end

  def test_choose_accepts_assembly_with_null_keep_and_missing_choice_refuses
    id = assignment_assembly("Paint")
    chosen = API.view(:context => @context, :name => "#{FACE_PREFIX}.choose",
                       :params => { "field" => "assembly_id", "value" => id })
    assert_equal "completed", chosen.fetch("status"), chosen.inspect
    assert_equal id, chosen.dig("value", "palette", "assembly_id")
    missing = API.view(:context => @context, :name => "#{FACE_PREFIX}.choose",
                        :params => { "field" => "assembly_id", "value" => "asm_000000000099" })
    assert_equal %w[refused reference.invalid], missing.values_at("status", "code")
    kept = API.view(:context => @context, :name => "#{FACE_PREFIX}.choose",
                     :params => { "field" => "assembly_id", "value" => nil })
    refute kept.fetch("value").fetch("palette").key?("assembly_id")
  end

  def test_selection_menu_reads_targets_and_matching_type_first_then_calls_reassignment
    group, entities = assignment_zone(500)
    assignment_classify(assignment_faces, "face_type" => { "mode" => "set", "value" => "Wall" })
    assignment_assembly("A floor", "type" => "Floor")
    wall = assignment_assembly("Z wall", "type" => "Wall")
    @model.active_path = [group]
    @model.selection.add(entities.first)
    selection = assignment_query("#{FACE_PREFIX}.selection")
    assert_equal assignment_faces.first.fetch("values"), selection.fetch("targets").first.fetch("expected_values")
    menu = PhComposer::Registry.current.menu_items.fetch("#{FACE_PREFIX}.assembly_menu")
    entries = menu.entries.call(read(menu))
    assert_equal "Assembly: Z wall", entries.first.label
    entries.first.handler.call(@session)
    assert_equal wall, STORE.read(entities.first).fetch("assembly_id")
    assert_equal "Wall", STORE.read(entities.first).fetch("face_type")
    refute STORE.read(entities.first).key?("boundary_condition")
  end

  private

  def read(declaration)
    PhComposer::HandlerRequest.for(@session, :owner => declaration.owner, :name => declaration.name)
  end
end
