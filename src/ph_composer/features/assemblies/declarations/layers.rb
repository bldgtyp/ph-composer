# frozen_string_literal: true

module PhComposer
  module Assemblies
    # One action per Builder gesture on an Assembly's Layers. Each names its Layer explicitly and
    # carries its own description, Undo name and side effects, written for an agent reading describe.
    module LayerRegistration
      LAYER_ID = "The Layer, by its id within this Assembly."
      module_function

      def install(feature)
        declare_add(feature)
        declare_edit(feature)
        declare_order(feature)
        declare_barrier(feature)
      end

      def action(feature, name, properties, example, description:, undo_name:, side_effects:, optional: [], &command)
        properties = { "id" => Shapes.id("asm", "The Assembly to edit."),
                       "expected_values" => Shapes.expected(Assembly::Schema::KIND) }.merge(properties)
        feature.action("#{FEATURE_ID}.assemblies.layers.#{name}", :description => description,
          :params => Shapes.object(properties, :optional => optional), :result => Shapes::RESULT,
          :undo_name => undo_name, :side_effects => side_effects,
          :examples => [example.merge("id" => Shapes::EXAMPLE_ID, "expected_values" => {})]) do |request, proposal|
          Operations.gesture(request, proposal) { |record| command.call(record, request.params, request) }
        end
      end

      def declare_add(feature)
        properties = {
          "index" => { "type" => "integer", "minimum" => 0,
                       "description" => "Where to insert the Layer in the stored order, 0 first. Not with " \
                                        "anchor_layer_id." },
          "thickness_mm" => Shapes.described(SchemaFields.number("mm"), "The new Layer's thickness; 100 mm when " \
                                                                        "absent."),
          "anchor_layer_id" => Shapes.id("lyr", "An existing Layer to place the new one beside, with side."),
          "side" => { "type" => "string", "enum" => %w[outside inside],
                      "description" => "Which side of anchor_layer_id, by the Assembly's orientation." }
        }
        action(feature, "add", properties, { "thickness_mm" => 100 }, :optional => properties.keys,
          :description => "Add a Layer with one Layer-Segment of no Material. With no position it goes after the " \
                          "last Layer in the stored order; give index, or anchor_layer_id and side.",
          :undo_name => "Add Assembly Layer",
          :side_effects => "Adds one Layer to this Assembly.") do |record, params, request|
          Commands.add_layer(record, :index => params["index"], :thickness_mm => params.fetch("thickness_mm", 100.0),
            :anchor_layer_id => params["anchor_layer_id"], :side => params["side"],
            :identity => Operations.identity_allocator(request))
        end
      end

      def declare_edit(feature)
        action(feature, "remove", { "layer_id" => Shapes.id("lyr", LAYER_ID) },
               { "layer_id" => Shapes::EXAMPLE_LAYER },
               :description => "Remove one Layer. An Assembly keeps at least one Layer.",
               :undo_name => "Remove Assembly Layer",
               :side_effects => "Removes the Layer and its Layer-Segments; clears the air barrier if it was on " \
                                "that Layer.") do |record, params|
          Commands.remove_layer(record, :layer_id => params.fetch("layer_id"))
        end
        action(feature, "update", { "layer_id" => Shapes.id("lyr", LAYER_ID),
                                    "thickness_mm" => Shapes.described(SchemaFields.number("mm"),
                                                                       "The new thickness.") },
               { "layer_id" => Shapes::EXAMPLE_LAYER, "thickness_mm" => 140 },
               :description => "Set one Layer's thickness.", :undo_name => "Change Layer Thickness",
               :side_effects => "Changes one Layer's thickness.") do |record, params|
          Commands.update_layer(record, :layer_id => params.fetch("layer_id"),
                                 :thickness_mm => params.fetch("thickness_mm"))
        end
        action(feature, "move", { "layer_id" => Shapes.id("lyr", LAYER_ID),
                                  "direction" => { "type" => "string", "enum" => %w[outward inward],
                                                   "description" => "Toward the outside or the inside, as the " \
                                                                    "Assembly's orientation defines them." } },
               { "layer_id" => Shapes::EXAMPLE_LAYER, "direction" => "inward" },
               :description => "Move one Layer one place outward or inward. A Layer already at that end stays.",
               :undo_name => "Move Assembly Layer",
               :side_effects => "Swaps two neighbouring Layers.") do |record, params|
          Commands.move_layer(record, :layer_id => params.fetch("layer_id"), :direction => params.fetch("direction"))
        end
      end

      def declare_order(feature)
        action(feature, "flip", {}, {},
               :description => "Reverse the stored order of the Layers and keep the orientation, so the outside " \
                               "Layer becomes the inside one.",
               :undo_name => "Flip Assembly Layers", :side_effects => "Reverses the Layer order.") do |record, _params|
          Commands.flip_layers(record)
        end
        action(feature, "flip_orientation", {}, {},
               :description => "Switch which end of the stored Layer order is the outside (first_layer_outside or " \
                               "last_layer_outside) and keep the order.",
               :undo_name => "Flip Assembly Orientation",
               :side_effects => "Changes only the orientation.") do |record, _params|
          Commands.flip_orientation(record)
        end
      end

      def declare_barrier(feature)
        properties = {
          "layer_id" => Shapes.id("lyr", "The Layer carrying the air barrier, or null to clear it.", :nullable => true),
          "face" => { "type" => "string", "enum" => %w[interior exterior],
                      "description" => "Which face of the Layer is the air barrier." }
        }
        action(feature, "set_air_barrier", properties,
               { "layer_id" => Shapes::EXAMPLE_LAYER, "face" => "interior" }, :optional => ["face"],
               :description => "Mark one face of one Layer as the Assembly's air barrier, or clear it.",
               :undo_name => "Set Air Barrier",
               :side_effects => "Replaces the Assembly's one air barrier.") do |record, params|
          Commands.set_air_barrier(record, :layer_id => params.fetch("layer_id"), :face => params["face"])
        end
      end
    end
  end
end
