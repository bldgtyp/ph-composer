# frozen_string_literal: true

module PhComposer
  module Assemblies
    module Materials
      # The thirteen stable category ids and the authored SI properties of a Material.
      module Schema
        CATEGORIES = {
          "insulation" => ["Insulation", "warm"], "finishes" => ["Finishes", "rose"],
          "woods" => ["Woods", "wood"], "metals" => ["Metals", "neutral"],
          "masonry" => ["Masonry", "rose"], "stud_layers_steel" => ["Stud-Layers (Steel)", "neutral"],
          "stud_layers_wood" => ["Stud-Layers (Wood)", "wood"],
          "air_horizontal_heat_flow" => ["Air: Horizontal Heat Flow", "blue"],
          "air_upward_heat_flow" => ["Air: Upward Heat Flow", "blue"],
          "air_downward_heat_flow" => ["Air: Downward Heat Flow", "blue"],
          "rainscreen_insulation" => ["Rainscreen Insulation", "warm"],
          "doors" => ["Doors", "wood"], "membrane" => ["Membrane", "violet"]
        }.freeze
        ALIASES = { "wood" => "woods", "metal" => "metals", "finish" => "finishes" }.freeze
        # A category param also takes a label or alias, which `category` turns into its id.
        LABELLED_FIELDS = ["category"].freeze

        module_function

        def category(value)
          text = value.to_s.strip
          key = ALIASES.fetch(text.downcase, text.downcase)
          return key if key.empty? || CATEGORIES.key?(key)

          match = CATEGORIES.find { |_id, entry| entry.first.casecmp(text).zero? }
          match ? match.first : text
        end

        def defaults(values)
          result = Fields.defaults(values).merge("color" => values.fetch("color", "#ffffff"))
          result["category"] = category(values.fetch("category", ""))
          result
        end

        def membrane?(material)
          material.fetch("category", "") == "membrane"
        end

        # A Layer of several Layer-Segments, one of them a membrane: a membrane Layer holds one segment.
        def membrane_in_mixed_layer?(layer, materials)
          segments = Array(layer["segments"])
          segments.length > 1 && segments.any? do |segment|
            material = materials[segment["material_id"]]
            material && membrane?(material)
          end
        end

        def membrane_layer?(layer, materials)
          layer.fetch("segments").all? do |segment|
            material = materials[segment["material_id"]]
            material && membrane?(material)
          end
        end

        AUTHORED_FIELDS = Fields.common + [
          Fields.field("category", { "type" => "string", "enum" => [""] + CATEGORIES.keys }),
          Fields.field("conductivity_w_mk", Fields.number("W/mK", :nullable => true)),
          Fields.field("density_kg_m3", Fields.number("kg/m3", :nullable => true)),
          Fields.field("specific_heat_j_kgk", Fields.number("J/kgK", :nullable => true)),
          Fields.field("emissivity", { "type" => %w[number null], "minimum" => 0, "maximum" => 1 }),
          Fields.field("color", { "type" => "string" })
        ]
        # The original provider category remains attribution even when its authored local category
        # falls back to Uncategorized. This does not widen the authored category vocabulary.
        SNAPSHOT_SCHEMA = Fields.source_snapshot_schema(AUTHORED_FIELDS.map do |field|
          field.key == "category" ? Fields.field("category", { "type" => "string" }) : field
        end)
        FIELDS = Fields.with_source_snapshot(AUTHORED_FIELDS, SNAPSHOT_SCHEMA)

        KIND = Records::RecordKind.new(
          :id => MATERIAL_KIND, :label => "Material", :schema_version => 1, :id_prefix => "mat",
          :fields => FIELDS, :validate => ->(values) {
                                            Fields.problems(values) +
                                                      Fields.source_problems(values["source"], SNAPSHOT_SCHEMA)
                                          }
        )
      end
    end
  end
end
