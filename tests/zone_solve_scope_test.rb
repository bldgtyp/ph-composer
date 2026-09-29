# frozen_string_literal: true

require_relative "test_helper"

# P1-D D4: what Solve does across a whole scope. Reading is unbounded and writing is not, so the
# interesting cases are the ones where a pairing reaches outside the Zones the caller named, and
# the ones the solver reports instead of pairing.
class ZoneSolveScopeTest < PhComposerTestCase
  API = PhComposer::API

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
    @next_id = 1_000
  end

  def test_solving_every_zone_pairs_each_full_wall_once
    wall(100, 0, 0, 4, 0, 3, :east)
    wall(110, 0, 0, 4, 0, 3, :west)
    wall(120, 6, 0, 4, 0, 3, :east)
    wall(130, 6, 0, 4, 0, 3, :west)
    author

    result = solve(all_references)

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_equal 2, result.dig("value", "pair_ids").length
    assert_equal 4, boundary_conditions.count("Surface")
  end

  def test_solving_one_zone_of_a_pair_refuses_and_names_both_zones
    wall(200, 0, 0, 4, 0, 3, :east)
    wall(210, 0, 0, 4, 0, 3, :west)
    author
    one = all_references.first

    result = solve([one])

    assert_equal %w[refused scope.incomplete none], result.values_at("status", "code", "effect")
    assert_empty boundary_conditions.compact.reject { |value| value == "Outdoors" }
  end

  def test_including_both_zones_after_the_refusal_succeeds
    wall(220, 0, 0, 4, 0, 3, :east)
    wall(230, 0, 0, 4, 0, 3, :west)
    author
    solve([all_references.first])

    result = solve(all_references)

    assert_equal "completed", result.fetch("status")
    assert_equal 2, boundary_conditions.count("Surface")
  end

  # A third Zone the caller did not name is still read, so its full-wall match with a scoped Zone
  # is what triggers the refusal rather than being silently ignored.
  def test_an_unscoped_neighbour_is_read_and_forces_the_refusal
    wall(300, 0, 0, 4, 0, 3, :east)
    wall(310, 0, 0, 4, 0, 3, :west)
    wall(320, 9, 0, 4, 0, 3, :east)
    author
    scoped = all_references.select { |reference| [[300], [320]].include?(reference.fetch("zone_path")) }

    result = solve(scoped)

    assert_equal %w[refused scope.incomplete none], result.values_at("status", "code", "effect")
  end

  def test_coplanar_faces_pointing_the_same_way_are_reported_as_overlapping_zones
    wall(400, 0, 0, 4, 0, 3, :east)
    wall(410, 0, 2, 6, 0, 3, :east)
    author

    result = solve(all_references)

    assert_equal "completed", result.fetch("status")
    assert_equal ["adjacency.overlapping_zones"], finding_codes(result)
    assert_empty boundary_conditions.compact.reject { |value| value == "Outdoors" }
  end

  def test_a_sliver_overlap_is_reported_and_pairs_nothing
    wall(500, 0, 0, 4, 0, 3, :east)
    wall(510, 0, 3.999, 8, 0, 3, :west)
    author

    result = solve(all_references)

    assert_equal ["adjacency.sliver_skipped"], finding_codes(result)
    assert_empty result.dig("value", "pair_ids")
  end

  def test_a_partial_overlap_cuts_both_faces_and_pairs_only_the_shared_part
    wall(600, 0, 0, 4, 0, 3, :east)
    wall(610, 0, 2, 6, 0, 3, :west)
    author

    result = solve(all_references)

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_equal 1, result.dig("value", "pair_ids").length
    assert_equal 4, faces.length
    shared, rest = faces.partition { |face| face.dig("values", "boundary_condition") == "Surface" }

    assert_equal 2, shared.length
    assert(shared.all? { |face| (face.fetch("area_m2") - 6.0).abs < 1.0e-6 })
    # Q21: the unpaired remainder keeps the classification it already had.
    assert_equal %w[Outdoors Outdoors], rest.map { |face| face.dig("values", "boundary_condition") }
    assert(rest.all? { |face| (face.fetch("area_m2") - 6.0).abs < 1.0e-6 })
  end

  def test_the_new_pair_is_reciprocal_and_reads_current
    wall(620, 0, 0, 4, 0, 3, :east)
    wall(630, 0, 2, 6, 0, 3, :west)
    author
    solve(all_references)

    shared = faces.select { |face| face.dig("values", "boundary_condition") == "Surface" }
    envelopes = shared.map { |face| face.dig("values", "adjacency") }

    assert_equal %w[current current], shared.map { |face| face.fetch("adjacency_state") }
    assert_equal 1, envelopes.map { |envelope| envelope.fetch("pair_id") }.uniq.length
    assert_equal shared.last.dig("reference", "entity_id"), envelopes.first.dig("counterpart", "entity_id")
    assert_equal shared.first.dig("reference", "entity_id"), envelopes.last.dig("counterpart", "entity_id")
  end

  # The split rules: the piece that kept the native persistent id keeps the Face id, and every
  # piece carries the payloads the Face had before the cut.
  def test_the_piece_keeping_the_persistent_id_keeps_the_face_id_and_every_piece_keeps_the_payload
    wall(640, 0, 0, 4, 0, 3, :east)
    wall(650, 0, 2, 6, 0, 3, :west)
    author
    original = faces.find { |face| face.dig("reference", "zone_path") == [640] }
    original_id = original.dig("reference", "entity_id")
    entity = @model.entities.to_a.find { |candidate| candidate.persistent_id == 640 }.entities.to_a.first
    store = PhComposer::FaceAssignment::FACE_STORE
    store.write(entity, store.read(entity).merge("user_data" => { "firm.note" => "keep" },
                                                 "extension_data" => { "other.ext" => { "payload" => 1 } }))

    solve(all_references)

    pieces = faces.select { |face| face.dig("reference", "zone_path") == [640] }

    assert_equal 2, pieces.length
    assert_includes pieces.map { |face| face.dig("reference", "entity_id") }, original_id
    assert(pieces.all? { |face| face.fetch("user_data") == { "firm.note" => "keep" } })
    assert(pieces.all? { |face| face.fetch("extension_data") == { "other.ext" => { "payload" => 1 } } })
  end

  def test_a_shared_region_wholly_inside_a_wall_is_cut_out_of_it
    wall(660, 0, 0, 6, 0, 4, :east)
    wall(670, 0, 1, 5, 1, 3, :west)
    author

    result = solve(all_references)

    assert_equal "completed", result.fetch("status")
    shared = faces.select { |face| face.dig("values", "boundary_condition") == "Surface" }

    assert_equal 2, shared.length
    assert(shared.all? { |face| (face.fetch("area_m2") - 8.0).abs < 1.0e-6 })
    larger = faces.find do |face|
      face.dig("reference", "zone_path") == [660] && face.dig("values", "boundary_condition") == "Outdoors"
    end

    assert_in_delta 24.0 - 8.0, larger.fetch("area_m2")
  end

  def test_undo_reverts_the_cut_and_the_records_together
    wall(680, 0, 0, 4, 0, 3, :east)
    wall(690, 0, 2, 6, 0, 3, :west)
    author
    solve(all_references)

    @model.undo

    assert_equal 2, faces.length
    assert_equal %w[Outdoors Outdoors], boundary_conditions
    assert(faces.all? { |face| (face.fetch("area_m2") - 12.0).abs < 1.0e-6 })
  end

  def test_a_failure_cutting_the_second_face_leaves_neither_face_cut
    wall(692, 0, 0, 4, 0, 3, :east)
    wall(694, 0, 2, 6, 0, 3, :west)
    author
    doomed = @model.entities.to_a.find { |entity| entity.persistent_id == 694 }
    doomed.entities.define_singleton_method(:add_face) { |_points| raise IOError, "the host refused the cut" }

    result = solve(all_references)

    assert_equal %w[failed operation.failed rolled_back], result.values_at("status", "code", "effect")
    assert_equal 2, faces.length
    assert(faces.all? { |face| (face.fetch("area_m2") - 12.0).abs < 1.0e-6 })
    assert_equal %w[Outdoors Outdoors], boundary_conditions
  end

  # A copied envelope that does not even name its own Face is not proof of a deleted counterpart.
  def test_cutting_a_face_with_an_unresolvable_pair_refuses_and_writes_nothing
    wall(696, 0, 0, 4, 0, 3, :east)
    wall(698, 0, 2, 6, 0, 3, :west)
    author
    entity = @model.entities.to_a.find { |candidate| candidate.persistent_id == 696 }.entities.to_a.first
    store = PhComposer::FaceAssignment::FACE_STORE
    record = store.read(entity)
    store.write(entity, record.merge(
      "boundary_condition" => "Surface",
      "adjacency" => {
        "schema_version" => 1, "pair_id" => "adj_000000000000",
        "self" => record_reference(record.fetch("id")), "counterpart" => record_reference("fac_000000000000"),
        "self_geometry" => { "digest" => "sha256:x", "area_m2" => 12.0 },
        "counterpart_geometry" => { "digest" => "sha256:y", "area_m2" => 12.0 }
      }
    ))

    result = solve(all_references)

    assert_equal %w[refused adjacency.unresolved none], result.values_at("status", "code", "effect")
    assert_equal 2, faces.length
    assert_equal "Surface", store.read(entity).fetch("boundary_condition")
  end

  def test_a_face_meeting_two_neighbours_is_reported_and_pairs_neither
    wall(700, 0, 0, 4, 0, 3, :east)
    wall(710, 0, 0, 4, 0, 3, :west)
    wall(720, 0, 0, 4, 0, 3, :west)
    author

    result = solve(all_references)

    # The two west-facing walls are also coplanar with each other and point the same way, so the
    # solver has two separate things to say about this model and says both.
    assert_includes finding_codes(result), "adjacency.multiple_neighbours"
    assert_includes finding_codes(result), "adjacency.overlapping_zones"
    assert_empty result.dig("value", "pair_ids")
  end

  def test_a_finding_names_the_zones_it_is_about
    wall(800, 0, 0, 4, 0, 3, :east)
    wall(810, 0, 2, 6, 0, 3, :east)
    author

    finding = solve(all_references).fetch("findings").first

    assert_equal 2, finding.fetch("zones").length
    assert_includes finding.fetch("message"), "Zone 1"
    assert_includes finding.fetch("message"), "Zone 2"
  end

  def test_solving_one_zone_with_no_neighbour_writes_nothing
    wall(900, 0, 0, 4, 0, 3, :east)
    author

    result = solve(all_references)

    assert_equal "none", result.fetch("effect")
    assert_empty result.dig("value", "pair_ids")
  end

  def test_solving_after_a_neighbour_is_deleted_retires_the_survivor_and_preserves_payloads
    left, right = paired_walls
    entity = left.entities.to_a.first
    store = PhComposer::FaceAssignment::FACE_STORE
    before = store.read(entity).merge("user_data" => { "note" => "keep" },
                                      "extension_data" => { "other.ext" => { "payload" => [1, 2] } })
    store.write(entity, before)
    @model.entities.erase_entities(right)

    result = solve(all_references)

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_empty result.dig("value", "pair_ids")
    expected = before.reject { |key, _value| %w[adjacency boundary_condition].include?(key) }
    assert_equal expected, store.read(entity)
    @model.undo
    assert_equal before, store.read(@model.entities.to_a.first.entities.to_a.first)
    @model.redo
    assert_equal expected, store.read(@model.entities.to_a.first.entities.to_a.first)
  end

  def test_solving_after_only_the_counterpart_face_is_deleted_retires_the_survivor
    _left, right = paired_walls
    right.entities.erase_entities(right.entities.to_a.first)

    result = solve(all_references)

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_equal [nil], boundary_conditions
  end

  def test_separated_pairs_retire_both_ends_and_a_repeat_solve_creates_no_undo_entry
    _left, right = paired_walls
    right.transformation = Geom::Transformation.translation([100, 0, 0])

    result = solve(all_references)

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_equal [nil, nil], boundary_conditions
    count = @model.operation_starts.length
    assert_equal "none", solve(all_references).fetch("effect")
    assert_equal count, @model.operation_starts.length
  end

  def test_a_stale_surviving_counterpart_outside_scope_refuses_before_any_write
    _left, right = paired_walls
    right.transformation = Geom::Transformation.translation([100, 0, 0])
    before = faces
    count = @model.operation_starts.length

    result = solve([all_references.first])

    assert_equal %w[refused scope.incomplete none], result.values_at("status", "code", "effect")
    assert_equal before, faces
    assert_equal count, @model.operation_starts.length
  end

  def test_a_duplicated_counterpart_zone_is_ambiguous_even_when_no_geometry_matches
    _left, right = paired_walls
    right.transformation = Geom::Transformation.translation([100, 0, 0])
    wall(930, 9, 0, 4, 0, 3, :west)
    duplicate = @model.entities.to_a.last
    store = PhComposer::Zones::ZONE_STORE
    store.write(duplicate, store.read(duplicate).merge("id" => store.read(right).fetch("id")))
    before = PhComposer::FaceAssignment::FACE_STORE.read(@model.entities.to_a.first.entities.to_a.first)

    result = solve([all_references.first])

    assert_equal %w[refused target.ambiguous none], result.values_at("status", "code", "effect")
    assert_equal before, PhComposer::FaceAssignment::FACE_STORE.read(@model.entities.to_a.first.entities.to_a.first)
  end

  def test_an_exploded_counterpart_is_unresolved_not_deleted
    _left, right = paired_walls
    @model.entities << right.entities.to_a.first
    @model.entities.erase_entities(right)
    before = boundary_conditions

    result = solve(all_references)

    assert_equal %w[refused adjacency.unresolved none], result.values_at("status", "code", "effect")
    assert_equal before, boundary_conditions
  end

  def test_a_deleted_path_with_a_surviving_face_uuid_is_unresolved
    _left, right = paired_walls
    store = PhComposer::FaceAssignment::FACE_STORE
    copied = store.read(right.entities.to_a.first)
    @model.entities.erase_entities(right)
    wall(930, 9, 0, 4, 0, 3, :west)
    store.write(@model.entities.to_a.last.entities.to_a.first, copied)

    result = solve([all_references.first])

    assert_equal %w[refused adjacency.unresolved none], result.values_at("status", "code", "effect")
    assert_equal %w[Surface Surface], boundary_conditions
  end

  def test_a_paired_zone_moved_inside_a_wrapper_reads_unresolved_without_remapping
    left, right = paired_walls
    store = PhComposer::FaceAssignment::FACE_STORE
    left_record = store.read(left.entities.to_a.first)
    right_record = store.read(right.entities.to_a.first)
    wrapper = Sketchup::Group.new(935, Sketchup::Entities.new)
    @model.entities << wrapper
    wrapper.entities << right
    count = @model.operation_starts.length

    rows = faces

    assert_equal [935, 920], rows.find { |row| row.dig("reference", "entity_id") == right_record.fetch("id") }
      .dig("reference", "zone_path")
    assert_equal %w[unresolved unresolved], rows.map { |row| row.fetch("adjacency_state") }.sort
    assert_equal [920], store.read(right.entities.to_a.first).dig("adjacency", "self", "zone_path")
    assert_equal count, @model.operation_starts.length

    result = solve(all_references)

    assert_equal %w[refused target.changed none], result.values_at("status", "code", "effect")
    assert_equal left_record, store.read(left.entities.to_a.first)
    assert_equal right_record, store.read(right.entities.to_a.first)
    assert_equal count, @model.operation_starts.length
  end

  def test_a_split_copy_of_the_local_face_uuid_reads_unresolved
    left, right = paired_walls
    store = PhComposer::FaceAssignment::FACE_STORE
    original = left.entities.to_a.first
    record = store.read(original)
    copied_face = Sketchup::Face.new(936, {},
                                    :points => original.outer_loop.vertices.map(&:position), :normal => original.normal)
    left.entities << copied_face
    store.write(copied_face, record)
    count = @model.operation_starts.length

    rows = faces

    assert_equal 3, rows.length
    assert_equal %w[unresolved unresolved unresolved], rows.map { |row| row.fetch("adjacency_state") }
    assert_equal count, @model.operation_starts.length

    result = solve(all_references)

    assert_equal %w[refused target.ambiguous none], result.values_at("status", "code", "effect")
    assert_equal record, store.read(original)
    assert_equal record, store.read(copied_face)
    assert_equal count, @model.operation_starts.length
  end

  def test_a_reciprocal_path_corruption_reads_unresolved_even_with_the_same_uuid
    left, right = paired_walls
    store = PhComposer::FaceAssignment::FACE_STORE
    left_record = store.read(left.entities.to_a.first)
    right_face = right.entities.to_a.first
    right_record = store.read(right_face)
    changed = PhComposer::DeepCopy.call(right_record)
    changed.fetch("adjacency").fetch("counterpart")["zone_path"] = [999]
    store.write(right_face, changed)
    count = @model.operation_starts.length

    rows = faces

    assert_equal %w[unresolved unresolved], rows.map { |row| row.fetch("adjacency_state") }
    assert_equal left_record.fetch("id"), changed.dig("adjacency", "counterpart", "entity_id")
    assert_equal count, @model.operation_starts.length
  end

  def test_common_motion_replaces_stale_stamps_and_then_solving_is_a_noop
    left, right = paired_walls
    [left, right].each { |group| group.transformation = Geom::Transformation.translation([100, 0, 0]) }

    result = solve(all_references)

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_equal %w[current current], faces.map { |face| face.fetch("adjacency_state") }
    count = @model.operation_starts.length
    assert_equal "none", solve(all_references).fetch("effect")
    assert_equal count, @model.operation_starts.length
  end

  def test_partial_repair_retires_the_old_pair_and_leaves_remainders_unclassified
    _left, right = paired_walls
    right.transformation = Geom::Transformation.translation([0, 2 / 0.0254, 0])

    result = solve(all_references)

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_equal 4, faces.length
    assert_equal 2, boundary_conditions.count("Surface")
    assert_equal 2, boundary_conditions.count(nil)
    assert_equal %w[current current], faces.filter_map { |face| face["adjacency_state"] }
  end

  def test_a_failed_cut_after_retirement_rolls_back_both_old_pair_records_and_all_geometry
    _left, right = paired_walls
    right.transformation = Geom::Transformation.translation([0, 2 / 0.0254, 0])
    before = faces
    right.entities.define_singleton_method(:add_face) { |_points| raise IOError, "the host refused the cut" }

    result = solve(all_references)

    assert_equal %w[failed operation.failed rolled_back], result.values_at("status", "code", "effect")
    assert_equal before, faces
    assert_equal %w[Surface Surface], boundary_conditions
  end

  def test_retirement_preview_is_read_only_and_lists_both_endpoints
    _left, right = paired_walls
    right.transformation = Geom::Transformation.translation([100, 0, 0])
    before = faces
    count = @model.operation_starts.length

    preview = API.preview(:context => @context, :name => "ph_composer.zones.solve_adjacency",
                          :params => { "zones" => all_references })

    assert_equal "completed", preview.fetch("status")
    assert_equal 2, preview.fetch("affected").count { |entry| entry.fetch("change") == "retired" }
    assert_equal before, faces
    assert_equal count, @model.operation_starts.length
  end

  def test_a_failure_writing_the_second_retirement_rolls_back_the_first
    left, right = paired_walls
    right.transformation = Geom::Transformation.translation([100, 0, 0])
    before = faces
    # Retirement writes the counterpart first, then the initiating Face.
    left.entities.to_a.first.define_singleton_method(:set_attribute) do |dictionary, key, value|
      raise IOError, "the host refused the write" if dictionary == PhComposer::FaceAssignment::FACE_DICTIONARY

      super(dictionary, key, value)
    end

    result = solve(all_references)

    assert_equal %w[failed operation.failed rolled_back], result.values_at("status", "code", "effect")
    assert_equal before, faces
  end

  private

  def paired_walls
    wall(910, 0, 0, 4, 0, 3, :east)
    wall(920, 0, 0, 4, 0, 3, :west)
    author
    assert_equal "committed", solve(all_references).fetch("effect")
    @model.entities.to_a
  end

  def invoke(name, params)
    @sequence += 1
    API.invoke(:context => @context, :name => name, :params => params,
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end

  def solve(references)
    invoke("ph_composer.zones.solve_adjacency", { "zones" => references })
  end

  def finding_codes(result)
    result.fetch("findings").map { |finding| finding.fetch("code") }.uniq
  end

  def zones_value
    API.query(:context => @context, :name => "ph_composer.zones.list").dig("value", "zones")
  end

  def all_references
    zones_value.map { |zone| zone.fetch("reference") }
  end

  def faces
    API.query(:context => @context, :name => "ph_composer.face_assignment.list").dig("value", "faces")
  end

  def boundary_conditions
    faces.map { |face| face.dig("values", "boundary_condition") }
  end

  # One Zone holding one vertical wall in the y-z plane at x = offset.
  def wall(persistent_id, offset, low, high, bottom, top, facing)
    points = [[offset, low, bottom], [offset, high, bottom], [offset, high, top], [offset, low, top]]
    points = points.reverse if facing == :west
    face = Sketchup::Face.new(@next_id += 1, {}, :points => points.map { |point| metres(point) },
                                                 :normal => Geom::Vector3d.new(facing == :east ? 1 : -1, 0, 0))
    @model.entities << Sketchup::Group.new(persistent_id, Sketchup::Entities.new([face]))
    invoke("ph_composer.zones.make", { "parent_path" => [], "entity_ids" => [persistent_id] })
  end

  def author
    invoke("ph_composer.face_assignment.classify", {
      "faces" => faces.map { |face| face.fetch("reference") },
      "intent" => { "face_type" => { "mode" => "set", "value" => "Wall" },
                    "boundary_condition" => { "mode" => "set", "value" => "Outdoors" } },
      "expected_values" => {}
    })
  end

  def record_reference(entity_id)
    { "zone_id" => "zon_000000000000", "zone_path" => [1], "entity_path" => [2], "entity_id" => entity_id }
  end

  def metres(point)
    Geom::Point3d.new(*point.map { |value| value / 0.0254 })
  end
end
