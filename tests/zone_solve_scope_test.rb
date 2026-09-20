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

  # Cutting a Face that still holds a Surface pair would strip that pair from the pieces and leave
  # its counterpart naming a Face that is gone. The full-match path already refuses this; so does
  # the cut, rather than quietly breaking the other endpoint.
  def test_cutting_a_face_that_still_holds_a_pair_refuses_and_writes_nothing
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

    assert_equal %w[refused adjacency.stale none], result.values_at("status", "code", "effect")
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

  private

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
