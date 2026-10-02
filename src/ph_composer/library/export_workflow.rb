# frozen_string_literal: true

require "securerandom"
require_relative "export_projection"
require_relative "file_writer"

module PhComposer
  module Library
    # The destination is the one the user chose in the native save dialog (Declarations::Approval),
    # with their consent to replace an existing file; it never enters params or the result. Writing is
    # not a Model operation and creates no Undo entry.
    module ExportWorkflow
      APPROVAL = Declarations::Approval.new(:kind => "save_file", :title => "Export Library File",
                                            :default_name => "model-library.json").freeze

      module_function

      def run(request)
        if request.params.key?("expected_revision") && request.params["expected_revision"] != request.session.revision
          raise Error.new("request.stale_revision", "The Model changed since the library export was requested.")
        end
        if request.params.key?("library_name") && request.params.fetch("library_name").strip.empty?
          raise Error.new("params.invalid", "The library name must not be blank.")
        end
        before = ExportProjection.build(request)
        writer = FileWriter.new(request.approval.path)
        if writer.replaces? && !request.approval.replace
          raise Error.new("export.replace_required", "The destination exists and was not approved for replacement.")
        end
        identity = request.params.fetch("identity", "new")
        library = if identity == "update"
                    existing(writer, request)
                  else
                    { "id" => SecureRandom.uuid, "name" => "Model library" }
                  end
        library["name"] = request.params["library_name"] if request.params.key?("library_name")
        document = { "format" => LibraryFile::FORMAT, "schema_version" => 1, "library" => library,
                     "exported_at" => Time.now.utc.iso8601(6) }.merge(before.slice("kind_schema_versions", "kinds"))
        document["record_origins"] = before.fetch("record_origins") unless before.fetch("record_origins").empty?
        bytes = JSON.pretty_generate(document) + "\n"
        if bytes.bytesize > LibraryFile::MAX_BYTES
          raise Error.new("library.file_too_large", "The library export exceeds the 32 MiB file limit.")
        end
        writer.write(bytes)
        ExportProjection.summary(before).merge("library_id" => library.fetch("id"),
                                               "library_name" => library.fetch("name"),
                                               "identity" => identity, "written" => true)
      rescue SystemCallError, IOError, EncodingError
        raise Error.new("library.export_write_failed", "The library file could not be written."), :cause => nil
      end

      def existing(writer, request)
        bytes = writer.prior_bytes
        unless bytes
          raise Error.new("library.update_destination_required", "Update identity needs an existing library file.")
        end

        adapters = request.registry.library_kinds.values.to_h { |row| [row.adapter.wire_kind, row.adapter] }
        lookup = ->(kind) { adapters[kind] }
        parsed = LibraryFile.parse(bytes, :adapters => lookup, :max_rows => FileProvider::MAX_ROWS)
        allowed = %w[library.row_optional_absent library.row_fields_omitted]
        warnings_valid = parsed.fetch("warnings").all? { |row| allowed.include?(row["code"]) }
        unless parsed.fetch("unavailable").empty? && warnings_valid && valid_rows?(parsed, adapters)
          raise Error.new("library.update_destination_invalid", "Update identity needs valid rows and supported kinds.")
        end
        DeepCopy.call(parsed.fetch("library"))
      end

      def valid_rows?(parsed, adapters)
        parsed.fetch("rows").all? do |kind, rows|
          adapter = adapters.fetch(kind)
          rows.all? do |row|
            mapped = adapter.map.call(DeepCopy.call(row.fetch("snapshot")))
            JsonValue.problems(mapped).empty? && JsonSchema.validate(mapped, adapter.mapped_schema).empty?
          end
        end
      rescue CodedError
        false
      end

      private_class_method :existing, :valid_rows?
    end
  end
end
