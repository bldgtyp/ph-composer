# frozen_string_literal: true

require_relative "../../../core/face_geometry"
require_relative "../../../core/vector3"
require_relative "world_geometry"
require_relative "../placement/plane"

module PhComposer
  module Windows
    module Units
      # Exploded pane stamps identify cells, not corners. Retain only rigid mappings whose
      # complete authored outlines agree; an Empty band must never be guessed from symmetry.
      module RestoreGeometry
        TOLERANCE_M = FaceGeometry::QUANTUM_M

        module_function

        def infer(plan, panes, geometry)
          refuse! if plan.panes.empty?
          first = plan.panes.first
          actual = panes.fetch(first.element_id)
          candidates = actual.length.times.filter_map do |offset|
            matrix = candidate(first.polygon_m, actual.rotate(offset))
            next unless matrix && matches?(plan, panes, matrix)

            plane = Placement::Plane.new(geometry)
            next unless Vector3.dot(matrix[8, 3], plane.normal).positive? &&
                        actual.all? { |point| plane.signed_distance_m(point).abs <= TOLERANCE_M }

            matrix
          end
          refuse! if candidates.empty?
          outline = WorldGeometry.map(plan, candidates.first).outer_polygon_m
          refuse! unless candidates.all? do |matrix|
            same_polygon?(outline, WorldGeometry.map(plan, matrix).outer_polygon_m)
          end

          plane = Placement::Plane.new(geometry)
          candidates.max_by do |matrix|
            Vector3.dot(matrix.take(3), plane.x_axis) + Vector3.dot(matrix[4, 3], plane.y_axis)
          end.freeze
        end

        def candidate(local, world)
          dx = local[1][0] - local[0][0]
          dy = local[2][1] - local[1][1]
          return if dx.zero? || dy.zero?

          x = Vector3.subtract(world[1], world[0]).map { |value| value / dx }
          y = Vector3.subtract(world[2], world[1]).map { |value| value / dy }
          return unless [x, y].all? { |axis| (Vector3.dot(axis, axis) - 1).abs <= TOLERANCE_M } &&
                        Vector3.dot(x, y).abs <= TOLERANCE_M

          x = Vector3.normalize(x)
          y = Vector3.normalize(y)
          normal = Vector3.cross(x, y)
          origin = 3.times.map { |i| world[0][i] - x[i] * local[0][0] - y[i] * local[0][1] }
          x + [0] + y + [0] + normal + [0] + origin.map { |value| value / INCH_TO_M } + [1]
        end

        def matches?(plan, panes, matrix)
          WorldGeometry.map(plan, matrix).panes.all? do |pane|
            same_polygon?(pane.polygon_m, panes.fetch(pane.element_id))
          end
        end

        def same_polygon?(before, after)
          before.length == after.length && after.length.times.any? do |offset|
            before.zip(after.rotate(offset)).all? do |a, b|
              Vector3.subtract(a, b).all? { |value| value.abs <= TOLERANCE_M }
            end
          end
        end

        def segment_touches?(points, polygon)
          origin = polygon.first
          width = Vector3.subtract(polygon[1], origin)
          height = Vector3.subtract(polygon[3], origin)
          x = Vector3.normalize(width)
          y = Vector3.normalize(height)
          normal = Vector3.cross(x, y)
          projected = points.map do |point|
            delta = Vector3.subtract(point, origin)
            [Vector3.dot(delta, x), Vector3.dot(delta, y), Vector3.dot(delta, normal)]
          end
          limits = [Vector3.dot(width, x), Vector3.dot(height, y)]
          left, right = 0.0, 1.0
          3.times do |axis|
            minimum = -TOLERANCE_M
            maximum = (axis == 2 ? 0 : limits[axis]) + TOLERANCE_M
            a, b = projected.map { |point| point[axis] }
            if (b - a).abs < 1e-12
              return false unless a.between?(minimum, maximum)
            else
              lower, upper = [(minimum - a) / (b - a), (maximum - a) / (b - a)].minmax
              left = [left, lower].max
              right = [right, upper].min
              return false if left > right
            end
          end
          true
        end

        def refuse!
          raise CodedError.new("window.restore_unavailable",
                               "The stamped Faces do not uniquely match the complete Window Type outline. Use Place instead.")
        end
      end
    end
  end
end
