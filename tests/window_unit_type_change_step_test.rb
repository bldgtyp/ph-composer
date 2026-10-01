# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/type_change_step"
require_relative "../src/ph_composer/features/windows/units/identity_step"

class WindowUnitTypeChangeStepTest < PhComposerTestCase
  include WindowRecordFixtures
  U = PhComposer::Windows::Units

  def setup
    super
    @model = Sketchup.active_model
    @before = window_record("columns_m" => [1.0], "rows_m" => [1.5])
    @after = PhComposer::DeepCopy.call(@before).merge("columns_m" => [2.0], "rows_m" => [2.5])
    @definition = U::DefinitionWriter.create(:model => @model, :type => @before,
      :plan => U::DefinitionPlan.build(@before))
    U::DefinitionIndex.write(@model, { @before.fetch("id") => @definition.persistent_id }, :expected => {})
  end

  def unit(anchor = "sill_center", matrix: Geom::Transformation.new, entities: @model.entities, definition: @definition)
    item = entities.add_instance(definition, matrix)
    U.write(item, "id" => window_allocator.call("wun"), "schema_version" => 1,
      "window_type_id" => @before.fetch("id"), "anchor" => anchor, "user_data" => { "literal" => [1] })
    item
  end

  def step(**options)
    U::TypeChangeStep.new(:model => @model, :before => @before, :after => @after, **options)
  end

  def test_all_nine_anchors_survive_resize_for_nested_scaled_and_mirrored_units
    group = @model.entities.add_group
    group.transformation = Geom::Transformation.translation([100, 200, 300])
    matrices = [Geom::Transformation.new,
      Geom::Transformation.new([-2, 0, 0, 0, 0.4, 3, 0, 0, 0, 0, 1, 0, 400, 500, 600, 1])]
    U::Anchors::ALL.each do |anchor|
      matrices.each { |matrix| unit(anchor, :matrix => matrix, :entities => group.entities) }
    end
    old_plan = U::DefinitionPlan.build(@before)
    old = U::Occurrences.all(@model).to_h do |item|
      [item.path, [U::WorldGeometry.anchor(old_plan, item.record.fetch("anchor"), item.transform.to_a), item.record]]
    end
    before_native = scope.capture(@model)
    change = step
    assert change.needed?
    @model.start_operation("Change Window Type")
    change.apply(@model, {})
    @model.commit_operation
    new_plan = U::DefinitionPlan.build(@after)
    U::Occurrences.all(@model).each do |item|
      point = U::WorldGeometry.anchor(new_plan, item.record.fetch("anchor"), item.transform.to_a)
      point.zip(old.fetch(item.path).first).each { |actual, expected| assert_in_delta expected, actual, 1e-12 }
      assert_equal old.fetch(item.path).last, item.record
    end
    after = scope.capture(@model)
    assert @model.undo
    assert_equal before_native, scope.capture(@model)
    assert_equal old_plan.panes.first.element_id,
      U::PANE_STORE.read(@model.definitions.first.entities.first).fetch("element_id")
    assert @model.redo
    assert_equal after, scope.capture(@model)
    assert_equal 1, @model.operation_starts.length
  end

  def test_name_only_change_renames_canonical_without_rebuilding_geometry
    item = unit
    @after = @before.merge("name" => "Renamed")
    original = @definition.entities.first
    matrix = item.transformation.to_a
    change = step
    change.apply(@model, {})
    assert_equal "PhComposer_Window_Renamed", @definition.name
    assert_same original, @definition.entities.first
    assert_equal matrix, item.transformation.to_a
    assert_empty change.affected
  end

  def test_products_operations_install_and_notes_do_not_write_native_geometry
    item = unit
    @after = PhComposer::DeepCopy.call(@before)
    @after.merge!("notes" => "New note", "install_depth_m" => 0.2)
    @after.fetch("elements").first.merge!("glazing_id" => "glz_other",
      "frames" => W::Types::SIDES.to_h { |side| [side, "frm_other"] },
      "installs" => W::Types::SIDES.to_h { |side| [side, "psi_other"] },
      "operation" => { "type" => "swing", "directions" => ["left"] })
    old = scope.capture(@model)
    original = @definition.entities.first
    change = step
    refute change.needed?
    change.apply(@model, {})
    assert_equal old, scope.capture(@model)
    assert_same original, @definition.entities.first
    assert_equal "sill_center", U.read(item).fetch("anchor")
  end

  def test_detached_make_unique_definition_and_its_instance_are_untouched
    unit
    detached = U::DefinitionWriter.create(:model => @model, :type => @before,
      :plan => U::DefinitionPlan.build(@before))
    copy = unit("center", :definition => detached)
    matrix = copy.transformation.to_a
    face = detached.entities.first
    step.apply(@model, {})
    assert_same face, detached.entities.first
    assert_equal matrix, copy.transformation.to_a
    assert_equal 1.0, U::WorldGeometry.map(U::DefinitionPlan.build(@before), matrix).outer_polygon_m[1][0]
  end

  def test_stale_matrix_glue_record_and_definition_geometry_refuse_before_any_write
    item = unit
    mutations = [-> { item.transformation = Geom::Transformation.translation([1, 0, 0]) },
      -> { item.glued_to = host_face }, -> { U.write(item, U.read(item).merge("user_data" => { "new" => [2] })) },
      -> { @definition.entities.first.reverse! }]
    mutations.each do |mutate|
      change = step
      @model.start_operation("Drift")
      mutate.call
      drift = scope.capture(@model)
      error = assert_raises(PhComposer::CodedError) { change.apply(@model, {}) }
      assert_equal "target.changed", error.code
      assert_equal drift, scope.capture(@model)
      @model.abort_operation
      @definition = @model.definitions.first
      item = @model.entities.grep(Sketchup::ComponentInstance).first
    end
  end

  def test_locked_shared_storage_and_editing_canonical_definition_refuse
    item = unit
    item.locked = true
    assert_equal "target.locked", refusal { step }
    item.locked = false
    @model.active_path = [item]
    assert_equal "window.definition_editing", refusal { step }
    @model.active_path = nil
    @model.entities.delete(item)
    parent = @model.definitions.add("Shared parent")
    parent.entities << item
    @model.entities.add_instance(parent, Geom::Transformation.new)
    assert_equal "target.shared_definition", refusal { step }
  end

  def test_unrecorded_canonical_instance_refuses_instead_of_resizing_without_anchor
    @model.entities.add_instance(@definition, Geom::Transformation.new)
    assert_equal "record.unreadable", refusal { step }
  end

  def test_expected_identity_repair_records_are_composable_without_exempting_other_drift
    item = unit
    occurrence = U::Occurrences.all(@model).first
    repaired = occurrence.record.merge("id" => window_allocator.call("wun"))
    change = step(:expected_records => { occurrence.path => repaired })
    U.write(item, repaired)
    change.apply(@model, {})
    assert_equal repaired, U.read(item)
    @before, @after = @after, @before
    next_change = step
    item.set_attribute("ph_composer.outside", "literal", "drift")
    assert_equal "target.changed", refusal { next_change.apply(@model, {}) }
  end

  def test_copy_identity_repair_and_type_geometry_share_one_enclosing_undo
    first = unit
    copy = unit("center")
    U.write(copy, U.read(first).merge("anchor" => "center"))
    before_native = scope.capture(@model)
    repairs = U::IdentityPlan.build(U::Occurrences.all(@model), :identity => window_allocator)
    expected = repairs.to_h { |repair| [repair.reference.fetch("entity_path"), repair.after] }
    change = step(:expected_records => expected)
    @model.start_operation("Repair copies and resize")
    U::IdentityStep.new(repairs).apply(@model, {})
    change.apply(@model, {})
    @model.commit_operation
    refute_equal U.read(first).fetch("id"), U.read(copy).fetch("id")
    after_native = scope.capture(@model)
    assert @model.undo
    assert_equal before_native, scope.capture(@model)
    assert @model.redo
    assert_equal after_native, scope.capture(@model)
    assert_equal 1, @model.operation_starts.length
  end

  def test_glued_resize_requires_explicit_host_and_other_unit_inventory
    item = unit("head_left")
    item.glued_to = host_face
    assert_equal "window.host_required", refusal { step }
    host = host_for(item)
    assert_equal "window.host_required", refusal { step(:hosts => { [item.persistent_id] => host }) }
    change = step(:hosts => { [item.persistent_id] => host }, :other_polygons_m => { [item.persistent_id] => [] })
    change.apply(@model, {})
    assert_equal 2.0, @after.fetch("columns_m").sum
  end

  def test_overhang_holes_and_other_unit_overlap_are_refused_while_planning
    item = unit("head_left")
    item.glued_to = host_face(1.1)
    assert_equal "window.overhang", refusal { host_step(item) }
    item.glued_to = host_face(4, :hole => [[1.4, -0.8, 0], [1.6, -0.8, 0], [1.6, -0.6, 0], [1.4, -0.6, 0]])
    assert_equal "window.overhang", refusal { host_step(item) }
    item.glued_to = host_face
    other = [[1.8, -1, 0], [2.3, -1, 0], [2.3, -0.5, 0], [1.8, -0.5, 0]]
    assert_equal "window.overlap", refusal { host_step(item, [other]) }
  end

  def test_resized_canonical_units_are_checked_against_one_another
    first = unit("head_left")
    second = unit("head_left", :matrix => Geom::Transformation.translation([1.5 / 0.0254, 0, 0]))
    first.glued_to = second.glued_to = host_face
    hosts = [first, second].to_h { |item| [[item.persistent_id], host_for(item)] }
    assert_equal "window.overlap", refusal { step(:hosts => hosts, :other_polygons_m => hosts.transform_values { [] }) }
  end

  def test_host_loop_only_drift_refuses_before_rebuilding_definition
    item = unit("head_left")
    item.glued_to = host_face
    change = host_step(item)
    item.glued_to.replace_outline!([[0, 0, 0], [3, 0, 0], [3, -3, 0], [0, -3, 0]].map do |point|
      Geom::Point3d.new(*point.map { |value| value / 0.0254 })
    end)
    face = @definition.entities.first
    assert_equal "target.changed", refusal { change.apply(@model, {}) }
    assert_same face, @definition.entities.first
  end

  def test_glued_resize_in_nonuniform_mirrored_parent_uses_actual_parent_basis
    group = @model.entities.add_group
    group.transformation = Geom::Transformation.new([0, -2, 0, 0, 3, 0, 0, 0, 0, 0, -0.5, 0, 100, 200, 300, 1])
    item = unit("head_left", :entities => group.entities,
      :matrix => Geom::Transformation.new([0.6, 0, 0, 0, 0.4, 0.7, 0, 0, 0, 0, 1, 0, 1.5 / 0.0254, 0, 0, 1]))
    item.glued_to = host_face
    group.entities << item.glued_to
    host = W::Placement::Host.new(:entity => item.glued_to, :parent_path => [group.persistent_id],
      :transform => group.transformation, :values => {}, :geometry => PhComposer::FaceGeometry.capture(
        item.glued_to, group.transformation))
    path = [group.persistent_id, item.persistent_id]
    change = step(:hosts => { path => host }, :other_polygons_m => { path => [] })
    point = U::WorldGeometry.anchor(U::DefinitionPlan.build(@before), "head_left",
      (group.transformation * item.transformation).to_a)
    change.apply(@model, {})
    actual = U::WorldGeometry.anchor(U::DefinitionPlan.build(@after), "head_left",
      (group.transformation * item.transformation).to_a)
    point.zip(actual).each { |expected, value| assert_in_delta expected, value, 1e-12 }
  end

  private

  def scope
    U::MutationScope.new(:definition_ids => [@definition.persistent_id])
  end

  def refusal
    assert_raises(PhComposer::CodedError) { yield }.code
  end

  def host_face(width = 4, hole: nil)
    loops = [[[0, 0, 0], [width, 0, 0], [width, -3, 0], [0, -3, 0]]]
    loops << hole if hole
    points = loops.map { |loop| loop.map { |point| Geom::Point3d.new(*point.map { |value| value / 0.0254 }) } }
    face = Sketchup::Face.new(Sketchup::Entities.allocate_persistent_id, {}, :points => points.first,
      :holes => points.drop(1))
    @model.entities << face
    face
  end

  def host_for(item)
    W::Placement::Host.new(:entity => item.glued_to, :parent_path => [], :transform => Geom::Transformation.new,
      :reference => {}, :values => {}, :geometry => PhComposer::FaceGeometry.capture(item.glued_to,
        Geom::Transformation.new))
  end

  def host_step(item, polygons = [])
    path = [item.persistent_id]
    step(:hosts => { path => host_for(item) }, :other_polygons_m => { path => polygons })
  end
end
