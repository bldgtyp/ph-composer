# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/definition_plan"
require_relative "../src/ph_composer/features/windows/units/anchors"
require "open3"
require "rbconfig"

class WindowDefinitionPlanTest < PhComposerTestCase
  include WindowRecordFixtures
  Plan = PhComposer::Windows::Units::DefinitionPlan
  Anchors = PhComposer::Windows::Units::Anchors

  def mulled
    merged = W::Types.blank(:identity => window_allocator).merge("row_span" => [0, 1], "column_span" => [0, 1])
    right = W::Types.blank(0, 2, :identity => window_allocator)
    empty = W::Types.blank(1, 2, :identity => window_allocator).merge("kind" => "empty")
    window_values("rows_m" => [0.8, 0.7], "columns_m" => [0.6, 0.4, 0.5], "elements" => [merged, right, empty])
  end

  def test_merged_glazed_panes_keep_identity_and_metre_size_while_empty_is_excluded
    record = mulled
    plan = Plan.build(record)
    assert_equal 1.5, plan.width_m
    assert_equal 1.5, plan.height_m
    assert_equal record.fetch("elements").take(2).map { |cell| cell.fetch("id") }, plan.panes.map(&:element_id)
    assert_equal [[0, -1.5, 0], [1.0, -1.5, 0], [1.0, 0, 0], [0, 0, 0]], plan.panes.first.polygon_m
    assert_equal [[1.0, -0.8, 0], [1.5, -0.8, 0], [1.5, 0, 0], [1.0, 0, 0]], plan.panes.last.polygon_m
    assert_equal [[0, -1.5, 0], [1.5, -1.5, 0], [1.5, 0, 0], [0, 0, 0]], plan.outer_polygon_m
    (plan.panes.map(&:polygon_m) + [plan.outer_polygon_m]).each do |polygon|
      a, b, c = polygon.take(3)
      z_normal = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
      assert_operator z_normal, :>, 0
      assert polygon.all? { |point| point.last.zero? }
    end
  end

  def test_one_two_and_three_glazed_elements_generate_one_polygon_each
    [1, 2, 3].each do |count|
      record = window_values("columns_m" => Array.new(count, 0.5), "elements" => count.times.map { |column|
        W::Types.blank(0, column, :identity => window_allocator)
      })
      assert_equal count, Plan.build(record).panes.length
    end
  end

  def test_all_nine_anchors_and_resize_translations_keep_the_same_fixed_point
    before = Plan.build(window_values("columns_m" => [2.0], "rows_m" => [3.0]))
    after = Plan.build(window_values("columns_m" => [4.0], "rows_m" => [5.0]))
    cases = {
      "sill_left" => [[0, -3, 0], [0, 2, 0]], "sill_center" => [[1, -3, 0], [-1, 2, 0]],
      "sill_right" => [[2, -3, 0], [-2, 2, 0]], "center_left" => [[0, -1.5, 0], [0, 1, 0]],
      "center" => [[1, -1.5, 0], [-1, 1, 0]], "center_right" => [[2, -1.5, 0], [-2, 1, 0]],
      "head_left" => [[0, 0, 0], [0, 0, 0]], "head_center" => [[1, 0, 0], [-1, 0, 0]],
      "head_right" => [[2, 0, 0], [-2, 0, 0]]
    }
    assert_equal cases.keys, Anchors::ALL
    cases.each do |anchor, (point, expected_delta)|
      assert_equal point, Anchors.point(anchor, :width_m => before.width_m, :height_m => before.height_m)
      delta = Anchors.resize_delta(anchor, :before => before, :after => after)
      assert_equal expected_delta, delta
      new_point = Anchors.point(anchor, :width_m => after.width_m, :height_m => after.height_m)
      3.times { |axis| assert_in_delta point[axis], new_point[axis] + delta[axis], 1e-12 }
    end
    assert_equal "sill_center", Anchors::DEFAULT
    assert_equal [1, -3, 0], Anchors.point(:width_m => 2, :height_m => 3)
  end

  def test_incomplete_nonpositive_nonfinite_and_overflowing_dimensions_refuse
    [nil, 0, -1, Float::NAN, Float::INFINITY, -Float::INFINITY, "1", 10**400].each do |bad|
      %w[rows_m columns_m].each do |axis|
        record = window_values(axis => [bad])
        error = assert_raises(PhComposer::CodedError) { Plan.build(record) }
        assert_equal "validation.failed", error.code
        assert_includes error.message, "Nothing was written."
      end
    end
    record = window_values("columns_m" => [Float::MAX, Float::MAX])
    assert_raises(PhComposer::CodedError) { Plan.build(record) }
    record = window_values("rows_m" => [])
    assert_raises(PhComposer::CodedError) { Plan.build(record) }
    assert_raises(PhComposer::CodedError) { Anchors.point(:width_m => nil, :height_m => 1) }
    assert_raises(PhComposer::CodedError) { Anchors.point("sill_middle", :width_m => 1, :height_m => 1) }
  end

  def test_nongeometry_changes_and_element_reordering_keep_the_signature
    before = mulled
    after = PhComposer::DeepCopy.call(before)
    after.merge!("name" => "Renamed", "notes" => "Note", "install_depth_m" => 0.4, "user_data" => { "x" => 1 })
    after.fetch("elements").first.merge!("name" => "Renamed pane", "glazing_id" => "glz_new",
      "frames" => W::Types::SIDES.to_h { |side| [side, "frm_new"] },
      "installs" => W::Types::SIDES.to_h { |side| [side, "psi_new"] },
      "operation" => { "type" => "swing", "directions" => ["left"] })
    after.fetch("elements").last["id"] = "wel_changed_empty_id"
    after["elements"].reverse!
    assert_equal Plan.build(before).signature, Plan.build(after).signature
  end

  def test_pane_identity_dimensions_spans_and_glazed_membership_change_the_signature
    record = mulled
    original = Plan.build(record).signature
    identity = PhComposer::DeepCopy.call(record)
    identity.fetch("elements").first["id"] = "wel_new_identity"
    refute_equal original, Plan.build(identity).signature
    size = PhComposer::DeepCopy.call(record)
    size.fetch("columns_m")[0] = 0.7
    refute_equal original, Plan.build(size).signature
    layout = PhComposer::DeepCopy.call(record)
    layout.fetch("elements").first["column_span"] = [1, 2]
    layout.fetch("elements")[1]["column_span"] = [0, 0]
    layout.fetch("elements").last["column_span"] = [0, 0]
    refute_equal original, Plan.build(layout).signature
    kind = PhComposer::DeepCopy.call(record)
    kind.fetch("elements").last["kind"] = "glazed"
    refute_equal original, Plan.build(kind).signature
  end

  def test_plan_and_signature_are_detached_frozen_values
    record = mulled
    plan = Plan.build(record)
    id = plan.panes.first.element_id.dup
    record.fetch("elements").first.fetch("id").replace("changed")
    record.fetch("rows_m")[0] = 4
    assert_equal id, plan.panes.first.element_id
    assert_equal [0.8, 0.7], plan.signature.rows_m
    assert_raises(FrozenError) { plan.panes.first.polygon_m.first[0] = 3 }
    assert_raises(FrozenError) { plan.signature.elements.first.row_span << 9 }
    assert_raises(FrozenError) { plan.width_m = 10 }
  end

  def test_pure_plan_loads_in_a_fresh_ruby_process_without_sketchup
    path = File.expand_path("../src/ph_composer/features/windows/units/anchors.rb", __dir__)
    code = "require ARGV.fetch(0); abort 'Host leaked' if defined?(Sketchup) || defined?(Geom); " \
           "puts PhComposer::Windows::Units::Anchors.point(width_m: 2, height_m: 3).inspect"
    out, err, status = Open3.capture3(RbConfig.ruby, "-e", code, path)
    assert status.success?, err
    assert_equal "[1.0, -3.0, 0.0]\n", out
  end
end
