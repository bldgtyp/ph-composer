# frozen_string_literal: true

module PhComposer
  module Assemblies
    module Shapes
      ID = { "type" => "string" }.freeze
      OBJECT = { "type" => "object" }.freeze
      NONE = SchemaFields.object({}).freeze
      RESULT = SchemaFields.object({ "id" => ID }, :required => ["id"]).freeze
      EXAMPLE_ID = "asm_Ab12Cd34Ef56"
      EXAMPLE_LAYER = "lyr_Ab12Cd34Ef56"
      EXAMPLE_SEGMENT = "seg_Ab12Cd34Ef56"
      FINDING = SchemaFields.object({
        "code" => ID, "message" => ID,
        "message_parts" => { "type" => "array", "items" => OBJECT },
        "assembly_id" => ID, "material_id" => ID, "layer_id" => ID, "segment_id" => ID,
        "missing_fields" => { "type" => "array", "items" => ID }
      }, :required => %w[code message message_parts]).freeze
      FINDINGS = { "type" => "array", "items" => FINDING }.freeze
      UNREADABLE = { "type" => "array", "items" => SchemaFields.object({
        "id" => ID, "code" => ID, "message" => ID
      }, :required => %w[id code message]) }.freeze

      module_function

      def object(properties, optional: [])
        SchemaFields.object(properties, :required => properties.keys - optional)
      end

      def list(items)
        { "type" => "array", "items" => items }
      end

      def with(base, properties)
        base.merge("required" => base.fetch("required", []) + properties.keys,
                   "properties" => base.fetch("properties").merge(properties))
      end

      def view(kind)
        with(kind.descriptor.view_schema, "kind" => ID, "extension_status" => OBJECT, "findings" => FINDINGS)
      end

      def editable_patch(kind, fields)
        schema = kind.descriptor.patch_schema
        schema["properties"] = schema.fetch("properties").select { |key, _value| fields.include?(key) }
        schema["properties"]["category"].delete("enum") if kind.id == MATERIAL_KIND
        schema
      end

      def create(kind)
        values = DeepCopy.call(kind.values_schema).merge("required" => ["name"])
        values["properties"]["category"].delete("enum") if kind.id == MATERIAL_KIND
        object({ "values" => values, "user_data" => OBJECT }, :optional => ["user_data"])
      end

      def update(kind, fields)
        object({ "id" => ID, "values" => editable_patch(kind, fields),
                 "expected_values" => kind.descriptor.patch_schema, "user_data" => OBJECT }, :optional => ["user_data"])
      end

      def list_params
        object({ "ids" => list(ID).merge("maxItems" => Pages::MAXIMUM_LIMIT),
                 "limit" => Pages::LIMIT, "cursor" => Pages::CURSOR }, :optional => %w[ids limit cursor])
      end
    end
  end
end
