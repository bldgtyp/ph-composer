# frozen_string_literal: true

require "json"

module PhComposer
  module Export
    # One detached traversal of the Model for every geometry contributor. Entries contain no live
    # SketchUp object, so a contributor cannot mutate the Model or rescan a definition behind export.
    class GeometrySnapshot
      Entry = Struct.new(:kind, :path, :transform, :dictionaries, :geometry, :native_name, :native,
        :keyword_init => true) do
        def record(dictionary)
          text = dictionaries.dig(dictionary, "record")
          return nil if text.nil?
          unless text.is_a?(String)
            raise Blocked.new("record.unreadable", "The #{dictionary} entity record is not JSON text.")
          end
          record = JSON.parse(text)
          unless record.is_a?(Hash)
            raise Blocked.new("record.unreadable", "The #{dictionary} entity record is not a JSON object.")
          end
          record
        rescue JSON::ParserError
          raise Blocked.new("record.unreadable", "The #{dictionary} entity record is not valid JSON.")
        end

        def to_h
          { "kind" => kind, "path" => path, "transform" => transform,
            "dictionaries" => dictionaries, "geometry" => geometry&.to_h }
        end
      end

      attr_reader :entries, :revision, :model_dictionaries

      # A traversal resumed by UI timers. One slice bounds both entity count and elapsed host work;
      # a single native Face capture cannot be interrupted, so it remains the smallest work unit.
      class Cursor
        attr_reader :entries, :count, :model_dictionaries

        def initialize(model)
          @model_dictionaries = GeometrySnapshot.send(:read_dictionaries, model)
          @walk = GeometrySnapshot.enum_for(:walk, model.entities, [], Geom::Transformation.new, {})
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
        new(cursor.entries, revision, :model_dictionaries => cursor.model_dictionaries)
      end

      def self.walk(entities, path, transform, definitions = {}, capture_faces: true, &block)
        entities.each do |entity|
          child_path = path + [entity.persistent_id]
          dictionaries = read_dictionaries(entity)
          if entity.is_a?(Sketchup::Face)
            entry = if capture_faces
                      Entry.new(:kind => "face", :path => child_path.freeze, :transform => transform.to_a.freeze,
                        :dictionaries => dictionaries, :geometry => FaceGeometry.capture(entity, transform))
                    end
            block.call(entry)
          elsif entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
            child_transform = transform * entity.transformation
            kind = entity.is_a?(Sketchup::Group) ? "group" : "component_instance"
            block.call(Entry.new(:kind => kind, :path => child_path.freeze, :transform => child_transform.to_a.freeze,
                                 :dictionaries => dictionaries, :geometry => nil,
                                 :native_name => entity.name.to_s.dup.freeze,
                                 :native => native_facts(entity, definitions, &block)))
            cuts = entity.is_a?(Sketchup::ComponentInstance) && entity.definition.behavior.cuts_opening?

            child_entities = entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
            walk(child_entities, child_path, child_transform, definitions, :capture_faces => capture_faces && !cuts,
              &block)
          else
            block.call(nil)
          end
        end
      end

      def self.native_facts(entity, definitions, &block)
        return nil unless entity.is_a?(Sketchup::ComponentInstance)

        definition = entity.definition
        facts = definitions[definition.persistent_id]
        unless facts
          children = []
          definition.entities.each do |child|
            children << definition_entity(child)
            block.call(nil) # A detached Face capture remains the smallest resumable native work unit.
          end
          facts = { "id" => definition.persistent_id, "dictionaries" => read_dictionaries(definition),
            "cuts_opening" => definition.behavior.cuts_opening?, "is2d" => definition.behavior.is2d?,
            "entities" => children.freeze }.freeze
          definitions[definition.persistent_id] = facts
        end
        { "definition" => facts, "glued_to_id" => entity.glued_to&.persistent_id }.freeze
      end

      def self.definition_entity(entity)
        result = { "dictionaries" => read_dictionaries(entity) }
        if entity.is_a?(Sketchup::Face)
          result.merge("kind" => "face", "geometry" => FaceGeometry.capture(entity, Geom::Transformation.new).to_h)
        elsif entity.is_a?(Sketchup::Edge)
          points = [entity.start.position, entity.end.position].map do |point|
            [point.x, point.y, point.z].map { |value| value.to_f * FaceGeometry::INCH_TO_M }.freeze
          end
          result.merge("kind" => "edge", "points_m" => points.freeze)
        else
          result.merge("kind" => "other")
        end.freeze
      end
      private_class_method :native_facts, :definition_entity

      def self.read_dictionaries(entity)
        Array(entity.attribute_dictionaries).each_with_object({}) do |dictionary, result|
          next unless dictionary.name.start_with?("#{DICTIONARY_PREFIX}.")

          values = {}
          dictionary.each { |key, value| values[key.to_s] = DeepCopy.call(value) }
          result[dictionary.name] = values.freeze
        end.freeze
      end
      private_class_method :read_dictionaries

      def initialize(entries, revision, model_dictionaries: {})
        @entries = entries.freeze
        @revision = revision
        @model_dictionaries = model_dictionaries.freeze
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
        @projections = {}
      end

      # Contributors share detached projections without repeating assessment or native reads.
      def projection(key)
        @projections.fetch(key) { @projections[key] = yield }
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
