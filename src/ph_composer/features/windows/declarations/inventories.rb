# frozen_string_literal: true

module PhComposer
  module Windows
    module InventoryRegistration
      NUM = { "type" => %w[number null] }.freeze
      EDGE_INSTALL = Shapes.object({ "source" => Shapes::TEXT, "id" => { "type" => %w[string null] }, "psi" => NUM })
      EDGE = Shapes.object({ "side" => Shapes::TEXT, "length_m" => NUM.merge("x-unit" => "m"),
                "install" => EDGE_INSTALL, "frame_area_m2" => NUM.merge("x-unit" => "m2"),
                "glass_edge_m" => NUM.merge("x-unit" => "m"), "h_frame_w_k" => NUM.merge("x-unit" => "W/K"),
                "h_spacer_w_k" => NUM.merge("x-unit" => "W/K") },
        :optional => %w[frame_area_m2 glass_edge_m h_frame_w_k h_spacer_w_k])
      ELEMENT_THERMAL = Shapes.object({ "id" => Shapes::TEXT, "area_m2" => NUM.merge("x-unit" => "m2"),
                "edges" => Shapes.list(EDGE), "findings" => Shapes.list(Shapes::TEXT),
                "h_construction_w_k" => NUM.merge("x-unit" => "W/K"), "h_install_w_k" => NUM.merge("x-unit" => "W/K"),
                "glazing_area_m2" => NUM.merge("x-unit" => "m2"), "frame_area_m2" => NUM.merge("x-unit" => "m2"),
                "h_glazing_w_k" => NUM.merge("x-unit" => "W/K"), "g_value" => NUM,
                "u_w" => NUM.merge("x-unit" => "W/m2K"), "u_effective" => NUM.merge("x-unit" => "W/m2K"),
                "complete" => { "type" => "boolean" } }, :optional => %w[glazing_area_m2 frame_area_m2 h_glazing_w_k])
      THERMAL = Shapes.object({ "elements" => Shapes.list(ELEMENT_THERMAL), "findings" => Shapes.list(Shapes::TEXT),
                "area_m2" => NUM.merge("x-unit" => "m2"), "empty_area_m2" => NUM.merge("x-unit" => "m2"),
                "h_construction_w_k" => NUM.merge("x-unit" => "W/K"), "h_install_w_k" => NUM.merge("x-unit" => "W/K"),
                "u_w" => NUM.merge("x-unit" => "W/m2K"), "u_effective" => NUM.merge("x-unit" => "W/m2K"),
                "complete" => { "type" => "boolean" } },
        :optional => %w[area_m2 empty_area_m2 h_construction_w_k h_install_w_k])
      DISPLAY = Shapes.object({ "thermal" => THERMAL, "width_m" => NUM.merge("x-unit" => "m"),
                "height_m" => NUM.merge("x-unit" => "m"), "install_depth_m" => NUM.merge("x-unit" => "m"),
                "complete" => { "type" => "boolean" } })
      USE = Shapes.object(%w[kind type_id element_id side name].to_h { |key| [key, Shapes::TEXT] },
        :optional => %w[type_id element_id side])

      module_function

      def result(kind, paged:)
        extra = kind.id == TYPE_KIND ? { "display" => DISPLAY } : {
          "uses" => Shapes.list(USE), "use_count" => { "type" => "integer", "minimum" => 0 },
          "element_use_count" => { "type" => "integer", "minimum" => 0 }
        }
        properties = { "records" => Shapes.list(Shapes.with(Shapes.view(kind), extra)),
                "unreadable" => Shapes::UNREADABLE }
        properties.merge!("next_cursor" => Pages::NEXT_CURSOR, "total" => Pages::TOTAL) if paged
        Shapes.object(properties)
      end

      def install(feature)
        (Products::KINDS.keys + ["types"]).each do |collection|
          kind = Operations.kind(collection)
          prefix = "#{FEATURE_ID}.#{collection}"
          feature.query("#{prefix}.list", :description => "A bounded page of #{collection} with display findings.",
            :params => Shapes.list_params, :result => result(kind, :paged => true),
            :examples => [{}, { "limit" => 20 }]) do |request|
            Snapshot.list(request, collection)
          end
          feature.query("#{prefix}.all", :description => "The complete #{collection} inventory for the panel snapshot.",
            :params => Shapes::NONE, :result => result(kind, :paged => false), :examples => [{}]) do |request|
            Snapshot.list(request, collection, :paged => false)
          end
          feature.snapshot_section(prefix, :query => "#{prefix}.all")
        end
      end
    end
  end
end
