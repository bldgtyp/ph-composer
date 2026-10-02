# frozen_string_literal: true

require_relative "admission"
require_relative "catalog"

module PhComposer
  module Library
    # Session-only catalog generations. Provider factories receive no host objects; private setup
    # stays in the configured provider. No row is fetched or copied during metadata discovery.
    class State
      def self.for(session)
        session.feature_state("ph_composer.library.catalogs") { new }
      end

      def initialize
        @catalog = Catalog.new
        @copy_times = {}
      end

      # A preview and its guarded invocation share the gesture's copy timestamp. Revision-bound,
      # bounded session memory keeps it out of semantic fingerprints and the Model until commit.
      def copy_time(revision, identity)
        key = [revision, identity]
        @copy_times.delete_if { |(stored_revision, _identity), _time| stored_revision != revision }
        @copy_times.shift while @copy_times.length >= 128 && !@copy_times.key?(key)
        @copy_times[key] ||= Time.now.utc.iso8601(6)
      end

      def providers(registry)
        rows = registry.library_providers.values.flat_map do |declaration|
          instances = factory_instances(declaration)
          valid = instances.is_a?(Array) &&
                  instances.all? { |provider| valid_provider?(provider, declaration, registry) }
          unless valid
            raise Error.new("library.provider_invalid", "The registered provider factory returned invalid metadata.")
          end
          instances
        end
        if rows.map(&:id).uniq.length != rows.length
          raise Error.new("library.provider_ambiguous", "Configured provider ids are ambiguous.")
        end
        rows
      end

      def provider(id, registry)
        providers(registry).find { |row| row.id == id } ||
          raise(Error.new("library.provider_unavailable", "The configured provider is unavailable."))
      end

      def metadata(registry)
        providers(registry).map do |provider|
          catalogs = provider.kinds.map do |kind|
            @catalog.fetch(provider.id, kind).slice(
              "kind", "generation", "state", "failure", "age_seconds", "freshness"
            )
          end
          { "id" => provider.id, "provider_kind" => provider.provider_kind, "label" => provider.label,
            "kinds" => provider.kinds, "catalogs" => catalogs }
        end
      end

      def remove(provider_id)
        @catalog.remove(provider_id)
        @copy_times.clear
        nil
      end

      def refresh(id, kind, registry)
        selected = provider(id, registry)
        unless selected.kinds.include?(kind)
          raise Error.new("library.kind_unavailable", "This provider does not serve the requested kind.")
        end
        declaration = self.class.kind(kind, registry)
        @catalog.refresh(selected, :kind => kind) do |batch|
          Admission.call(batch, :kind => kind, :adapter => declaration.adapter)
        end
      end

      def fetch(id, kind, registry, generation: nil)
        selected = provider(id, registry)
        unless selected.kinds.include?(kind)
          raise Error.new("library.kind_unavailable", "This provider does not serve the requested kind.")
        end
        @catalog.fetch(id, kind, :generation => generation)
      end

      def self.kind(wire_kind, registry)
        registry.library_kinds.values.find { |row| row.adapter.wire_kind == wire_kind } ||
          raise(Error.new("library.kind_unavailable", "The library kind is unavailable."))
      end

      private

      def factory_instances(declaration)
        declaration.factory.call
      rescue StandardError
        raise Error.new("library.provider_failed", "Provider metadata is unavailable."), :cause => nil
      end

      def valid_provider?(provider, declaration, registry)
        return false unless %i[id provider_kind label kinds list freshness].all? { |name| provider.respond_to?(name) }
        return false unless provider.provider_kind == declaration.name
        return false unless provider.id.is_a?(String) && /\A[a-zA-Z0-9_.-]+\z/.match?(provider.id)
        return false unless provider.label.is_a?(String) && !provider.label.strip.empty?

        known = registry.library_kinds.values.map { |row| row.adapter.wire_kind }
        served = declaration.kinds == ["*"] ? known : declaration.kinds
        kinds = provider.kinds
        kinds.is_a?(Array) && !kinds.empty? && kinds.uniq == kinds && (kinds - served).empty?
      rescue StandardError
        false
      end
    end
  end
end
