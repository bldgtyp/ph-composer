# frozen_string_literal: true

module PhComposer
  module Assemblies
    module LayerRegistration
      module_function

      def install(feature)
        declare_add(feature)
        declare_edit(feature)
        declare_order(feature)
        declare_barrier(feature)
      end

      def action(feature, name, properties, example, optional: [], &command)
        properties = { "id" => Shapes::ID, "expected_values" => Assembly::Schema::KIND.descriptor.patch_schema }
                     .merge(properties)
        feature.action("#{FEATURE_ID}.assemblies.layers.#{name}",
          :description => "#{name.capitalize.tr('_', ' ')} Layers of one explicit Assembly.",
          :params => Shapes.object(properties, :optional => optional), :result => Shapes::RESULT,
          :undo_name => "Edit Assembly Layers", :side_effects => "Updates the Assembly's authored Layer values.",
          :examples => [example.merge("id" => Shapes::EXAMPLE_ID, "expected_values" => {})]) do |request, proposal|
          Operations.gesture(request, proposal) { |record| command.call(record, request.params, request) }
        end
      end

      def declare_add(feature)
        properties = { "index" => { "type" => "integer", "minimum" => 0 },
                       "thickness_mm" => SchemaFields.number("mm"), "anchor_layer_id" => Shapes::ID,
                       "side" => { "type" => "string", "enum" => %w[outside inside] } }
        action(feature, "add", properties, { "thickness_mm" => 100 }, 
:optional => properties.keys) do |record, params, request|
          Commands.add_layer(record, :index => params["index"], :thickness_mm => params.fetch("thickness_mm", 100.0),
            :anchor_layer_id => params["anchor_layer_id"], :side => params["side"],
            :identity => Operations.identity_allocator(request))
        end
      end

      def declare_edit(feature)
        action(feature, "remove", { "layer_id" => Shapes::ID },
               { "layer_id" => Shapes::EXAMPLE_LAYER }) do |record, params|
          Commands.remove_layer(record, :layer_id => params.fetch("layer_id"))
        end
        action(feature, "update", { "layer_id" => Shapes::ID, "thickness_mm" => SchemaFields.number("mm") },
               { "layer_id" => Shapes::EXAMPLE_LAYER, "thickness_mm" => 140 }) do |record, params|
          Commands.update_layer(record, :layer_id => params.fetch("layer_id"),
                                 :thickness_mm => params.fetch("thickness_mm"))
        end
        action(feature, "move", { "layer_id" => Shapes::ID,
                                  "direction" => { "type" => "string", "enum" => %w[outward inward] } },
               { "layer_id" => Shapes::EXAMPLE_LAYER, "direction" => "inward" }) do |record, params|
          Commands.move_layer(record, :layer_id => params.fetch("layer_id"), :direction => params.fetch("direction"))
        end
      end

      def declare_order(feature)
        action(feature, "flip", {}, {}) { |record, _params| Commands.flip_layers(record) }
        action(feature, "flip_orientation", {}, {}) { |record, _params| Commands.flip_orientation(record) }
      end

      def declare_barrier(feature)
        properties = { "layer_id" => { "type" => %w[string null] },
                       "face" => { "type" => "string", "enum" => %w[interior exterior] } }
        action(feature, "set_air_barrier", properties,
               { "layer_id" => Shapes::EXAMPLE_LAYER, "face" => "interior" }, :optional => ["face"]) do |record, params|
          Commands.set_air_barrier(record, :layer_id => params.fetch("layer_id"), :face => params["face"])
        end
      end
    end
  end
end
