# frozen_string_literal: true

require_relative "canonical_json"
require_relative "errors"
require_relative "vector3"

module PhComposer
  # Detached, SI geometry for one SketchUp Face occurrence. Both adjacency and export use this
  # representation, so a transform or digest cannot mean one thing to the solver and another to HBJSON.
  # Everything here is pure over Arrays of Floats and loads without SketchUp
  # (tests/face_geometry_pure_test.rb); FaceCapture reads a live Face into it.
  module FaceGeometry
    INCH_TO_M = 0.0254
    QUANTUM_M = 0.000001 # 0.001 mm, the geometry-stamp normalization.

    # Glue is detached host state used to decide whether adjacency may cut, not geometric identity.
    # It stays out of the geometry digest and exported geometry payload.
    Snapshot = Struct.new(:loops_m, :normal, :plane_offset_m, :area_m2, :digest, :has_glued_instances,
                          keyword_init: true) do
      def outer_loop
        loops_m.first
      end

      def holes
        loops_m.drop(1)
      end

      def to_h
        {
          "loops_m" => loops_m, "normal" => normal, "plane_offset_m" => plane_offset_m,
          "area_m2" => area_m2, "digest" => digest
        }
      end
    end

    module_function

    # The detached value for one Face from explicit world loops in metres (outer first) and its
    # world unit normal. Pure: the SketchUp read is FaceCapture's.
    def build(loops_m:, normal:, has_glued_instances: false)
      plane = Vector3.dot(normal, loops_m.fetch(0).fetch(0))
      area = loop_area_m2(loops_m.fetch(0)) - loops_m.drop(1).sum { |loop| loop_area_m2(loop) }
      canonical = {
        "plane" => quantize(plane), "normal" => normal.map { |value| quantize(value) },
        "outer" => canonical_loop(loops_m.fetch(0)),
        "holes" => loops_m.drop(1).map { |loop| canonical_loop(loop) }.sort
      }
      Snapshot.new(:loops_m => loops_m, :normal => normal, :plane_offset_m => plane, :area_m2 => area,
                   :digest => "sha256:#{CanonicalJson.digest(canonical)}",
                   :has_glued_instances => has_glued_instances)
    end

    # SDK Face.area includes visual openings cut by glued components, even when those openings
    # create no Face inner loop. Gross geometry follows the actual world-space boundary loops.
    # Shift to the first vertex before summing cross products to avoid large-coordinate cancellation.
    def loop_area_m2(loop)
      origin = loop.fetch(0)
      points = loop.map { |point| point.zip(origin).map { |coordinate, offset| coordinate - offset } }
      vector = [0.0, 0.0, 0.0]
      points.each_with_index do |point, index|
        following = points[(index + 1) % points.length]
        vector[0] += point[1] * following[2] - point[2] * following[1]
        vector[1] += point[2] * following[0] - point[0] * following[2]
        vector[2] += point[0] * following[1] - point[1] * following[0]
      end
      Math.sqrt(vector.sum { |coordinate| coordinate**2 }) / 2.0
    end

    def equivalent_full_face?(left, right, plane_tolerance_m:, angle_tolerance_degrees:, point_tolerance_m:)
      return false if left.area_m2 < 0.01 || right.area_m2 < 0.01
      return false unless opposite_normals?(left.normal, right.normal, angle_tolerance_degrees)
      return false unless coplanar?(left, right, plane_tolerance_m)
      return false unless same_outline?(left, right, point_tolerance_m)

      minimum_edge(left.outer_loop) >= 0.01 && minimum_edge(right.outer_loop) >= 0.01
    end

    # Outline equality is independent of normal direction and cut thresholds. The solver uses
    # it to identify same-normal overlapping Zones, including identical holed or concave Faces.
    def same_outline?(left, right, tolerance_m)
      same_loops?(left.loops_m, right.loops_m, tolerance_m)
    end

    def opposite_normals?(left, right, tolerance_degrees)
      Vector3.dot(left, right) <= -Math.cos(tolerance_degrees * Math::PI / 180.0) + 1.0e-12
    end

    # Whether two captured Faces lie in one plane, to within `tolerance` metres. Public because the
    # Classify tool's Shift flood asks it directly: a whole wall drawn as several pieces is one
    # plane, and the tool must not coin a second tolerance of its own for what that means.
    def coplanar?(left, right, tolerance)
      left_points = left.loops_m.flatten(1)
      right_points = right.loops_m.flatten(1)
      left_points.all? { |point| (Vector3.dot(right.normal, point) - right.plane_offset_m).abs <= tolerance } &&
        right_points.all? { |point| (Vector3.dot(left.normal, point) - left.plane_offset_m).abs <= tolerance }
    end

    def same_loops?(left, right, tolerance)
      return false unless left.length == right.length

      loop_equal?(left.first, right.first, tolerance) &&
        match_unordered(left.drop(1), right.drop(1), tolerance)
    end

    def match_unordered(left, right, tolerance)
      unmatched = right.dup
      left.all? do |loop|
        index = unmatched.index { |candidate| loop_equal?(loop, candidate, tolerance) }
        index ? !unmatched.delete_at(index).nil? : false
      end
    end

    def loop_equal?(left, right, tolerance)
      return false unless left.length == right.length

      right.length.times.any? do |offset|
        aligned = left.each_index.all? do |index|
          point_close?(left[index], right[(index + offset) % right.length], tolerance)
        end
        reversed = left.each_index.all? do |index|
          point_close?(left[index], right[(offset - index) % right.length], tolerance)
        end
        aligned || reversed
      end
    end

    def point_close?(left, right, tolerance)
      Math.sqrt(left.zip(right).sum { |a, b| (a - b)**2 }) <= tolerance
    end

    def minimum_edge(loop)
      loop.each_with_index.map { |point, index| distance(point, loop[(index + 1) % loop.length]) }.min || 0.0
    end

    def distance(left, right)
      Math.sqrt(left.zip(right).sum { |a, b| (a - b)**2 })
    end

    # Refuses a 4x4 column-major matrix, 16 Floats, that collapses geometry (a zero scale); answers
    # its linear determinant.
    def check_transform!(matrix)
      values = matrix
      a, b, c = values[0], values[4], values[8]
      d, e, f = values[1], values[5], values[9]
      g, h, i = values[2], values[6], values[10]
      determinant = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
      raise CodedError.new("geometry.invalid", "The geometry transform is singular.") if determinant.abs < 1.0e-12

      determinant
    end

    # The world unit normal of local `normal` ([x, y, z]) under a 4x4 column-major matrix of 16 Floats:
    # the inverse transpose, so a non-uniform or mirrored scale keeps the normal perpendicular.
    def world_normal(normal, matrix)
      values = matrix
      a, b, c = values[0], values[4], values[8]
      d, e, f = values[1], values[5], values[9]
      g, h, i = values[2], values[6], values[10]
      determinant = check_transform!(matrix)
      nx, ny, nz = normal

      vector = [
        ((e * i - f * h) * nx + (f * g - d * i) * ny + (d * h - e * g) * nz) / determinant,
        ((c * h - b * i) * nx + (a * i - c * g) * ny + (b * g - a * h) * nz) / determinant,
        ((b * f - c * e) * nx + (c * d - a * f) * ny + (a * e - b * d) * nz) / determinant
      ]
      length = Math.sqrt(vector.sum { |value| value**2 })
      raise CodedError.new("geometry.invalid", "The Face normal has no direction.") if length.zero?

      vector.map { |value| value / length }
    end

    def canonical_loop(loop)
      values = loop.map { |point| point.map { |coordinate| quantize(coordinate) } }
      rotations = values.length.times.map { |index| values.rotate(index) }
      rotations.min
    end

    def quantize(value)
      rounded = (value / QUANTUM_M).round * QUANTUM_M
      rounded.zero? ? 0.0 : rounded
    end

    private_class_method :opposite_normals?, :same_loops?, :match_unordered,
                         :point_close?, :minimum_edge, :distance, :canonical_loop, :quantize,
                         :loop_area_m2
  end
end
