# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/definition_writer"

class WindowDefinitionWriterTest < PhComposerTestCase
  include WindowRecordFixtures
  U = PhComposer::Windows::Units
  Writer = U::DefinitionWriter

  def setup
    super
    @model = Sketchup.active_model
    @type = window_record("rows_m" => [1.2], "columns_m" => [0.7, 0.8, 0.5],
      "elements" => 3.times.map { |column| W::Types.blank(0, column, :identity => window_allocator) })
    @type.fetch("elements").last["kind"] = "empty"
  end

  def test_create_writes_one_positive_z_pane_per_glazed_element_in_native_units
    definition = create
    assert_equal "PhComposer_Window_Test type", definition.name
    assert_equal [definition], @model.definitions.to_a
    assert_equal({ "window_type_id" => @type.fetch("id") }, U::DEFINITION_STORE.read(definition))
    panes = definition.entities.grep(Sketchup::Face)
    assert_equal 2, panes.length
    panes.zip(U::DefinitionPlan.build(@type).panes).each do |face, planned|
      assert_operator face.normal.z, :>, 0
      assert_equal({ "window_type_id" => @type.fetch("id"), "element_id" => planned.element_id },
        U::PANE_STORE.read(face))
      face.outer_loop.vertices.zip(planned.polygon_m).each do |vertex, expected|
        point = vertex.position
        [point.x, point.y, point.z].zip(expected).each do |actual, metres|
          assert_in_delta metres, actual * 0.0254, 1e-12
        end
      end
    end
    assert definition.behavior.is2d?
    assert definition.behavior.cuts_opening?
    assert_equal SnapTo_Arbitrary, definition.behavior.snapto
    assert_equal 127, definition.behavior.no_scale_mask?
    assert_empty @model.operation_starts
  end

  def test_all_empty_elements_create_no_faces
    @type.fetch("elements").each { |element| element["kind"] = "empty" }
    definition = create
    assert_empty definition.entities.to_a
    assert definition.behavior.cuts_opening?
  end

  def test_new_glass_material_is_shared_by_both_faces_without_duplication
    first = create
    second = create
    glass = @model.materials["PhComposer_Window_Glass"]
    assert_equal [glass], @model.materials.to_a
    assert_equal [173, 216, 230, 255], glass.color.to_a
    assert_equal 0.35, glass.alpha
    (first.entities.to_a + second.entities.to_a).each do |face|
      assert_same glass, face.material
      assert_same glass, face.back_material
    end
  end

  def test_existing_shared_material_and_its_users_are_never_rewritten
    glass = @model.materials.add("PhComposer_Window_Glass")
    glass.color = Sketchup::Color.new(9, 8, 7)
    glass.alpha = 0.8
    user = @model.entities.add_face([Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(1, 0, 0),
      Geom::Point3d.new(1, 1, 0)])
    user.material = glass
    definition = create
    assert_equal [9, 8, 7, 255], glass.color.to_a
    assert_equal 0.8, glass.alpha
    assert_same glass, user.material
    assert_same glass, definition.entities.first.material
    assert_equal 1, @model.materials.length
  end

  def test_rewrite_uses_resolved_definition_and_preserves_metadata_and_type_input
    definition = create
    old_ids = definition.entities.map(&:persistent_id)
    definition.set_attribute("outside.fixture", "literal", "preserved")
    stamp = U::DEFINITION_STORE.read(definition).merge("user_data" => { "tags" => ["literal"] })
    U::DEFINITION_STORE.write(definition, stamp)
    @type.merge!("notes" => "nongeometry", "user_data" => { "literal" => "authoring" })
    before = PhComposer::DeepCopy.call(@type)
    result = rewrite(definition)
    assert_same definition, result
    assert_equal stamp, U::DEFINITION_STORE.read(definition)
    assert_equal "preserved", definition.get_attribute("outside.fixture", "literal")
    assert_equal before, @type
    assert_empty old_ids & definition.entities.map(&:persistent_id)
    assert_empty @model.operation_starts
  end

  def test_one_enclosing_operation_undoes_and_redoes_creation_with_catalog_sharing
    @model.start_operation("Place window")
    definition = create
    instance = @model.entities.add_instance(definition, Geom::Transformation.new)
    id = instance.persistent_id
    @model.commit_operation
    after = state
    assert_equal 1, @model.operation_starts.length
    assert @model.undo
    assert_empty @model.definitions.to_a
    assert_empty @model.materials.to_a
    assert_empty @model.entities.to_a
    assert @model.redo
    assert_equal after, state
    restored = @model.entities.find { |entity| entity.persistent_id == id }
    assert_same @model.definitions.first, restored.definition
    assert_same @model.materials.first, restored.definition.entities.first.material
  end

  def test_rewrite_restores_type_name_and_one_undo_retains_native_rename
    definition = create
    definition.name = "User rename"
    @type["name"] = "Renamed type"
    @model.start_operation("Rewrite Window type", true)
    rewrite(definition)
    @model.commit_operation
    assert_equal "PhComposer_Window_Renamed type", definition.name
    @model.undo
    assert_equal "User rename", @model.definitions.first.name
    @model.redo
    assert_equal "PhComposer_Window_Renamed type", @model.definitions.first.name
  end

  def test_abort_restores_rewritten_geometry_behavior_stamps_and_material_catalog
    definition = @model.definitions.add("Existing")
    definition.entities.add_face([Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(1, 0, 0),
      Geom::Point3d.new(1, 1, 0)])
    definition.behavior.no_scale_mask = 4
    definition.set_attribute("outside.fixture", "literal", "before")
    U::DEFINITION_STORE.write(definition, "window_type_id" => "wnt_previous")
    instance = @model.entities.add_instance(definition, Geom::Transformation.new)
    before = state
    @model.start_operation("Rewrite window")
    rewrite(definition)
    assert_equal 127, definition.behavior.no_scale_mask?
    @model.abort_operation
    assert_equal before, state
    restored = @model.entities.find { |entity| entity.persistent_id == instance.persistent_id }
    assert_same @model.definitions.first, restored.definition
    assert_equal "before", restored.definition.get_attribute("outside.fixture", "literal")
    assert_equal [["Rewrite window", false, :aborted]], @model.operations
  end

  def test_abort_removes_new_definition_and_new_shared_material
    before = state
    @model.start_operation("Failed placement")
    create
    @model.abort_operation
    assert_equal before, state
  end

  def test_failed_second_pane_can_be_aborted_without_partial_geometry_or_materials
    definition = @model.definitions.add("Existing")
    before = state
    @model.start_operation("Failed rewrite")
    definition.entities.define_singleton_method(:add_face) do |points|
      return nil unless to_a.empty?

      super(points)
    end
    error = assert_raises(PhComposer::CodedError) { rewrite(definition) }
    assert_equal "geometry.failed", error.code
    assert_equal 1, definition.entities.to_a.length
    @model.abort_operation
    assert_equal before, state
  end

  def test_unused_definition_removal_is_restored_by_the_enclosing_undo
    definition = create
    before = state
    @model.start_operation("Remove unused definition")
    assert @model.definitions.remove(definition)
    refute @model.definitions.remove(definition)
    @model.commit_operation
    assert_empty @model.definitions.to_a
    assert @model.undo
    assert_equal before, state
    assert @model.redo
    assert_empty @model.definitions.to_a
    assert_equal 1, @model.materials.length
  end

  private

  def create
    Writer.create(:model => @model, :type => @type, :plan => U::DefinitionPlan.build(@type))
  end

  def rewrite(definition)
    Writer.rewrite(:model => @model, :definition => definition, :type => @type,
      :plan => U::DefinitionPlan.build(@type))
  end

  def state
    definitions = @model.definitions.map do |definition|
      behavior = definition.behavior
      faces = definition.entities.map do |face|
        points = face.outer_loop.vertices.map { |vertex| [vertex.position.x, vertex.position.y, vertex.position.z] }
        [face.persistent_id, points, U::PANE_STORE.read(face), face.material&.name, face.back_material&.name]
      end
      [definition.persistent_id, definition.name, U::DEFINITION_STORE.read(definition),
        definition.get_attribute("outside.fixture", "literal"), behavior.is2d?, behavior.cuts_opening?,
        behavior.snapto, behavior.no_scale_mask?, faces]
    end
    materials = @model.materials.map { |material| [material.name, material.color.to_a, material.alpha] }
    instances = @model.entities.to_a.map { |instance| [instance.persistent_id, instance.definition.persistent_id] }
    [definitions, materials, instances]
  end
end
