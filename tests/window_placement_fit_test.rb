# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/placement/fit"

class WindowPlacementFitTest < PhComposerTestCase
  F = PhComposer::Windows::Placement::Fit

  def rectangle(x0, y0, x1, y1, z = 0.0)
    [[x0, y0, z], [x1, y0, z], [x1, y1, z], [x0, y1, z]]
  end

  def host(holes = [])
    PhComposer::FaceGeometry::Snapshot.new(:loops_m => [rectangle(0, 0, 4, 3)] + holes,
                                           :normal => [0.0, 0.0, 1.0])
  end

  def test_fit_is_geometric_and_does_not_depend_on_host_glue
    assert F.check!(host, rectangle(1, 1, 2, 2))
    assert F.check!(host, rectangle(0, 0, 4, 3))
    assert_raises(PhComposer::CodedError) { F.check!(host, rectangle(1, 1, 2, 2, 0.01)) }
    error = assert_raises(PhComposer::CodedError) { F.check!(host, rectangle(1, 1, 5, 2)) }
    assert_equal "window.overhang", error.code
  end

  def test_hole_inside_unit_outline_and_partial_hole_crossing_refuse
    face = host([rectangle(1.2, 1.2, 1.8, 1.8)])
    [rectangle(1, 1, 2, 2), rectangle(0.5, 1, 1.5, 2)].each do |unit|
      error = assert_raises(PhComposer::CodedError) { F.check!(face, unit) }
      assert_equal "window.overhang", error.code
    end
    assert F.check!(face, rectangle(2, 1, 3, 2))
  end

  def test_overlap_refuses_even_without_glue_but_other_planes_and_touching_do_not
    unit = rectangle(1, 1, 2, 2)
    error = assert_raises(PhComposer::CodedError) do
      F.check!(host, unit, :existing_polygons_m => [rectangle(1.5, 1, 2.5, 2)])
    end
    assert_equal "window.overlap", error.code
    assert F.check!(host, unit, :existing_polygons_m => [rectangle(1, 1, 2, 2, 0.2)])
    assert F.check!(host, unit, :existing_polygons_m => [rectangle(2, 1, 3, 2)])
  end

  def test_missing_outline_and_nonplanar_hole_refuse
    assert_raises(PhComposer::CodedError) { F.check!(host, []) }
    face = host([rectangle(1.2, 1.2, 1.8, 1.8, 0.1)])
    assert_raises(PhComposer::CodedError) { F.check!(face, rectangle(2, 1, 3, 2)) }
  end
end
