# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/place_step"

class WindowUnitPlaceStepTest < PhComposerTestCase
  include WindowRecordFixtures

  U = PhComposer::Windows::Units
  P = PhComposer::Windows::Placement

  def setup
    super
    @model = Sketchup.active_model
    @type = window_record("columns_m" => [0.7], "rows_m" => [1.5])
    W::Types::KIND.store.write(@model, @type)
    @group = @model.entities.add_group
    @face = @group.entities.add_face([[0, 0, 0], [8, 0, 0], [8, 0, 6], [0, 0, 6]].map { |point|
      Geom::Point3d.new(*point.map { |value| value / 0.0254 })
    })
  end

  def host
    zone_host(@face, @group)
  end

  def record(id = "wun_AAAAAAAAAAAA")
    { "id" => id, "schema_version" => 1, "window_type_id" => @type.fetch("id"), "anchor" => "sill_center",
      "user_data" => { "note" => ["literal"] },
      "extension_data" => { "outside.example" => { "version" => 1, "payload" => [2] } } }
  end

  def step(id: "wun_AAAAAAAAAAAA", point_m: [2, 0, 1], **options)
    U::PlaceStep.new(:model => @model, :host => host, :type => @type, :record => record(id),
                     :point_m => point_m, **options)
  end

  def apply(placement)
    slots = {}
    placement.apply(@model, slots)
    slots.fetch(placement.temporary_ids.first)
  end

  def unit(reference)
    U::Occurrences.resolve(@model, reference).entity
  end

  def capture
    U::MutationScope.new(:definition_ids => @model.definitions.map(&:persistent_id)).capture(@model)
  end

  def test_constructor_is_read_only_and_first_placement_indexes_generated_definition_and_glues_instance
    before = capture
    placement = step
    assert_equal before, capture
    assert_empty @model.operation_starts
    @model.start_operation("Place Window", true)
    reference = apply(placement)
    @model.commit_operation
    placed = unit(reference)
    assert_equal record, U.read(placed)
    assert_same @face, placed.glued_to
    assert_equal [@group.persistent_id, placed.persistent_id], reference.fetch("entity_path")
    assert_same placed.definition, U::DefinitionIndex.resolve(@model, @type.fetch("id"))
    assert_equal 1, @model.definitions.length
    assert_equal 1, @model.operation_starts.length
    assert_equal reference, placement.affected.first.fetch("reference")
    anchor = U::WorldGeometry.anchor(U::DefinitionPlan.build(@type), "sill_center",
                                     (@group.transformation * placed.transformation).to_a)
    [2, 0, 1].zip(anchor).each { |expected, actual| assert_in_delta expected, actual, 1e-12 }
  end

  def test_two_placements_share_canonical_definition_and_each_enclosing_operation_undoes_exactly
    before = capture
    @model.start_operation("First placement", true)
    first = apply(step)
    @model.commit_operation
    after_first = capture
    @model.start_operation("Second placement", true)
    second = apply(step(:id => "wun_BBBBBBBBBBBB", :point_m => [4, 0, 1]))
    @model.commit_operation
    after_second = capture
    assert_same unit(first).definition, unit(second).definition
    assert_equal 1, @model.definitions.length
    assert @model.undo
    assert_equal after_first, capture
    assert @model.undo
    assert_equal before, capture
    assert @model.redo
    assert_equal after_first, capture
    assert @model.redo
    assert_equal after_second, capture
    first_unit, second_unit = U::Occurrences.all(@model).map(&:entity)
    assert_same first_unit.definition, second_unit.definition
    assert_same first_unit.glued_to, second_unit.glued_to
    assert_same @model.materials.first, first_unit.definition.entities.first.material
  end

  def test_nested_scaled_rotated_parent_uses_local_sdk_transform_but_world_anchor_and_basis_are_correct
    @group.transformation = Geom::Transformation.new([0, 2, 0, 0, -3, 0, 0, 0, 0, 0, 0.5, 0, 100, 200, 300, 1])
    target = P::Offsets.point(host.geometry, :x_m => 2, :y_m => 1)
    reference = apply(step(:point_m => target))
    placed = unit(reference)
    world = (@group.transformation * placed.transformation).to_a
    actual = U::WorldGeometry.anchor(U::DefinitionPlan.build(@type), "sill_center", world)
    target.zip(actual).each { |expected, coordinate| assert_in_delta expected, coordinate, 1e-10 }
    assert U::WorldGeometry.transform_state(world).rigid?
    assert_same @face, placed.glued_to
    assert_empty @model.operation_starts
  end

  def test_overhang_overlap_and_incomplete_type_refuse_before_native_writes
    before = capture
    assert_raises(PhComposer::CodedError) { step(:point_m => [0, 0, 1]) }
    plan = U::DefinitionPlan.build(@type)
    occupied = P::Plane.new(host.geometry).map(plan, :point_m => [2, 0, 1]).outer_polygon_m
    error = assert_raises(PhComposer::CodedError) { step(:existing_polygons_m => [occupied]) }
    assert_equal "window.overlap", error.code
    @type["rows_m"] = [nil]
    assert_raises(PhComposer::CodedError) { step }
    assert_equal before, capture
  end

  def test_stale_host_geometry_transform_lock_or_shared_parent_refuses_before_creation
    placement = step
    @group.transformation = Geom::Transformation.translation([1, 0, 0])
    assert_raises(PhComposer::CodedError) { apply(placement) }
    @group.transformation = Geom::Transformation.new
    @group.locked = true
    assert_raises(PhComposer::CodedError) { apply(placement) }
    @group.locked = false
    @model.entities << Sketchup::Group.new(900001, @group.entities)
    assert_raises(PhComposer::CodedError) { apply(placement) }
    assert_empty @model.definitions.to_a
    assert_empty U::Occurrences.all(@model)
  end

  def test_canonical_pointer_and_native_definition_edits_are_guarded_and_never_silently_rewritten
    apply(step)
    planned = step(:id => "wun_BBBBBBBBBBBB", :point_m => [4, 0, 1])
    definition = U::DefinitionIndex.resolve(@model, @type.fetch("id"))
    definition.behavior.no_scale_mask = 4
    before = capture
    error = assert_raises(PhComposer::CodedError) { apply(planned) }
    assert_equal "target.changed", error.code
    assert_equal before, capture
    assert_raises(PhComposer::CodedError) { step(:id => "wun_BBBBBBBBBBBB", :point_m => [4, 0, 1]) }
  end

  def test_missing_canonical_definition_and_stale_index_refuse_without_fallback_definition
    placement = step
    U::DefinitionIndex::STORE.write(@model, "schema_version" => 1,
                                            "definitions" => { @type.fetch("id") => 999999 })
    assert_raises(PhComposer::CodedError) { apply(placement) }
    assert_raises(PhComposer::CodedError) { step }
    assert_empty @model.definitions.to_a
  end

  def test_canonical_actual_panes_differing_from_type_refuse_and_host_normal_drift_is_guarded
    planned = step
    @face.reverse!
    assert_raises(PhComposer::CodedError) { apply(planned) }
    @face.reverse!
    wrong_type = @type.merge("columns_m" => [0.9])
    definition = U::DefinitionWriter.create(:model => @model, :type => wrong_type,
                                            :plan => U::DefinitionPlan.build(wrong_type))
    U::DefinitionIndex.write(@model, { @type.fetch("id") => definition.persistent_id }, :expected => {})
    before = capture
    error = assert_raises(PhComposer::CodedError) { step }
    assert_equal "window.definition_changed", error.code
    assert_equal before, capture
    assert_empty U::Occurrences.all(@model)
  end

  def test_authored_type_changes_and_caller_scope_changes_refuse_before_native_writes
    placement = step
    W::Types::KIND.store.write(@model, @type.merge("notes" => "Changed elsewhere"))
    assert_raises(PhComposer::CodedError) { apply(placement) }
    W::Types::KIND.store.write(@model, @type)
    scope = PhComposer::Operations::EntityScope.new([@group.persistent_id])
    placement = step(:expected_scope => scope, :expected_state => scope.capture(@model))
    @face.set_attribute("ph_composer.synthetic", "state", "changed")
    assert_raises(PhComposer::CodedError) { apply(placement) }
    assert_empty @model.definitions.to_a
  end

  def test_unit_identity_and_record_type_mismatch_refuse_before_creation
    apply(step)
    assert_raises(PhComposer::CodedError) { step(:point_m => [4, 0, 1]) }
    wrong = record("wun_BBBBBBBBBBBB").merge("window_type_id" => "wnt_BBBBBBBBBBBB")
    assert_raises(PhComposer::CodedError) do
      U::PlaceStep.new(:model => @model, :host => host, :type => @type, :record => wrong, :point_m => [4, 0, 1])
    end
    assert_equal 1, U::Occurrences.all(@model).length
  end

  def test_failed_native_glue_can_abort_new_instance_definition_material_and_index_together
    placement = step
    before = capture
    @model.start_operation("Failed placement", true)
    @group.entities.define_singleton_method(:add_instance) do |definition, transform|
      super(definition, transform).tap do |instance|
        instance.define_singleton_method(:glued_to=) { |_face| raise "Synthetic native glue failure" }
      end
    end
    assert_raises(RuntimeError) { apply(placement) }
    @model.abort_operation
    assert_equal before, capture
    assert_empty @model.definitions.to_a
    assert_empty @model.materials.to_a
  end

  def test_native_glue_that_silently_declines_is_detected_and_one_abort_restores_all_state
    placement = step
    before = capture
    @model.start_operation("Declined glue", true)
    @group.entities.define_singleton_method(:add_instance) do |definition, transform|
      super(definition, transform).tap do |instance|
        instance.define_singleton_method(:glued_to=) { |_face| nil }
      end
    end
    error = assert_raises(PhComposer::CodedError) { apply(placement) }
    assert_equal "geometry.failed", error.code
    @model.abort_operation
    assert_equal before, capture
  end

  def test_descriptor_detaches_values_and_proposal_digest_normalizes_allocated_unit_identity
    placement = step
    description = placement.descriptor
    description.fetch("record").fetch("user_data").fetch("note") << "mutated"
    assert_equal ["literal"], placement.descriptor.dig("record", "user_data", "note")
    proposal = PhComposer::Operations::Proposal.new
    proposal.add_step(placement, :scopes => [U::MutationScope.new])
    alternate = PhComposer::Operations::Proposal.new
    alternate.add_step(step(:id => "wun_BBBBBBBBBBBB"), :scopes => [U::MutationScope.new])
    assert_equal proposal.digest, alternate.digest
    assert_equal ["wun_AAAAAAAAAAAA"], placement.temporary_ids
    assert_equal "placed", placement.affected.first.fetch("change")
    assert_empty @model.operation_starts
  end
end
