# frozen_string_literal: true

require_relative "test_helper"

# P1-D D4: the pure SI overlap geometry the adjacency solver decides with. No SketchUp here, so
# every candidate, sliver and modelling-error case is settled before any geometry could move.
class ZoneOverlapTest < PhComposerTestCase
  OVERLAP = PhComposer::Zones::Overlap
  TOLERANCES = {
    :plane_tolerance_m => PhComposer::Zones::Adjacency::PLANE_TOLERANCE_M,
    :angle_tolerance_degrees => PhComposer::Zones::Adjacency::NORMAL_ANGLE_TOLERANCE_DEGREES,
    :point_tolerance_m => PhComposer::Zones::Adjacency::POINT_TOLERANCE_M
  }.freeze

  def test_identical_facing_outlines_are_a_full_match_with_no_split
    result = between(wall(0, 4, 0, 3), wall(0, 4, 0, 3, :facing => :west))

    assert_equal :full, result.kind
    assert result.paired?
    assert_in_delta 12.0, result.area_m2
  end

  def test_a_half_shared_wall_is_a_partial_match_carrying_the_shared_outline
    result = between(wall(0, 4, 0, 3), wall(2, 6, 0, 3, :facing => :west))

    assert_equal :partial, result.kind
    assert result.paired?
    assert_in_delta 6.0, result.area_m2
    assert_equal 4, result.polygon_m.length
    assert(result.polygon_m.all? { |point| point[0].abs < 1.0e-9 })
    assert_in_delta 2.0, result.polygon_m.map { |point| point[1] }.min
    assert_in_delta 4.0, result.polygon_m.map { |point| point[1] }.max
  end

  def test_a_wall_wholly_inside_a_larger_one_is_partial_on_the_smaller_outline
    result = between(wall(0, 4, 0, 3), wall(1, 3, 0.5, 2.5, :facing => :west))

    assert_equal :partial, result.kind
    assert_in_delta 4.0, result.area_m2
  end

  def test_outlines_that_do_not_meet_are_no_match_at_all
    result = between(wall(0, 4, 0, 3), wall(9, 12, 0, 3, :facing => :west))

    assert_equal :none, result.kind
    refute result.paired?
  end

  def test_faces_on_different_planes_are_no_match
    far = wall(0, 4, 0, 3, :facing => :west, :offset => 1.0)

    assert_equal :none, between(wall(0, 4, 0, 3), far).kind
  end

  def test_an_overlap_under_the_area_threshold_is_a_reported_sliver
    result = between(wall(0, 4, 0, 3), wall(3.999, 8, 0, 3, :facing => :west))

    assert_equal :sliver, result.kind
    refute result.paired?
    assert_includes result.reason, "0.01"
    assert_operator result.area_m2, :<, OVERLAP::MINIMUM_AREA_M2
  end

  # Wide enough to clear the area threshold, too narrow to cut: the width rule is independent.
  def test_an_overlap_wider_than_the_area_threshold_but_narrower_than_the_width_is_still_a_sliver
    result = between(wall(0, 40, 0, 3), wall(39.995, 80, 0, 3, :facing => :west))

    assert_operator result.area_m2, :>, OVERLAP::MINIMUM_AREA_M2
    assert_equal :sliver, result.kind
  end

  def test_coplanar_overlapping_faces_pointing_the_same_way_are_overlapping_zones
    result = between(wall(0, 4, 0, 3), wall(2, 6, 0, 3))

    assert_equal :same_normal, result.kind
    refute result.paired?
    assert_in_delta 6.0, result.area_m2
  end

  def test_a_face_with_a_hole_is_reported_rather_than_cut
    holed = wall(0, 4, 0, 3, :hole => [[0, 1, 1], [0, 2, 1], [0, 2, 2], [0, 1, 2]])

    result = between(holed, wall(2, 6, 0, 3, :facing => :west))

    assert_equal :unsupported, result.kind
    assert_includes result.reason, "hole"
  end

  def test_two_concave_outlines_are_reported_rather_than_cut
    result = between(chevron, chevron(:facing => :west, :shift => 1.0))

    assert_equal :unsupported, result.kind
    assert_includes result.reason, "convex"
  end

  # A cut needs both outlines convex, not just the clip: the remainder of a concave Face is a
  # shape this code will not decompose. A concave Face still pairs on a full match, which cuts
  # nothing.
  def test_a_concave_outline_is_not_cut_even_against_a_convex_one
    result = between(chevron, wall(0, 6, 0, 4, :facing => :west))

    assert_equal :unsupported, result.kind
    assert_includes result.reason, "convex"
  end

  def test_a_concave_outline_still_pairs_on_a_full_match
    assert_equal :full, between(chevron, chevron(:facing => :west)).kind
  end

  def test_a_partial_match_reports_what_each_face_would_be_left_holding
    result = between(wall(0, 4, 0, 3), wall(2, 6, 0, 3, :facing => :west))

    assert_equal 1, result.left_remainders_m.length
    assert_equal 1, result.right_remainders_m.length
    assert_in_delta 6.0, area_of(result.left_remainders_m.first)
    assert_in_delta 6.0, area_of(result.right_remainders_m.first)
  end

  def test_a_wall_inside_a_larger_one_leaves_the_larger_one_in_pieces
    result = between(wall(0, 4, 0, 3), wall(1, 3, 0.5, 2.5, :facing => :west))

    assert_in_delta 4.0, result.area_m2
    assert_empty result.right_remainders_m
    assert_equal 12.0 - 4.0, result.left_remainders_m.sum { |piece| area_of(piece) }.round(6)
  end

  # Q17 governs everything the cut creates. A shared region well over both thresholds is still
  # refused when it would leave a sliver behind.
  def test_a_split_that_would_leave_a_sliver_behind_is_skipped_whole
    result = between(wall(0, 4, 0, 3), wall(0, 3.999, 0, 3, :facing => :west))

    assert_operator result.area_m2, :>, OVERLAP::MINIMUM_AREA_M2
    assert_equal :sliver, result.kind
  end

  def test_the_clip_is_independent_of_which_way_each_outline_is_wound
    forward = between(wall(0, 4, 0, 3), wall(2, 6, 0, 3, :facing => :west))
    reversed = between(wall(2, 6, 0, 3, :facing => :west), wall(0, 4, 0, 3))

    assert_equal forward.kind, reversed.kind
    assert_in_delta forward.area_m2, reversed.area_m2
  end

  def test_convexity_rejects_a_degenerate_outline
    refute OVERLAP.convex?([[0.0, 0.0], [1.0, 0.0]])
    refute OVERLAP.convex?([[0.0, 0.0], [1.0, 0.0], [2.0, 0.0]])
    assert OVERLAP.convex?([[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0]])
  end

  private

  def between(left, right)
    OVERLAP.between(left, right, **TOLERANCES)
  end

  def capture(points, normal, holes: [])
    face = Sketchup::Face.new(1, {}, :points => points.map { |point| metres(point) },
                                     :holes => holes.map { |loop| loop.map { |point| metres(point) } },
                                     :normal => Geom::Vector3d.new(*normal))
    PhComposer::FaceGeometry.capture(face, Geom::Transformation.new)
  end

  # One vertical wall in the y-z plane at x = offset, facing east or west.
  def wall(low, high, bottom, top, facing: :east, offset: 0.0, hole: nil)
    points = [[offset, low, bottom], [offset, high, bottom], [offset, high, top], [offset, low, top]]
    points = points.reverse if facing == :west
    capture(points, facing == :east ? [1, 0, 0] : [-1, 0, 0], :holes => hole ? [hole] : [])
  end

  # An L-shaped outline: concave, so it can never be the clip polygon.
  def chevron(facing: :east, shift: 0.0)
    points = [[0, shift, 0], [0, shift + 6, 0], [0, shift + 6, 2], [0, shift + 3, 2],
              [0, shift + 3, 4], [0, shift, 4]]
    points = points.reverse if facing == :west
    capture(points, facing == :east ? [1, 0, 0] : [-1, 0, 0])
  end

  # Shoelace on the world points, which all sit in the x = 0 plane here.
  def area_of(polygon)
    doubled = polygon.each_index.sum do |index|
      following = polygon[(index + 1) % polygon.length]
      (polygon[index][1] * following[2]) - (following[1] * polygon[index][2])
    end
    doubled.abs / 2.0
  end

  def metres(point)
    Geom::Point3d.new(*point.map { |value| value / 0.0254 })
  end
end
