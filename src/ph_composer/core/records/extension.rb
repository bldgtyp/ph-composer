# frozen_string_literal: true

module PhComposer
  module Records
    # A maintained extension's structured data on records (CONTRACTS.md C5). A record carries one
    # envelope per namespace under `extension_data`:
    #
    #   {"example.review": {"schema_version": 2, "payload": {...},
    #    "references": [{"path": "$.checked_against", "target_kind": "example.part", "cardinality": "one"}],
    #    "export_relevance": "required"}}
    #
    # The envelope stores its own reference declarations and export relevance, so a record keeps
    # them even where the extension is not installed. Preserving a payload never implies it was
    # understood, validated or may be exported.
    class Extension
      RELEVANCE = %w[required local_only unknown].freeze

      # How a record's envelope for one namespace stands against what is installed.
      #   understood   registered, and the stored version is the current one
      #   outdated     registered, stored at an older version that migrations can raise
      #   unsupported  a newer version than installed, or an envelope that cannot be read
      #   unavailable  no extension with this namespace is installed
      STATUSES = %w[understood outdated unsupported unavailable].freeze

      attr_reader :namespace, :schema_version, :references, :export_relevance, :copy, :migrations

      # `references` are the current version's declarations. `migrations` maps a version to
      # `->(payload) { payload_at_the_next_version }`. `validate` is `->(payload) { [finding, ...] }`.
      # `copy` is :remap (declared references follow a duplicated collection) or :refuse.
      def initialize(namespace:, schema_version:, references: [], export_relevance: "unknown",
                     migrations: {}, validate: nil, copy: :remap)
        @namespace = namespace
        @schema_version = schema_version
        @references = references.map { |reference| DeepCopy.string_keys(reference) }.freeze
        @export_relevance = export_relevance
        @migrations = migrations.freeze
        @validate = validate
        @copy = copy
      end

      def problems(payload)
        found = JsonValue.problems(payload)
        found.concat(Array(@validate&.call(payload))) if found.empty?
        found
      end

      # A current-version envelope for `payload`, carrying this declaration's references.
      def envelope(payload)
        {
          "schema_version" => schema_version, "payload" => payload,
          "references" => DeepCopy.call(references), "export_relevance" => export_relevance
        }
      end

      # The envelope's status given the installed extension for its namespace, or nil.
      def self.status(envelope, installed)
        return "unsupported" unless readable?(envelope)
        return "unavailable" unless installed

        version = envelope.fetch("schema_version")
        return "understood" if version == installed.schema_version
        return "unsupported" if version > installed.schema_version

        migratable = (version...installed.schema_version).all? { |step| installed.migrations.key?(step) }
        migratable ? "outdated" : "unsupported"
      end

      # Whether the envelope's versioned shape can be read at all; only then are its declared
      # references usable.
      def self.readable?(envelope)
        return false unless envelope.is_a?(Hash) && envelope["schema_version"].is_a?(Integer)
        return false unless envelope.key?("payload")
        return false unless RELEVANCE.include?(envelope.fetch("export_relevance", "unknown"))

        Array(envelope.fetch("references", [])).all? do |reference|
          reference.is_a?(Hash) && reference["path"].to_s.start_with?("$.") &&
            reference["target_kind"].is_a?(String) && %w[one many].include?(reference["cardinality"])
        end
      end

      # The payload with every declared reference whose id is in `mapping` replaced by its counterpart.
      def self.remap(payload, references, mapping)
        references.reduce(DeepCopy.call(payload)) do |copy, reference|
          keys = reference.fetch("path").delete_prefix("$.").split(".")
          parent = keys[0...-1].reduce(copy) { |node, key| node.is_a?(Hash) ? node[key] : nil }
          next copy unless parent.is_a?(Hash) && parent.key?(keys.last)

          current = parent[keys.last]
          parent[keys.last] =
            current.is_a?(Array) ? current.map { |id| mapping.fetch(id, id) } : mapping.fetch(current, current)
          copy
        end
      end

      # The ids a payload's declared references name, as [target_kind, id] pairs.
      def self.referenced_ids(payload, references)
        references.flat_map do |reference|
          keys = reference.fetch("path").delete_prefix("$.").split(".")
          value = keys.reduce(payload) { |node, key| node.is_a?(Hash) ? node[key] : nil }
          Array(value).compact.map { |id| [reference.fetch("target_kind"), id] }
        end
      end
    end
  end
end
