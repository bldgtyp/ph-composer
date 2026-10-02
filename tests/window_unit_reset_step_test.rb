# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/place_step"
require_relative "../src/ph_composer/features/windows/units/identity_step"
require_relative "../src/ph_composer/features/windows/units/reset_step"

class WindowUnitResetStepTest < PhComposerTestCase
  include WindowRecordFixtures
  U = PhComposer::Windows::Units
  P = PhComposer::Windows::Placement

  def setup
    super
    @model = Sketchup.active_model
    @type = window_record("columns_m" => [0.7], "rows_m" => [1.5])
    W::Types::KIND.store.write(@model, @type)
    @group = @model.entities.add_group
    @face = @group.entities.add_face([[0, 0, 0], [12, 0, 0], [12, 0, 8], [0, 0, 8]].map { |point|
      Geom::Point3d.new(*point.map { |value| value / 0.0254 })
    })
    @host = zone_host(@face, @group)
    @first = place("wun_AAAAAAAAAAAA", [2, 0, 1])
  end

  def place(id, point)
    record = { "id" => id, "schema_version" => 1, "window_type_id" => @type.fetch("id"),
      "anchor" => "sill_center", "user_data" => { "literal" => ["preserve"] } }
    slots = {}
    U::PlaceStep.new(:model => @model, :host => @host, :type => @type, :record => record,
      :point_m => point).apply(@model, slots)
    U::Occurrences.resolve(@model, slots.fetch(id)).entity
  end

  def occurrence(entity)
    U::Occurrences.all(@model).find { |item| item.path.last == entity.persistent_id }
  end

  def item(entity, record = U.read(entity))
    { :reference => occurrence(entity).reference, :expected_record => record }
  end

  def reset(selected = [item(@first)], **options)
    current = U::Occurrences.all(@model)
    hosts = current.to_h { |entry| [entry.path, @host] }
    inventory = current.to_h do |entry|
      [entry.path, U::WorldGeometry.map(U::DefinitionPlan.build(@type), entry.transform.to_a).outer_polygon_m]
    end
    U::ResetStep.new(:model => @model, :type => @type, :items => selected,
      :hosts => hosts, :outline_inventory_m => inventory, **options)
  end

  def capture
    U::MutationScope.new(:definition_ids => @model.definitions.map(&:persistent_id)).capture(@model)
  end

  def anchor(entity)
    U::WorldGeometry.anchor(U::DefinitionPlan.build(@type), U.read(entity).fetch("anchor"),
      occurrence(entity).transform.to_a)
  end

  def scale(entity, x = 2, y = 1.3, z = 1)
    entity.transformation *= Geom::Transformation.scaling(x, y, z)
  end

  def test_selected_scale_reset_preserves_physical_anchor_and_one_undo_redo_restores_exact_native_state
    scale(@first)
    fixed = anchor(@first)
    record = U.read(@first)
    before = capture
    step = reset
    assert step.needed?
    @model.start_operation("Reset Window", true)
    step.apply(@model, {})
    @model.commit_operation
    after = capture
    fixed.zip(anchor(@first)).each { |a, b| assert_in_delta a, b, 1e-10 }
    assert U::WorldGeometry.transform_state(occurrence(@first).transform.to_a).rigid?
    assert_equal record, U.read(@first)
    assert_same @face, @first.glued_to
    assert @model.undo
    assert_equal before, capture
    assert @model.redo
    assert_equal after, capture
    assert_equal 1, @model.operation_starts.length
  end

  def test_world_basis_normalization_uses_parent_inverse_and_gram_schmidt_without_moving_anchor
    @group.transformation = Geom::Transformation.new([0, 2, 0, 0, -3, 0, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 1])
    @first.glued_to = nil
    matrix = @first.transformation.to_a
    matrix[4] += 0.5
    @first.transformation = Geom::Transformation.new(matrix)
    fixed = anchor(@first)
    reset.apply(@model, {})
    state = U::WorldGeometry.transform_state(occurrence(@first).transform.to_a)
    refute state.scaled
    refute state.sheared
    refute state.mirrored
    fixed.zip(anchor(@first)).each { |a, b| assert_in_delta a, b, 1e-10 }
    assert_empty @model.operation_starts
  end

  def test_detached_selected_definition_repoints_but_unselected_detached_copy_remains_untouched
    detached = U::DefinitionWriter.create(:model => @model, :type => @type, :plan => U::DefinitionPlan.build(@type))
    @first.definition = detached
    second = @group.entities.add_instance(detached, Geom::Transformation.new)
    U.write(second, U.read(@first).merge("id" => "wun_BBBBBBBBBBBB"))
    second_before = second.transformation.to_a
    reset.apply(@model, {})
    assert_same U::DefinitionIndex.resolve(@model, @type.fetch("id")), @first.definition
    assert_same detached, second.definition
    assert_equal second_before, second.transformation.to_a
    assert_equal 2, @model.definitions.length
  end

  def test_edited_shared_canonical_rewrites_all_its_users_and_warns_with_affected_references
    second = place("wun_BBBBBBBBBBBB", [5, 0, 1])
    canonical = @first.definition
    canonical.entities.first.reverse!
    canonical.behavior.no_scale_mask = 4
    before = capture
    step = reset
    assert_equal 2, step.affected.length
    assert_equal 2, step.findings.first.fetch("references").length
    @model.start_operation("Reset shared Window", true)
    step.apply(@model, {})
    @model.commit_operation
    assert U::DefinitionGeometry.matches?(canonical, :type_id => @type.fetch("id"),
      :plan => U::DefinitionPlan.build(@type))
    assert_equal 127, canonical.behavior.no_scale_mask?
    assert_same canonical, second.definition
    assert_same @face, second.glued_to
    assert @model.undo
    assert_equal before, capture
  end

  def test_missing_or_differently_stamped_primary_rebuilds_one_fresh_definition_for_batch
    second = place("wun_BBBBBBBBBBBB", [5, 0, 1])
    old = @first.definition
    other_type = @type.merge("id" => "wnt_CCCCCCCCCCCC", "name" => "Other")
    other = U::DefinitionWriter.create(:model => @model, :type => other_type,
      :plan => U::DefinitionPlan.build(other_type))
    index = U::DefinitionIndex.read(@model)
    U::DefinitionIndex.write(@model, index.merge(other_type.fetch("id") => other.persistent_id), :expected => index)
    U::DEFINITION_STORE.write(old, "window_type_id" => "wnt_BBBBBBBBBBBB")
    step = reset([item(@first), item(second)])
    step.apply(@model, {})
    fresh = U::DefinitionIndex.resolve(@model, @type.fetch("id"))
    refute_same old, fresh
    assert_same fresh, @first.definition
    assert_same fresh, second.definition
    assert_equal 3, @model.definitions.length
    assert_equal other.persistent_id, U::DefinitionIndex.read(@model).fetch(other_type.fetch("id"))
    @first.definition = old
    U::DefinitionIndex::STORE.write(@model, "schema_version" => 1,
      "definitions" => { @type.fetch("id") => 999999, other_type.fetch("id") => other.persistent_id })
    reset.apply(@model, {})
    refute_equal 999999, U::DefinitionIndex.read(@model).fetch(@type.fetch("id"))
    refute_same fresh, @first.definition
    assert_same fresh, second.definition
    assert_equal other.persistent_id, U::DefinitionIndex.read(@model).fetch(other_type.fetch("id"))
  end

  def test_mirror_locks_shared_storage_and_active_canonical_edit_refuse_before_writes
    scale(@first, -1, 1)
    assert_equal "window.mirrored", assert_raises(PhComposer::CodedError) { reset }.code
    scale(@first, -1, 1)
    scale(@first)
    @first.locked = true
    assert_raises(PhComposer::CodedError) { reset }
    @first.locked = false
    @model.active_path = [@first]
    assert_equal "window.definition_editing", assert_raises(PhComposer::CodedError) { reset }.code
    @model.active_path = nil
    @model.entities << Sketchup::Group.new(900001, @group.entities)
    assert_raises(PhComposer::CodedError) { reset }
  end

  def test_stale_type_native_state_and_host_geometry_refuse_atomic_reset
    scale(@first)
    step = reset
    W::Types::KIND.store.write(@model, @type.merge("notes" => "changed"))
    assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    W::Types::KIND.store.write(@model, @type)
    @face.reverse!
    assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    @face.reverse!
    @first.definition.behavior.no_scale_mask = 4
    before = capture
    assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    assert_equal before, capture
  end

  def test_all_batch_planned_outlines_conflict_even_when_one_unit_is_unglued
    second = place("wun_BBBBBBBBBBBB", [5, 0, 1])
    second.glued_to = nil
    second.transformation = @first.transformation
    scale(@first)
    scale(second)
    before = capture
    error = assert_raises(PhComposer::CodedError) { reset([item(@first), item(second)]) }
    assert_equal "window.overlap", error.code
    assert_equal before, capture
  end

  def test_unselected_detached_same_type_outsider_blocks_overlap_and_is_not_part_of_primary_reset
    detached = U::DefinitionWriter.create(:model => @model, :type => @type, :plan => U::DefinitionPlan.build(@type))
    outsider = @group.entities.add_instance(detached, @first.transformation)
    U.write(outsider, U.read(@first).merge("id" => "wun_BBBBBBBBBBBB"))
    @first.definition.entities.first.reverse!
    before = capture
    error = assert_raises(PhComposer::CodedError) { reset }
    assert_equal "window.overlap", error.code
    assert_equal before, capture
    assert_same detached, outsider.definition
  end

  def test_glued_reset_requires_public_host_and_explicit_complete_others
    scale(@first)
    input = [item(@first)]
    assert_raises(PhComposer::CodedError) do
      U::ResetStep.new(:model => @model, :type => @type, :items => input)
    end
    assert_raises(PhComposer::CodedError) do
      U::ResetStep.new(:model => @model, :type => @type, :items => input,
        :hosts => { occurrence(@first).path => @host })
    end
  end

  def test_shared_definition_rewrite_refuses_an_unselected_locked_user_and_unknown_type_needs_explicit_swap
    second = place("wun_BBBBBBBBBBBB", [5, 0, 1])
    @first.definition.entities.first.reverse!
    second.locked = true
    before = capture
    assert_equal "target.locked", assert_raises(PhComposer::CodedError) { reset }.code
    assert_equal before, capture
    second.locked = false
    W::Types::KIND.store.delete(@model, @type.fetch("id"))
    assert_equal "window.unknown_type", assert_raises(PhComposer::CodedError) { reset }.code
  end

  def test_normal_and_z_only_scaled_units_are_noops_and_projected_identity_repair_composes
    scale(@first, 1, 1, 4)
    before = capture
    step = reset
    refute step.needed?
    assert_empty step.affected
    step.apply(@model, {})
    assert_equal before, capture
    scale(@first)
    original = U.read(@first)
    projected = original.merge("id" => "wun_BBBBBBBBBBBB")
    step = reset([item(@first, projected)], :expected_records => { occurrence(@first).path => projected })
    repair = U::IdentityStep.new([U::IdentityPlan::Update.new(:reference => occurrence(@first).reference,
      :before => original, :after => projected)])
    repair.apply(@model, {})
    step.apply(@model, {})
    assert_equal projected, U.read(@first)
    assert_empty @model.operation_starts
  end

  def test_native_glue_failure_aborts_rewritten_definition_and_all_instance_changes
    scale(@first)
    @first.definition.entities.first.reverse!
    step = reset
    before = capture
    @model.start_operation("Failed reset", true)
    @first.define_singleton_method(:glued_to=) { |_face| @glued_to = nil }
    assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    @model.abort_operation
    assert_equal before, capture
  end

  def test_unmanaged_primary_instance_in_unused_definition_refuses_shared_rewrite
    canonical = @first.definition
    unused = @model.definitions.add("Unused container")
    native = unused.entities.add_instance(canonical, Geom::Transformation.new)
    canonical.entities.first.reverse!
    before = capture
    assert_equal "record.unreadable", assert_raises(PhComposer::CodedError) { reset }.code
    assert_equal before, capture
    assert_same canonical, native.definition
    # Even a valid record in unreachable storage cannot enter an occurrence-scoped reset.
    U.write(native, U.read(@first).merge("id" => "wun_BBBBBBBBBBBB"))
    assert_equal "record.unreadable", assert_raises(PhComposer::CodedError) { reset }.code
  end

  def test_unused_storage_getting_a_primary_instance_after_preview_refuses_before_rewrite
    canonical = @first.definition
    unused = @model.definitions.add("Unused container")
    canonical.entities.first.reverse!
    step = reset
    unused.entities.add_instance(canonical, Geom::Transformation.new)
    before = capture
    assert_equal "record.unreadable", assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }.code
    assert_equal before, capture
  end

  def test_detached_repoint_cannot_discard_nested_unit_storage
    detached = U::DefinitionWriter.create(:model => @model, :type => @type, :plan => U::DefinitionPlan.build(@type))
    nested = detached.entities.add_instance(@first.definition, Geom::Transformation.new)
    U.write(nested, U.read(@first).merge("id" => "wun_BBBBBBBBBBBB"))
    @first.definition = detached
    assert_equal "window.nested_units", assert_raises(PhComposer::CodedError) { reset }.code
    assert_same detached, @first.definition
  end
end
