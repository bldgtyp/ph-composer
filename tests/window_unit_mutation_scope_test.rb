# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/definition_writer"
require_relative "../src/ph_composer/features/windows/units/mutation_scope"

class WindowUnitMutationScopeTest < PhComposerTestCase
  include WindowRecordFixtures

  U = PhComposer::Windows::Units

  def setup
    super
    @model = Sketchup.active_model
    @type = window_record
    @definition = U::DefinitionWriter.create(:model => @model, :type => @type,
                                             :plan => U::DefinitionPlan.build(@type))
    @scope = U::MutationScope.new(:definition_ids => [@definition.persistent_id])
  end

  def record
    { "id" => "wun_AAAAAAAAAAAA", "schema_version" => 1, "window_type_id" => @type.fetch("id"),
      "anchor" => "sill_center", "user_data" => { "literal" => [1] }, "extension_data" => {} }
  end

  def add_unit(entities = @model.entities)
    entities.add_instance(@definition, Geom::Transformation.new).tap { |unit| U.write(unit, record) }
  end

  def test_scope_path_is_stable_and_distinguishes_target_sets
    id = @definition.persistent_id
    assert_equal @scope.path, U::MutationScope.new(:definition_ids => [id, id]).path
    refute_equal @scope.path, U::MutationScope.new.path
    assert @scope.path.frozen?
    assert @scope.path.all?(&:frozen?)
    assert_raises(ArgumentError) { U::MutationScope.new(:definition_ids => [0]) }
  end

  def test_projected_identity_preimage_matches_only_the_planned_record_write
    unit = add_unit
    path = [unit.persistent_id]
    after = record.merge("id" => "wun_BBBBBBBBBBBB")
    projected = @scope.capture(@model, :expected_records => { path => after })
    refute_equal projected, @scope.capture(@model)
    assert_equal record, U.read(unit)
    U.write(unit, after)
    assert_equal projected, @scope.capture(@model)
    unit.set_attribute("ph_composer.synthetic", "note", "changed")
    refute_equal projected, @scope.capture(@model)
    assert_raises(PhComposer::CodedError) { @scope.capture(@model, :expected_records => { [999999] => after }) }
  end

  def test_absent_index_and_valid_empty_index_are_distinct_without_repair
    before = @scope.capture(@model)
    assert_nil U::DefinitionIndex::STORE.read(@model)
    U::DefinitionIndex::STORE.write(@model, "schema_version" => 1, "definitions" => {})
    refute @scope.unchanged?(@model, before)
    U::DefinitionIndex::STORE.delete(@model)
    assert @scope.unchanged?(@model, before)
  end

  def test_unused_definition_and_material_creation_are_detected_even_without_instances
    before = @scope.capture(@model)
    extra = @model.definitions.add("Unused ghost")
    refute @scope.unchanged?(@model, before)
    @model.definitions.remove(extra)
    assert @scope.unchanged?(@model, before)
    @model.materials.add("Unused ghost")
    refute @scope.unchanged?(@model, before)
  end

  def test_canonical_index_is_detached_and_dangling_pointer_stays_capturable_for_rebuild
    type_id = @type.fetch("id")
    U::DefinitionIndex::STORE.write(@model, "schema_version" => 1,
                                            "definitions" => { type_id => @definition.persistent_id })
    before = @scope.capture(@model)
    U::DefinitionIndex.read(@model)[type_id] = 99
    assert @scope.unchanged?(@model, before)
    U::DefinitionIndex::STORE.write(@model, "schema_version" => 1,
                                            "definitions" => { type_id => @definition.persistent_id + 1 })
    refute @scope.unchanged?(@model, before)
    dangling = @scope.capture(@model)
    assert @scope.unchanged?(@model, dangling)
    U::DefinitionIndex::STORE.write(@model, "schema_version" => 1,
                                            "definitions" => { type_id => @definition.persistent_id })
    refute @scope.unchanged?(@model, dangling)
  end

  def test_definition_behavior_name_and_stamps_are_exact
    before = @scope.capture(@model)
    { :is2d => [true, false], :cuts_opening => [true, false],
      :snapto => [SnapTo_Arbitrary, SnapTo_Arbitrary + 1], :no_scale_mask => [127, 0] }.each do |field, values|
      @definition.behavior.public_send("#{field}=", values.last)
      refute @scope.unchanged?(@model, before)
      @definition.behavior.public_send("#{field}=", values.first)
      assert @scope.unchanged?(@model, before)
    end
    @definition.name = "Changed"
    refute @scope.unchanged?(@model, before)
    @definition.name = "PhComposer_Window_Test type"
    @definition.set_attribute("ph_composer.outside", "literal", [2])
    refute @scope.unchanged?(@model, before)
  end

  def test_face_normal_geometry_and_front_back_material_assignments_are_captured
    face = @definition.entities.grep(Sketchup::Face).first
    before = @scope.capture(@model)
    face.reverse!
    refute @scope.unchanged?(@model, before)
    face.reverse!
    assert @scope.unchanged?(@model, before)
    face.back_material = nil
    refute @scope.unchanged?(@model, before)
    face.back_material = face.material
    assert @scope.unchanged?(@model, before)
    face.set_attribute("ph_composer.outside", "stamp", "changed")
    refute @scope.unchanged?(@model, before)
  end

  def test_shared_material_properties_and_attributes_are_captured
    material = @model.materials.to_a.first
    before = @scope.capture(@model)
    material.alpha = 0.8
    refute @scope.unchanged?(@model, before)
    material.alpha = 0.35
    assert @scope.unchanged?(@model, before)
    material.color = Sketchup::Color.new(1, 2, 3)
    refute @scope.unchanged?(@model, before)
    material.color = Sketchup::Color.new(173, 216, 230)
    material.set_attribute("ph_composer.outside", "literal", [3])
    refute @scope.unchanged?(@model, before)
  end

  def test_edge_geometry_and_attributes_are_captured_exactly
    edge = Sketchup::Edge.new(500, Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(1, 0, 0))
    @definition.entities << edge
    before = @scope.capture(@model)
    edge.transform!(Geom::Transformation.translation([0.00000001, 0, 0]))
    refute @scope.unchanged?(@model, before)
    edge.transform!(Geom::Transformation.translation([-0.00000001, 0, 0]))
    # A fresh baseline avoids assuming floating-point inverse arithmetic is byte-identical.
    before = @scope.capture(@model)
    edge.set_attribute("ph_composer.outside", "stamp", "changed")
    refute @scope.unchanged?(@model, before)
  end

  def test_shared_storage_paths_and_orphans_remain_separate_occurrences
    parent = @model.definitions.add("Shared parent")
    child = add_unit(parent.entities)
    parents = 2.times.map { @model.entities.add_instance(parent, Geom::Transformation.new) }
    add_unit
    before = @scope.capture(@model)
    assert_equal 3, U::Occurrences.all(@model).length
    parents.last.transformation = Geom::Transformation.translation([1, 0, 0])
    refute @scope.unchanged?(@model, before)
    parents.last.transformation = Geom::Transformation.new
    assert @scope.unchanged?(@model, before)
    U.write(child, record.merge("user_data" => { "literal" => [3] }))
    refute @scope.unchanged?(@model, before)
  end

  def test_orphan_copies_metadata_transformation_and_glue_are_captured
    first = add_unit
    add_unit
    before = @scope.capture(@model)
    U.write(first, record.merge("user_data" => { "literal" => [2] }))
    refute @scope.unchanged?(@model, before)
    U.write(first, record)
    assert @scope.unchanged?(@model, before)
    first.transformation = Geom::Transformation.translation([1, 0, 0])
    refute @scope.unchanged?(@model, before)
    first.transformation = Geom::Transformation.new
    first.glued_to = @model.entities.add_face([Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(1, 0, 0),
                                               Geom::Point3d.new(0, 1, 0)])
    refute @scope.unchanged?(@model, before)
  end

  def test_native_abort_and_undo_restore_exact_capture_including_shared_catalogs
    unit = add_unit
    before = @scope.capture(@model)
    @model.start_operation("Scope proof", true, false, false)
    U::DefinitionWriter.rewrite(:model => @model, :definition => @definition,
                                :type => @type, :plan => U::DefinitionPlan.build(@type))
    @model.definitions.add("Ghost")
    @model.materials.add("Ghost")
    U::DefinitionIndex::STORE.write(@model, "schema_version" => 1, "definitions" => {})
    unit.transformation = Geom::Transformation.translation([1, 0, 0])
    unit.glued_to = @model.entities.add_face([Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(1, 0, 0),
                                              Geom::Point3d.new(0, 1, 0)])
    @model.abort_operation
    assert @scope.unchanged?(@model, before)
    @model.start_operation("Scope proof", true, false, false)
    @model.definitions.to_a.first.behavior.is2d = false
    @model.commit_operation
    refute @scope.unchanged?(@model, before)
    @model.undo
    assert @scope.unchanged?(@model, before)
  end

  def test_unreadable_index_unit_or_geometry_stamp_refuses_capture_and_comparison
    before = @scope.capture(@model)
    U::DefinitionIndex::STORE.write(@model, {})
    assert_raises(PhComposer::CodedError) { @scope.capture(@model) }
    refute @scope.unchanged?(@model, before)
    U::DefinitionIndex::STORE.delete(@model)
    face = @definition.entities.grep(Sketchup::Face).first
    U::PANE_STORE.write(face, [])
    assert_raises(PhComposer::CodedError) { @scope.capture(@model) }
    refute @scope.unchanged?(@model, before)
    U::PANE_STORE.write(face, nil)
    assert_raises(PhComposer::CodedError) { @scope.capture(@model) }
    U::PANE_STORE.delete(face)
    U::DEFINITION_STORE.write(@definition, nil)
    assert_raises(PhComposer::CodedError) { @scope.capture(@model) }
    U::DEFINITION_STORE.write(@definition, "window_type_id" => @type.fetch("id"))
    unit = add_unit
    U::STORE.write(unit, record.merge("anchor" => "invalid"))
    assert_raises(PhComposer::CodedError) { @scope.capture(@model) }
    refute @scope.unchanged?(@model, before)
  end

  def test_missing_definition_and_non_json_attributes_fail_closed
    before = @scope.capture(@model)
    @definition.set_attribute("ph_composer.outside", "invalid", Float::NAN)
    assert_raises(PhComposer::CodedError) { @scope.capture(@model) }
    refute @scope.unchanged?(@model, before)
    @model.definitions.remove(@definition)
    assert_raises(PhComposer::CodedError) { @scope.capture(@model) }
    refute @scope.unchanged?(@model, before)
  end

  def test_nested_group_storage_identity_survives_native_undo
    group = @definition.entities.add_group
    group.entities.add_face([[0, 0, 0], [1, 0, 0], [0, 1, 0]].map { |point| Geom::Point3d.new(*point) })
    before = @scope.capture(@model)
    @model.start_operation("Synthetic definition edit", true)
    group.entities.clear!
    @model.commit_operation
    refute @scope.unchanged?(@model, before)
    @model.undo
    assert @scope.unchanged?(@model, before)
  end

  def test_null_definition_and_pane_stamps_are_not_absence
    [[U::DEFINITION_STORE, @definition],
     [U::PANE_STORE, @definition.entities.grep(Sketchup::Face).first]].each do |store, entity|
      original = store.read(entity)
      before = @scope.capture(@model)
      entity.set_attribute(store.dictionary, store.key, "null")
      assert_raises(PhComposer::CodedError) { @scope.capture(@model) }
      refute @scope.unchanged?(@model, before)
      store.write(entity, original)
    end
  end
end
