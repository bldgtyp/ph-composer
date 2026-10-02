# frozen_string_literal: true

require "json"
require_relative "library_file"

module PhComposer
  module Library
    # Every provider passes the same schema and privacy admission before a generation is published.
    # Third-party diagnostics are reduced to declared identities and codes, never arbitrary text.
    module Admission
      MAX_ROWS = 20_000
      MAX_BYTES = 64 * 1024 * 1024
      NOTE_FIELDS = %w[code kind library_id record_id index].freeze
      module_function

      def call(batch, kind:, adapter:)
        unless batch.is_a?(Provider::Batch)
          raise Error.new("library.provider_invalid", "The provider response is malformed.")
        end
        if batch.rows.length > MAX_ROWS || JSON.generate(batch.to_h).bytesize > MAX_BYTES
          raise Error.new("library.catalog_budget", "The provider response exceeds the catalog budget.")
        end
        warnings = notes(batch.warnings)
        unavailable = notes(batch.unavailable)
        duplicate = batch.rows.group_by { |row| [row.fetch("library_id"), row.fetch("record_id")] }
                         .select { |_identity, rows| rows.length > 1 }.keys.map(&:first).uniq
        duplicate.each do |id|
          unavailable << { "code" => "library.duplicate_record_id", "kind" => kind, "library_id" => id }
        end
        unsupported = batch.rows.reject { |row| row.fetch("wire_schema_version") == adapter.wire_version }
                           .map { |row| row.fetch("library_id") }.uniq
        unsupported.each do |id|
          unavailable << { "code" => "library.kind_schema_unsupported", "kind" => kind, "library_id" => id }
        end
        rows = batch.rows.filter_map do |row|
          next if duplicate.include?(row.fetch("library_id")) || unsupported.include?(row.fetch("library_id"))
          snapshot, codes = LibraryFile.normalize_row(row.fetch("snapshot"), adapter.wire_schema)
          warnings.concat(codes.map do |code|
            { "code" => code, "kind" => kind, "library_id" => row.fetch("library_id"),
              "record_id" => row.fetch("record_id") }
          end)
          next unless snapshot
          unless semantic_row?(snapshot, adapter)
            warnings << { "code" => "library.row_semantic_invalid", "kind" => kind,
                          "library_id" => row.fetch("library_id"), "record_id" => row.fetch("record_id") }
            next
          end

          row.merge("snapshot" => snapshot)
        end
        freshness = batch.freshness.slice("loaded_at", "exported_at").select do |_key, value|
          value.is_a?(String) && /\A\d{4}-\d\d-\d\dT[0-9:.+-]+Z?\z/.match?(value)
        end
        Provider::Batch.new(:rows => rows, :warnings => warnings, :unavailable => unavailable.uniq,
                            :freshness => freshness)
      rescue JSON::GeneratorError, EncodingError
        raise Error.new("library.provider_invalid", "The provider response is malformed."), :cause => nil
      end

      def semantic_row?(snapshot, adapter)
        mapped = adapter.map.call(DeepCopy.call(snapshot))
        JsonValue.problems(mapped).empty? && JsonSchema.validate(mapped, adapter.mapped_schema).empty?
      rescue CodedError => error
        raise unless error.code == "library.row_semantic_invalid"

        false
      end

      def notes(values)
        values.filter_map do |row|
          next unless row.is_a?(Hash) && row["code"].is_a?(String) && /\Alibrary\.[a-z0-9_.]+\z/.match?(row["code"])

          row.slice(*NOTE_FIELDS).select do |key, value|
            key == "index" ? value.is_a?(Integer) && value >= 0 : value.is_a?(String)
          end
        end
      end
      private_class_method :notes, :semantic_row?
    end
  end
end
