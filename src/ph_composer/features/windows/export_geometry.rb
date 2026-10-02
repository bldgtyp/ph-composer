# frozen_string_literal: true

module PhComposer
  module Windows
    # Reads PH-Composer records out of the export snapshot's detached dictionaries. Native entities are
    # never retained or read again. Definition geometry is compared by Units::DefinitionGeometry.facts_match?,
    # the one matcher authoring uses too.
    module ExportGeometry
      module_function

      def record(dictionaries, store)
        text = dictionaries.dig(store.dictionary, store.key)
        return nil unless dictionaries.fetch(store.dictionary, {}).key?(store.key)
        unless text.is_a?(String)
          raise Export::Blocked.new("record.unreadable", "A Window record or geometry stamp is not JSON text.")
        end
        result = JSON.parse(text)
        unless result.is_a?(Hash)
          raise Export::Blocked.new("record.unreadable", "A Window record or geometry stamp is not a JSON object.")
        end
        result
      rescue JSON::ParserError
        raise Export::Blocked.new("record.unreadable", "A Window geometry stamp is not valid JSON.")
      end
    end
  end
end
