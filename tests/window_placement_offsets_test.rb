# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/placement/offsets"

class WindowPlacementOffsetsTest < PhComposerTestCase
  OFFSETS = PhComposer::Windows::Placement::Offsets

  def geometry(rotation = 0)
    PhComposer::FaceGeometry::Snapshot.new(:normal => [0.0, -1.0, 0.0],
                                           :loops_m => [[[0.0, 2.0, 0.0],
                                                         [4.0, 2.0, 0.0], [4.0, 2.0, 3.0], [0.0, 2.0, 3.0]].rotate(rotation)])
  end

  def test_offsets_have_stable_host_corner_origin_after_loop_rotation
    4.times do |rotation|
      assert_equal [1.0, 2.0, 0.75], OFFSETS.point(geometry(rotation), :x_m => 1.0, :y_m => 0.75)
    end
  end

  def test_explicit_world_anchor_and_offsets_round_trip
    point = [1.5, 2.0, 1.0]
    offsets = OFFSETS.from_point(geometry, point)
    assert_equal({ "x_m" => 1.5, "y_m" => 1.0 }, offsets)
    assert_equal point, OFFSETS.point(geometry, :x_m => offsets.fetch("x_m"), :y_m => offsets.fetch("y_m"))
  end

  def test_off_plane_point_and_nonfinite_offsets_refuse
    assert_raises(PhComposer::CodedError) { OFFSETS.from_point(geometry, [1, 2.1, 1]) }
    assert_raises(PhComposer::CodedError) { OFFSETS.point(geometry, :x_m => Float::INFINITY, :y_m => 1) }
    assert_raises(PhComposer::CodedError) { OFFSETS.point(geometry, :x_m => Complex(1, 1), :y_m => 1) }
  end
end
