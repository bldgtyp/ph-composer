# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/definition_writer"
require_relative "../src/ph_composer/features/windows/units/remove_step"
require_relative "../src/ph_composer/features/windows/units/identity_step"

class WindowUnitRemoveStepTest < PhComposerTestCase
  include WindowRecordFixtures
  U = PhComposer::Windows::Units

  def setup
    super
    @model = Sketchup.active_model
    @type = window_record
    @definition = U::DefinitionWriter.create(:model => @model, :type => @type,
      :plan => U::DefinitionPlan.build(@type))
    @group = @model.entities.add_group
    @face = @group.entities.add_face([Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(100, 0, 0),
      Geom::Point3d.new(100, 100, 0)])
    @record = { "id" => "wun_AAAAAAAAAAAA", "schema_version" => 1, "window_type_id" => @type.fetch("id"),
      "anchor" => "sill_center", "user_data" => { "literal" => ["preserve"] } }
    @unit = @group.entities.add_instance(@definition, Geom::Transformation.translation([20, 30, 40]))
    @unit.glued_to = @face
    U.write(@unit, @record)
    @reference = U::Occurrences.all(@model).first.reference
  end

  def removal(record = @record)
    U::RemoveStep.new(:model => @model, :reference => @reference, :expected_record => record)
  end

  def capture
    U::MutationScope.new(:definition_ids => [@definition.persistent_id]).capture(@model)
  end

  def test_remove_erases_only_the_explicit_instance_and_one_undo_redo_restores_exact_glue_and_sharing
    second = @group.entities.add_instance(@definition, Geom::Transformation.new)
    U.write(second, @record.merge("id" => "wun_BBBBBBBBBBBB"))
    before = capture
    step = removal
    assert_equal before, capture
    @model.start_operation("Remove Window", true)
    step.apply(@model, {})
    @model.commit_operation
    after = capture
    assert_equal [second], U::Occurrences.all(@model).map(&:entity)
    assert_equal [@face, second], @group.entities.to_a
    assert_equal [@definition], @model.definitions.to_a
    assert @model.undo
    assert_equal before, capture
    restored = U::Occurrences.all(@model)
    assert_same restored.first.entity.definition, restored.last.entity.definition
    assert_equal @face.persistent_id, restored.first.entity.glued_to.persistent_id
    assert @model.redo
    assert_equal after, capture
    assert_equal 1, @model.operation_starts.length
    assert_equal "removed", step.affected.first.fetch("change")
  end

  def test_projected_identity_repair_composes_and_reference_removal_uses_original_exact_preimage
    expected = @record.merge("id" => "wun_BBBBBBBBBBBB", "user_data" => { "literal" => ["projected"] })
    step = removal(expected)
    typed = step.removal(:before_record => @record)
    assert_instance_of PhComposer::Records::ReferenceRemoval, typed
    assert_equal @reference.fetch("entity_path"), typed.key
    assert_equal @record, typed.before
    stored = PhComposer::Records::ReferenceEntry.new(:kind => typed.kind, :key => typed.key, :record => @record)
    copied = PhComposer::Records::ReferenceEntry.new(:kind => typed.kind, :key => [999998], :record => @record)
    projected = PhComposer::Records::ReferencePlan.new(:entries => [], :removals => [typed]).project([stored, copied])
    assert_equal [copied], projected
    typed.before.fetch("user_data").fetch("literal") << "detached"
    assert_equal @record, step.removal(:before_record => @record).before
    identity = U::IdentityStep.new([U::IdentityPlan::Update.new(:reference => @reference,
      :before => @record, :after => expected)])
    before = capture
    @model.start_operation("Repair and remove", true)
    identity.apply(@model, {})
    step.apply(@model, {})
    @model.commit_operation
    assert_empty U::Occurrences.all(@model)
    assert_equal "wun_BBBBBBBBBBBB", step.affected.first.fetch("id")
    assert @model.undo
    assert_equal before, capture
  end

  def test_stale_record_native_transform_definition_geometry_or_glue_refuses_before_erasure
    step = removal
    U.write(@unit, @record.merge("anchor" => "head_left"))
    assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    U.write(@unit, @record)
    @unit.transformation = Geom::Transformation.new
    assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    @unit.transformation = Geom::Transformation.translation([20, 30, 40])
    @unit.glued_to = nil
    assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    @unit.glued_to = @face
    @definition.entities.first.reverse!
    assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    assert_includes @group.entities.to_a, @unit
    assert_empty @model.operation_starts
  end

  def test_locked_shared_parent_and_missing_reference_refuse
    step = removal
    @unit.locked = true
    assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    @unit.locked = false
    @model.entities << Sketchup::Group.new(900001, @group.entities)
    assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    assert_raises(PhComposer::CodedError) { removal }
    missing = @reference.merge("entity_path" => [999999])
    assert_raises(PhComposer::CodedError) do
      U::RemoveStep.new(:model => @model, :reference => missing, :expected_record => @record)
    end
  end

  def test_silent_native_erasure_failure_refuses_and_caller_abort_restores_state
    step = removal
    before = capture
    @model.start_operation("Declined erase", true)
    @group.entities.define_singleton_method(:erase_entities) { |_entity| true }
    error = assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    assert_equal "geometry.failed", error.code
    @model.abort_operation
    assert_equal before, capture
  end

  def test_descriptor_and_removal_detach_inputs_and_report_occurrence_not_id_wide_exclusion
    step = removal
    description = step.descriptor
    description.fetch("expected_record").fetch("user_data").fetch("literal") << "changed"
    assert_equal ["preserve"], step.descriptor.dig("expected_record", "user_data", "literal")
    assert_equal @reference, step.affected.first.fetch("reference")
    assert_equal U::REFERENCE_KIND, step.removal(:before_record => @record).kind
    assert_empty step.temporary_ids
    assert_empty @model.operation_starts
  end
end
