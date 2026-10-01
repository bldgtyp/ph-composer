# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require "ripper"

class WindowRecordsSchemaTest < PhComposerTestCase
  include WindowRecordFixtures

  def test_four_final_version_one_closed_schemas_round_trip_optional_values
    W::Products::KINDS.each do |collection, kind|
      values = W::Products.defaults(collection, "name" => "Synthetic", "notes" => "Kept",
        "datasheet_links" => ["https://example.invalid/data.pdf"])
      record = values.merge("id" => "#{kind.id_prefix}_AAAAAAAAAAAA", "schema_version" => 1,
        "user_data" => { "fixture" => { "comments" => ["kept"] } })
      assert_empty kind.problems(record), collection
      kind.store.write(Sketchup.active_model, record)
      assert_equal record, kind.store.read(Sketchup.active_model, record.fetch("id"))
      refute_empty kind.problems(record.merge("preview_id" => nil))
      assert_equal 1, kind.schema_version
    end
    record = window_record("install_depth_m" => 0.0, "product_photos" => ["photo"])
    assert_empty W::Types::KIND.problems(record)
    W::Types::KIND.store.write(Sketchup.active_model, record)
    assert_equal record, W::Types::KIND.store.read(Sketchup.active_model, record.fetch("id"))
    refute_empty W::Types::KIND.problems(record.merge("preview_id" => nil))
    refute W::Products::KINDS.fetch("frames").values_schema["properties"].key?("psi_install")
  end

  def test_zero_signed_values_and_glazing_fraction_endpoints_are_authorable
    { "frames" => { "width_m" => 0, "uf_w_m2k" => 0, "psi_g_w_mk" => -0.1 },
      "glazings" => { "ug_w_m2k" => 0, "g_value" => 0 },
      "psi_install_types" => { "psi_w_mk" => -0.2 } }.each do |collection, values|
      kind = W::Products::KINDS.fetch(collection)
      record = W::Products.defaults(collection, values.merge("name" => "Zero"))
                .merge("id" => "#{kind.id_prefix}_AAAAAAAAAAAA", "schema_version" => 1)
      assert_empty kind.problems(record)
      if collection == "glazings"
        assert_empty kind.problems(record.merge("g_value" => 1))
        refute_empty kind.problems(record.merge("g_value" => 1.1))
      end
    end
  end

  def test_nested_reference_declarations_cover_all_nine_slots
    references = W::Types::KIND.references
    assert_equal 9, references.length
    references.each do |reference|
      assert_empty reference.declaration_problems(W::Types::KIND.values_schema), reference.key
    end
    assert_equal 4, references.count { |ref| ref.target_kind == W::FRAME_KIND }
    assert_equal 4, references.count { |ref| ref.target_kind == W::PSI_INSTALL_KIND }
    assert_equal 1, references.count { |ref| ref.target_kind == W::GLAZING_KIND }
  end

  def test_grid_coverage_empty_product_rules_and_operation_directions_are_strict
    record = window_record
    cell = record.fetch("elements").first
    refute_empty W::Types::KIND.problems(record.merge("elements" => [cell, cell]))
    bad = PhComposer::DeepCopy.call(record)
    bad["elements"][0]["row_span"] = [0, 1]
    refute_empty W::Types::KIND.problems(bad)
    bad = PhComposer::DeepCopy.call(record)
    bad["elements"][0].merge!("kind" => "empty", "glazing_id" => "glz_AAAAAAAAAAAA")
    refute_empty W::Types::KIND.problems(bad)
    %w[fixed swing].each do |type|
      bad = PhComposer::DeepCopy.call(record)
      bad["elements"][0]["operation"] = { "type" => type, "directions" => %w[left left] }
      refute_empty W::Types::KIND.problems(bad)
    end
    assert_empty W::Types::KIND.problems(record.merge("rows_m" => [nil]))
  end

  def test_definitions_name_no_geometry_or_higher_feature
    files = Dir[File.join(__dir__, "../src/ph_composer/features/windows/{products,types}/**/*.rb")]
    refute_empty files
    files.each do |path|
      text = File.read(path)
      constants = Ripper.lex(text).select { |token| token[1] == :on_const }.map { |token| token[2] }
      assert_empty(constants & %w[Zones Faces Face Sketchup ComponentInstance ComponentDefinition], path)
      refute_match(/features\/zones|ph_composer\.zones\.|designph/i, text, path)
    end
  end
end
