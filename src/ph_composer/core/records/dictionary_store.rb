# frozen_string_literal: true

require "json"

module PhComposer
  module Records
    # Model-level persistence: one attribute dictionary per record kind, one JSON string per record id.
    # Reads never create a dictionary, so a read cannot mark the Model modified. The registry adds the
    # dictionary to Dictionaries when the kind is published, not when it is declared.
    class DictionaryStore
      attr_reader :dictionary

      def initialize(kind_id)
        @dictionary = "#{DICTIONARY_PREFIX}.records.#{kind_id}"
      end

      # The stored record as parsed JSON, or nil when absent. Raises JSON::ParserError when the stored
      # text is not JSON; the engine reports that record as unreadable.
      def read(model, id)
        text = model.attribute_dictionary(@dictionary)&.[](id)
        text.nil? ? nil : JSON.parse(text)
      end

      def ids(model)
        dictionary = model.attribute_dictionary(@dictionary)
        return [] unless dictionary

        ids = []
        dictionary.each { |key, _text| ids << key.to_s }
        ids.sort
      end

      def write(model, record)
        model.attribute_dictionary(@dictionary, true)[record.fetch("id")] = CanonicalJson.generate(record)
      end
    end
  end
end
