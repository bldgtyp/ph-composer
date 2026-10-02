# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/flip_step"
require_relative "../src/ph_composer/features/windows/units/identity_step"

class WindowUnitFlipStepTest < PhComposerTestCase
  include WindowRecordFixtures
  U = PhComposer::Windows::Units
  P = PhComposer::Windows::Placement

  def setup
    super
    @model = Sketchup.active_model
    cells = 3.times.map { |column| W::Types.blank(0, column, :identity => window_allocator) }
    cells[1]["kind"] = "empty"
    @source = window_record("columns_m" => [0.4, 0.3, 0.8], "rows_m" => [1.5], "elements" => cells)
    W::Types::KIND.store.write(@model, @source)
    @definition = U::DefinitionWriter.create(:model => @model, :type => @source,
      :plan => U::DefinitionPlan.build(@source))
    U::DefinitionIndex.write(@model, { @source.fetch("id") => @definition.persistent_id }, :expected => {})
    @target = target_type
    @unit = unit
  end

  def target_type
    result = W::GridOperations.apply(@source, "flip", {}, :identity => window_allocator)
    result["id"] = window_allocator.call("wnt")
    result["name"] = "Flipped Type"
    result.fetch("elements").each { |cell| cell["id"] = window_allocator.call("wel") }
    result
  end

  def unit(anchor = "sill_center", matrix = Geom::Transformation.scaling(-1, 1, 1))
    entity = @model.entities.add_instance(@definition, matrix)
    U.write(entity, "id" => window_allocator.call("wun"), "schema_version" => 1,
      "window_type_id" => @source.fetch("id"), "anchor" => anchor,
      "user_data" => { "literal" => ["preserve"] },
      "extension_data" => { "outside.example" => { "version" => 1, "payload" => { "note" => "literal" } } })
    entity
  end

  def occurrence(entity = @unit)
    U::Occurrences.all(@model).find { |item| item.entity.equal?(entity) }
  end

  def step(expected = U.read(@unit), other_polygons_m: [], **options)
    U::FlipStep.new(:model => @model, :source_type => @source, :target_type => @target,
      :reference => occurrence.reference, :expected_record => expected,
      :other_polygons_m => other_polygons_m, **options)
  end

  def panes(plan, matrix)
    U::WorldGeometry.map(plan, matrix).panes.map { |pane| pane.polygon_m.map { |point|
      point.map { |value| value.round(9) }
    }.sort }.sort
  end

  def capture
    [U::MutationScope.new(:definition_ids => @model.definitions.map(&:persistent_id)).capture(@model),
     W::Types::KIND.store.ids(@model).map { |id| W::Types::KIND.store.read(@model, id) }]
  end

  def test_asymmetric_visual_panes_metadata_and_anchor_survive_one_operation_exact_undo_redo
    plan = U::DefinitionPlan.build(@source)
    before_panes = panes(plan, occurrence.transform.to_a)
    fixed = U::WorldGeometry.anchor(plan, U.read(@unit).fetch("anchor"), occurrence.transform.to_a)
    before_record = U.read(@unit)
    before = capture
    flip = step
    assert_nil W::Types::KIND.store.read(@model, @target.fetch("id"))
    @model.start_operation("New flipped Type", true)
    flip.apply(@model, {})
    W::Types::KIND.store.write(@model, @target)
    @model.commit_operation
    after = capture
    after_record = U.read(@unit)
    target_plan = U::DefinitionPlan.build(@target)
    assert_equal before_panes, panes(target_plan, occurrence.transform.to_a)
    actual_anchor = U::WorldGeometry.anchor(target_plan, after_record.fetch("anchor"), occurrence.transform.to_a)
    fixed.zip(actual_anchor).each do |a, b|
      assert_in_delta a, b, 1e-10
    end
    assert_equal before_record.merge("window_type_id" => @target.fetch("id")), after_record
    refute U::WorldGeometry.transform_state(occurrence.transform.to_a).mirrored
    assert_same U::DefinitionIndex.resolve(@model, @target.fetch("id")), @unit.definition
    assert_equal 2, @model.definitions.length
    assert @model.undo
    assert_equal before, capture
    assert @model.redo
    assert_equal after, capture
    assert_equal 1, @model.operation_starts.length
  end

  def test_all_nine_anchor_labels_swap_left_right_and_preserve_the_same_physical_point
    U::Anchors::ALL.each_with_index do |anchor, index|
      @target = target_type
      transform = Geom::Transformation.translation([(index * 3 + 10) / 0.0254, 0, 0]) *
        Geom::Transformation.scaling(-1, 1, 1)
      @unit = unit(anchor, transform)
      fixed = U::WorldGeometry.anchor(U::DefinitionPlan.build(@source), anchor, occurrence.transform.to_a)
      step.apply(@model, {})
      W::Types::KIND.store.write(@model, @target)
      swapped = anchor.end_with?("left") ? anchor.sub("left", "right") : anchor.sub("right", "left")
      assert_equal swapped, U.read(@unit).fetch("anchor")
      actual = U::WorldGeometry.anchor(U::DefinitionPlan.build(@target), swapped, occurrence.transform.to_a)
      fixed.zip(actual).each { |a, b| assert_in_delta a, b, 1e-10 }
    end
  end

  def test_z_only_normal_basis_mirror_preserves_xy_panes_and_reports_no_inplane_scale
    @unit.transformation = Geom::Transformation.scaling(1, 1, -2)
    old = panes(U::DefinitionPlan.build(@source), occurrence.transform.to_a)
    flip = step
    flip.apply(@model, {})
    assert_equal old, panes(U::DefinitionPlan.build(@target), occurrence.transform.to_a)
    refute U::WorldGeometry.transform_state(occurrence.transform.to_a).mirrored
    assert_empty flip.findings
  end

  def test_existing_scale_and_shear_are_preserved_with_explicit_remaining_findings
    @unit.transformation = Geom::Transformation.new([-2, 0, 0, 0, 0.5, 3, 0, 0, 0, 0, 1, 0, 100, 200, 0, 1])
    old = panes(U::DefinitionPlan.build(@source), occurrence.transform.to_a)
    flip = step
    assert_equal %w[scaled sheared], flip.findings.map { |finding| finding.fetch("code") }.sort
    flip.apply(@model, {})
    assert_equal old, panes(U::DefinitionPlan.build(@target), occurrence.transform.to_a)
    state = U::WorldGeometry.transform_state(occurrence.transform.to_a)
    assert state.scaled
    assert state.sheared
    refute state.mirrored
  end

  def host
    points = [[-4, -4, 0], [4, -4, 0], [4, 4, 0], [-4, 4, 0]].map { |point|
      Geom::Point3d.new(*point.map { |value| value / 0.0254 })
    }
    face = @model.entities.add_face(points)
    @unit.glued_to = face
    P::Host.new(:entity => face, :entities => @model.entities, :parent_path => [],
      :transform => Geom::Transformation.new, :reference => { "zone_id" => "zone_synthetic" }, :values => {},
      :geometry => PhComposer::FaceGeometry.capture(face, Geom::Transformation.new))
  end

  def test_glue_and_full_world_outline_fit_are_preserved_without_native_geometry_movement
    public_host = host
    flip = step(U.read(@unit), :host => public_host)
    flip.apply(@model, {})
    assert_same public_host.entity, @unit.glued_to
    assert_equal 2, @model.definitions.length
    assert_empty @model.operation_starts
  end

  def test_identity_projection_composes_and_final_reference_plan_names_new_type_and_anchor
    before_record = U.read(@unit).merge("anchor" => "head_left")
    U.write(@unit, before_record)
    expected = before_record.merge("id" => "wun_ZZZZZZZZZZZZ")
    flip = step(expected, :expected_records => { occurrence.path => expected })
    repair = U::IdentityStep.new([U::IdentityPlan::Update.new(:reference => occurrence.reference,
      :before => before_record, :after => expected)])
    repair.apply(@model, {})
    flip.apply(@model, {})
    assert_equal expected.merge("window_type_id" => @target.fetch("id"), "anchor" => "head_right"), U.read(@unit)
    assert_equal U.read(@unit), flip.reference_entries.first.record
    assert_instance_of PhComposer::Records::ReferencePlan, flip.reference_plan
    assert_includes flip.temporary_ids, @target.fetch("id")
  end

  def test_target_appearing_source_drift_locks_and_native_geometry_changes_refuse_before_writes
    flip = step
    W::Types::KIND.store.write(@model, @target)
    assert_raises(PhComposer::CodedError) { flip.apply(@model, {}) }
    W::Types::KIND.store.delete(@model, @target.fetch("id"))
    @unit.locked = true
    assert_raises(PhComposer::CodedError) { flip.apply(@model, {}) }
    @unit.locked = false
    @definition.entities.first.reverse!
    assert_raises(PhComposer::CodedError) { flip.apply(@model, {}) }
    assert_raises(PhComposer::CodedError) { step }
    @definition.entities.first.reverse!
    W::Types::KIND.store.write(@model, @source.merge("notes" => "Changed elsewhere"))
    assert_raises(PhComposer::CodedError) { flip.apply(@model, {}) }
    assert_equal 1, @model.definitions.length
  end

  def test_nonmirrored_or_nonflipped_target_refuses_and_unselected_units_stay_unchanged
    @unit.transformation = Geom::Transformation.new
    assert_raises(PhComposer::CodedError) { step }
    @unit.transformation = Geom::Transformation.scaling(-1, 1, 1)
    target = @target
    @target = @target.merge("columns_m" => @source.fetch("columns_m"))
    assert_raises(PhComposer::CodedError) { step }
    @target = target
    other = unit("center", Geom::Transformation.translation([500, 0, 0]))
    old = [U.read(other), other.transformation.to_a, other.definition]
    step.apply(@model, {})
    assert_equal old, [U.read(other), other.transformation.to_a, other.definition]
  end

  def test_inactive_model_is_explicitly_targeted_and_its_source_edit_context_refuses
    active = Sketchup.active_model
    Sketchup.active_model = Sketchup::Model.new
    flip = step
    @model.active_path = [@unit]
    assert_equal "window.definition_editing", assert_raises(PhComposer::CodedError) { step }.code
    assert_equal "window.definition_editing", assert_raises(PhComposer::CodedError) { flip.apply(@model, {}) }.code
    assert_equal 1, @model.definitions.length
    @model.active_path = nil
    flip.apply(@model, {})
    assert_equal @target.fetch("id"), U.read(@unit).fetch("window_type_id")
    assert_empty Sketchup.active_model.definitions.to_a
  ensure
    Sketchup.active_model = active
  end

  def test_overlapping_unglued_outline_refuses_and_reserved_target_index_key_cannot_be_overwritten
    polygon = U::WorldGeometry.map(U::DefinitionPlan.build(@source), occurrence.transform.to_a).outer_polygon_m
    error = assert_raises(PhComposer::CodedError) { step(:other_polygons_m => [polygon]) }
    assert_equal "window.overlap", error.code
    index = U::DefinitionIndex.read(@model)
    reserved = U::DefinitionWriter.create(:model => @model, :type => @target,
      :plan => U::DefinitionPlan.build(@target))
    U::DefinitionIndex.write(@model, index.merge(@target.fetch("id") => reserved.persistent_id), :expected => index)
    assert_equal "target.changed", assert_raises(PhComposer::CodedError) { step }.code
    assert_equal 2, @model.definitions.length
  end

  def test_failed_native_glue_restoration_can_abort_fresh_definition_index_and_unit_changes
    public_host = host
    flip = step(:host => public_host)
    before = capture
    @model.start_operation("Failed flip", true)
    @unit.define_singleton_method(:glued_to=) { |_face| @glued_to = nil }
    assert_equal "geometry.failed", assert_raises(PhComposer::CodedError) { flip.apply(@model, {}) }.code
    @model.abort_operation
    assert_equal before, capture
  end
end
