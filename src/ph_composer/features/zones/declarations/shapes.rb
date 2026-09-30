# frozen_string_literal: true

module PhComposer
  module Zones
    # Schema pieces the declarations share. Record values come from each kind's descriptor, never a
    # second hand-written copy.
    module Shapes
      ID = { "type" => "string" }.freeze
      COUNT = { "type" => "integer", "minimum" => 0 }.freeze
      # The params of an operation that takes none.
      NONE = { "type" => "object", "additionalProperties" => false, "properties" => {} }.freeze

      module_function

      # A closed object; every property is required unless `optional` names it.
      def object(properties, optional: [], description: nil)
        schema = { "type" => "object", "additionalProperties" => false,
                   "required" => properties.keys - optional, "properties" => properties }
        description ? schema.merge("description" => description) : schema
      end

      def list(items, description: nil)
        schema = { "type" => "array", "items" => items }
        description ? schema.merge("description" => description) : schema
      end

      # `base`, a closed object schema, with more required properties.
      def with(base, properties)
        base.merge("required" => base.fetch("required") + properties.keys,
                   "properties" => base.fetch("properties").merge(properties))
      end
    end
  end
end
