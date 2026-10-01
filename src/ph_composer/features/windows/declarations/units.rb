# frozen_string_literal: true

require_relative "../units/actions"

module PhComposer
  module Windows
    module UnitRegistration
      module_function

      def install(feature, registry)
        face = DeepCopy.call(registry.record_descriptor("ph_composer.zones.faces.face").occurrence_schema)
        reference = Units::TARGET.descriptor.occurrence_schema
        finding = Shapes.object({ "code" => Shapes::ID, "repair" => Shapes::ID })
        view = Shapes.with(Units::RECORD_KIND.descriptor.view_schema,
          "reference" => reference, "host" => face.merge("type" => %w[object null]),
          "findings" => Shapes.list(finding))
        feature.reference_target(Units::TARGET)
        prefix = "#{FEATURE_ID}.units"
        result = Shapes.object({ "units" => Shapes.list(view) })
        feature.query("#{prefix}.list", :description => "Window occurrences and native findings, without writes.",
          :params => Shapes.list_params, :result => Shapes.with(result, "next_cursor" => Pages::NEXT_CURSOR,
            "total" => Pages::TOTAL), :examples => [{}]) { |request| Units::Actions.list(request) }
        feature.query("#{prefix}.all", :description => "All Window occurrences and native findings for the snapshot.",
          :params => Shapes::NONE, :result => result, :examples => [{}]) do |request|
          Units::Actions.list(request, :paged => false)
        end
        feature.snapshot_section(prefix, :query => "#{prefix}.all")
        feature.action("#{prefix}.place", :description => "Place an anchored Window on an explicit writable Zone Face.",
          :params => Shapes.object({ "host" => face, "type_id" => Shapes::ID,
            "anchor" => { "type" => "string", "enum" => Units::Anchors::ALL },
            "offsets" => Shapes.object({ "x_m" => { "type" => "number", "x-unit" => "m" },
              "y_m" => { "type" => "number", "x-unit" => "m" } }), "user_data" => Shapes::OBJECT },
            :optional => ["user_data"]), :result => Shapes.object({ "unit_id" => Shapes::ID }),
          :undo_name => "Place Window",
          :side_effects => "Creates or reuses the Type definition, glues an instance and stores its Unit record.",
          :examples => [{ "host" => { "zone_id" => "zon_Ab12Cd34Ef56", "zone_path" => [1201],
            "entity_path" => [1202], "entity_id" => nil }, "type_id" => "wnt_Ab12Cd34Ef56",
            "anchor" => "sill_center", "offsets" => { "x_m" => 1.0, "y_m" => 0.8 } }]) do |request, proposal|
          Units::Actions.place(request, proposal)
        end
      end
    end
  end
end
