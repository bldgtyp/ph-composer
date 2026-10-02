# frozen_string_literal: true

module PhComposer
  module Windows
    # A Window Type layout read by side: row bands descend from the top, column bands run left to
    # right, and each element spans an inclusive range of both. Sides are indexed as `Types::SIDES`:
    # top, right, bottom, left. Side 0's boundary is the first row of a span, side 1's the last
    # column, side 2's the last row and side 3's the first column (host-measured, TECH_STACK section 6).
    class Grid
      # The band index a span's `side_index` boundary sits on.
      def self.edge(row_span, column_span, side_index)
        [row_span.first, column_span.last, row_span.last, column_span.first].fetch(side_index)
      end

      def initialize(record)
        @rows_m = record.fetch("rows_m")
        @columns_m = record.fetch("columns_m")
        @elements = record.fetch("elements")
      end

      # Every band pair a non-empty element covers.
      def occupancy
        @occupancy ||= @elements.each_with_object({}) do |cell, occupied|
          next if cell["kind"] == "empty"

          Range.new(*cell["row_span"]).each do |row|
            Range.new(*cell["column_span"]).each { |column| occupied[[row, column]] = true }
          end
        end
      end

      # The band pairs just outside each side of `cell`.
      def neighbors(cell)
        r0, r1 = cell["row_span"]
        c0, c1 = cell["column_span"]
        [(c0..c1).map { |c| [r0 - 1, c] }, (r0..r1).map { |r| [r, c1 + 1] },
         (c0..c1).map { |c| [r1 + 1, c] }, (r0..r1).map { |r| [r, c0 - 1] }]
      end

      # Per side: `:perimeter` when nothing lies beyond it, `:shared` when elements cover all of it,
      # `:partial` otherwise.
      def classify(cell)
        neighbors(cell).map do |coords|
          count = coords.count { |rc| occupancy[rc] }
          count.zero? ? :perimeter : (count == coords.length ? :shared : :partial)
        end
      end

      def outer_limit(side_index)
        Grid.edge([0, @rows_m.length - 1], [0, @columns_m.length - 1], side_index)
      end

      def cell_edge(cell, side_index)
        Grid.edge(cell.fetch("row_span"), cell.fetch("column_span"), side_index)
      end

      def on_outer_edge?(cell, side_index)
        cell_edge(cell, side_index) == outer_limit(side_index)
      end

      # The bands a side runs along: columns for top and bottom, rows for left and right.
      def bands(side_index)
        side_index.even? ? @columns_m : @rows_m
      end

      # The band indices `cell` covers along `side_index`.
      def span(cell, side_index)
        Range.new(*cell.fetch(side_index.even? ? "column_span" : "row_span"))
      end

      # The band sizes `cell` covers along `side_index`.
      def side_bands(cell, side_index)
        bands(side_index)[span(cell, side_index)]
      end

      def side_length(cell, side_index)
        side_bands(cell, side_index).sum
      end

      # Local plane corners, native corner 0 at bottom left.
      def rectangle(cell)
        r0, r1 = cell.fetch("row_span")
        c0, c1 = cell.fetch("column_span")
        x0 = @columns_m.take(c0).sum
        x1 = @columns_m.take(c1 + 1).sum
        top = @rows_m.take(r0).sum
        bottom = @rows_m.take(r1 + 1).sum
        [[x0, -bottom], [x1, -bottom], [x1, -top], [x0, -top]]
      end

      def outer_rectangle
        [[0, -@rows_m.sum], [@columns_m.sum, -@rows_m.sum], [@columns_m.sum, 0], [0, 0]]
      end
    end
  end
end
