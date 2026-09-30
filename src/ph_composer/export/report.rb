# frozen_string_literal: true

require "json"

module PhComposer
  module Export
    # The report that travels beside the HBJSON. It checks the translator's result document against the
    # composed privacy allowlist, renders the shell's sections and each contributor's own, and embeds
    # the result document unchanged for any later reader.
    module Report
      STYLESHEET = File.join(__dir__, "report.css")
      RESULT_ELEMENT_ID = "phc-export-result"
      STATE_LABELS = {
        "complete" => "Export complete", "complete_with_findings" => "Export complete with findings",
        "failed" => "Export not created"
      }.freeze

      module_function

      # `result` is the parsed result document; `notes` are the collection's findings about what was
      # left out of the extraction. Raises CodedError `export.privacy_undeclared` before rendering
      # anything if the result carries a field no declaration names.
      def render(result, notes: [], display_units: "SI", registry: Registry.current)
        Privacy.validate!(result, registry)
        title = STATE_LABELS.fetch(result.fetch("state"))
        sections = [
          summary(result.fetch("summary")),
          *registry.export_contributors.values.flat_map do |contributor|
            contributor.report ? Array(contributor.report.call(result, display_units)) : []
          end,
          findings("Findings", result.fetch("findings"), "No findings."),
          findings("Left out of the export", notes, "Nothing was left out.")
        ]
        <<~HTML
          <!doctype html>
          <html lang="en">
          <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>#{ReportHtml.h(title)}</title>
          <style>#{File.read(STYLESHEET, :encoding => 'UTF-8')}</style>
          </head>
          <body>
          <main>
          <p class="eyebrow">PH-Composer</p>
          <h1>#{ReportHtml.h(title)}</h1>
          <p>Values in this report are shown in #{ReportHtml.h(display_units)} units. HBJSON values remain SI.</p>
          #{sections.join("\n")}
          <footer>Run #{ReportHtml.h(result.fetch('run_id'))}</footer>
          </main>
          <script id="#{RESULT_ELEMENT_ID}" type="application/json">#{embedded_json(result)}</script>
          </body>
          </html>
        HTML
      end

      # The result document as the report embeds it. `JSON.parse` of the element's text returns it.
      def embedded_json(result)
        JSON.generate(result).gsub("<", "\\u003c").gsub(">", "\\u003e").gsub("&", "\\u0026")
      end

      def summary(summary)
        rows = [["Objects translated", summary.fetch("objects")], ["Objects unavailable", summary.fetch("unavailable")],
                ["Findings", summary.fetch("findings")]]
        ReportHtml.section("Summary", ReportHtml.table(%w[Item Count], rows))
      end
      private_class_method :summary

      def findings(title, rows, empty)
        return ReportHtml.section(title, ReportHtml.paragraph(empty)) if rows.empty?

        table = rows.map { |row| [row.fetch("object_id"), row.fetch("message")] }
        ReportHtml.section(title, ReportHtml.table(%w[Object Finding], table))
      end
      private_class_method :findings
    end
  end
end
