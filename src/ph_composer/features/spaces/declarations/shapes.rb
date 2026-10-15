# frozen_string_literal: true

module PhComposer
  module Spaces
    # Schema pieces the Spaces declarations share. Record values come from each kind's descriptor.
    module Shapes
      extend SchemaShapes

      TEXT = { "type" => "string" }.freeze
      COUNT = { "type" => "integer", "minimum" => 0 }.freeze
      NONE = object({}).freeze
      ZONE_PATH = { "type" => "array", "items" => { "type" => "integer" } }.freeze

      module_function

      def quantity(unit, description, nullable: false)
        { "type" => nullable ? %w[number null] : "number", "x-unit" => unit, "description" => description }
      end
    end
  end
end
