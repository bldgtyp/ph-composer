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

      # Geometry is read in bounded slices; each declared contributor then consumes that same
      # detached snapshot. The caller owns coherence and cancellation checks between advances.
      class Builder
        attr_reader :count

        def initialize(model, run_id:, registry: Registry.current)
          @model = model
          @run_id = run_id
          @registry = registry
          @cursor = GeometrySnapshot::Cursor.new(model)
          @contributors = registry.export_contributors.values.sort_by(&:name)
          @sections = {}
          @count = 0
        end

        def advance
          unless @cursor.done?
            @cursor.advance
            @count = @cursor.count
            return false
          end
          @reader ||= reader
          contributor = @contributors.shift
          return true unless contributor

          records = @reader.within(contributor.name) { contributor.contract.call(@reader) }
          @sections[contributor.name] = { "version" => contributor.section_version, "records" => records }
          false
        end

        def extraction
          Extraction.new(:document => { "schema_version" => SCHEMA_VERSION, "run_id" => @run_id,
                                        "sections" => @sections }, :findings => @reader.findings.map(&:to_h))
        end

        private

        def reader
          records = RecordReader.new(Records::Engine.new(@model, @registry.catalog), @registry.catalog)
          snapshot = GeometrySnapshot.new(@cursor.entries, Sessions.for(@model).revision,
                                          :model_dictionaries => @cursor.model_dictionaries)
          SnapshotReader.new(records, snapshot, :registry => @registry)
        end
      end

      module_function

      # Reads the Model; never writes. Raises Export::Blocked when data that export cannot leave out
      # would be lost.
      def build(model, run_id:, registry: Registry.current, contributors: nil)
        catalog = registry.catalog
        session = Sessions.for(model)
        revision = session.revision
        records = RecordReader.new(Records::Engine.new(model, catalog), catalog)
        reader = SnapshotReader.new(records, GeometrySnapshot.capture(model, :revision => revision),
                                    :registry => registry)
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
