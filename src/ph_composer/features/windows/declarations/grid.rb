# frozen_string_literal: true

module PhComposer
  module Windows
    # One action per Window Type grid gesture (types/grid_operations.rb). Each carries its own
    # description and Undo name, written for an agent reading describe.
    module GridRegistration
      AXIS = { "type" => "string", "enum" => %w[rows_m columns_m],
               "description" => "rows_m for a horizontal band, columns_m for a vertical one." }.freeze
      DIMENSION = { "type" => %w[number null], "exclusiveMinimum" => 0, "x-unit" => "m" }.freeze
      EXAMPLE_ID = "wnt_Ab12Cd34Ef56"
      EXAMPLE_ELEMENT = "wel_Ab12Cd34Ef56"
      ELEMENT_ID = "The element, by its id within this Window Type."
      Gesture = Struct.new(:description, :undo_name, :properties, :example, keyword_init: true)

      module_function

      def element(description = ELEMENT_ID)
        Shapes.id("wel", description)
      end

      def elements(description)
        Shapes.list(Shapes.id("wel", "An element id within this Window Type.")).merge("minItems" => 1,
                                                                                       "description" => description)
      end

      def index(description)
        { "type" => "integer", "minimum" => 0, "description" => description }
      end

      GESTURES = {
        "insert" => Gesture.new(
          :description => "Insert a row or column band at a grid boundary, filled with new glazed elements. " \
                          "Elements spanning that boundary must be split first.",
          :undo_name => "Insert Window Band",
          :properties => { "axis" => AXIS,
                           "index" => index("The boundary to insert at, 0 before the first band."),
                           "value" => Shapes.described(DIMENSION, "The new band's size, or null to leave it unset.") },
          :example => { "axis" => "columns_m", "index" => 1, "value" => 1.0 }
        ),
        "remove" => Gesture.new(
          :description => "Remove one row or column band and the elements only it held. Refused while the " \
                          "layout carries installation assignments, and for the last band.",
          :undo_name => "Remove Window Band",
          :properties => { "axis" => AXIS, "index" => index("The band to remove, 0 first.") },
          :example => { "axis" => "rows_m", "index" => 0 }
        ),
        "merge" => Gesture.new(
          :description => "Merge two or more elements of one kind that cover one rectangle into a single " \
                          "element under a new id.",
          :undo_name => "Merge Window Elements",
          :properties => { "ids" => elements("The elements to merge.") },
          :example => { "ids" => [EXAMPLE_ELEMENT] }
        ),
        "split" => Gesture.new(
          :description => "Split one merged element back into one element per grid cell, each under a new id.",
          :undo_name => "Split Window Element",
          :properties => { "element_id" => element("The merged element to split.") },
          :example => { "element_id" => EXAMPLE_ELEMENT }
        ),
        "kind" => Gesture.new(
          :description => "Make elements glazed or Empty. Empty is wall area: it clears the elements' Glazing, " \
                          "Frames, installs and operation.",
          :undo_name => "Change Window Element Kind",
          :properties => { "ids" => elements("The elements to change."),
                           "kind" => { "type" => "string", "enum" => %w[glazed empty],
                                       "description" => "glazed or empty." } },
          :example => { "ids" => [EXAMPLE_ELEMENT], "kind" => "empty" }
        ),
        "flip" => Gesture.new(
          :description => "Mirror the layout left to right, swapping left and right Frames, installs and " \
                          "operation directions.",
          :undo_name => "Flip Window Type", :properties => {}, :example => {}
        ),
        "dimension" => Gesture.new(
          :description => "Set one row or column band's size.",
          :undo_name => "Resize Window Band",
          :properties => { "axis" => AXIS, "index" => index("The band to size, 0 first."),
                           "value" => Shapes.described(DIMENSION, "The band's size, or null to unset it.") },
          :example => { "axis" => "columns_m", "index" => 0, "value" => 1.2 }
        ),
        "paste" => Gesture.new(
          :description => "Copy one glazed element's Glazing, Frames, operation and installs onto other glazed " \
                          "elements. Installs copy only where the edges match.",
          :undo_name => "Paste Window Element",
          :properties => { "source_id" => element("The glazed element to copy from."),
                           "ids" => elements("The glazed elements to paste onto.") },
          :example => { "source_id" => EXAMPLE_ELEMENT, "ids" => ["wel_Zy98Xw76Vu54"] }
        ),
        "set_element_name" => Gesture.new(
          :description => "Name one element.", :undo_name => "Rename Window Element",
          :properties => { "element_id" => element,
                           "name" => { "type" => "string", "description" => "The element's name." } },
          :example => { "element_id" => EXAMPLE_ELEMENT, "name" => "Fixed" }
        ),
        "set_element_glazing" => Gesture.new(
          :description => "Set or clear one glazed element's Glazing.", :undo_name => "Set Window Glazing",
          :properties => { "element_id" => element,
                           "glazing_id" => Shapes.id("glz", "The Glazing, or null to clear it.", :nullable => true) },
          :example => { "element_id" => EXAMPLE_ELEMENT, "glazing_id" => "glz_Ab12Cd34Ef56" }
        ),
        "set_element_frame" => Gesture.new(
          :description => "Set or clear the Frame on one side of one glazed element; the other sides stay.",
          :undo_name => "Set Window Frame",
          :properties => { "element_id" => element,
                           "side" => { "type" => "string", "enum" => Types::SIDES,
                                       "description" => "The element side, as seen from outside." },
                           "frame_id" => Shapes.id("frm", "The Frame, or null to clear it.", :nullable => true) },
          :example => { "element_id" => EXAMPLE_ELEMENT, "side" => "left", "frame_id" => "frm_Ab12Cd34Ef56" }
        ),
        "set_element_operation" => Gesture.new(
          :description => "Set or clear how one glazed element opens. A fixed element has no directions.",
          :undo_name => "Set Window Operation",
          :properties => { "element_id" => element,
                           "operation" => Shapes.described(Types::OPERATION, "fixed, swing or slide with the " \
                                                                             "directions it opens toward, or " \
                                                                             "null when not specified.") },
          :example => { "element_id" => EXAMPLE_ELEMENT, "operation" => { "type" => "swing",
                                                                          "directions" => ["left"] } }
        )
      }.freeze

      def install(feature)
        GESTURES.each do |command, gesture|
          properties = gesture.properties.merge("id" => Shapes.id("wnt", "The Window Type to edit."),
                                                "expected_values" => Shapes.expected(Types::KIND))
          feature.action("#{FEATURE_ID}.types.grid.#{command}", :description => gesture.description,
            :params => Shapes.object(properties), :result => Shapes::TYPE_RESULT, :undo_name => gesture.undo_name,
            :side_effects => Shapes.side_effects("Changes this Window Type; its placed Windows follow."),
            :examples => [gesture.example.merge("id" => EXAMPLE_ID, "expected_values" => {})]) do |request, proposal|
            params = request.params
            Operations.grid(request, proposal, :command => command, :id => params.fetch("id"),
              :values => params.reject { |key, _| %w[id expected_values].include?(key) },
              :expected_values => params.fetch("expected_values"))
          end
        end
      end
    end
  end
end
