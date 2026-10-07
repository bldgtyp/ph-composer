# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/place_step"
require_relative "../src/ph_composer/features/windows/units/rehost_step"
require_relative "../src/ph_composer/features/windows/units/identity_step"

class WindowUnitRehostStepTest < PhComposerTestCase
  include WindowRecordFixtures

  U = PhComposer::Windows::Units
  P = PhComposer::Windows::Placement

  def setup
    super
    @model = Sketchup.active_model
    @type = window_record("columns_m" => [0.7], "rows_m" => [1.5])
    W::Types::KIND.store.write(@model, @type)
    @group = @model.entities.add_group
    @face = face(@group.entities)
    @host = host(@face)
    @record = { "id" => "wun_AAAAAAAAAAAA", "schema_version" => 1, "window_type_id" => @type.fetch("id"),
                "anchor" => "sill_center", "user_data" => { "literal" => ["preserve"] } }
    slots = {}
    U::PlaceStep.new(:model => @model, :host => @host, :type => @type, :record => @record,
                     :point_m => [2, 0, 1]).apply(@model, slots)
    @reference = slots.fetch(@record.fetch("id"))
    @unit = U::Occurrences.resolve(@model, @reference).entity
    @unit.glued_to = nil
  end

  def face(entities)
    native = [[0, 0, 0], [8, 0, 0], [8, 0, 6], [0, 0, 6]].map { |point|
      Geom::Point3d.new(*point.map { |value| value / 0.0254 })
    }
    entities << Sketchup::Face.new(Sketchup::Entities.allocate_persistent_id, {},
                                   :points => native,
                                   :normal => Geom::Vector3d.new(0, -1, 0))
    entities.to_a.last
  end

  def host(face, group = @group, values = {})
    zone_host(face, group, values)
  end

  def rehost(expected = @record, target = @host, **options)
    U::RehostStep.new(:model => @model, :reference => @reference, :expected_record => expected,
                      :host => target, :type => @type, **options)
  end

  def capture
    U::MutationScope.new(:definition_ids => @model.definitions.map(&:persistent_id)).capture(@model)
  end

  def test_rehost_changes_only_glue_and_one_undo_redo_keeps_matrix_geometry_metadata_and_definition
    before = capture
    step = rehost
    matrix = @unit.transformation.to_a
    geometry = U::DefinitionGeometry.capture(@unit.definition)
    @model.start_operation("Rehost Window", true)
    step.apply(@model, {})
    @model.commit_operation
    after = capture
    assert_same @face, @unit.glued_to
    assert_equal matrix, @unit.transformation.to_a
    assert_equal geometry, U::DefinitionGeometry.capture(@unit.definition)
    assert_equal @record, U.read(@unit)
    assert_equal 1, @model.definitions.length
    assert @model.undo
    assert_equal before, capture
    assert @model.redo
    assert_equal after, capture
    assert_equal 1, @model.operation_starts.length
    assert_equal "rehosted", step.affected.first.fetch("change")
  end

  def test_projected_identity_repair_composes_without_native_geometry_regeneration
    expected = @record.merge("id" => "wun_BBBBBBBBBBBB")
    step = rehost(expected)
    identity = U::IdentityStep.new([U::IdentityPlan::Update.new(:reference => @reference,
                                                                :before => @record, :after => expected)])
    identity.apply(@model, {})
    step.apply(@model, {})
    assert_equal expected, U.read(@unit)
    assert_same @face, @unit.glued_to
    assert_equal expected.fetch("id"), step.affected.first.fetch("id")
    assert_empty @model.operation_starts
  end

  def test_cross_parent_surface_off_plane_and_overlap_refuse_before_glue
    other = @model.entities.add_group
    foreign = host(face(other.entities), other)
    assert_raises(PhComposer::CodedError) { rehost(@record, foreign) }
    assert_raises(PhComposer::CodedError) { rehost(@record, host(@face, @group, "boundary_condition" => "Surface")) }
    shifted = face(@group.entities)
    shifted.loops.each { |loop| loop.vertices.each { |vertex| vertex.position.instance_variable_set(:@y, 10) } }
    assert_raises(PhComposer::CodedError) { rehost(@record, host(shifted)) }
    polygon = U::WorldGeometry.map(U::DefinitionPlan.build(@type),
                                   U::Occurrences.resolve(@model, @reference).transform.to_a).outer_polygon_m
    error = assert_raises(PhComposer::CodedError) { rehost(@record, @host, :existing_polygons_m => [polygon]) }
    assert_equal "window.overlap", error.code
    assert_nil @unit.glued_to
  end

  def test_stale_host_geometry_semantic_scope_record_native_matrix_and_definition_refuse
    step = rehost
    @face.reverse!
    assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    @face.reverse!
    @unit.transformation = Geom::Transformation.new
    assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    @unit.transformation = Geom::Transformation.new(step.descriptor.fetch("native_before").fetch("matrix"))
    U.write(@unit, @record.merge("anchor" => "head_left"))
    assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    U.write(@unit, @record)
    @unit.definition.entities.first.reverse!
    assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    @unit.definition.entities.first.reverse!
    scope = PhComposer::Operations::EntityScope.new([@group.persistent_id])
    guarded = rehost(@record, @host, :expected_scope => scope, :expected_state => scope.capture(@model))
    @face.set_attribute("ph_composer.synthetic", "semantics", "changed")
    assert_raises(PhComposer::CodedError) { guarded.apply(@model, {}) }
    assert_nil @unit.glued_to
  end

  def test_unit_locks_and_shared_storage_refuse_at_apply
    step = rehost
    @unit.locked = true
    assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    @unit.locked = false
    @model.entities << Sketchup::Group.new(900001, @group.entities)
    assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    assert_nil @unit.glued_to
  end

  def test_native_glue_failure_or_silent_decline_can_abort_without_moving_or_rewriting_unit
    [false, true].each do |raises|
      unit = U::Occurrences.all(@model).first.entity
      step = rehost
      before = capture
      @model.start_operation("Failed rehost", true)
      unit.define_singleton_method(:glued_to=) do |_face|
        raise "Synthetic glue failure" if raises

        nil
      end
      assert_raises(raises ? RuntimeError : PhComposer::CodedError) { step.apply(@model, {}) }
      @model.abort_operation
      assert_equal before, capture
    end
  end

  def test_descriptor_detaches_public_host_values_and_has_no_temporary_identity
    step = rehost
    data = step.descriptor
    data.fetch("expected_record").fetch("user_data").fetch("literal") << "mutated"
    assert_equal ["preserve"], step.descriptor.dig("expected_record", "user_data", "literal")
    assert_equal @reference, step.affected.first.fetch("reference")
    assert_empty step.temporary_ids
    assert_empty @model.operation_starts
  end

  def test_native_glue_that_moves_instance_is_refused_and_abort_preserves_exact_original_matrix
    step = rehost
    before = capture
    @model.start_operation("Moving glue", true)
    @unit.define_singleton_method(:glued_to=) do |face|
      @glued_to = face
      self.transformation = Geom::Transformation.translation([1, 0, 0]) * transformation
    end
    error = assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    assert_equal "geometry.failed", error.code
    @model.abort_operation
    assert_equal before, capture
  end
end
