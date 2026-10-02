# frozen_string_literal: true

require "time"
require_relative "provider"

module PhComposer
  module Library
    # One session's immutable catalogs. Refresh stages a complete response before publishing; failed
    # reads retain the exact old generation. This object has no disk cache or Model dependency.
    class Catalog
      def initialize(clock: -> { Time.now.utc })
        @clock = clock
        @entries = {}
        @generation = 0
      end

      def refresh(provider, kind:)
        batch = provider.list(kind)
        unless batch.is_a?(Provider::Batch)
          raise Error.new("library.provider_invalid", "The provider did not return a valid catalog response.")
        end

        batch = yield(batch) if block_given?
        unless batch.is_a?(Provider::Batch)
          raise Error.new("library.provider_invalid", "The normalized catalog response is malformed.")
        end

        @generation += 1
        @entries[[provider.id, kind]] = Provider.immutable(
          "provider_id" => provider.id, "kind" => kind, "generation" => @generation,
          "state" => batch.rows.empty? ? "empty" : "loaded", "rows" => batch.rows,
          "warnings" => batch.warnings, "unavailable" => batch.unavailable, "freshness" => batch.freshness,
          "published_at" => @clock.call.utc.iso8601(6), "failure" => nil
        )
        fetch(provider.id, kind)
      rescue StandardError => error
        # A third-party provider exception may include its transport address. Neither its text,
        # details nor cause is copied into session state or an outcome.
        key = [provider.id, kind]
        old = @entries[key] || empty(provider.id, kind)
        code = error.is_a?(Error) && /\Alibrary\.[a-z0-9_.]+\z/.match?(error.code) ?
          error.code : "library.provider_failed"
        @entries[key] = Provider.immutable(old.merge(
          "state" => "failed", "failure" => { "code" => code, "message" => "Catalog refresh failed." }
        ))
        fetch(provider.id, kind)
      end

      def fetch(provider_id, kind, generation: nil)
        row = @entries.fetch([provider_id, kind]) { empty(provider_id, kind) }
        if !generation.nil? && row.fetch("generation") != generation
          raise Error.new("library.catalog_stale", "The catalog generation has changed; read it again before copying.")
        end

        published = row["published_at"]
        age = published ? [@clock.call.to_f - Time.iso8601(published).to_f, 0.0].max : nil
        Provider.immutable(row.merge("age_seconds" => age))
      end

      def remove(provider_id)
        @entries.delete_if { |(id, _kind), _row| id == provider_id }
        nil
      end

      private

      def empty(provider_id, kind)
        { "provider_id" => provider_id, "kind" => kind, "generation" => nil, "state" => "unloaded",
          "rows" => [], "warnings" => [], "unavailable" => [], "freshness" => {},
          "published_at" => nil, "failure" => nil }
      end
    end
  end
end
