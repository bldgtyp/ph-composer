# frozen_string_literal: true

require_relative "definition_plan"
require_relative "mutation_scope"

module PhComposer
  module Windows
    module Units
      # Read actual geometry, not a cached signature or copied definition stamp. Materials and
      # names do not alter pane geometry; native drift guards capture those independently.
      module DefinitionGeometry
        module_function

        def capture(definition)
          CanonicalJson.digest(MutationScope.new.definition_snapshot(definition))
        end

        # Detached corners for geometry matching; callers retain the original native topology
        # separately for stale guards and removal. Collinear splits do not change a contour.
        def normalized_contour(points)
          normalized(points).map(&:dup)
        end

        def matches?(definition, type_id:, plan:)
          stamp = DEFINITION_STORE.read(definition)
          return false unless stamp.is_a?(Hash) && stamp["window_type_id"] == type_id

          entities = definition.entities.to_a
          return false unless entities.all? { |entity| entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Edge) }

          faces = entities.grep(Sketchup::Face)
          return false unless faces.length == plan.panes.length

          remaining = plan.panes.dup
          faces.each do |face|
            pane_stamp = PANE_STORE.read(face)
            return false unless pane_stamp.is_a?(Hash) && pane_stamp["window_type_id"] == type_id

            pane = remaining.find { |item| item.element_id == pane_stamp["element_id"] }
            return false unless pane && face.loops.length == 1 && face.normal.z.positive?

            actual = face.outer_loop.vertices.map { |vertex| metres(vertex.position) }
            return false unless cyclic_match?(actual, pane.polygon_m)

            remaining.delete(pane)
          end
          planned_edges = plan.panes.flat_map { |pane| segments(pane.polygon_m) }
          actual_edges = entities.grep(Sketchup::Edge).map do |edge|
            [metres(edge.start.position), metres(edge.end.position)]
          end
          actual_edges.all? do |edge|
            planned_edges.any? { |planned| edge.all? { |point| on_segment?(point, planned) } }
          end
        rescue StandardError
          false
        end

        def cyclic_match?(actual, expected)
          actual = normalized(actual)
          expected = normalized(expected)
          actual.length == expected.length && actual.length.times.any? do |index|
            actual.rotate(index).zip(expected).all? { |left, right| close?(left, right) }
          end
        end

        def close?(left, right)
          left.zip(right).all? { |a, b| a.finite? && (a - b).abs <= FaceGeometry::QUANTUM_M }
        end

        def metres(point)
          [point.x, point.y, point.z].map { |value| value.to_f * FaceGeometry::INCH_TO_M }
        end

        def segments(points)
          points.each_index.map { |index| [points[index], points[(index + 1) % points.length]] }
        end

        def normalized(points)
          values = points.dup
          loop do
            index = values.each_index.find do |i|
              neighbors = [values[(i - 1) % values.length], values[(i + 1) % values.length]]
              values.length > 3 && on_segment?(values[i], neighbors)
            end
            return values unless index

            values.delete_at(index)
          end
        end

        def on_segment?(point, segment)
          first, last = segment
          return true if close?(point, first) || close?(point, last)
          delta = first.zip(last).map { |a, b| b - a }
          square = delta.sum { |value| value * value }
          return close?(point, first) unless square.positive? && square.finite?

          t = point.zip(first).zip(delta).sum { |(p, a), d| (p - a) * d } / square
          return false unless t.between?(0.0, 1.0)

          projected = first.zip(delta).map { |a, d| a + t * d }
          close?(point, projected)
        end

        private_class_method :cyclic_match?, :close?, :metres, :segments, :normalized, :on_segment?
      end
    end
  end
end
