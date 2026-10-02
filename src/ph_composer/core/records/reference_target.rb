# frozen_string_literal: true

module PhComposer
  module Records
    # A detached, typed occurrence. Keys identify storage occurrences, not UUIDs: two copied
    # entities can have the same UUID while occupying different paths.
    ReferenceEntry = Struct.new(:kind, :key, :record, keyword_init: true)

    # Removal names an existing storage occurrence and its complete expected record, never a
    # nil-record tombstone or a UUID-wide exclusion that could hide another copied occurrence.
    ReferenceRemoval = Struct.new(:kind, :key, :before, keyword_init: true)

    # One live entity a reference target's `locate:` found: the entity, the collection holding it,
    # the accumulated parent-to-world transform and the persistent-id path of its parent. A caller
    # may read its geometry and glue to it; writes to its records stay with the owner.
    LocatedEntity = Struct.new(:kind, :reference, :entity, :entities, :transform, :parent_path, keyword_init: true)

    # A feature's read-only reference inventory. The provider returns ReferenceEntry values;
    # validation is pure and returns findings. Neither this contract nor the Engine exposes CRUD
    # for entity storage. Built-in and outside features register through FeatureScope alike.
    #
    # The optional `schema_version`, `values`, `occurrence` and `references` describe the kind
    # (descriptor.rb). `references` are the record's outgoing core references, which the engine's
    # incoming-reference scan enforces as it does a catalog kind's reference fields.
    #
    # The optional `locate:` is the owner's resolver, `->(model, reference, mutable:) { LocatedEntity }`,
    # raising the owner's `target.*` refusals. Other features reach it through `request.locate`.
    class ReferenceTarget
      attr_reader :id, :label, :provider, :validator, :descriptor

      def initialize(id:, label:, records:, validate:, schema_version: nil, values: Descriptor::ANY_OBJECT,
                     occurrence: nil, references: [], locate: nil)
        @id = id
        @label = label
        @provider = records
        @validator = validate
        @resolver = locate
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

      def locatable?
        !@resolver.nil?
      end

      def locate(model, reference, mutable:)
        raise InternalError, "#{id} declares no locate." unless locatable?

        located = @resolver.call(model, DeepCopy.call(reference), :mutable => mutable)
        unless located.is_a?(LocatedEntity) && located.kind == id && located.entity && located.entities &&
               located.transform && located.parent_path.is_a?(Array)
          raise InternalError, "#{id} returned an invalid located entity."
        end

        located
      end
    end

    # The exact entity collection an operation will replace, add or remove. New final records
    # and expected removed records are checked through their feature's pure validator.
    # This is a final-state projection, never a whitelist of arbitrary mapped UUID strings.
    class ReferencePlan
      attr_reader :entries, :removals

      def initialize(entries:, removals: [])
        valid_entries = entries.all? { |entry| entry.is_a?(ReferenceEntry) && entry.key && entry.record.is_a?(Hash) }
        valid_removals = removals.all? do |removal|
          removal.is_a?(ReferenceRemoval) && removal.key && removal.before.is_a?(Hash)
        end
        unless valid_entries && valid_removals
          raise InternalError, "A reference plan needs typed record occurrences."
        end
        keys = (entries + removals).map { |entry| [entry.kind, entry.key] }
        raise InternalError, "A reference plan repeats an occurrence." unless keys.uniq.length == keys.length

        @entries = entries.map do |entry|
          ReferenceEntry.new(:kind => DeepCopy.call(entry.kind), :key => DeepCopy.call(entry.key),
                             :record => DeepCopy.call(entry.record))
        end.freeze
        @removals = removals.map do |removal|
          ReferenceRemoval.new(:kind => DeepCopy.call(removal.kind), :key => DeepCopy.call(removal.key),
                               :before => DeepCopy.call(removal.before))
        end.freeze
      end

      def project(stored)
        removals.each { |removal| check_removal!(removal, stored) }
        replaced = (entries + removals).map { |entry| [entry.kind, entry.key] }
        stored.reject { |entry| replaced.include?([entry.kind, entry.key]) } + entries
      end

      private

      def check_removal!(removal, stored)
        matches = stored.select { |entry| entry.kind == removal.kind && entry.key == removal.key }
        detail = { "target_kind" => removal.kind, "key" => DeepCopy.call(removal.key) }
        if matches.empty?
          raise CodedError.new("target.not_found", "The planned removed occurrence no longer exists.", detail)
        end
        if matches.length > 1
          raise CodedError.new("target.ambiguous", "The planned removed occurrence is not unique.", detail)
        end
        return if matches.first.record == removal.before

        raise CodedError.new("target.changed", "The planned removed occurrence has changed.", detail)
      end
    end
  end
end
