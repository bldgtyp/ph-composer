# frozen_string_literal: true

module PhComposer
  module Windows
    # Pure checks over the generic export snapshot's detached definition facts. Native entities are
    # never retained or read again; the same contour normalization as authoring ignores collinear splits.
    module ExportGeometry
      module_function

      def record(dictionaries, store)
        text = dictionaries.dig(store.dictionary, store.key)
        return nil unless dictionaries.fetch(store.dictionary, {}).key?(store.key)
        unless text.is_a?(String)
          raise Export::Blocked.new("record.unreadable", "A Window record or geometry stamp is not JSON text.")
        end
        result = JSON.parse(text)
        unless result.is_a?(Hash)
          raise Export::Blocked.new("record.unreadable", "A Window record or geometry stamp is not a JSON object.")
        end
        result
      rescue JSON::ParserError
        raise Export::Blocked.new("record.unreadable", "A Window geometry stamp is not valid JSON.")
      end

      def matches?(definition, type_id:, plan:)
        stamp = record(definition.fetch("dictionaries"), Units::DEFINITION_STORE)
        return false unless stamp.is_a?(Hash) && stamp["window_type_id"] == type_id
        return false unless definition["cuts_opening"] && definition["is2d"]

        children = definition.fetch("entities")
        return false unless children.all? { |child| %w[face edge].include?(child["kind"]) }
        faces = children.select { |child| child["kind"] == "face" }
        return false unless faces.length == plan.panes.length

        remaining = plan.panes.dup
        faces.each do |face|
          pane_stamp = record(face.fetch("dictionaries"), Units::PANE_STORE)
          return false unless pane_stamp.is_a?(Hash) && pane_stamp["window_type_id"] == type_id
          pane = remaining.find { |item| item.element_id == pane_stamp["element_id"] }
          geometry = face.fetch("geometry")
          return false unless pane && geometry.fetch("normal")[2].positive? && geometry.fetch("loops_m").length == 1
          actual = Units::DefinitionGeometry.normalized_contour(geometry.fetch("loops_m").first)
          return false unless FaceGeometry.loop_equal?(actual, pane.polygon_m, FaceGeometry::QUANTUM_M)

          remaining.delete(pane)
        end
        edges = plan.panes.flat_map { |pane| segments(pane.polygon_m) }
        children.select { |child| child["kind"] == "edge" }.all? do |child|
          edges.any? { |edge| child.fetch("points_m").all? { |point| on_segment?(point, edge) } }
        end
      end

      def segments(points)
        points.each_index.map { |index| [points[index], points[(index + 1) % points.length]] }
      end

      def on_segment?(point, edge)
        delta = edge[1].zip(edge[0]).map { |b, a| b - a }
        length = delta.sum { |value| value * value }
        return close?(point, edge[0]) unless length.positive?

        t = point.zip(edge[0]).zip(delta).sum { |(p, a), d| (p - a) * d } / length
        return false unless t.between?(0.0, 1.0)

        expected = edge[0].zip(delta).map { |a, d| a + t * d }
        close?(point, expected)
      end

      def close?(left, right)
        left.zip(right).sum { |a, b| (a - b)**2 } <= FaceGeometry::QUANTUM_M**2
      end
      private_class_method :segments, :on_segment?, :close?
    end
  end
end
