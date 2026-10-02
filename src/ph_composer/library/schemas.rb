# frozen_string_literal: true

module PhComposer
  module Library
    # Transport shapes stay generic; each registered kind validates its snapshot and mapped fields.
    module Schemas
      TEXT = { "type" => "string" }.freeze
      NULLABLE_TEXT = { "type" => %w[string null] }.freeze
      OBJECT = { "type" => "object" }.freeze
      NULLABLE_NUMBER = { "type" => %w[number null], "minimum" => 0 }.freeze
      GENERATION = { "type" => %w[integer null], "minimum" => 1 }.freeze
      VALUE = { "type" => %w[string number boolean object array null] }.freeze
      BOOLEAN = { "type" => "boolean" }.freeze

      module_function

      def object(properties, optional: [])
        { "type" => "object", "properties" => properties, "additionalProperties" => false,
          "required" => properties.keys - optional }
      end

      def list(items)
        { "type" => "array", "items" => items }
      end

      def summary
        object({ "provider_id" => TEXT, "kind" => TEXT, "generation" => GENERATION,
          "state" => { "type" => "string", "enum" => %w[unloaded empty loaded failed] },
          "warnings" => list(note), "unavailable" => list(note), "freshness" => freshness,
          "published_at" => NULLABLE_TEXT, "failure" => failure, "age_seconds" => NULLABLE_NUMBER })
      end

      def note
        object({ "code" => TEXT, "kind" => TEXT, "library_id" => TEXT, "record_id" => TEXT,
                 "index" => { "type" => "integer", "minimum" => 0 } },
               :optional => %w[kind library_id record_id index])
      end

      def freshness
        object({ "loaded_at" => TEXT, "exported_at" => TEXT }, :optional => %w[loaded_at exported_at])
      end

      def failure
        schema = object({ "code" => TEXT, "message" => TEXT })
        schema.merge("type" => %w[object null])
      end

      def providers
        keys = %w[kind generation state failure age_seconds freshness]
        catalog = object(summary.fetch("properties").slice(*keys))
        list(object({ "id" => TEXT, "provider_kind" => TEXT, "label" => TEXT,
                      "kinds" => list(TEXT), "catalogs" => list(catalog) }))
      end

      def resolution
        difference = object({ "field" => TEXT, "local" => VALUE, "incoming" => VALUE,
                              "local_present" => BOOLEAN, "incoming_present" => BOOLEAN })
        candidate = object({ "id" => TEXT, "name" => TEXT, "differences" => list(difference),
          "expected_values" => OBJECT, "comparison_available" => BOOLEAN,
          "source_changed" => { "type" => %w[boolean null] } })
        outcomes = %w[create reuse review_required ambiguous_source ambiguous_name]
        object({ "outcome" => { "type" => "string", "enum" => outcomes },
                 "candidates" => list(candidate) })
      end

      def page(resolved: false)
        row = object({ "library_id" => TEXT, "library_name" => TEXT, "record_id" => TEXT,
                       "wire_schema_version" => { "type" => "integer", "minimum" => 1 }, "snapshot" => OBJECT })
        row["properties"]["resolution"] = resolution if resolved
        row["required"] << "resolution" if resolved
        object(summary.fetch("properties").merge("rows" => list(row),
          "total" => { "type" => "integer", "minimum" => 0 }, "offset" => { "type" => "integer", "minimum" => 0 },
          "next_offset" => { "type" => %w[integer null], "minimum" => 0 }))
      end

      def copy_result
        object({ "resolution" => resolution, "local_id" => NULLABLE_TEXT, "assigned" => BOOLEAN })
      end
    end
  end
end
