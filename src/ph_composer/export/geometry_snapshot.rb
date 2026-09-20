# frozen_string_literal: true

require "json"

module PhComposer
  module Export
    # One detached traversal of the Model for every geometry contributor. Entries contain no live
    # SketchUp object, so a contributor cannot mutate the Model or rescan a definition behind export.
    class GeometrySnapshot
      Entry = Struct.new(:kind, :path, :transform, :dictionaries, :geometry, keyword_init: true) do
        def record(dictionary)
          text = dictionaries.dig(dictionary, "record")
          text.nil? ? nil : JSON.parse(text)
        rescue JSON::ParserError
          raise Blocked.new("record.unreadable", "The #{dictionary} entity record is not valid JSON.")
        end

        def to_h
          { "kind" => kind, "path" => path, "transform" => transform,
            "dictionaries" => dictionaries, "geometry" => geometry&.to_h }
        end
      end

      attr_reader :entries, :revision

      def self.capture(model, revision:)
        found = []
        walk(model.entities, [], Geom::Transformation.new, found)
        new(found, revision)
      end

      def self.walk(entities, path, transform, found)
        entities.each do |entity|
          child_path = path + [entity.persistent_id]
          dictionaries = read_dictionaries(entity)
          if entity.is_a?(Sketchup::Face)
            found << Entry.new(:kind => "face", :path => child_path.freeze, :transform => transform.to_a.freeze,
                               :dictionaries => dictionaries, :geometry => FaceGeometry.capture(entity, transform))
          elsif entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
            child_transform = transform * entity.transformation
            kind = entity.is_a?(Sketchup::Group) ? "group" : "component_instance"
            found << Entry.new(:kind => kind, :path => child_path.freeze, :transform => child_transform.to_a.freeze,
                               :dictionaries => dictionaries, :geometry => nil)
            child_entities = entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
            walk(child_entities, child_path, child_transform, found)
          end
        end
      end
      private_class_method :walk

      def self.read_dictionaries(entity)
        Array(entity.attribute_dictionaries).each_with_object({}) do |dictionary, result|
          next unless dictionary.name.start_with?("#{DICTIONARY_PREFIX}.")

          values = {}
          dictionary.each { |key, value| values[key.to_s] = DeepCopy.call(value) }
          result[dictionary.name] = values.freeze
        end.freeze
      end
      private_class_method :read_dictionaries

      def initialize(entries, revision)
        @entries = entries.freeze
        @revision = revision
      end

      def records(dictionary, kind: nil)
        entries.filter_map do |entry|
          next if kind && entry.kind != kind
          record = entry.record(dictionary)
          [entry, record] if record
        end
      end

      def entry_at(path, kind: nil)
        matches = entries.select { |entry| entry.path == path && (!kind || entry.kind == kind) }
        if matches.length > 1
          raise Blocked.new("target.ambiguous", "An export occurrence path resolves more than once.")
        end
        matches.first
      end

      def zone_owner(entry)
        matches = records(Zones::ZONE_DICTIONARY, :kind => "group").select do |zone_entry, _record|
          prefix?(entry.path, zone_entry.path) && entry.path.length > zone_entry.path.length
        end
        if matches.length > 1
          raise Blocked.new("face.wrong_zone", "A Face is contained by more than one Zone.")
        end
        matches.first
      end

      def descendants(parent, kind: nil)
        entries.select do |entry|
          (!kind || entry.kind == kind) && entry.path.length > parent.path.length && prefix?(entry.path, parent.path)
        end
      end

      private

      def prefix?(path, prefix)
        path[0, prefix.length] == prefix
      end
    end

    # The existing metadata-safe record reader plus the one shared geometry snapshot.
    class SnapshotReader
      attr_reader :snapshot

      def initialize(records, snapshot)
        @records = records
        @snapshot = snapshot
      end

      def within(section, &block)
        @records.within(section, &block)
      end

      def records(*arguments, **keywords)
        @records.records(*arguments, **keywords)
      end

      def entity_record(record, fields:)
        @records.entity_record(record, :fields => fields)
      end

      def findings
        @records.findings
      end
    end
  end
end
