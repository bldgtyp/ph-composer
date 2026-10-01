# frozen_string_literal: true

require "ripper"
require_relative "test_helper"
require_relative "../src/ph_composer/features/assemblies/install"
require_relative "support/assembly_record_fixtures"

class AssemblyRecordsSchemaTest < PhComposerTestCase
  include AssemblyRecordFixtures

  def test_the_synthetic_records_round_trip_and_unknown_fields_refuse
    material = fixture_materials.values.first
    assembly = fixture_assembly(reference_layers)
    pairs = [[Assemblies::Materials::Schema::KIND, material], [Assemblies::Assembly::Schema::KIND, assembly]]
    pairs.each do |kind, record|
      assert_empty kind.problems(JSON.parse(JSON.generate(record)))
      refute_empty kind.problems(record.merge("invented" => 1))
    end
  end

  def test_material_categories_keep_the_thirteen_presets_and_aliases
    assert_equal 13, Assemblies::Materials::Schema::CATEGORIES.length
    { "Wood" => "woods", "metal" => "metals", "finish" => "finishes" }.each do |input, category|
      assert_equal category, Assemblies::Materials::Schema.defaults("name" => input, "category" => input)["category"]
    end
    assert Assemblies::Materials::Schema.membrane?(fixture_materials.fetch(material_id("membrane")))
  end

  def test_nested_identity_geometry_hints_and_air_barrier_are_validated
    mutations = [
      ->(row) { row["layers"] = [] },
      ->(row) { row["layers"][0]["id"] = "lyr_bad" },
      ->(row) { row["layers"] << PhComposer::DeepCopy.call(row["layers"][0]) },
      ->(row) { row["layers"][0]["segments"] = [] },
      ->(row) { row["layers"][0]["segments"][0]["width_mm"] = 0 },
      ->(row) { row["layers"][0]["segments"][0]["material_id"] = "bad" },
      ->(row) { row["type"] = "wall" },
      ->(row) { row["exterior_condition"] = "ventilated" },
      ->(row) { row["air_barrier"] = { "layer_id" => "lyr_MISSING00000", "face" => "interior" } }
    ]
    mutations.each do |mutate|
      record = fixture_assembly(reference_layers)
      mutate.call(record)
      refute_empty Assemblies::Assembly::Schema::KIND.problems(record)
    end
  end

  def test_one_layer_cannot_carry_two_steel_stud_spacings_or_duplicate_segment_ids
    record = fixture_assembly([[140, [[850, "wool"], [150, "wood"]]]])
    record["layers"][0]["segments"].each { |segment| segment["steel_stud_spacing_mm"] = 600 }
    assert_includes Assemblies::Assembly::Schema::KIND.problems(record),
                    "A Layer can carry only one steel stud spacing."
    record["layers"][0]["segments"].each { |segment| segment["steel_stud_spacing_mm"] = nil }
    record["layers"][0]["segments"][1]["id"] = record["layers"][0]["segments"][0]["id"]
    refute_empty Assemblies::Assembly::Schema::KIND.problems(record)
  end

  def test_library_source_has_required_provenance_and_an_authored_snapshot_ceiling
    source = { "kind" => "library", "provider_kind" => "file", "library_id" => "synthetic",
               "record_kind" => Assemblies::MATERIAL_KIND, "record_id" => "mat_LIBRARY00000",
               "fingerprint" => "synthetic-fingerprint", "fingerprint_version" => 1,
               "copied_at" => "2026-10-01T12:00:00Z", "snapshot" => { "name" => "Wool", "conductivity_w_mk" => 0.04 } }
    material = fixture_materials.fetch(material_id("wool")).merge("source" => source)
    assert_empty Assemblies::Materials::Schema::KIND.problems(material)
    mutations = [->(row) { row["source"].delete("library_id") },
                 ->(row) { row["source"]["copied_at"] = "yesterday" },
                 ->(row) { row["source"]["fingerprint_version"] = 2 },
                 ->(row) { row["source"]["snapshot"]["provider_address"] = "https://example.invalid" },
                 ->(row) { row["source"]["snapshot"]["user_data"] = {} },
                 ->(row) { row["source"]["snapshot"]["source"] = { "kind" => "manual" } }]
    mutations.each do |mutate|
      candidate = PhComposer::DeepCopy.call(material)
      mutate.call(candidate)
      refute_empty Assemblies::Materials::Schema::KIND.problems(candidate)
    end
  end

  def test_definition_feature_never_names_a_geometry_or_placed_feature
    files = Dir[File.expand_path("../src/ph_composer/features/assemblies/**/*.rb", __dir__)]
    files.each do |file|
      source = File.read(file)
      constants = Ripper.lex(source).select { |token| token.fetch(1) == :on_const }.map { |token| token.fetch(2) }
      assert_empty constants & %w[Zones Face Faces Window Windows], file
      refute_match(%r{features/(zones|windows)|ph_composer\.(zones|windows)}, source, file)
    end
  end
end
