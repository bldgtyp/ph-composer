# frozen_string_literal: true

module PhComposer
  # Detached, SI geometry for one SketchUp Face occurrence. Both adjacency and export use this
  # representation, so a transform or digest cannot mean one thing to the solver and another to HBJSON.
  module FaceGeometry
    INCH_TO_M = 0.0254
    QUANTUM_M = 0.000001 # 0.001 mm, the Phase 1 geometry-stamp contract.

    Snapshot = Struct.new(:loops_m, :normal, :plane_offset_m, :area_m2, :digest, keyword_init: true) do
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

    def capture(face, transform)
      loops = face.loops.map do |loop|
        loop.vertices.map do |vertex|
          point = vertex.position.transform(transform)
          [point.x.to_f * INCH_TO_M, point.y.to_f * INCH_TO_M, point.z.to_f * INCH_TO_M]
        end
      end
      normal = world_normal(face.normal, transform)
      plane = dot(normal, loops.fetch(0).fetch(0))
      area = face.area(transform).to_f * INCH_TO_M * INCH_TO_M
      canonical = {
        "plane" => quantize(plane), "normal" => normal.map { |value| quantize(value) },
        "outer" => canonical_loop(loops.fetch(0)),
        "holes" => loops.drop(1).map { |loop| canonical_loop(loop) }.sort
      }
      Snapshot.new(:loops_m => loops, :normal => normal, :plane_offset_m => plane, :area_m2 => area,
                   :digest => "sha256:#{CanonicalJson.digest(canonical)}")
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
      dot(left, right) <= -Math.cos(tolerance_degrees * Math::PI / 180.0) + 1.0e-12
    end

    # Whether two captured Faces lie in one plane, to within `tolerance` metres. Public because the
    # Classify tool's Shift flood asks it directly: a whole wall drawn as several pieces is one
    # plane, and the tool must not coin a second tolerance of its own for what that means.
    def coplanar?(left, right, tolerance)
      left_points = left.loops_m.flatten(1)
      right_points = right.loops_m.flatten(1)
      left_points.all? { |point| (dot(right.normal, point) - right.plane_offset_m).abs <= tolerance } &&
        right_points.all? { |point| (dot(left.normal, point) - left.plane_offset_m).abs <= tolerance }
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

    def world_normal(normal, transformation)
      values = transformation.to_a
      a, b, c = values[0], values[4], values[8]
      d, e, f = values[1], values[5], values[9]
      g, h, i = values[2], values[6], values[10]
      determinant = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
      raise CodedError.new("geometry.invalid", "The Face transform is singular.") if determinant.abs < 1.0e-12

      vector = [
        ((e * i - f * h) * normal.x + (f * g - d * i) * normal.y + (d * h - e * g) * normal.z) / determinant,
        ((c * h - b * i) * normal.x + (a * i - c * g) * normal.y + (b * g - a * h) * normal.z) / determinant,
        ((b * f - c * e) * normal.x + (c * d - a * f) * normal.y + (a * e - b * d) * normal.z) / determinant
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

    def dot(left, right)
      left.zip(right).sum { |a, b| a * b }
    end

    private_class_method :opposite_normals?, :same_loops?, :match_unordered,
                         :point_close?, :minimum_edge, :distance, :world_normal, :canonical_loop, :quantize, :dot
  end
end
