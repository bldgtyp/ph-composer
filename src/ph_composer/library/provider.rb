# frozen_string_literal: true

module PhComposer
  module Library
    class Error < CodedError; end

    # Providers expose catalog data, never transport configuration or Model operations. The reusable
    # contract test accepts any provider implementing id/provider_kind/label/kinds/list/freshness.
    module Provider
      module_function

      # JSON values only, including cycle/encoding checks before any structural copy. The same
      # depth ceiling as JSON.parse keeps a Ruby-only provider from supplying an unrepresentable tree.
      def json_value?(value)
        pending = [[value, []]]
        until pending.empty?
          node, ancestors = pending.pop
          case node
          when Hash, Array
            return false if ancestors.length >= 100 || ancestors.any? { |entry| entry.equal?(node) }
            if node.is_a?(Hash) && node.keys.any? { |key|
              !key.is_a?(String) || !key.valid_encoding? || !(key.encoding == Encoding::UTF_8 || key.ascii_only?)
            }
              return false
            end

            children = node.is_a?(Hash) ? node.values : node
            children.each { |child| pending << [child, ancestors + [node]] }
          when String
            return false unless node.valid_encoding? && (node.encoding == Encoding::UTF_8 || node.ascii_only?)
          when Float
            return false unless node.finite?
          when Integer, TrueClass, FalseClass, NilClass
            next
          else
            return false
          end
        end
        true
      end

      def immutable(value)
        copy = DeepCopy.call(value)
        freeze_tree(copy)
      end

      def freeze_tree(value)
        case value
        when Hash
          value.each do |key, child|
            key.freeze
            freeze_tree(child)
          end
        when Array
          value.each { |child| freeze_tree(child) }
        end
        value.freeze
      end
      private_class_method :freeze_tree

      class Batch
        attr_reader :rows, :warnings, :unavailable, :freshness

        def initialize(rows:, warnings:, unavailable:, freshness:)
          valid = rows.is_a?(Array) && rows.all? { |row| valid_row?(row) } &&
                  warnings.is_a?(Array) && unavailable.is_a?(Array) && freshness.is_a?(Hash) &&
                  Provider.json_value?([rows, warnings, unavailable, freshness])
          unless valid
            raise Error.new("library.provider_invalid", "The provider catalog response is malformed.")
          end

          @rows = Provider.immutable(rows)
          @warnings = Provider.immutable(warnings)
          @unavailable = Provider.immutable(unavailable)
          @freshness = Provider.immutable(freshness)
          freeze
        end

        def to_h
          { "rows" => rows, "warnings" => warnings, "unavailable" => unavailable, "freshness" => freshness }.freeze
        end

        private

        # `display_label` is admission's (Admission.label_for); a provider's own is replaced there.
        def valid_row?(row)
          fields = %w[library_id library_name record_id snapshot wire_schema_version]
          labelled = row.is_a?(Hash) && row.key?("display_label")
          return false if labelled && !(row["display_label"].is_a?(String) && !row["display_label"].strip.empty?)

          row.is_a?(Hash) && row.keys.length == fields.length + (labelled ? 1 : 0) &&
            fields.all? { |key| row.key?(key) } &&
            %w[library_id library_name record_id].all? { |key| row[key].is_a?(String) && !row[key].strip.empty? } &&
            row["wire_schema_version"].is_a?(Integer) && row["wire_schema_version"].positive? &&
            row["snapshot"].is_a?(Hash) && row.dig("snapshot", "id") == row["record_id"]
        end
      end
    end
  end
end
