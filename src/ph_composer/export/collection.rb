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
      def build(model, run_id:, registry: Registry.current, contributors: nil)
        catalog = registry.catalog
        session = Sessions.for(model)
        revision = session.revision
        records = RecordReader.new(Records::Engine.new(model, catalog), catalog)
        reader = SnapshotReader.new(records, GeometrySnapshot.capture(model, :revision => revision))
        declared = registry.export_contributors.values
        declared = declared.select { |contributor| Array(contributors).include?(contributor.name) } if contributors
        sections = declared.sort_by(&:name).to_h do |contributor|
          records = reader.within(contributor.name) { contributor.contract.call(reader) }
          [contributor.name, { "version" => contributor.section_version, "records" => records }]
        end
        if session.revision != revision
          raise Blocked.new("export.model_changed", "The Model changed while export geometry was collected.")
        end
        document = { "schema_version" => SCHEMA_VERSION, "run_id" => run_id.to_s, "sections" => sections }
        Extraction.new(:document => document, :findings => reader.findings.map(&:to_h))
      end
    end
  end
end
