# frozen_string_literal: true

module PhComposer
  module Assemblies
    module Shapes
      # Any string: names, messages, codes and ids in results. A param naming a record uses `id`.
      TEXT = { "type" => "string" }.freeze
      OBJECT = { "type" => "object" }.freeze
      NONE = SchemaFields.object({}).freeze
      RESULT = SchemaFields.object({ "id" => TEXT }, :required => ["id"]).freeze
      EXPECTED = "Any of the record's values as last read; if one changed since, the edit is refused as " \
                 "target.changed. {} skips the check."
      USER_DATA = { "type" => "object", "description" => "Free metadata kept with the record and exported " \
                                                         "verbatim." }.freeze
      EXAMPLE_ID = "asm_Ab12Cd34Ef56"
      EXAMPLE_LAYER = "lyr_Ab12Cd34Ef56"
      EXAMPLE_SEGMENT = "seg_Ab12Cd34Ef56"
      FINDING = SchemaFields.object({
        "code" => TEXT, "message" => TEXT,
        "message_parts" => { "type" => "array", "items" => OBJECT },
        "assembly_id" => TEXT, "material_id" => TEXT, "layer_id" => TEXT, "segment_id" => TEXT,
        "missing_fields" => { "type" => "array", "items" => TEXT }
      }, :required => %w[code message message_parts]).freeze
      FINDINGS = { "type" => "array", "items" => FINDING }.freeze
      UNREADABLE = { "type" => "array", "items" => SchemaFields.object({
        "id" => TEXT, "code" => TEXT, "message" => TEXT
      }, :required => %w[id code message]) }.freeze

      module_function

      # A param naming one record or part by its id, such as `asm_Ab12Cd34Ef56` for prefix "asm".
      def id(prefix, description, nullable: false)
        { "type" => nullable ? %w[string null] : "string", "pattern" => "^#{prefix}_[A-Za-z0-9]{12}$",
          "description" => description }
      end

      def described(schema, description)
        schema.merge("description" => description)
      end

      def expected(kind)
        described(kind.descriptor.patch_schema, EXPECTED)
      end

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
        with(kind.descriptor.view_schema, "kind" => TEXT, "extension_status" => OBJECT, "findings" => FINDINGS)
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
        object({ "values" => described(values, "The new #{kind.label}'s values; name is required and every " \
                                               "other value takes its default."),
                 "user_data" => USER_DATA }, :optional => ["user_data"])
      end

      def update(kind, fields)
        object({ "id" => id(kind.id_prefix, "The #{kind.label} to edit."),
                 "values" => described(editable_patch(kind, fields), "The values to change; any not given stay."),
                 "expected_values" => expected(kind), "user_data" => USER_DATA }, :optional => ["user_data"])
      end

      def list_params
        object({ "ids" => list(TEXT).merge("maxItems" => Pages::MAXIMUM_LIMIT,
                                           "description" => "Only these record ids; every record when absent."),
                 "limit" => Pages::LIMIT, "cursor" => Pages::CURSOR }, :optional => %w[ids limit cursor])
      end
    end
  end
end
