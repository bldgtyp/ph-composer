# frozen_string_literal: true

require_relative "test_helper"

class ColourByHatchTest < PhComposerTestCase
  Tessellation = PhComposer::ColourBy::Tessellation

  def test_world_anchored_hatch_continues_across_a_mesh_diagonal
    triangles = rectangle(0, 0, 24, 24)

    hatch = Tessellation.hatch(triangles)

    refute_empty hatch
    assert_equal 0, hatch.length % 2
    # Every segment lies on one globally anchored stripe, including the two pieces split by the
    # rectangle's triangulation. A local per-triangle phase would give different sums here.
    levels = hatch.each_slice(2).map { |start_point, end_point|
      assert_in_delta start_point.x + start_point.y, end_point.x + end_point.y, 1.0e-7
      ((start_point.x + start_point.y) / Math.sqrt(2)).round(6)
    }
    assert_operator levels.uniq.length, :<, levels.length
    assert_equal [3, 9, 15, 21, 27, 33], levels.uniq.sort
  end

  def test_hole_and_concave_void_receive_no_hatch_segments
    # Four strips triangulate a 24-inch square around its open 8..16-inch centre. The SketchUp
    # stub's Face#mesh omits holes, so this explicit mesh tests the clipping contract itself.
    ring = rectangle(0, 0, 24, 8) + rectangle(0, 16, 24, 24) +
           rectangle(0, 8, 8, 16) + rectangle(16, 8, 24, 16)
    concave = rectangle(0, 0, 24, 8) + rectangle(0, 8, 8, 24)

    [ring, concave].each do |triangles|
      hatch = Tessellation.hatch(triangles)
      refute_empty hatch
      hatch.each_slice(2) do |start_point, end_point|
        middle_x = (start_point.x + end_point.x) / 2.0
        middle_y = (start_point.y + end_point.y) / 2.0
        if triangles.equal?(ring)
          refute middle_x > 8 && middle_x < 16 && middle_y > 8 && middle_y < 16
        else
          refute middle_x > 8 && middle_y > 8
        end
      end
    end
  end

  def test_reflected_and_slanted_meshes_keep_a_hatch
    vertical = rectangle(0, 0, 24, 24).map { |point| Geom::Point3d.new(4, point.x, point.y) }
    reflection = Geom::Transformation.scaling(-1, 1, 1)
    reflected = rectangle(0, 0, 24, 24).map { |point| point.transform(reflection) }
    assert reflected.all? { |point| point.x <= 0 }
    # The normal of this Face is parallel to the primary stripe axis. The fallback projected axis
    # still gives it visible stripes.
    slanted = [point(0, 0, 0), point(24, -24, 0), point(24, 0, -24)]

    [vertical, reflected, slanted].each { |triangles| refute_empty Tessellation.hatch(triangles) }
  end

  def test_large_mesh_widens_spacing_before_it_exceeds_the_segment_budget
    triangles = rectangle(-100_000, -100_000, 100_000, 100_000)

    hatch = Tessellation.hatch(triangles)

    refute_empty hatch
    assert_operator hatch.length / 2, :<=, Tessellation::MAX_HATCH_SEGMENTS
  end

  def test_density_budget_applies_to_the_whole_batch_without_truncating_later_faces
    triangles = 1_000.times.flat_map do |index|
      rectangle(index * 60, 0, (index * 60) + 24, 24)
    end

    hatch = Tessellation.hatch(triangles)

    refute_empty hatch
    assert_operator hatch.length / 2, :<=, Tessellation::MAX_HATCH_SEGMENTS
    assert hatch.any? { |point| point.x < 24 }
    assert hatch.any? { |point| point.x > 999 * 60 }
  end

  def test_vertex_only_tangencies_do_not_make_visible_hatch_disappear
    root_two = 2 * Math.sqrt(2)
    root_three = 3 * Math.sqrt(2)
    root_four = 4 * Math.sqrt(2)
    crossing = [point(root_two, 0, 0), point(root_four, 0, 0), point(root_four, 1, 0)]
    tangent = [point(root_three, 0, 0), point(root_four, 0, 0), point(root_four, 1, 0)]
    triangles = (crossing * 5_000) + (tangent * 4_000)

    hatch = Tessellation.hatch(triangles)

    assert_equal 5_000, hatch.length / 2
    assert hatch.all? { |point| ((point.x + point.y) / Math.sqrt(2) - 3).abs < 1.0e-7 }
  end

  def test_a_stripe_along_a_triangle_edge_remains_a_visible_segment
    edge = 3 * Math.sqrt(2)
    triangles = [point(edge, 0, 0), point(0, edge, 0), point(edge, edge, 0)]

    hatch = Tessellation.hatch(triangles)

    assert_equal 1, hatch.length / 2
    assert hatch.all? { |point| ((point.x + point.y) / Math.sqrt(2) - 3).abs < 1.0e-7 }
  end

  def test_near_vertex_crossings_still_count_toward_the_budget
    # The crossing lies within the numeric tangency tolerance at the low vertex, yet the triangle
    # is long enough along the stripe to make a visible segment. It must not be counted as zero.
    triangle = [diagonal_point(3 - 1.0e-9, 0), diagonal_point(4, 1_000),
                diagonal_point(4, -1_000)]
    assert_equal 1, Tessellation.hatch(triangle).length / 2

    hatch = Tessellation.hatch(triangle * 9_000)

    assert_operator hatch.length / 2, :<=, Tessellation::MAX_HATCH_SEGMENTS
  end

  def test_degenerate_triangles_are_skipped
    assert_empty Tessellation.hatch([point(0, 0, 0), point(1, 1, 1), point(2, 2, 2)])
  end

  private

  def rectangle(left, bottom, right, top)
    low_left = point(left, bottom, 0)
    low_right = point(right, bottom, 0)
    high_right = point(right, top, 0)
    high_left = point(left, top, 0)
    [low_left, low_right, high_right, low_left, high_right, high_left]
  end

  def point(x_value, y_value, z_value)
    Geom::Point3d.new(x_value, y_value, z_value)
  end

  def diagonal_point(across, along)
    point((across + along) / Math.sqrt(2), (across - along) / Math.sqrt(2), 0)
  end
end
