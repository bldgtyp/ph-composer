# frozen_string_literal: true

require "cgi"

module PhComposer
  module Export
    # The HTML pieces the report and every contributor's report sections share, so a value renders the
    # same way everywhere. Every value is escaped here.
    module ReportHtml
      module_function

      def section(title, body)
        "<section><h2>#{h(title)}</h2>#{body}</section>"
      end

      def table(headings, rows)
        head = headings.map { |label| "<th>#{h(label)}</th>" }.join
        body = rows.map { |values| "<tr>#{values.map { |value| "<td>#{h(value)}</td>" }.join}</tr>" }.join
        "<table><thead><tr>#{head}</tr></thead><tbody>#{body}</tbody></table>"
      end

      def paragraph(text)
        "<p>#{h(text)}</p>"
      end

      # A heading inside a section, whose own title is the h2: `level` is 3 to 6.
      def heading(level, text)
        raise ArgumentError, "heading level #{level} is not 3 to 6" unless (3..6).cover?(level)

        "<h#{level}>#{h(text)}</h#{level}>"
      end

      def h(value)
        CGI.escapeHTML(value.to_s)
      end
    end
  end
end
