# frozen_string_literal: true

require_relative "test_helper"

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
    original = Geometry.capture(face, Geom::Transformation.new)
    moved = Geometry.capture(face, Geom::Transformation.translation([1, 0, 0]))
    opposite = Sketchup::Face.new(2, {}, :points => rectangle(0, 2, 0, 3), :holes => [hole],
                                          :normal => Geom::Vector3d.new(-1, 0, 0))

    refute_equal original.digest, moved.digest
    refute_equal original.digest, Geometry.capture(opposite, Geom::Transformation.new).digest
    assert_equal 1, original.holes.length
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
    Geometry.capture(face, transform)
  end

  def rectangle(y0, y1, z0, z1)
    inch = 1.0 / 0.0254
    [[0, y0, z0], [0, y1, z0], [0, y1, z1], [0, y0, z1]].map do |x, y, z|
      Geom::Point3d.new(x * inch, y * inch, z * inch)
    end
  end
end
