# frozen_string_literal: true

require "json"
require_relative "file_provider"

module PhComposer
  module Library
    # Per-machine native setup. Configuration paths cross only this store and the private provider
    # constructor. Every projection for a public client omits them.
    module Setup
      SECTION = "ph_composer.library"
      KEY = "file_providers"
      MAX_STORED_BYTES = 256 * 1024
      module_function

      def load
        raw = Sketchup.read_default(SECTION, KEY, nil)
        return [] unless raw.is_a?(String) && raw.bytesize <= MAX_STORED_BYTES * 2

        rows = JSON.parse(raw.unpack1("m0"))
        valid_configurations!(rows)
        Provider.immutable(rows)
      rescue Error, JSON::ParserError, ArgumentError, EncodingError
        []
      rescue SystemCallError, IOError
        raise Error.new("library.setup_unavailable", "Provider setup could not be read."), :cause => nil
      end

      def save(rows)
        valid_configurations!(rows)
        previous = load
        text = JSON.generate(rows.map { |row| row.slice("id", "label", "path") })
        if text.bytesize > MAX_STORED_BYTES
          raise Error.new("library.setup_too_large", "The provider setup exceeds its storage limit.")
        end
        unless Sketchup.write_default(SECTION, KEY, [text].pack("m0"))
          raise Error.new("library.setup_unavailable", "Provider setup could not be saved.")
        end
        changed_ids = (previous + rows).map { |row| row.fetch("id") }.uniq.select do |id|
          previous.find { |row| row.fetch("id") == id } != rows.find { |row| row.fetch("id") == id }
        end
        Sessions.all.each do |session|
          changed_ids.each { |id| State.for(session).remove(id) }
        end
        providers
      rescue SystemCallError, IOError
        raise Error.new("library.setup_unavailable", "Provider setup could not be saved."), :cause => nil
      end

      def add_file(id:, label:, path:)
        rows = load.reject { |row| row.fetch("id") == id }
        save(rows + [{ "id" => id, "label" => label, "path" => path }])
      end

      def remove(id)
        save(load.reject { |row| row.fetch("id") == id })
      end

      def providers
        Provider.immutable(load.map { |row|
 row.slice("id", "label").merge("provider_kind" => FileProvider::PROVIDER_KIND) })
      end

      def file_providers(kinds:, adapters:)
        load.map do |configuration|
          FileProvider.new(:id => configuration.fetch("id"), :label => configuration.fetch("label"),
                           :path => configuration.fetch("path"), :kinds => kinds, :adapters => adapters)
        end
      end

      def provider(id, kinds:, adapters:)
        configuration = load.find { |row| row.fetch("id") == id }
        unless configuration
          raise Error.new("library.provider_unavailable", "The configured library provider is unavailable.")
        end
        FileProvider.new(:id => configuration.fetch("id"), :label => configuration.fetch("label"),
                         :path => configuration.fetch("path"), :kinds => kinds, :adapters => adapters)
      end

      def valid_configurations!(rows)
        valid = rows.is_a?(Array) && rows.all? do |row|
          row.is_a?(Hash) && %w[id label path].all? { |key| row[key].is_a?(String) && !row[key].strip.empty? } &&
            /\A[a-zA-Z0-9_.-]+\z/.match?(row.fetch("id")) && (row.keys - %w[id label path]).empty?
        end
        ids = valid ? rows.map { |row| row.fetch("id") } : []
        return if valid && ids.uniq.length == ids.length

        raise Error.new("library.setup_invalid", "The provider setup is invalid.")
      end
      private_class_method :valid_configurations!
    end
  end
end
