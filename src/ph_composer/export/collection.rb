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
          @contributors = Collection.ordered(registry.export_contributors.values)
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
          unless contributor
            @reader.reconcile!
            return true
          end

          records = @reader.within(contributor.name) { contributor.contract.call(@reader) }
          @sections[contributor.name] = { "version" => contributor.section_version, "records" => records }
          false
        end

        def extraction
          Extraction.new(:document => { "schema_version" => SCHEMA_VERSION, "run_id" => @run_id,
                                        "sections" => @sections.sort.to_h }, :findings => @reader.findings.map(&:to_h))
        end

        private

        def reader
          records = RecordReader.new(Records::Engine.new(@model, @registry.catalog), @registry.catalog,
                                     :reserved => Collection.reserved(@registry),
                                     :claims => Collection.claims(@registry))
          snapshot = GeometrySnapshot.new(@cursor.entries, Sessions.for(@model).revision,
                                          :model_dictionaries => @cursor.model_dictionaries)
          SnapshotReader.new(records, snapshot, :registry => @registry)
        end
      end

      module_function

      # Contributors in name order, except that each runs after every section it `requires:`, so an
      # entity owner's section has handed its claimed rows over before the claimant reads them.
      # Registration refuses section cycles (ExportValidation); the guard here stops one that slipped by.
      def ordered(contributors)
        by_name = contributors.to_h { |contributor| [contributor.name, contributor] }
        done = []
        visiting = []
        visit = lambda do |contributor|
          next if done.include?(contributor)
          raise InternalError,
                "Export sections require each other at #{contributor.name}." if visiting.include?(contributor)

          visiting << contributor
          Array(contributor.requires).sort.each { |name| visit.call(by_name[name]) if by_name[name] }
          visiting.delete(contributor)
          done << contributor
        end
        contributors.sort_by(&:name).each(&visit)
        done
      end

      # The user_data top-level keys exporters write themselves, which a user's own data may not take.
      def reserved(registry)
        Privacy.user_data_keys(registry).map { |key| key.split(".").first }.uniq
      end

      # `[namespace, target_kind]` to the claiming contributor and its declared fields.
      def claims(registry)
        registry.export_contributors.values.each_with_object({}) do |contributor, claims|
          Array(contributor.entity_projections).each do |claim|
            claims[claim.values_at("namespace", "target_kind")] = {
              "contributor" => contributor.name, "fields" => claim.fetch("fields"),
              "source_section" => claim.fetch("source_section")
            }
          end
        end
      end

      # Reads the Model; never writes. Raises Export::Blocked when data that export cannot leave out
      # would be lost.
      def build(model, run_id:, registry: Registry.current, contributors: nil)
        catalog = registry.catalog
        session = Sessions.for(model)
        revision = session.revision
        record_reader = RecordReader.new(Records::Engine.new(model, catalog), catalog, :claims => claims(registry),
                                                                                       :reserved => reserved(registry))
        reader = SnapshotReader.new(record_reader, GeometrySnapshot.capture(model, :revision => revision),
                                    :registry => registry)
        declared = registry.export_contributors.values
        declared = declared.select { |contributor| Array(contributors).include?(contributor.name) } if contributors
        sections = ordered(declared).to_h do |contributor|
          records = reader.within(contributor.name) { contributor.contract.call(reader) }
          [contributor.name, { "version" => contributor.section_version, "records" => records }]
        end.sort.to_h
        record_reader.reconcile!
        if session.revision != revision
          raise Blocked.new("export.model_changed", "The Model changed while export geometry was collected.")
        end

        document = { "schema_version" => SCHEMA_VERSION, "run_id" => run_id.to_s, "sections" => sections }
        Extraction.new(:document => document, :findings => reader.findings.map(&:to_h))
      end
    end
  end
end
