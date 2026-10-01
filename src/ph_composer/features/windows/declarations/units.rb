# frozen_string_literal: true

require_relative "../units/actions"
require_relative "../units/repairs"

module PhComposer
  module Windows
    module UnitRegistration
      EXAMPLE_UNIT = { "unit_id" => "wun_Ab12Cd34Ef56", "entity_path" => [1201, 1203] }.freeze
      module_function

      def install(feature, registry)
        face = DeepCopy.call(registry.record_descriptor("ph_composer.zones.faces.face").occurrence_schema)
        reference = Units::TARGET.descriptor.occurrence_schema
        feature.reference_target(Units::TARGET)
        reads(feature, face, reference)
        repairs(feature, face, reference)
        batch_repairs(feature, reference)
        flip_repair(feature, reference)
        restore_repair(feature, face)
        place(feature, face)
      end

      def reads(feature, face, reference)
        finding = Shapes.object({ "code" => Shapes::ID, "repair" => Shapes::ID })
        view = Shapes.with(Units::RECORD_KIND.descriptor.view_schema,
          "reference" => reference, "host" => face.merge("type" => %w[object null]),
          "findings" => Shapes.list(finding))
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
      end

      def repairs(feature, face, reference)
        prefix = "#{FEATURE_ID}.units"
        feature.action("#{prefix}.remove", :description => "Remove explicit Window occurrences with reference guards.",
          :params => Shapes.object({ "units" => Shapes.list(reference).merge("minItems" => 1, "maxItems" => 500) }),
          :result => Shapes.object({ "unit_ids" => Shapes.list(Shapes::ID) }), :undo_name => "Remove Windows",
          :side_effects => "Removes only the chosen instances; incoming references must remain valid.",
          :examples => [{ "units" => [EXAMPLE_UNIT] }]) do |request, proposal|
          Units::Repairs.remove(request, proposal)
        end
        feature.action("#{prefix}.rehost", :description => "Glue an unmoved Window to an explicit same-storage Face.",
          :params => Shapes.object({ "unit" => reference, "host" => face }),
          :result => Shapes.object({ "unit_id" => Shapes::ID }), :undo_name => "Re-host Window",
          :side_effects => "Changes glue only, after containment and overlap checks.",
          :examples => [{ "unit" => { "unit_id" => "wun_Ab12Cd34Ef56", "entity_path" => [1201, 1203] },
            "host" => { "zone_id" => "zon_Ab12Cd34Ef56", "zone_path" => [1201],
              "entity_path" => [1202], "entity_id" => nil } }]) do |request, proposal|
          Units::Repairs.rehost(request, proposal)
        end
      end

      def batch_repairs(feature, reference)
        units = Shapes.list(reference).merge("minItems" => 1, "maxItems" => 500)
        feature.action("#{FEATURE_ID}.units.swap_type",
          :description => "Swap explicit Windows, preserving their anchors.",
          :params => Shapes.object({ "units" => units, "type_id" => Shapes::ID }),
          :result => Shapes.object({ "unit_ids" => Shapes.list(Shapes::ID) }), :undo_name => "Swap Window Type",
          :side_effects => "Reuses one target definition and preserves each Unit's metadata and host.",
          :examples => [{ "units" => [EXAMPLE_UNIT], "type_id" => "wnt_Ab12Cd34Ef56" }]) do |request, proposal|
          Units::Repairs.swap_type(request, proposal)
        end
        feature.action("#{FEATURE_ID}.units.reset_to_type",
          :description => "Reset explicit Windows of one Type to its authored geometry.",
          :params => Shapes.object({ "units" => units }),
          :result => Shapes.object({ "unit_ids" => Shapes.list(Shapes::ID) }), :undo_name => "Reset Windows to Type",
          :side_effects => "Repairs selected instances; regenerating an edited primary affects all its Units.",
          :examples => [{ "units" => [EXAMPLE_UNIT] }]) do |request, proposal|
          Units::Repairs.reset_to_type(request, proposal)
        end
      end

      def flip_repair(feature, reference)
        feature.action("#{FEATURE_ID}.units.new_flipped_type",
          :description => "Create a horizontally flipped Type for one mirrored Window.",
          :params => Shapes.object({ "unit" => reference, "name" => { "type" => "string", "minLength" => 1 } },
            :optional => ["name"]),
          :result => Shapes.object({ "unit_id" => Shapes::ID, "type_id" => Shapes::ID }),
          :undo_name => "New Flipped Window Type",
          :side_effects => "Creates one independent Type; preserves physical panes, metadata and glue.",
          :examples => [{ "unit" => EXAMPLE_UNIT }]) do |request, proposal|
          Units::Repairs.new_flipped_type(request, proposal)
        end
      end

      def restore_repair(feature, face)
        path = { "type" => "array", "minItems" => 1, "items" => { "type" => "integer", "minimum" => 1 } }
        feature.action("#{FEATURE_ID}.units.restore", :description => "Recover a Unit from exact stamped pane Faces.",
          :params => Shapes.object({ "host" => face, "type_id" => Shapes::ID,
            "pane_paths" => Shapes.list(path).merge("minItems" => 1, "maxItems" => 500) }),
          :result => Shapes.object({ "unit_id" => Shapes::ID }), :undo_name => "Restore Window",
          :side_effects => "Creates a new default-anchor Unit and removes only its exact loose panes and edges.",
          :examples => [{ "host" => { "zone_id" => "zon_Ab12Cd34Ef56", "zone_path" => [1201],
            "entity_path" => [1202], "entity_id" => nil }, "type_id" => "wnt_Ab12Cd34Ef56",
            "pane_paths" => [[1201, 1204]] }]) do |request, proposal|
          Units::Repairs.restore(request, proposal)
        end
      end

      def place(feature, face)
        prefix = "#{FEATURE_ID}.units"
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
