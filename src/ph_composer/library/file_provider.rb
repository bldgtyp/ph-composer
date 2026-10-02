# frozen_string_literal: true

require_relative "library_file"

module PhComposer
  module Library
    # The private path is used only to read immediate candidate files. Exceptions and returned
    # catalog values carry configured ids and public labels, never filenames or OS error text.
    class FileProvider
      PROVIDER_KIND = "ph_composer.library.file"
      MAX_BYTES = 64 * 1024 * 1024
      MAX_ROWS = 20_000
      attr_reader :id, :label, :kinds, :freshness

      def initialize(id:, label:, path:, kinds:, adapters:)
        @id = Provider.immutable(id)
        @label = Provider.immutable(label)
        @path = path.to_s.dup.freeze
        @kinds = Provider.immutable(kinds)
        @adapters = adapters
        @freshness = Provider.immutable("loaded_at" => nil, "exported_at" => nil)
      end

      def provider_kind
        PROVIDER_KIND
      end

      def inspect
        "#<#{self.class.name} id=#{id.inspect}>"
      end

      def list(kind)
        unless kinds.include?(kind)
          raise Error.new("library.kind_unavailable", "This provider does not serve that record kind.")
        end

        documents, warnings = read_documents
        rows, unavailable = merge(documents, kind)
        warnings.concat(documents.flat_map { |document|
                          document.fetch("warnings").select { |row|
                            row["kind"] == kind
                          }
                        })
        exported = documents.map { |document| document.fetch("exported_at") }.max
        @freshness = Provider.immutable("loaded_at" => Time.now.utc.iso8601(6), "exported_at" => exported)
        Provider::Batch.new(:rows => rows, :warnings => warnings, :unavailable => unavailable, :freshness => freshness)
      rescue SystemCallError, IOError, EncodingError
        raise Error.new("library.file_unreadable", "The configured library file or folder could not be read."),
              :cause => nil
      end

      private

      def candidate_files
        return [@path] if File.file?(@path)

        return Dir.children(@path).sort.filter_map do |name|
          path = File.join(@path, name)
          path if File.file?(path) && File.extname(name).downcase == ".json"
        end if File.directory?(@path)

        raise Error.new("library.file_unreadable", "The configured library file or folder could not be read.")
      end

      def read_documents
        files = candidate_files
        sizes = files.map { |path| File.size(path) }
        if sizes.any? { |size| size > LibraryFile::MAX_BYTES }
          raise Error.new("library.file_too_large", "A library file exceeds the 32 MiB limit.")
        end
        if sizes.sum > MAX_BYTES
          raise Error.new("library.catalog_too_large", "The catalog exceeds the 64 MiB aggregate limit.")
        end

        documents = []
        warnings = []
        bytes = 0
        rows = 0
        files.each do |path|
          text = File.open(path, "rb") { |file| file.read(LibraryFile::MAX_BYTES + 1) }
          bytes += text.bytesize
          raise Error.new("library.catalog_too_large",
                          "The catalog exceeds the 64 MiB aggregate limit.") if bytes > MAX_BYTES

          document = read_candidate(text, File.directory?(@path), warnings, MAX_ROWS - rows)
          next unless document

          rows += document.fetch("raw_row_count")
          documents << document
        end
        [documents, warnings]
      end

      def read_candidate(text, folder, warnings, budget)
        LibraryFile.parse(text, :adapters => @adapters, :max_rows => budget)
      rescue Error => error
        raise if !folder || %w[library.file_too_large library.catalog_too_many_rows].include?(error.code)

        warnings << { "code" => error.code }
        nil
      end

      def merge(documents, kind)
        rows = documents.flat_map { |document| document.fetch("rows").fetch(kind, []) }
        unavailable = documents.flat_map { |document| document.fetch("unavailable") }
        labels = documents.group_by { |document| document.dig("library", "id") }
        labels.each do |library_id, parts|
          next if parts.map { |document| document.dig("library", "name") }.uniq.length == 1

          unavailable << { "code" => "library.identity_conflict", "kind" => kind, "library_id" => library_id }
        end
        rows.group_by { |row| [row.fetch("library_id"), row.fetch("record_id")] }.each do |(library_id, _id), entries|
          next if entries.length < 2

          unavailable << { "code" => "library.duplicate_record_id", "kind" => kind, "library_id" => library_id }
        end
        refused = unavailable.select { |row| row["kind"] == kind }.map { |row| row["library_id"] }
        rows.reject! { |row| refused.include?(row.fetch("library_id")) }
        [rows.sort_by { |row| [row.fetch("library_id"), row.dig("snapshot", "name").downcase, row.fetch("record_id")] },
         unavailable.uniq]
      end
    end
  end
end
