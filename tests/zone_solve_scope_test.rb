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

  def test_a_partial_overlap_is_reported_rather_than_claiming_surface_over_the_whole_face
    wall(600, 0, 0, 4, 0, 3, :east)
    wall(610, 0, 2, 6, 0, 3, :west)
    author

    result = solve(all_references)

    assert_equal ["adjacency.split_not_applied"], finding_codes(result)
    assert_empty result.dig("value", "pair_ids")
    assert_empty boundary_conditions.compact.reject { |value| value == "Outdoors" }
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

  def metres(point)
    Geom::Point3d.new(*point.map { |value| value / 0.0254 })
  end
end
