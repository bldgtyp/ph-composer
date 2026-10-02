# frozen_string_literal: true

module PhComposer
  module Windows
    module GridRegistration
      AXIS = { "type" => "string", "enum" => %w[rows_m columns_m] }.freeze
      INDEX = { "type" => "integer", "minimum" => 0 }.freeze
      DIMENSION = { "type" => %w[number null], "exclusiveMinimum" => 0, "x-unit" => "m" }.freeze
      EXAMPLE_ID = "wnt_Ab12Cd34Ef56"
      EXAMPLE_ELEMENT = "wel_Ab12Cd34Ef56"
      COMMANDS = {
        "insert" => [{ "axis" => AXIS, "index" => INDEX, "value" => DIMENSION },
{ "axis" => "columns_m", "index" => 1, "value" => 1.0 }],
        "remove" => [{ "axis" => AXIS, "index" => INDEX }, { "axis" => "rows_m", "index" => 0 }],
        "merge" => [{ "ids" => Shapes.list(Shapes::ID).merge("minItems" => 1) }, { "ids" => [EXAMPLE_ELEMENT] }],
        "split" => [{ "element_id" => Shapes::ID }, { "element_id" => EXAMPLE_ELEMENT }],
        "kind" => [{ "ids" => Shapes.list(Shapes::ID).merge("minItems" => 1),
                "kind" => { "type" => "string",
                "enum" => %w[glazed empty] } }, { "ids" => [EXAMPLE_ELEMENT], "kind" => "empty" }],
        "flip" => [{}, {}],
        "dimension" => [{ "axis" => AXIS, "index" => INDEX, "value" => DIMENSION },
{ "axis" => "columns_m", "index" => 0, "value" => 1.2 }],
        "paste" => [{ "source_id" => Shapes::ID, "ids" => Shapes.list(Shapes::ID).merge("minItems" => 1) },
                { "source_id" => EXAMPLE_ELEMENT, "ids" => ["wel_Zy98Xw76Vu54"] }],
        "set_element_name" => [{ "element_id" => Shapes::ID, "name" => { "type" => "string" } },
                { "element_id" => EXAMPLE_ELEMENT, "name" => "Fixed" }],
        "set_element_glazing" => [{ "element_id" => Shapes::ID, "glazing_id" => Types::ID },
                { "element_id" => EXAMPLE_ELEMENT, "glazing_id" => "wgl_Ab12Cd34Ef56" }],
        "set_element_frame" => [{ "element_id" => Shapes::ID,
                "side" => { "type" => "string", "enum" => Types::SIDES }, "frame_id" => Types::ID },
                { "element_id" => EXAMPLE_ELEMENT, "side" => "left", "frame_id" => "wfr_Ab12Cd34Ef56" }],
        "set_element_operation" => [{ "element_id" => Shapes::ID, "operation" => Types::OPERATION },
                { "element_id" => EXAMPLE_ELEMENT, "operation" => { "type" => "swing", "directions" => ["left"] } }]
      }.freeze

      module_function

      def install(feature)
        COMMANDS.each do |command, (properties, example)|
          properties = properties.merge("id" => Shapes::ID, "expected_values" => Types::KIND.descriptor.patch_schema)
          feature.action("#{FEATURE_ID}.types.grid.#{command}", :description => "Apply the #{command} grid gesture.",
            :params => Shapes.object(properties), :result => Shapes::TYPE_RESULT,
            :undo_name => "Edit Window Type: #{command}",
            :side_effects => Shapes.side_effects("Changes one definition in one Undo step."),
            :examples => [example.merge("id" => EXAMPLE_ID, "expected_values" => {})]) do |request, proposal|
            Operations.grid(request, proposal, command)
          end
        end
      end
    end
  end
end
