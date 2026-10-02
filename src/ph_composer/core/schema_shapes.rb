# frozen_string_literal: true

module PhComposer
  # The JSON Schema pieces every declaration builds params and results from. A feature's own
  # `Shapes` module extends this one and adds only the constants that are its own.
  module SchemaShapes
    # `extend self`, not `module_function`, so a feature module that extends this one gets public
    # methods.
    extend self

    # A closed object; every property is required unless `optional` names it.
    def object(properties, optional: [], description: nil)
      schema = { "type" => "object", "additionalProperties" => false,
                 "required" => properties.keys - optional, "properties" => properties }
      description ? described(schema, description) : schema
    end

    def list(items, description: nil)
      schema = { "type" => "array", "items" => items }
      description ? described(schema, description) : schema
    end

    # `base`, a closed object schema, with more required properties.
    def with(base, properties)
      base.merge("required" => base.fetch("required", []) + properties.keys,
                 "properties" => base.fetch("properties").merge(properties))
    end

    # `schema` with what it means to a caller, for discovery.
    def described(schema, description)
      schema.merge("description" => description)
    end

    # A param naming one record or part by its id, such as `asm_Ab12Cd34Ef56` for prefix "asm".
    def id(prefix, description, nullable: false)
      { "type" => nullable ? %w[string null] : "string", "pattern" => "^#{prefix}_[A-Za-z0-9]{12}$",
        "description" => description }
    end
  end
end
