# frozen_string_literal: true

require_relative "../../src/ph_composer/features/assemblies/install"

module AssemblyRecordFixtures
  Assemblies = PhComposer::Assemblies

  def fixture_materials
    { "board" => [0.038, "insulation"], "wool" => [0.04, "insulation"],
      "soft" => [0.035, "insulation"], "wood" => [0.13, "woods"], "membrane" => [nil, "membrane"] }.to_h do |key, pair|
      id = material_id(key)
      [id, Assemblies::Materials::Schema.defaults("name" => key, "category" => pair.last,
                                                  "conductivity_w_mk" => pair.first)
                                        .merge("id" => id, "schema_version" => 1)]
    end
  end

  def material_id(key)
    "mat_#{key.ljust(12, '0')}"
  end

  def fixture_assembly(layers, overrides = {})
    values = Assemblies::Assembly::Schema.defaults({ "name" => "Reference" })
    values["layers"] = layers.map do |thickness, segments|
      Assemblies::Assembly::Schema.layer(thickness).merge("segments" => segments.map do |width, key|
        Assemblies::Assembly::Schema.segment(width).merge("material_id" => key && material_id(key))
      end)
    end
    values.merge(overrides).merge("id" => "asm_AAAAAAAAAAAA", "schema_version" => 1)
  end

  def reference_layers
    [[12.0, [[1000.0, "board"]]], [140.0, [[1000.0, "wool"]]], [40.0, [[1000.0, "soft"]]]]
  end
end
