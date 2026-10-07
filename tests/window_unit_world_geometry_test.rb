# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/world_geometry"
require "json"
require "open3"
require "rbconfig"

class WindowUnitWorldGeometryTest < PhComposerTestCase
  include WindowRecordFixtures

  Geometry = PhComposer::Windows::Units::WorldGeometry
  Plans = PhComposer::Windows::Units::DefinitionPlan
  Anchors = PhComposer::Windows::Units::Anchors

  def matrix(x = [1, 0, 0], y = [0, 1, 0], z = [0, 0, 1], origin_m = [0, 0, 0])
    x + [0] + y + [0] + z + [0] + origin_m.map { |value| value / 0.0254 } + [1]
  end

  def assert_point(expected, actual)
    expected.zip(actual).each { |a, b| assert_in_delta a, b, 1e-10 }
  end

  def test_column_major_axes_apply_metres_and_only_translation_converts_inches
    transform = matrix([0, 1, 0], [0, 0, 1], [1, 0, 0], [10, 20, 30])
    polygon = Geometry.polygon([[0, 0, 0], [2, 0, 0], [2, -3, 0], [0, -3, 0]], transform)
    assert_point [10, 20, 30], polygon[0]
    assert_point [10, 22, 30], polygon[1]
    assert_point [10, 22, 27], polygon[2]
    assert_point [10, 20, 27], polygon[3]
    assert Geometry.transform_state(transform).rigid?
    assert_raises(FrozenError) { polygon.first[0] = 0 }
  end

  def test_all_anchor_world_points_survive_resize_under_rotation_scaling_shear_and_mirror
    before = Plans.build(window_values("columns_m" => [1.2], "rows_m" => [1.5]))
    after = Plans.build(window_values("columns_m" => [2.4], "rows_m" => [2.5]))
    transforms = [matrix, matrix([0, 1, 0], [0, 0, 1], [1, 0, 0], [10, -20, 30]),
                  matrix([0, 2, 0], [0, 0, 3], [0.5, 0, 0], [-4, 6, 2]),
                  matrix([-2, 0, 0], [0.4, 3, 0], [0, 0, 1], [7, 8, 9])]
    transforms.each do |transform|
      original = transform.dup
      Anchors::ALL.each do |anchor|
        changed = Geometry.reanchor(transform, :before => before, :after => after, :anchor => anchor)
        assert_point Geometry.anchor(before, anchor, transform), Geometry.anchor(after, anchor, changed)
        assert_equal original.take(12), changed.take(12)
        assert_equal 1, changed[15]
        assert changed.frozen?
      end
      assert_equal original, transform
    end
  end

  def test_transformation_state_distinguishes_scale_shear_reflection_and_rigid_rotation
    rigid = Geometry.transform_state(matrix([0, 1, 0], [0, 0, 1], [1, 0, 0], [6, 7, 8]))
    assert_equal({ :scaled => false, :sheared => false, :mirrored => false }, rigid.to_h)
    scaled = Geometry.transform_state(matrix([2, 0, 0], [0, 3, 0], [0, 0, 0.5]))
    assert scaled.scaled
    refute scaled.sheared
    refute scaled.rigid?
    shear = Geometry.transform_state(matrix([1, 0, 0], [0.5, 1, 0]))
    assert shear.sheared
    refute shear.rigid?
    unit_shear = Geometry.transform_state(matrix([1, 0, 0], [0.5, Math.sqrt(0.75), 0]))
    assert unit_shear.sheared
    refute unit_shear.scaled
    mirrored = Geometry.transform_state(matrix([-1, 0, 0]))
    assert mirrored.mirrored
    assert mirrored.rigid?
    refute mirrored.scaled
    refute mirrored.sheared
    assert mirrored.frozen?
  end

  def test_unused_normal_basis_does_not_report_inplane_shear_or_scale
    plan = Plans.build(window_values)
    changed = matrix([1, 0, 0], [0, 1, 0], [0.3, 0.4, 2])
    assert_equal Geometry.map(plan, matrix), Geometry.map(plan, changed)
    state = Geometry.transform_state(changed)
    refute state.scaled
    refute state.sheared
    refute state.mirrored
    assert state.rigid?
  end

  def test_new_layout_maps_merged_panes_and_retains_ids_with_physically_transformed_winding
    merged = W::Types.blank(:identity => window_allocator).merge("row_span" => [0, 1], "column_span" => [0, 1])
    small = W::Types.blank(0, 2, :identity => window_allocator)
    empty = W::Types.blank(1, 2, :identity => window_allocator).merge("kind" => "empty")
    plan = Plans.build(window_values("rows_m" => [0.8, 0.7], "columns_m" => [0.6, 0.4, 0.5],
                                     "elements" => [merged, small, empty]))
    transform = matrix([0, -2, 0], [0, 0, 3], [1, 0, 0], [10, 20, 30])
    mapped = Geometry.map(plan, transform)
    assert_equal [merged.fetch("id"), small.fetch("id")], mapped.panes.map(&:element_id)
    assert_equal 2, mapped.panes.length
    assert_point [10, 20, 25.5], mapped.panes.first.polygon_m.first
    assert_point [10, 18, 30], mapped.panes.first.polygon_m[2]
    a, b, c = mapped.panes.first.polygon_m
    assert_point [-6, 0, 0], cross(subtract(b, a), subtract(c, b)).map { |value| value / 1.5 }
    assert Geometry.transform_state(transform).mirrored
    assert_raises(FrozenError) { mapped.panes.first.element_id.replace("new") }
    assert_raises(FrozenError) { mapped.outer_polygon_m << [0, 0, 0] }
  end

  def test_nongeometry_edits_leave_world_geometry_and_matrix_unchanged
    original = window_values
    edited = PhComposer::DeepCopy.call(original)
    edited.merge!("name" => "New name", "notes" => "Note", "install_depth_m" => 0.2,
                  "user_data" => { "synthetic" => true })
    edited.fetch("elements").first.merge!("glazing_id" => "glz_changed", "name" => "Pane",
                                          "operation" => { "type" => "swing", "directions" => ["right"] })
    before, after = [original, edited].map { |values| Plans.build(values) }
    transform = matrix([0, 1, 0], [-1, 0, 0], [0, 0, 1], [3, 4, 5])
    assert_equal Geometry.map(before, transform), Geometry.map(after, transform)
    assert_equal transform, Geometry.reanchor(transform, :before => before, :after => after, :anchor => "center")
  end

  def test_invalid_nonfinite_nonaffine_and_degenerate_matrices_refuse
    invalid = [nil, [], Array.new(16, 0), matrix.map { "0" }, matrix.tap { |value| value[0] = Float::NAN },
               matrix.tap { |value| value[12] = Float::INFINITY }, matrix.tap { |value| value[3] = 0.1 },
               matrix.tap { |value| value[15] = 2 }, matrix([1, 0, 0], [2, 0, 0]),
               matrix([0, 0, 0])]
    plan = Plans.build(window_values)
    invalid.each do |transform|
      error = assert_raises(PhComposer::CodedError) { Geometry.transform_state(transform) }
      assert_equal "geometry.invalid", error.code
      assert_includes error.message, "Nothing was written."
      assert_raises(PhComposer::CodedError) { Geometry.map(plan, transform) }
    end
    assert_raises(PhComposer::CodedError) { Geometry.polygon([[0, 0, 0], [1, 0, 0], [1, 2, Float::INFINITY]], matrix) }
    assert_raises(PhComposer::CodedError) { Geometry.polygon([[0, 0, 0], [1, 0, 0], [1, 2]], matrix) }
    assert_raises(PhComposer::CodedError) { Geometry.polygon([], matrix) }
    overflowing = [[0, 0, 0], [Float::MAX, 0, 0], [0, 1, 0]]
    assert_raises(PhComposer::CodedError) { Geometry.polygon(overflowing, matrix([2, 0, 0])) }
  end

  def test_detached_result_round_trips_json_without_nonfinite_values
    plan = Plans.build(window_values)
    transform = matrix([-1, 0, 0], [0, 2, 0], [0, 0, 1], [3, 4, 5])
    result = Geometry.map(plan, transform)
    transform[12] = 0
    expected = { "outer" => result.outer_polygon_m, "panes" => result.panes.map { |pane|
      { "id" => pane.element_id, "polygon" => pane.polygon_m }
    }, "state" => Geometry.transform_state(transform).to_h.transform_keys(&:to_s) }
    assert_equal expected, JSON.parse(JSON.generate(expected))
    assert_point [3, 4, 5], result.outer_polygon_m.last
  end

  def test_world_geometry_loads_without_sketchup_in_a_fresh_process
    path = File.expand_path("../src/ph_composer/features/windows/units/world_geometry.rb", __dir__)
    code = "require ARGV.fetch(0); abort 'Host leaked' if defined?(Sketchup) || defined?(Geom); puts 'pure'"
    out, err, status = Open3.capture3(RbConfig.ruby, "-e", code, path)
    assert status.success?, err
    assert_equal "pure\n", out
  end

  private

  def subtract(left, right)
    left.zip(right).map { |a, b| a - b }
  end

  def cross(a, b)
    [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
  end
end
