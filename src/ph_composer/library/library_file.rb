# frozen_string_literal: true

require "json"
require "time"
require_relative "provider"

module PhComposer
  module Library
    # Neutral envelope reader. The adapter supplies an explicit wire schema, independently of its
    # mapping or provider. Unknown fields are omitted; invalid declared values cost their row.
    module LibraryFile
      MAX_BYTES = 32 * 1024 * 1024
      FORMAT = "ph-composer.library"

      module_function

      def parse(text, adapters:, max_rows: nil)
        if !text.is_a?(String) || text.bytesize > MAX_BYTES
          raise Error.new("library.file_too_large", "A library file exceeds the 32 MiB limit.")
        end

        envelope = JSON.parse(text)
        validate_envelope!(envelope)
        library = envelope.fetch("library")
        count = envelope.fetch("kinds").values.sum { |input| input.is_a?(Array) ? input.length : 0 }
        if max_rows && count > max_rows
          raise Error.new("library.catalog_too_many_rows", "The catalog exceeds the 20,000 row aggregate limit.")
        end

        rows = {}
        warnings = []
        unavailable = []
        envelope.fetch("kinds").each do |kind, input|
          adapter = adapters.call(kind)
          code = kind_problem(envelope, kind, input, adapter)
          if code
            unavailable << note(code, kind, library.fetch("id"))
            next
          end
          normalized, skipped, duplicate = normalize(input, adapter.wire_schema, kind, library, adapter.wire_version)
          rows[kind] = duplicate ? [] : normalized
          warnings.concat(skipped)
          unavailable << note("library.duplicate_record_id", kind, library.fetch("id")) if duplicate
        end
        Provider.immutable("rows" => rows, "warnings" => warnings, "unavailable" => unavailable,
                           "raw_row_count" => count, "library" => library.slice("id", "name"),
                           "exported_at" => envelope.fetch("exported_at"))
      rescue JSON::ParserError, EncodingError
        raise Error.new("library.file_malformed", "The library file is not readable JSON."), :cause => nil
      end

      def validate_envelope!(value)
        unless value.is_a?(Hash) && value["format"] == FORMAT
          raise Error.new("library.format_invalid", "The file does not use the PH-Composer library format.")
        end
        unless value["schema_version"] == 1
          raise Error.new("library.schema_unsupported", "The library envelope version is not supported.")
        end

        library = value["library"]
        valid = value["kind_schema_versions"].is_a?(Hash) && value["kinds"].is_a?(Hash) && library.is_a?(Hash) &&
                text?(library["id"]) && text?(library["name"]) && timestamp?(value["exported_at"])
        return if valid

        raise Error.new("library.file_malformed", "The library envelope has a malformed required field.")
      end

      def kind_problem(envelope, kind, input, adapter)
        return "library.kind_unavailable" unless adapter
        return "library.kind_schema_missing" unless envelope.fetch("kind_schema_versions").key?(kind)

        version = envelope.fetch("kind_schema_versions")[kind]
        return "library.kind_schema_unsupported" unless version == adapter.wire_version
        return "library.kind_malformed" unless input.is_a?(Array)

        nil
      end

      def normalize(input, schema, kind, library, version)
        rows = []
        warnings = []
        ids = input.filter_map { |row| row["id"] if row.is_a?(Hash) && text?(row["id"]) }
        duplicate = ids.uniq.length != ids.length
        input.each_with_index do |row, index|
          snapshot, notes = normalize_row(row, schema)
          warnings.concat(notes.map do |code|
            note(code, kind, library.fetch("id")).merge("index" => index)
          end)
          next unless snapshot

          rows << { "library_id" => library.fetch("id"), "library_name" => library.fetch("name"),
                    "record_id" => snapshot.fetch("id"), "wire_schema_version" => version, "snapshot" => snapshot }
        end
        [rows.sort_by { |row|
           [row.dig("snapshot", "name").to_s.downcase, row.fetch("record_id")]
         }, warnings, duplicate]
      end

      # Shared pure schema admission for file and contributor-provider rows. Returns an allowlisted
      # detached snapshot and code-only warnings; it never maps semantic values or guesses units.
      def normalize_row(row, schema)
        return [nil, ["library.row_required_invalid"]] unless row.is_a?(Hash)

        properties = schema.fetch("properties")
        required = schema.fetch("required", [])
        snapshot = row.slice(*properties.keys)
        missing = required - snapshot.keys
        if missing.any? { |field| properties.fetch(field).key?("x-unit") }
          return [nil, ["library.unit_invalid"]]
        end

        bad_required = required.any? do |field|
          !snapshot.key?(field) || !JsonSchema.validate(snapshot[field], properties.fetch(field)).empty? ||
            (%w[id name].include?(field) && !text?(snapshot[field]))
        end
        return [nil, ["library.row_required_invalid"]] if bad_required

        bad_optional = (snapshot.keys - required).any? do |field|
          !JsonSchema.validate(snapshot[field], properties.fetch(field)).empty?
        end
        return [nil, ["library.row_optional_invalid"]] if bad_optional

        warnings = []
        warnings << "library.row_optional_absent" unless (properties.keys - required - snapshot.keys).empty?
        warnings << "library.row_fields_omitted" unless (row.keys - properties.keys).empty?
        [DeepCopy.call(snapshot), warnings]
      end

      def text?(value)
        value.is_a?(String) && !value.strip.empty?
      end

      def timestamp?(value)
        value.is_a?(String) && /T.*(?:Z|[+-]\d\d:\d\d)\z/.match?(value) && Time.iso8601(value)
      rescue ArgumentError
        false
      end

      def note(code, kind, library_id)
        { "code" => code, "kind" => kind, "library_id" => library_id }
      end
      private_class_method :validate_envelope!, :kind_problem, :normalize, :text?, :timestamp?, :note
    end
  end
end
