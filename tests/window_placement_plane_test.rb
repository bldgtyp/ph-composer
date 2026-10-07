# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/placement/plane"
require "open3"
require "rbconfig"

class WindowPlacementPlaneTest < PhComposerTestCase
  include WindowRecordFixtures

  Plane = PhComposer::Windows::Placement::Plane
  Plans = PhComposer::Windows::Units::DefinitionPlan
  Anchors = PhComposer::Windows::Units::Anchors

  def snapshot(normal, points)
    PhComposer::FaceGeometry::Snapshot.new(:normal => normal, :loops_m => [points])
  end

  def wall(normal = [0, -2, 0])
    snapshot(normal, [[10, 20, 30], [14, 20, 30], [14, 20, 35], [10, 20, 35]])
  end

  def assert_vector(expected, actual)
    expected.zip(actual).each { |left, right| assert_in_delta left, right, 1e-10 }
  end

  def test_vertical_face_uses_world_up_and_normalizes_detached_axes
    source = wall
    plane = Plane.new(source)
    assert_vector [1, 0, 0], plane.x_axis
    assert_vector [0, 0, 1], plane.y_axis
    assert_vector [0, -1, 0], plane.normal
    assert_vector [2, 3], plane.project([12, 20, 33])
    assert_in_delta 0, plane.signed_distance_m([12, 20, 33]), 1e-12
    source.normal[1] = 9
    source.outer_loop.first[0] = 90
    assert_vector [0, -1, 0], plane.normal
    assert_vector [10, 20, 30], plane.origin_m
    assert_raises(FrozenError) { plane.y_axis[0] = 2 }
  end

  def test_sloped_face_projects_world_up_into_the_plane
    plane = Plane.new(snapshot([0, -4, 4], [[0, 0, 0], [4, 0, 0], [4, 3, 3], [0, 3, 3]]))
    root = 1.0 / Math.sqrt(2)
    assert_vector [1, 0, 0], plane.x_axis
    assert_vector [0, root, root], plane.y_axis
    assert_vector [0, -root, root], plane.normal
    assert_vector [2, Math.sqrt(8)], plane.project([2, 2, 2])
    assert_in_delta 0, dot(plane.x_axis, plane.y_axis), 1e-12
    assert_vector plane.normal, cross(plane.x_axis, plane.y_axis)
    # Even a nearly horizontal slope keeps projected world up, rather than switching to Model green.
    slight = Plane.new(snapshot([1e-14, 0, 1], [[0, 0, 0], [1, 0, -1e-14], [1, 1, -1e-14], [0, 1, 0]]))
    assert_vector [-1, 0, 1e-14], slight.y_axis
    assert_vector [0, 1, 0], slight.x_axis
  end

  def test_horizontal_roof_uses_model_green_and_reversed_normal_keeps_up
    points = [[1, 2, 8], [5, 2, 8], [5, 6, 8], [1, 6, 8]]
    forward = Plane.new(snapshot([0, 0, 5], points))
    reverse = Plane.new(snapshot([0, 0, -5], points.reverse))
    assert_vector [0, 1, 0], forward.y_axis
    assert_vector [1, 0, 0], forward.x_axis
    assert_vector [0, 1, 0], reverse.y_axis
    assert_vector [-1, 0, 0], reverse.x_axis
    assert_vector [0, 0, -1], cross(reverse.x_axis, reverse.y_axis)
    reversed_wall = Plane.new(wall([0, 2, 0]))
    assert_vector [0, 0, 1], reversed_wall.y_axis
    assert_vector [-1, 0, 0], reversed_wall.x_axis
  end

  def test_all_anchors_map_to_the_explicit_world_target_and_resize_keeps_it_fixed
    plane = Plane.new(wall)
    target = [12, 20, 32]
    before = Plans.build(window_values("columns_m" => [2.0], "rows_m" => [3.0]))
    after = Plans.build(window_values("columns_m" => [4.0], "rows_m" => [5.0]))
    Anchors::ALL.each do |anchor|
      [before, after].each do |plan|
        mapped = plane.map(plan, :point_m => target, :anchor => anchor)
        local_anchor = Anchors.point(anchor, :width_m => plan.width_m, :height_m => plan.height_m)
        local_corner = plan.outer_polygon_m.first
        fixed = mapped.outer_polygon_m.first.each_index.map do |axis|
          mapped.outer_polygon_m.first[axis] + plane.x_axis[axis] * (local_anchor[0] - local_corner[0]) +
            plane.y_axis[axis] * (local_anchor[1] - local_corner[1])
        end
        assert_vector target, fixed
        assert_equal plan.panes.map(&:element_id), mapped.panes.map(&:element_id)
        mapped.outer_polygon_m.each { |point| assert plane.assert_on_plane!(point) }
      end
    end
    assert_equal plane.map(before, :point_m => target, :anchor => "sill_center"),
                 plane.map(before, :point_m => target)
  end

  def test_mapped_panes_keep_dimensions_winding_and_empty_regions_do_not_emit_panes
    plane = Plane.new(wall)
    cells = [W::Types.blank(0, 0, :identity => window_allocator),
             W::Types.blank(0, 1, :identity => window_allocator).merge("kind" => "empty")]
    plan = Plans.build(window_values("columns_m" => [0.7, 0.3], "elements" => cells))
    mapped = plane.map(plan, :point_m => [12, 20, 32])
    assert_equal 1, mapped.panes.length
    a, b, c = mapped.panes.first.polygon_m
    assert_in_delta 0.7, b[0] - a[0], 1e-12
    assert_operator dot(cross(subtract(b, a), subtract(c, a)), plane.normal), :>, 0
    assert_in_delta 1, mapped.outer_polygon_m[1][0] - mapped.outer_polygon_m[0][0], 1e-12
    assert_raises(FrozenError) { mapped.panes.first.polygon_m.first[0] = 0 }
  end

  def test_off_plane_assertion_and_mapping_refuse_instead_of_silently_projecting
    plane = Plane.new(wall)
    assert_in_delta(-0.01, plane.signed_distance_m([12, 20.01, 32]), 1e-12)
    assert_vector [2, 2], plane.project([12, 20.01, 32])
    error = assert_raises(PhComposer::CodedError) { plane.assert_on_plane!([12, 20.01, 32]) }
    assert_equal "geometry.invalid", error.code
    assert_includes error.message, "Nothing was written."
    plan = Plans.build(window_values)
    assert_raises(PhComposer::CodedError) { plane.map(plan, :point_m => [12, 20.01, 32]) }
    assert plane.assert_on_plane!([12, 20.0005, 32], :tolerance_m => 0.001)
    assert_raises(PhComposer::CodedError) { plane.assert_on_plane!([12, 20, 32], :tolerance_m => -1) }
  end

  def test_invalid_normals_points_and_empty_or_nonplanar_outlines_refuse
    [[0, 0, 0], [0, Float::NAN, 0], [Float::INFINITY, 0, 0], [0, 1], [0, "1", 0]].each do |normal|
      assert_raises(PhComposer::CodedError) { Plane.new(wall(normal)) }
    end
    [[], [[0, 0, 0]], [[0, 0, 0], [1, 0, 0], [2, 0, 0]],
     [[0, 0, 0], [1, 0, 0], [1, 0.1, 1]], [[0, 0, 0], [1, 0, 0], [1, 0, Float::NAN]]].each do |points|
      assert_raises(PhComposer::CodedError) { Plane.new(snapshot([0, -1, 0], points)) }
    end
    plane = Plane.new(wall)
    [nil, [1, 2], [1, 2, Float::INFINITY], [1, nil, 3]].each do |point|
      assert_raises(PhComposer::CodedError) { plane.project(point) }
    end
    huge_normal = Plane.new(wall([0, -1e300, 0]))
    assert_vector [0, -1, 0], huge_normal.normal
  end

  def test_plane_loads_without_sketchup_in_a_fresh_process
    path = File.expand_path("../src/ph_composer/features/windows/placement/plane.rb", __dir__)
    code = "require ARGV.fetch(0); abort 'Host leaked' if defined?(Sketchup) || defined?(Geom); puts 'pure'"
    out, err, status = Open3.capture3(RbConfig.ruby, "-e", code, path)
    assert status.success?, err
    assert_equal "pure\n", out
  end

  private

  def dot(left, right)
    left.zip(right).sum { |a, b| a * b }
  end

  def subtract(left, right)
    left.zip(right).map { |a, b| a - b }
  end

  def cross(a, b)
    [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
  end
end
