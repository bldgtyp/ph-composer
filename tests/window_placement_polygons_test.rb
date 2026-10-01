# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/placement/polygons"

class WindowPlacementPolygonsTest < PhComposerTestCase
  P = PhComposer::Windows::Placement::Polygons

  def rectangle(x0, y0, x1, y1)
    [[x0, y0], [x1, y0], [x1, y1], [x0, y1]]
  end

  def test_containment_allows_boundary_contact_and_refuses_overhang
    host = rectangle(0, 0, 4, 3)
    assert P.contained?(rectangle(0, 0, 4, 3), host)
    assert P.contained?(rectangle(1, 1, 3, 2), host.reverse)
    refute P.contained?(rectangle(-0.01, 1, 3, 2), host)
  end

  def test_corners_inside_do_not_admit_edge_crossing_concave_recess
    host = [[0, 0], [4, 0], [4, 4], [3, 4], [3, 1], [1, 1], [1, 4], [0, 4]]
    candidate = rectangle(0.5, 2, 3.5, 3)
    assert candidate.all? { |point| P.inside?(point, host) }
    refute P.contained?(candidate, host)
    assert P.contained?(rectangle(0.2, 0.2, 3.8, 0.8), host)
  end

  def test_coincident_and_collinear_partial_overlap_are_positive_area
    unit = rectangle(0, 0, 2, 2)
    assert P.overlap?(unit, unit.reverse)
    assert P.overlap?(unit, rectangle(1, 0, 3, 2))
    assert P.overlap?(unit, rectangle(-1, 0.5, 3, 1.5))
  end

  def test_edge_and_corner_contact_and_separation_are_not_overlap
    unit = rectangle(0, 0, 2, 2)
    refute P.overlap?(unit, rectangle(2, 0, 4, 2))
    refute P.overlap?(unit, rectangle(2, 2, 3, 3))
    refute P.overlap?(unit, rectangle(3, 0, 4, 2))
  end

  def test_fully_enclosed_hole_and_crossing_hole_are_detected
    unit = rectangle(0, 0, 4, 4)
    assert P.overlap?(unit, rectangle(1, 1, 2, 2))
    assert P.overlap?(unit, rectangle(3, 1, 5, 2))
    refute P.overlap?(unit, rectangle(5, 1, 6, 2))
  end

  def test_integer_coordinates_on_sloped_edges_do_not_truncate_projection
    triangle = [[0, 0], [4, 3], [0, 3]]
    assert P.inside?([1, 1], triangle)
    refute P.inside?([2, 1], triangle)
    refute P.contained?(rectangle(0, 1, 3, 2), triangle)
  end
end
