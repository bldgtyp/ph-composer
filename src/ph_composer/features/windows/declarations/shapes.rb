# frozen_string_literal: true

module PhComposer
  module Windows
    module Shapes
      ID = { "type" => "string" }.freeze
      OBJECT = { "type" => "object" }.freeze
      NONE = Fields.object({}).freeze
      RESULT = Fields.object({ "id" => ID }, :required => ["id"]).freeze
      TYPE_RESULT = Fields.object({ "id" => ID, "unit_count" => { "type" => "integer", "minimum" => 0 } },
        :required => %w[id unit_count]).freeze
      UNREADABLE = { "type" => "array", "items" => Fields.object(
        %w[id code message].to_h { |key| [key, ID] }, :required => %w[id code message]) }.freeze
      FINDING = Fields.object({ "code" => ID, "message" => ID, "element_id" => ID, "side" => ID,
                "product_id" => ID }, :required => %w[code message]).freeze
      FINDINGS = { "type" => "array", "items" => FINDING }.freeze

      module_function

      def object(properties, optional: [])
        Fields.object(properties, :required => properties.keys - optional)
      end

      def list(items)
        { "type" => "array", "items" => items }
      end

      def with(base, properties)
        base.merge("required" => base.fetch("required", []) + properties.keys,
          "properties" => base.fetch("properties").merge(properties))
      end

      def create_values(kind)
        DeepCopy.call(kind.values_schema).merge("required" => ["name"])
      end

      def create(kind)
        object({ "values" => create_values(kind), "user_data" => OBJECT }, :optional => ["user_data"])
      end

      def patch(kind)
        shape = kind.descriptor.patch_schema
        shape["properties"].delete("source")
        shape
      end

      def update(kind)
        object({ "id" => ID, "values" => patch(kind), "expected_values" => kind.descriptor.patch_schema,
                "user_data" => OBJECT }, :optional => ["user_data"])
      end

      def view(kind)
        with(kind.descriptor.view_schema, "kind" => ID, "extension_status" => OBJECT, "findings" => FINDINGS)
      end

      def list_params
        object({ "ids" => list(ID).merge("maxItems" => Pages::MAXIMUM_LIMIT), "limit" => Pages::LIMIT,
                "cursor" => Pages::CURSOR }, :optional => %w[ids limit cursor])
      end
    end
  end
end
