# frozen_string_literal: true

require_relative "test_helper"
require "open3"
require "rbconfig"

class FaceGeometryTest < PhComposerTestCase
  Geometry = PhComposer::FaceGeometry

  def test_plane_offset_boundary_is_independent_and_inclusive
    left = snapshot([1, 0, 0])
    at_boundary = snapshot([-1, 0, 0], Geom::Transformation.translation([0.001, 0, 0]))
    beyond = snapshot([-1, 0, 0], Geom::Transformation.translation([0.001004, 0, 0]))

    assert equivalent?(left, at_boundary)
    refute equivalent?(left, beyond)
  end

  def test_normal_angle_boundary_and_same_normal_skip
    radians = 0.1 * Math::PI / 180.0
    at_boundary = [-Math.cos(radians), Math.sin(radians), 0]
    beyond = [-Math.cos(radians * 1.01), Math.sin(radians * 1.01), 0]
    left = snapshot([1, 0, 0], Geom::Transformation.new, :width_m => 0.011)

    assert equivalent?(left, snapshot(at_boundary, Geom::Transformation.new, :width_m => 0.011))
    refute equivalent?(left, snapshot(beyond, Geom::Transformation.new, :width_m => 0.011))
    refute equivalent?(left, snapshot([1, 0, 0], Geom::Transformation.new, :width_m => 0.011))
  end

  def test_small_area_and_narrow_faces_do_not_match
    left = snapshot([1, 0, 0], Geom::Transformation.new, :width_m => 0.009)
    right = snapshot([-1, 0, 0], Geom::Transformation.new, :width_m => 0.009)

    refute equivalent?(left, right)
  end

  def test_digest_covers_holes_world_transform_and_oriented_normal
    hole = rectangle(0.5, 1.0, 0.5, 1.0)
    face = Sketchup::Face.new(1, {}, :points => rectangle(0, 2, 0, 3), :holes => [hole],
                                     :normal => Geom::Vector3d.new(1, 0, 0))
    original = PhComposer::FaceCapture.call(face, Geom::Transformation.new)
    moved = PhComposer::FaceCapture.call(face, Geom::Transformation.translation([1, 0, 0]))
    opposite = Sketchup::Face.new(2, {}, :points => rectangle(0, 2, 0, 3), :holes => [hole],
                                         :normal => Geom::Vector3d.new(-1, 0, 0))

    refute_equal original.digest, moved.digest
    refute_equal original.digest, PhComposer::FaceCapture.call(opposite, Geom::Transformation.new).digest
    assert_equal 1, original.holes.length
  end

  def test_gross_area_comes_from_loops_when_cutting_instance_changes_sdk_net_area
    face = Sketchup::Face.new(10, {}, :points => rectangle(0, 4, 0, 3))
    original = PhComposer::FaceCapture.call(face, Geom::Transformation.new)
    # Native evidence: a 0.25 m2 cutting component changes SDK Face.area to 11.75 m2
    # while the underlying Face still owns the same 12 m2 outer loop and no inner loop.
    face.define_singleton_method(:area) { |_transform| 11.75 / (0.0254**2) }
    face.define_singleton_method(:get_glued_instances) { [:synthetic_glued_instance] }
    captured = PhComposer::FaceCapture.call(face, Geom::Transformation.new)

    assert_in_delta 12.0, captured.area_m2, 1.0e-10
    assert_equal original.to_h, captured.to_h
    assert captured.has_glued_instances
    assert_empty captured.holes
  end

  def test_polygon_area_is_independent_of_cyclic_start_and_winding_for_concave_faces
    inch = 1.0 / 0.0254
    points = [[0, 0], [4, 0], [4, 1], [1, 1], [1, 3], [0, 3]].map do |y, z|
      Geom::Point3d.new(0, y * inch, z * inch)
    end
    points.length.times do |index|
      [points.rotate(index), points.rotate(index).reverse].each do |loop|
        face = Sketchup::Face.new(11, {}, :points => loop)
        face.define_singleton_method(:area) { |_transform| raise "SDK area must not supply gross area." }
        assert_in_delta 6.0, PhComposer::FaceCapture.call(face, Geom::Transformation.new).area_m2, 1.0e-10
      end
    end
  end

  def test_actual_inner_loops_are_subtracted_independently_of_winding_and_sdk_net_area
    holes = [rectangle(0.5, 1.5, 0.5, 1.5).reverse, rectangle(2.0, 2.5, 1.0, 1.5)]
    face = Sketchup::Face.new(12, {}, :points => rectangle(0, 4, 0, 3), :holes => holes)
    face.define_singleton_method(:area) { |_transform| 10.5 / (0.0254**2) }
    captured = PhComposer::FaceCapture.call(face, Geom::Transformation.new)

    assert_in_delta 10.75, captured.area_m2, 1.0e-10
    assert_equal 2, captured.holes.length
  end

  def test_area_of_arbitrary_world_plane_with_nonuniform_mirrored_transform_and_real_holes
    face = Sketchup::Face.new(13, {}, :points => rectangle(0, 4, 0, 3),
                                      :holes => [rectangle(0.5, 1.5, 0.5, 1.5), rectangle(2.0, 2.5, 1.0, 1.5).reverse])
    # Orthonormal axes rotate the original y-z rectangle onto an oblique world plane;
    # independent y/z factors 2 and -3 mirror it and multiply every loop area by six.
    a, b, c = 1.0 / Math.sqrt(3), 1.0 / Math.sqrt(2), 1.0 / Math.sqrt(6)
    rotation = Geom::Transformation.new([a, a, a, 0, b, -b, 0, 0, c, c, -2 * c, 0, 0, 0, 0, 1])
    moved = Geom::Transformation.translation([1000 / 0.0254, -2000 / 0.0254, 3000 / 0.0254])
    transform = moved * rotation * Geom::Transformation.scaling(1.5, 2, -3)
    face.define_singleton_method(:area) { |_transform| 1.0 }

    assert_in_delta 64.5, PhComposer::FaceCapture.call(face, transform).area_m2, 1.0e-8
  end

  def test_the_rules_run_in_a_bare_process_without_sketchup
    path = File.join(TESTS_ROOT, "support", "face_geometry_pure.rb")
    out, err, status = Open3.capture3(RbConfig.ruby, path)
    assert status.success?, out + err
    assert_match(/0 failures, 0 errors/, out)
  end

  def test_the_adapter_builds_the_same_value_from_the_same_numbers
    face = Sketchup::Face.new(14, {}, :points => rectangle(0, 2, 0, 3), :holes => [rectangle(0.5, 1, 0.5, 1)],
                                      :normal => Geom::Vector3d.new(1, 0, 0))
    face.define_singleton_method(:get_glued_instances) { [:synthetic_glued_instance] }
    transform = Geom::Transformation.translation([10, 0, 0]) * Geom::Transformation.scaling(1, 2, 1)
    captured = PhComposer::FaceCapture.call(face, transform)
    loops = face.loops.map do |loop|
      loop.vertices.map do |vertex|
        point = vertex.position.transform(transform)
        [point.x, point.y, point.z].map { |value| value * 0.0254 }
      end
    end
    built = Geometry.build(:loops_m => loops, :normal => Geometry.world_normal([1.0, 0.0, 0.0], transform.to_a),
                           :has_glued_instances => true)

    assert_equal built.to_h, captured.to_h
    assert_equal built.digest, captured.digest
    assert captured.has_glued_instances
  end

  private

  def equivalent?(left, right)
    Geometry.equivalent_full_face?(
      left, right, :plane_tolerance_m => PhComposer::Zones::Adjacency::PLANE_TOLERANCE_M,
                   :angle_tolerance_degrees => PhComposer::Zones::Adjacency::NORMAL_ANGLE_TOLERANCE_DEGREES,
                   :point_tolerance_m => PhComposer::Zones::Adjacency::POINT_TOLERANCE_M
    )
  end

  def snapshot(normal, transform = Geom::Transformation.new, width_m: 2.0)
    face = Sketchup::Face.new(1, {}, :points => rectangle(0, width_m, 0, 3),
                                     :normal => Geom::Vector3d.new(*normal))
    PhComposer::FaceCapture.call(face, transform)
  end

  def rectangle(y0, y1, z0, z1)
    inch = 1.0 / 0.0254
    [[0, y0, z0], [0, y1, z0], [0, y1, z1], [0, y0, z1]].map do |x, y, z|
      Geom::Point3d.new(x * inch, y * inch, z * inch)
    end
  end
end
