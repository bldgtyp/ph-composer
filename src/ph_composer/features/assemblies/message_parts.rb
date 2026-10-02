# frozen_string_literal: true

module PhComposer
  module Assemblies
    # The display layer formats quantities from canonical SI values. Ruby supplies no unit text.
    module MessageParts
      module_function

      def text(value)
        { "text" => value }
      end

      def quantity(quantity, value)
        { "quantity" => quantity, "value" => value }
      end

      def plain(lines)
        Array(lines).map { |line| [text(line)] }
      end

      def unique(lines, parts)
        indexes = lines.each_index.select { |index| lines.index(lines[index]) == index }
        [indexes.map { |index| lines[index] }, indexes.map { |index| parts.fetch(index) }]
      end
    end
  end
end
