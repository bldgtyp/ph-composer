# frozen_string_literal: true

require_relative "test_helper"

class AuthoringFieldsTest < PhComposerTestCase
  Fields = PhComposer::Records::AuthoringFields

  def test_feature_alias_preserves_the_shared_public_api_and_feature_constants
    assert_same Fields, PhComposer::Assemblies::SchemaFields
    assert_equal "ph_composer.assemblies", PhComposer::Assemblies::FEATURE_ID
    assert_equal "ph_composer.assemblies.material", PhComposer::Assemblies::MATERIAL_KIND
    assert_equal %w[name notes datasheet_links source], Fields.common.map(&:key)
    assert_equal %w[number null], Fields.number("mm", :nullable => true).fetch("type")
  end

  def test_defaults_and_source_validation_are_detached_and_feature_neutral
    input = { "name" => "  Example  ", "datasheet_links" => ["https://example.invalid/sheet"] }
    values = Fields.defaults(input)
    assert_equal "Example", values.fetch("name")
    assert_equal({ "kind" => "manual" }, values.fetch("source"))
    values.fetch("datasheet_links") << "other"
    assert_equal 1, input.fetch("datasheet_links").length
    snapshot = Fields.source_snapshot_schema(Fields.common)
    refute snapshot.fetch("properties").key?("source")
    provenance = { "kind" => "library", "provider_kind" => "test.provider", "library_id" => "test-library",
      "record_kind" => "widgets", "record_id" => "row", "fingerprint" => "digest", "fingerprint_version" => 1,
      "copied_at" => "2026-10-01T12:00:00Z", "snapshot" => { "name" => "Example" } }
    assert_empty Fields.source_problems(provenance, snapshot)
    provenance.fetch("snapshot")["private_address"] = "private"
    refute_empty Fields.source_problems(provenance, snapshot)
  end
end
