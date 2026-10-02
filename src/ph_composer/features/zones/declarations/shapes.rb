# frozen_string_literal: true

module PhComposer
  module Zones
    # Schema pieces the declarations share. Record values come from each kind's descriptor, never a
    # second hand-written copy.
    module Shapes
      extend SchemaShapes

      ID = { "type" => "string" }.freeze
      COUNT = { "type" => "integer", "minimum" => 0 }.freeze
      # The params of an operation that takes none.
      NONE = object({}).freeze
    end
  end
end
