# frozen_string_literal: true

module PhComposer
  module Windows
    # Reads and naming rules every Windows definition kind shares: products, Window Types, and the
    # Window Unit repairs that create Types.
    module Definitions
      module_function

      def records(request, kind)
        request.engine.ids(kind.id).map { |id| request.engine.find(kind.id, id) }
      end

      def unique_name!(name, rows, except: nil)
        if name.strip.empty? || rows.any? { |row| row["id"] != except && row["name"].strip.casecmp(name.strip).zero? }
          raise CodedError.new("validation.failed", "Give the record a unique, nonempty name.")
        end
      end

      def duplicate_name(name, rows)
        stem = name.strip
        existing = rows.map { |row| row.fetch("name").strip.downcase }
        index = 1
        loop do
          candidate = index == 1 ? "#{stem} (copy)" : "#{stem} (copy #{index})"
          return candidate unless existing.include?(candidate.downcase)
          index += 1
        end
      end
    end
  end
end
