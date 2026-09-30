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

      # A traversal resumed by UI timers. One slice bounds both entity count and elapsed host work;
      # a single native Face capture cannot be interrupted, so it remains the smallest work unit.
      class Cursor
        attr_reader :entries, :count

        def initialize(model)
          @walk = GeometrySnapshot.enum_for(:walk, model.entities, [], Geom::Transformation.new)
          @entries = []
          @count = 0
          @done = false
        end

        def advance(limit: 100, budget_seconds: 0.008)
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          limit.times do
            entry = @walk.next
            @entries << entry if entry
            @count += 1
            break if Process.clock_gettime(Process::CLOCK_MONOTONIC) - started >= budget_seconds
          end
          done?
        rescue StopIteration
          @done = true
        end

        def done?
          @done
        end
      end

      def self.capture(model, revision:)
        cursor = Cursor.new(model)
        cursor.advance until cursor.done?
        new(cursor.entries, revision)
      end

      def self.walk(entities, path, transform, &block)
        entities.each do |entity|
          child_path = path + [entity.persistent_id]
          dictionaries = read_dictionaries(entity)
          if entity.is_a?(Sketchup::Face)
            block.call(Entry.new(:kind => "face", :path => child_path.freeze, :transform => transform.to_a.freeze,
                                 :dictionaries => dictionaries, :geometry => FaceGeometry.capture(entity, transform)))
          elsif entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
            child_transform = transform * entity.transformation
            kind = entity.is_a?(Sketchup::Group) ? "group" : "component_instance"
            block.call(Entry.new(:kind => kind, :path => child_path.freeze, :transform => child_transform.to_a.freeze,
                                 :dictionaries => dictionaries, :geometry => nil))
            child_entities = entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
            walk(child_entities, child_path, child_transform, &block)
          else
            block.call(nil)
          end
        end
      end

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

      def descendants(parent, kind: nil)
        entries.select { |entry| (!kind || entry.kind == kind) && contains?(parent, entry) }
      end

      # Whether `entry` lies strictly inside `parent`, by occurrence path.
      def contains?(parent, entry)
        entry.path.length > parent.path.length && entry.path[0, parent.path.length] == parent.path
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
