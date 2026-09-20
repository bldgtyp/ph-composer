# frozen_string_literal: true

require "json"

module PhComposer
  module Records
    # Canonical JSON stored on one explicitly resolved SketchUp entity. The caller owns occurrence
    # resolution; this store never scans the Model or substitutes a similarly named entity.
    class EntityStore
      attr_reader :dictionary, :key

      def initialize(dictionary, key: "record")
        @dictionary = Dictionaries.register(dictionary)
        @key = key
      end

      def read(entity)
        text = entity.get_attribute(dictionary, key)
        text.nil? ? nil : JSON.parse(text)
      rescue JSON::ParserError
        raise CodedError.new("record.unreadable", "The #{dictionary} record is not valid JSON.")
      end

      def write(entity, record)
        entity.set_attribute(dictionary, key, CanonicalJson.generate(record))
      end

      def delete(entity)
        entity.delete_attribute(dictionary, key)
      end
    end
  end
end
