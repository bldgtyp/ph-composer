# frozen_string_literal: true

# FaceGeometry's rules in a bare Ruby process: no SketchUp, no stub, no test_helper. It is not a
# `*_test.rb` file, so the stubbed suite never loads it; tests/face_geometry_test.rb runs it as a
# subprocess, and `ruby tests/support/face_geometry_pure.rb` runs it alone. A rule that needs the
# host here belongs in an adapter instead.
require "minitest/autorun"
require_relative "../../src/ph_composer/core/face_geometry"

class FaceGeometryPureTest < Minitest::Test
  G = PhComposer::FaceGeometry
  IDENTITY = [1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0].freeze

  def rectangle(y0, y1, z0, z1, x = 0.0)
    [[x, y0, z0], [x, y1, z0], [x, y1, z1], [x, y0, z1]]
  end

  def build(loops, normal = [1.0, 0.0, 0.0])
    G.build(:loops_m => loops, :normal => normal)
  end

  def test_no_sketchup_is_loaded
    refute defined?(Sketchup)
    refute defined?(Geom)
  end

  def test_concave_and_holed_areas_are_independent_of_start_and_winding
    concave = [[0, 0, 0], [0, 4, 0], [0, 4, 1], [0, 1, 1], [0, 1, 3], [0, 0, 3]].map { |p| p.map(&:to_f) }
    concave.length.times do |index|
      [concave.rotate(index), concave.rotate(index).reverse].each do |loop|
        assert_in_delta 6.0, build([loop]).area_m2, 1.0e-10
      end
    end
    holed = build([rectangle(0, 4, 0, 3), rectangle(0.5, 1.5, 0.5, 1.5).reverse, rectangle(2.0, 2.5, 1.0, 1.5)])
    assert_in_delta 10.75, holed.area_m2, 1.0e-10
  end

  def test_large_coordinates_keep_area_precision
    loop = rectangle(1_000_000.0, 1_000_004.0, 2_000_000.0, 2_000_003.0, 3_000_000.0)
    assert_in_delta 12.0, build([loop]).area_m2, 1.0e-6
  end

  def test_digest_ignores_loop_start_and_covers_holes_plane_and_normal
    base = build([rectangle(0, 2, 0, 3)])
    assert_equal base.digest, build([rectangle(0, 2, 0, 3).rotate(2)]).digest
    refute_equal base.digest, build([rectangle(0, 2, 0, 3), rectangle(0.5, 1, 0.5, 1)]).digest
    refute_equal base.digest, build([rectangle(0, 2, 0, 3, 1.0)]).digest
    refute_equal base.digest, build([rectangle(0, 2, 0, 3)], [-1.0, 0.0, 0.0]).digest
  end

  def test_world_normal_under_scaled_reflected_and_singular_matrices
    scaled = [2.0, 0, 0, 0, 0, 3.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0]
    normal = G.world_normal([1.0, 1.0, 0.0], scaled)
    expected = [1.0 / 2, 1.0 / 3, 0.0]
    length = Math.sqrt(expected.sum { |v| v**2 })
    expected.zip(normal).each { |want, got| assert_in_delta want / length, got, 1.0e-12 }
    reflected = [-1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0]
    assert_equal [-1.0, 0.0, 0.0], G.world_normal([1.0, 0.0, 0.0], reflected)
    assert_equal [1.0, 0.0, 0.0], G.world_normal([1.0, 0.0, 0.0], IDENTITY)
    singular = [0.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0]
    error = assert_raises(PhComposer::CodedError) { G.world_normal([1.0, 0.0, 0.0], singular) }
    assert_equal "geometry.invalid", error.code
  end

  def test_equivalence_and_coplanarity_fixtures
    left = build([rectangle(0, 2, 0, 3)], [1.0, 0.0, 0.0])
    right = build([rectangle(0, 2, 0, 3).reverse], [-1.0, 0.0, 0.0])
    tolerances = { :plane_tolerance_m => 0.001, :angle_tolerance_degrees => 0.1, :point_tolerance_m => 0.001 }
    assert G.equivalent_full_face?(left, right, **tolerances)
    shifted = build([rectangle(0, 2, 0, 3, 0.002).reverse], [-1.0, 0.0, 0.0])
    refute G.equivalent_full_face?(left, shifted, **tolerances)
    narrow = build([rectangle(0, 0.009, 0, 3)])
    refute G.equivalent_full_face?(narrow, build([rectangle(0, 0.009, 0, 3).reverse], [-1.0, 0.0, 0.0]),
                                   **tolerances)
  end
end
