# frozen_string_literal: true

module PhComposer
  module Assemblies
    module InventoryRegistration
      THERMAL = Shapes.object({
        "complete" => { "type" => "boolean" }, "flags" => Shapes.list(Shapes::TEXT),
        "warnings" => Shapes.list(Shapes::TEXT), "message_parts" => Shapes.list(Shapes.list(Shapes::OBJECT)),
        "u_effective" => { "type" => %w[number null], "x-unit" => "W/m2K" },
        "u_construction" => { "type" => %w[number null], "x-unit" => "W/m2K" },
        "r_construction" => { "type" => %w[number null], "x-unit" => "m2K/W" },
        "rsi" => { "type" => "number", "x-unit" => "m2K/W" },
        "rse" => { "type" => "number", "x-unit" => "m2K/W" }, "direction" => Shapes::TEXT
      })
      DISPLAY = Shapes.object({
        "color" => Shapes::TEXT, "layer_count" => { "type" => "integer", "minimum" => 1 },
        "total_thickness_mm" => { "type" => "number", "minimum" => 0, "x-unit" => "mm" },
        "thermal" => THERMAL, "complete" => { "type" => "boolean" }
      })
      USE = Shapes.object({ "assembly_id" => Shapes::TEXT, "name" => Shapes::TEXT })
      MATERIAL_ROW = Shapes.with(Shapes.view(Materials::Schema::KIND),
                                "uses" => Shapes.list(USE), "use_count" => { "type" => "integer", "minimum" => 0 })
      ASSEMBLY_ROW = Shapes.with(Shapes.view(Assembly::Schema::KIND), "display" => DISPLAY)
      CATEGORY = Shapes.object(%w[id label tone].to_h { |key| [key, Shapes::TEXT] })

      module_function

      def result(kind, paged:)
        material = kind == MATERIAL_KIND
        properties = { "records" => Shapes.list(material ? MATERIAL_ROW : ASSEMBLY_ROW),
                       "unreadable" => Shapes::UNREADABLE }
        properties["categories"] = Shapes.list(CATEGORY) if material
        properties.merge!("next_cursor" => Pages::NEXT_CURSOR, "total" => Pages::TOTAL) if paged
        Shapes.object(properties)
      end

      def install(feature)
        declare(feature, "materials", MATERIAL_KIND)
        declare(feature, "assemblies", ASSEMBLY_KIND)
      end

      def declare(feature, collection, kind)
        prefix = "#{FEATURE_ID}.#{collection}"
        feature.query("#{prefix}.list", :description => "One bounded page of #{collection}, with display findings.",
                      :params => Shapes.list_params, :result => result(kind, :paged => true),
                      :examples => [{}, { "limit" => 20 }]) do |request|
          Snapshot.list(request, kind)
        end
        feature.query("#{prefix}.all", :description => "The complete #{collection} inventory for the panel snapshot.",
                      :params => Shapes::NONE, :result => result(kind, :paged => false), :examples => [{}]) do |request|
          Snapshot.list(request, kind, :paged => false)
        end
        feature.snapshot_section(prefix, :query => "#{prefix}.all")
      end
    end
  end
end
