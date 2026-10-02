# frozen_string_literal: true

module PhComposer
  module Assemblies
    # Report-only attribution. The owning projection admits stable identifiers, never transport
    # configuration, the raw source snapshot or local metadata.
    module SourceReport
      SECTION = "#{FEATURE_ID}.export.material_sources"
      FIELDS = %w[id name provider_kind library_id record_id].freeze

      module_function

      def install(feature)
        feature.export_contributor(SECTION,
                                   :section_version => 1,
                                   :result => { "material_sources" => [Export::Privacy.fields(FIELDS)] },
                                   :report => method(:report)) do |reader|
          reader.records(MATERIAL_KIND).filter_map do |record|
            source = record["source"]
            next unless source.is_a?(Hash) && source["kind"] == "library"

            record.slice("id", "name").merge(source.slice("provider_kind", "library_id", "record_id"))
          end
        end
      end

      def report(result, _display_units)
        rows = result.fetch("material_sources", [])
        return [] if rows.empty?

        data = rows.map { |row| FIELDS.map { |key| row.fetch(key) } }
        body = Export::ReportHtml.table(["Local id", "Material", "Provider", "Library id", "Record id"], data)
        [Export::ReportHtml.section("Material source attribution", body)]
      end
    end
  end
end
