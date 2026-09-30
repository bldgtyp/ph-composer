# frozen_string_literal: true

module PhComposer
  module Records
    # A detached, typed occurrence. Keys identify storage occurrences, not UUIDs: two copied
    # entities can have the same UUID while occupying different paths.
    ReferenceEntry = Struct.new(:kind, :key, :record, keyword_init: true)

    # A feature's read-only reference inventory. The provider returns ReferenceEntry values;
    # validation is pure and returns findings. Neither this contract nor the Engine exposes CRUD
    # for entity storage. Built-in and outside features register through FeatureScope alike.
    #
    # The optional `schema_version`, `values`, `occurrence` and `references` describe the kind
    # (descriptor.rb). `references` are the record's outgoing core references, which the engine's
    # incoming-reference scan enforces as it does a catalog kind's reference fields.
    class ReferenceTarget
      attr_reader :id, :label, :provider, :validator, :descriptor

      def initialize(id:, label:, records:, validate:, schema_version: nil, values: Descriptor::ANY_OBJECT,
                     occurrence: nil, references: [])
        @id = id
        @label = label
        @provider = records
        @validator = validate
        @descriptor = Descriptor.new(:kind => id, :label => label, :schema_version => schema_version,
                                     :values_schema => values, :occurrence_schema => occurrence,
                                     :references => references)
      end

      def entries(model)
        provider.call(model).map do |entry|
          unless entry.is_a?(ReferenceEntry) && entry.kind == id && entry.key && entry.record.is_a?(Hash)
            raise InternalError, "#{id} returned an invalid reference occurrence."
          end

          ReferenceEntry.new(:kind => id, :key => DeepCopy.call(entry.key), :record => DeepCopy.call(entry.record))
        end
      end
    end

    # The exact entity collection an operation will replace, supplied as typed before/after
    # occurrences. Newly allocated records are checked through their feature's pure validator.
    # This is a final-state projection, never a whitelist of arbitrary mapped UUID strings.
    class ReferencePlan
      attr_reader :entries

      def initialize(entries:)
        unless entries.all? { |entry| entry.is_a?(ReferenceEntry) && entry.key && entry.record.is_a?(Hash) }
          raise InternalError, "A reference plan needs typed record occurrences."
        end
        keys = entries.map { |entry| [entry.kind, entry.key] }
        raise InternalError, "A reference plan repeats an occurrence." unless keys.uniq.length == keys.length

        @entries = entries.map do |entry|
          ReferenceEntry.new(:kind => entry.kind, :key => DeepCopy.call(entry.key),
                             :record => DeepCopy.call(entry.record))
        end.freeze
      end

      def project(stored)
        replaced = entries.map { |entry| [entry.kind, entry.key] }
        stored.reject { |entry| replaced.include?([entry.kind, entry.key]) } + entries
      end
    end
  end
end
