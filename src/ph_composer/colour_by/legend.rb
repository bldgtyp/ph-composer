# frozen_string_literal: true

module PhComposer
  module ColourBy
    # How an entry becomes a legend row's wording and figure. Pure; the service calls it at rebuild, inside
    # the mode's failure boundary, so a malformed label or figure turns the mode off with a notice.
    module Legend
      module_function

      # The entry's label as given (text, or parts formatted where shown), else its value, else
      # "Unclassified".
      def label(entry)
        return ReadoutOutput.parts!(entry.label) if entry.label.is_a?(Array)

        text = entry.label || entry.value
        text.nil? ? "Unclassified" : text.to_s
      end

      # Adds one entry's figure to its row's sum: one `[quantity, si_value]`, or a list of them summed position
      # by position (supply and extract). A row sums the same quantities in the same order throughout, so an
      # entry giving others, or anything that is not quantity pairs, fails the mode.
      def add_figure(row, figure)
        return unless figure

        pairs = figure.first.is_a?(Array) ? figure : [figure]
        unless pairs.all? { |pair| pair.is_a?(Array) && pair.length == 2 && !pair.first.is_a?(Array) }
          raise ArgumentError, "A legend figure is a [quantity, value] pair or a list of them."
        end

        ReadoutOutput.parts!(pairs)
        if row.figure && row.figure.map(&:first) != pairs.map(&:first)
          raise ArgumentError, "A legend row sums the same quantities throughout."
        end

        row.figure = pairs.each_with_index.map do |(quantity, value), index|
          [quantity, (row.figure ? row.figure[index].last : 0.0) + value.to_f]
        end
      end

      # A row's figures as display text: "60 m³/h / 40 m³/h".
      def figure_text(figure, system)
        figure.map { |pair| ReadoutOutput.text([pair], system) }.join(" / ")
      end
    end
  end
end
