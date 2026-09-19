# frozen_string_literal: true

module PhComposer
  module Export
    # The extraction document the translation package reads (python/ph_composer_translation), built
    # from every registered export contributor. Export knows no feature: each section is whatever its
    # contributor's contract returns.
    #
    #   {"schema_version": 1, "run_id": "...",
    #    "sections": {"<contributor name>": {"version": 1, "records": [{"id": ...}, ...]}}}
    module Collection
      SCHEMA_VERSION = 1

      Extraction = Struct.new(:document, :findings, keyword_init: true)

      module_function

      # Reads the Model; never writes. Raises Export::Blocked when data that export cannot leave out
      # would be lost.
      def build(model, run_id:, registry: Registry.current)
        catalog = registry.catalog
        reader = RecordReader.new(Records::Engine.new(model, catalog), catalog)
        sections = registry.export_contributors.values.sort_by(&:name).to_h do |contributor|
          records = reader.within(contributor.name) { contributor.contract.call(reader) }
          [contributor.name, { "version" => contributor.section_version, "records" => records }]
        end
        document = { "schema_version" => SCHEMA_VERSION, "run_id" => run_id.to_s, "sections" => sections }
        Extraction.new(:document => document, :findings => reader.findings.map(&:to_h))
      end
    end
  end
end
