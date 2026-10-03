# frozen_string_literal: true

module PhComposer
  module Assemblies
    module InventoryRegistration
      THERMAL = Shapes.object({
        "complete" => { "type" => "boolean" }, "flags" => Shapes.list(Shapes::TEXT),
        "warnings" => Shapes.list(Shapes::TEXT), "message_parts" => Shapes.list(Shapes.list(Shapes::OBJECT)),
        "u_effective_w_m2k" => { "type" => %w[number null], "x-unit" => "W/m2K" },
        "u_construction_w_m2k" => { "type" => %w[number null], "x-unit" => "W/m2K" },
        "r_construction_m2k_w" => { "type" => %w[number null], "x-unit" => "m2K/W" },
        "rsi_m2k_w" => { "type" => "number", "x-unit" => "m2K/W" },
        "rse_m2k_w" => { "type" => "number", "x-unit" => "m2K/W" }, "direction" => Shapes::TEXT
      })
      DISPLAY = Shapes.object({
        "color" => Shapes::TEXT, "layer_count" => { "type" => "integer", "minimum" => 1 },
        "total_thickness_mm" => { "type" => "number", "minimum" => 0, "x-unit" => "mm" },
        "thermal" => THERMAL, "complete" => { "type" => "boolean" }
      })
      USE = Shapes.object({ "assembly_id" => Shapes::TEXT, "name" => Shapes::TEXT })
      MATERIAL_ROW = Shapes.with(Shapes.view(Materials::Schema::KIND),
                                 "uses" => Shapes.list(USE), "use_count" => { "type" => "integer", "minimum" => 0 })
      ASSEMBLY_ROW = Shapes.with(Shapes.view(Assembly::Schema::KIND),
                                 "display" => DISPLAY,
                                 "export_ready" => Shapes.described({ "type" => "boolean" },
                                                                    "Whether a Face can export with this Assembly."),
                                 "export_blockers" => Shapes.described(Shapes::FINDINGS,
                                                                       "Why a Face cannot export with it; empty " \
                                                                       "when export_ready."))
      CATEGORY = Shapes.object(%w[id label tone].to_h { |key| [key, Shapes::TEXT] })

      module_function

      def result(row, paged:, categories: false)
        properties = { "records" => Shapes.list(row), "unreadable" => Shapes::UNREADABLE }
        properties["categories"] = Shapes.list(CATEGORY) if categories
        properties.merge!("next_cursor" => Pages::NEXT_CURSOR, "total" => Pages::TOTAL) if paged
        Shapes.object(properties)
      end

      def install(feature)
        declare(feature, "materials", MATERIAL_ROW, :categories => true) do |request, paged|
          Snapshot.materials(request, :paged => paged)
        end
        declare(feature, "assemblies", ASSEMBLY_ROW) { |request, paged| Snapshot.assemblies(request, :paged => paged) }
      end

      # The list and all queries for one collection; `read` takes the request and whether to page.
      def declare(feature, collection, row, categories: false, &read)
        prefix = "#{FEATURE_ID}.#{collection}"
        feature.query("#{prefix}.list", :description => "One bounded page of #{collection}, with display findings.",
                                        :refuses => Refuses::PAGE,
                                        :params => Shapes.list_params,
                                        :result => result(row, :paged => true, :categories => categories),
                                        :examples => [{}, { "limit" => 20 }]) do |request|
          read.call(request, true)
        end
        feature.query("#{prefix}.all",
                      :description => "The complete #{collection} inventory for the panel snapshot.",
                      :refuses => [],
                      :params => Shapes::NONE, :result => result(row, :paged => false, :categories => categories),
                      :examples => [{}]) do |request|
          read.call(request, false)
        end
        feature.snapshot_section(prefix, :query => "#{prefix}.all")
      end
    end
  end
end
