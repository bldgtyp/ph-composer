# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/restore_step"

class WindowUnitRestoreStepTest < PhComposerTestCase
  include WindowRecordFixtures
  U = PhComposer::Windows::Units
  P = PhComposer::Windows::Placement

  def setup
    super
    @model = Sketchup.active_model
    @group = @model.entities.add_group
    @host_face = Sketchup::Face.new(900_001, {}, :points => native([[0, 0, 0], [8, 0, 0], [8, 0, 6], [0, 0, 6]]))
    @group.entities << @host_face
    @type = window_record("columns_m" => [0.7], "rows_m" => [1.5])
    store_type
    @matrix = [1, 0, 0, 0, 0, 0, 1, 0, 0, -1, 0, 0, 2 / 0.0254, 0, 3 / 0.0254, 1]
    @glass = @model.materials.add(U::DefinitionWriter::GLASS_NAME)
    add_panes
  end

  def native(points)
    points.map { |point| Geom::Point3d.new(*point.map { |value| value / 0.0254 }) }
  end

  def store_type
    W::Types::KIND.store.write(@model, @type)
  end

  def host
    zone_host(@host_face, @group)
  end

  def add_panes
    @panes = U::WorldGeometry.map(U::DefinitionPlan.build(@type), @matrix).panes.map do |pane|
      points = native(pane.polygon_m).map { |point| point.transform(@group.transformation.inverse) }
      edges = points.each_with_index.map do |point, index|
        edge = Sketchup::Edge.new(Sketchup::Entities.allocate_persistent_id, point, points[(index + 1) % 4])
        @group.entities << edge
        edge
      end
      face = Sketchup::Face.new(Sketchup::Entities.allocate_persistent_id, {}, :points => points, :edges => edges)
      @group.entities << face
      face.material = @glass
      face.back_material = @glass
      U::PANE_STORE.write(face, "window_type_id" => @type.fetch("id"), "element_id" => pane.element_id)
      face
    end
  end

  def clear_panes
    @group.entities.erase_entities(@panes.flat_map { |face| [face, *face.edges] })
  end

  def record
    { "id" => "wun_AAAAAAAAAAAA", "schema_version" => 1, "window_type_id" => @type.fetch("id"),
      "anchor" => U::Anchors::DEFAULT }
  end

  def step(**options)
    U::RestoreStep.new(:model => @model, :host => host, :type => @type, :record => record,
      :pane_paths => @panes.map { |face| [@group.persistent_id, face.persistent_id] },
      :existing_polygons_m => [], **options)
  end

  def apply(restore)
    slots = {}
    restore.apply(@model, slots)
    U::Occurrences.resolve(@model, slots.fetch(record.fetch("id"))).entity
  end

  def capture(restore)
    restore.scopes.map { |scope| scope.capture(@model) }
  end

  def test_equivalent_symmetric_full_pane_restores_default_anchor_and_new_identity_in_one_operation
    restore = step
    before = capture(restore)
    assert_empty @model.operation_starts
    assert_equal before, capture(restore)
    @model.start_operation("Restore", true)
    instance = apply(restore)
    @model.commit_operation
    assert_equal record, U.read(instance)
    assert_same @host_face, instance.glued_to
    assert @panes.none? { |face| @group.entities.to_a.include?(face) }
    assert_equal "restored", restore.affected.first.fetch("change")
    assert_equal 1, @model.operation_starts.length
    assert_equal ["wun_AAAAAAAAAAAA"], restore.temporary_ids
    assert_equal [], restore.definition_ids
    assert @model.undo
    assert_equal before, restore.scopes.map { |scope| scope.capture(@model) }
    assert @model.redo
    assert_equal 1, U::Occurrences.all(@model).length
  end

  def test_complete_multi_pane_set_preserves_world_geometry_and_reuses_canonical_definition
    clear_panes
    @type = window_record("columns_m" => [0.7, 1.1], "rows_m" => [1.5])
    @type["elements"] = [0, 1].map do |column|
      @type["elements"].first.merge("id" => window_allocator.call("wel"), "column_span" => [column, column])
    end
    store_type
    add_panes
    definition = U::DefinitionWriter.create(:model => @model, :type => @type, :plan => U::DefinitionPlan.build(@type))
    U::DefinitionIndex.write(@model, { @type.fetch("id") => definition.persistent_id }, :expected => {})
    restore = step
    assert_equal [definition.persistent_id], restore.definition_ids
    expected = U::WorldGeometry.map(U::DefinitionPlan.build(@type), @matrix)
    instance = apply(restore)
    assert_same definition, instance.definition
    actual = U::WorldGeometry.map(U::DefinitionPlan.build(@type), instance.transformation.to_a)
    expected.panes.zip(actual.panes).each do |a, b|
      assert U::RestoreGeometry.same_polygon?(a.polygon_m, b.polygon_m)
    end
  end

  def test_rotated_rigid_world_geometry_in_scaled_parent_is_preserved
    clear_panes
    @group.transformation = Geom::Transformation.new([2, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 1])
    axis = Math.sqrt(0.5)
    @matrix = [axis, 0, axis, 0, -axis, 0, axis, 0, 0, -1, 0, 0, 3 / 0.0254, 0, 2 / 0.0254, 1]
    add_panes
    expected = U::WorldGeometry.map(U::DefinitionPlan.build(@type), @matrix).outer_polygon_m
    restore = step
    assert_equal 3, capture(restore).length
    instance = apply(restore)
    actual = U::WorldGeometry.map(U::DefinitionPlan.build(@type),
      (@group.transformation * instance.transformation).to_a).outer_polygon_m
    assert U::RestoreGeometry.same_polygon?(expected, actual)
  end

  def test_empty_bands_with_different_possible_full_outlines_refuse
    clear_panes
    @type = window_record("columns_m" => [0.7, 1.1], "rows_m" => [1.5])
    @type["elements"] = [0, 1].map do |column|
      @type["elements"].first.merge("id" => window_allocator.call("wel"), "column_span" => [column, column])
    end
    @type["elements"][1]["kind"] = "empty"
    store_type
    add_panes
    error = assert_raises(PhComposer::CodedError) { step }
    assert_equal "window.restore_unavailable", error.code
    assert_empty @model.definitions.to_a
  end

  def test_all_empty_incomplete_missing_duplicate_and_outside_paths_refuse
    paths = @panes.map { |face| [@group.persistent_id, face.persistent_id] }
    invalid = [[], paths + paths, [[@panes.first.persistent_id]], [[@group.persistent_id, @host_face.persistent_id]]]
    invalid.each do |value|
      assert_raises(PhComposer::CodedError) { step(:pane_paths => value) }
    end
    clear_panes
    @type["elements"].first["kind"] = "empty"
    store_type
    assert_raises(PhComposer::CodedError) { step }
  end

  def test_scaled_mirrored_off_plane_and_edited_panes_refuse_before_writes
    [[2, 0, 0, 0, 0, 0, 1, 0, 0, -1, 0, 0, 80, 0, 120, 1],
     [-1, 0, 0, 0, 0, 0, 1, 0, 0, -1, 0, 0, 160, 0, 120, 1],
     [1, 0, 0, 0, 0, 0, 1, 0, 0, -1, 0, 0, 80, 1, 120, 1]].each do |matrix|
      clear_panes
      @matrix = matrix
      add_panes
      assert_raises(PhComposer::CodedError) { step }
    end
    assert_empty @model.definitions.to_a
  end

  def test_foreign_face_edge_attributes_material_and_wall_shared_edges_refuse
    face = @panes.first
    face.set_attribute("outside.example", "literal", [1])
    assert_raises(PhComposer::CodedError) { step }
    face.delete_attribute("outside.example")
    edge = face.edges.first
    edge.set_attribute("ph_composer.other", "literal", [2])
    assert_raises(PhComposer::CodedError) { step }
    edge.delete_attribute("ph_composer.other")
    face.material = nil
    assert_raises(PhComposer::CodedError) { step }
    face.material = @glass
    edge.attach_face(@host_face)
    assert_raises(PhComposer::CodedError) { step }
    assert_empty @model.definitions.to_a
  end

  def test_changed_stamp_geometry_material_or_edge_topology_is_stale_before_creation
    restore = step
    @panes.first.set_attribute("outside.example", "late", true)
    assert_raises(PhComposer::CodedError) { apply(restore) }
    assert_empty @model.definitions.to_a
    @panes.first.delete_attribute("outside.example")
    restore = step
    @panes.first.edges.first.attach_face(@host_face)
    assert_raises(PhComposer::CodedError) { apply(restore) }
    assert_empty @model.definitions.to_a
    assert_empty U::Occurrences.all(@model)
  end

  def test_fit_overlap_nondefault_anchor_and_old_metadata_refuse
    occupied = U::WorldGeometry.map(U::DefinitionPlan.build(@type), @matrix).outer_polygon_m
    assert_raises(PhComposer::CodedError) { step(:existing_polygons_m => [occupied]) }
    assert_raises(PhComposer::CodedError) { step(:record => record.merge("anchor" => "head_left")) }
    assert_raises(PhComposer::CodedError) { step(:record => record.merge("user_data" => {})) }
    assert_empty @model.definitions.to_a
  end

  def test_late_native_erase_failure_aborts_instance_definition_index_and_panes_together
    restore = step
    before = capture(restore)
    @group.entities.define_singleton_method(:erase_entities) { |*_entities| raise "Synthetic erase failure" }
    @model.start_operation("Restore", true)
    assert_raises(RuntimeError) { apply(restore) }
    @model.abort_operation
    assert_equal before, restore.scopes.map { |scope| scope.capture(@model) }
    assert_empty @model.definitions.to_a
    assert_empty U::Occurrences.all(@model)
  end

  def test_descriptor_is_detached_and_stale_authored_type_refuses
    restore = step
    description = restore.descriptor
    description.fetch("pane_paths").first << 999
    description.fetch("panes_before").clear
    refute_empty restore.descriptor.fetch("panes_before")
    assert_equal 2, restore.descriptor.fetch("pane_paths").first.length
    W::Types::KIND.store.write(@model, @type.merge("notes" => "Changed"))
    assert_raises(PhComposer::CodedError) { apply(restore) }
    assert_empty @model.definitions.to_a
  end

  def test_empty_bands_are_inferred_when_asymmetric_stamped_cells_fix_the_complete_outline
    clear_panes
    @type = window_record("columns_m" => [0.7, 0.3, 1.1], "rows_m" => [1.5])
    template = @type.fetch("elements").first
    @type["elements"] = [0, 1, 2].map do |column|
      template.merge("id" => window_allocator.call("wel"), "column_span" => [column, column],
        "kind" => column == 1 ? "empty" : "glazed")
    end
    store_type
    add_panes
    restore = step
    expected = U::WorldGeometry.map(U::DefinitionPlan.build(@type), @matrix).outer_polygon_m
    instance = apply(restore)
    actual = U::WorldGeometry.map(U::DefinitionPlan.build(@type), instance.transformation.to_a).outer_polygon_m
    assert U::RestoreGeometry.same_polygon?(expected, actual)
    assert_equal 2, instance.definition.entities.grep(Sketchup::Face).length
  end

  def test_extra_interior_and_crossing_edges_refuse_but_distant_geometry_is_retained
    distant = Sketchup::Edge.new(910_000, *native([[6, 0, 1], [7, 0, 1]]))
    @group.entities << distant
    restore = step
    assert_same distant, @group.entities.to_a.find { |entity| entity.persistent_id == distant.persistent_id }
    edge = Sketchup::Edge.new(910_001, *native([[1, 0, 2], [4, 0, 2]]))
    @group.entities << edge
    assert_raises(PhComposer::CodedError) { step }
    assert_raises(PhComposer::CodedError) { apply(restore) }
    @group.entities.erase_entities(edge)
    edge = Sketchup::Edge.new(910_002, *native([[2.1, 0, 2], [2.4, 0, 2]]))
    @group.entities << edge
    assert_raises(PhComposer::CodedError) { step }
    assert_empty @model.definitions.to_a
  end

  def test_exact_geometry_stamp_and_canonical_definition_guards_precede_native_writes
    restore = step
    @panes.first.transform!(Geom::Transformation.translation([1, 0, 0]))
    assert_raises(PhComposer::CodedError) { apply(restore) }
    @panes.first.transform!(Geom::Transformation.translation([-1, 0, 0]))
    restore = step
    stamp = U::PANE_STORE.read(@panes.first)
    U::PANE_STORE.write(@panes.first, stamp.merge("element_id" => "wel_ZZZZZZZZZZZZ"))
    assert_raises(PhComposer::CodedError) { apply(restore) }
    U::PANE_STORE.write(@panes.first, stamp)
    definition = U::DefinitionWriter.create(:model => @model, :type => @type, :plan => U::DefinitionPlan.build(@type))
    U::DefinitionIndex.write(@model, { @type.fetch("id") => definition.persistent_id }, :expected => {})
    restore = step
    definition.behavior.no_scale_mask = 4
    assert_raises(PhComposer::CodedError) { apply(restore) }
    assert_equal 1, @model.definitions.length
    assert_empty U::Occurrences.all(@model)
  end

  def test_preview_digest_uses_new_identity_placeholder_and_constructor_never_repairs
    restore = step
    before = capture(restore)
    proposal = PhComposer::Operations::Proposal.new
    proposal.add_step(restore, :scopes => restore.scopes)
    alternate = PhComposer::Operations::Proposal.new
    alternate.add_step(step(:record => record.merge("id" => "wun_BBBBBBBBBBBB")), :scopes => restore.scopes)
    assert_equal proposal.digest, alternate.digest
    assert_equal before, capture(restore)
    assert_empty @model.operation_starts
  end

  def test_restore_scope_detects_material_only_and_boundary_adjacency_abort_failures
    restore = step
    scope = restore.scopes.last
    before = scope.capture(@model)
    assert scope.unchanged?(@model, before)
    @panes.first.back_material = nil
    refute scope.unchanged?(@model, before)
    @panes.first.back_material = @glass
    assert scope.unchanged?(@model, before)
    @panes.first.edges.first.attach_face(@host_face)
    refute scope.unchanged?(@model, before)
  end

  def split_pane_boundary(edge_index: 0, fraction: 0.5)
    face = @panes.first
    points = face.outer_loop.vertices.map(&:position)
    first = points[edge_index]
    last = points[(edge_index + 1) % points.length]
    midpoint = Geom::Point3d.new(*[first.x, first.y, first.z].zip([last.x, last.y, last.z]).map do |a, b|
      a + (b - a) * fraction
    end)
    points.insert(edge_index + 1, midpoint)
    @group.entities.erase_entities([face, *face.edges])
    edges = points.each_with_index.map do |point, index|
      edge = Sketchup::Edge.new(Sketchup::Entities.allocate_persistent_id, point, points[(index + 1) % points.length])
      @group.entities << edge
      edge
    end
    replacement = Sketchup::Face.new(face.persistent_id, {}, :points => points, :edges => edges)
    @group.entities << replacement
    replacement.material = @glass
    replacement.back_material = @glass
    U::PANE_STORE.write(replacement, U::PANE_STORE.read(face))
    @panes[0] = replacement
  end

  def test_collinear_split_boundary_restores_and_removes_every_original_edge
    split_pane_boundary
    face = @panes.first
    edges = face.edges.dup
    restore = step
    assert_equal 5, restore.descriptor.fetch("panes_before").find { |row| row["id"] == face.persistent_id }
      .fetch("loops").first.length
    assert_equal 5, edges.length
    apply(restore)
    assert edges.none? { |edge| @group.entities.to_a.include?(edge) }
    refute @group.entities.to_a.include?(face)
  end

  def test_collinear_split_boundary_keeps_full_topology_guard_and_foreign_adjacency_refusal
    restore = step
    split_pane_boundary
    assert_raises(PhComposer::CodedError) { apply(restore) }
    assert_empty @model.definitions.to_a
    @panes.first.edges.first.attach_face(@host_face)
    assert_raises(PhComposer::CodedError) { step }
    assert_empty @model.definitions.to_a
  end

  def test_merged_cell_t_junction_allows_boundary_edges_shared_only_with_selected_panes
    clear_panes
    @type = window_record("columns_m" => [0.7, 1.1], "rows_m" => [0.6, 0.9])
    template = @type.fetch("elements").first
    @type["elements"] = [[[0, 1], [0, 0]], [[0, 0], [1, 1]], [[1, 1], [1, 1]]].map do |rows, columns|
      template.merge("id" => window_allocator.call("wel"), "row_span" => rows, "column_span" => columns)
    end
    store_type
    add_panes
    split_pane_boundary(:edge_index => 1, :fraction => 0.6)
    # Native topology at the T shares the split right boundary with the two right cells.
    [[@panes.first.edges[1], @panes[2]], [@panes.first.edges[2], @panes[1]]].each do |shared, neighbor|
      old = neighbor.edges[3]
      neighbor.edges[3] = shared
      shared.attach_face(neighbor)
      @group.entities.erase_entities(old)
    end
    restore = step
    original_edges = @panes.flat_map(&:edges).uniq
    instance = apply(restore)
    assert_equal 3, instance.definition.entities.grep(Sketchup::Face).length
    assert original_edges.none? { |edge| @group.entities.to_a.include?(edge) }
  end
end
