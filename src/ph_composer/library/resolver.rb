# frozen_string_literal: true

module PhComposer
  module Library
    # Resolves source identity before semantic equality. Inputs are detached projections;
    # no provider, Model or mutation callback is needed to decide whether review is required.
    module Resolver
      IDENTITY_FIELDS = %w[provider_kind library_id record_kind record_id].freeze

      module_function

      def resolve(source:, mapped:, locals:)
        exact = locals.select { |row| same_source?(row["source"], source) }
        return result("reuse", exact, mapped) if exact.length == 1
        return result("ambiguous_source", exact, mapped) if exact.length > 1

        names = locals.select do |row|
          row.fetch("mapped").fetch("name").strip.downcase == mapped.fetch("name").strip.downcase
        end
        return result("create", [], mapped) if names.empty?
        return result("ambiguous_name", names, mapped) if names.length > 1

        outcome = names.first.fetch("mapped") == mapped ? "reuse" : "review_required"
        result(outcome, names, mapped)
      end

      def same_source?(local, source)
        local.is_a?(Hash) && local["kind"] == "library" &&
          IDENTITY_FIELDS.all? { |key| source.key?(key) && local[key] == source[key] }
      end

      def result(outcome, candidates, mapped)
        {
          "outcome" => outcome,
          "candidates" => candidates.sort_by { |row| row.fetch("id") }.map do |row|
            values = row.fetch("mapped")
            differences = (values.keys | mapped.keys).sort.filter_map do |field|
              next if values.key?(field) == mapped.key?(field) && values[field] == mapped[field]

              { "field" => field, "local" => DeepCopy.call(values[field]), "incoming" => DeepCopy.call(mapped[field]),
                "local_present" => values.key?(field), "incoming_present" => mapped.key?(field) }
            end
            { "id" => row.fetch("id"), "name" => DeepCopy.call(values.fetch("name")), "differences" => differences,
              "expected_values" => DeepCopy.call(row.fetch("expected_values", {})) }
          end
        }
      end
      private_class_method :same_source?, :result
    end
  end
end
