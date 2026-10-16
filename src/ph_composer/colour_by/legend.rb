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

      # Adds one entry's `[quantity, si_value]` to its row's sum. A row sums one quantity, so entries giving
      # different quantities fail the mode.
      def add_figure(row, figure)
        return unless figure

        quantity, value = ReadoutOutput.parts!([figure]).first
        if row.figure && row.figure.first != quantity
          raise ArgumentError, "A legend row sums one quantity; #{row.figure.first} and #{quantity} differ."
        end

        row.figure = [quantity, (row.figure ? row.figure.last : 0.0) + value.to_f]
      end
    end
  end
end
