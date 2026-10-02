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

        # Whether a live definition holds exactly the panes `plan` places for `type_id`. It captures
        # the definition as the export snapshot does and runs the one comparison both use. A stamp that
        # is not JSON or a degenerate pane Face is a coded data condition, so the geometry differs; any
        # other error is a defect and propagates to the dispatcher's `operation.failed` and the log.
        def matches?(definition, type_id:, plan:)
          facts_match?(Export::GeometrySnapshot.definition_facts(definition), :type_id => type_id, :plan => plan)
        rescue CodedError
          false
        end

        # Whether detached definition facts (Export::GeometrySnapshot.definition_facts) hold exactly
        # the panes `plan` places for `type_id`: one stamped, upward, single-loop Face per pane on the
        # pane's contour, and only Edges lying on pane edges. Behaviour flags are the caller's policy.
        def facts_match?(definition, type_id:, plan:)
          stamp = ExportGeometry.record(definition.fetch("dictionaries"), DEFINITION_STORE)
          return false unless stamp.is_a?(Hash) && stamp["window_type_id"] == type_id

          children = definition.fetch("entities")
          return false unless children.all? { |child| %w[face edge].include?(child["kind"]) }

          faces = children.select { |child| child["kind"] == "face" }
          return false unless faces.length == plan.panes.length

          remaining = plan.panes.dup
          faces.each do |face|
            pane_stamp = ExportGeometry.record(face.fetch("dictionaries"), PANE_STORE)
            return false unless pane_stamp.is_a?(Hash) && pane_stamp["window_type_id"] == type_id

            pane = remaining.find { |item| item.element_id == pane_stamp["element_id"] }
            geometry = face.fetch("geometry")
            return false unless pane && geometry.fetch("loops_m").length == 1 && geometry.fetch("normal")[2].positive?
            return false unless cyclic_match?(geometry.fetch("loops_m").first, pane.polygon_m)

            remaining.delete(pane)
          end
          planned_edges = plan.panes.flat_map { |pane| segments(pane.polygon_m) }
          children.select { |child| child["kind"] == "edge" }.all? do |child|
            planned_edges.any? { |planned| child.fetch("points_m").all? { |point| on_segment?(point, planned) } }
          end
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

        private_class_method :cyclic_match?, :close?, :segments, :normalized, :on_segment?
      end
    end
  end
end
