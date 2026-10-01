# frozen_string_literal: true

require_relative "test_helper"
require_relative "../tools/api_reference/api_reference"

# Discovery and description are enough to use the building operations. Every Zone and Face operation
# publishes specific input and output schemas and a worked example that validates, the entity kinds
# publish their descriptors, and docs/API_REFERENCE.md is generated from the same registrations rather
# than kept by hand.
class ApiReferenceTest < PhComposerTestCase
  include FixtureFiles
  API = PhComposer::API
  REFERENCE = File.expand_path("../docs/API_REFERENCE.md", __dir__)
  ANY_OBJECT = { "type" => "object" }.freeze

  def test_an_entity_kind_describes_its_values_references_and_occurrence
    zone = API.describe(:name => "ph_composer.zones.zone")
    face = API.describe(:name => "ph_composer.zones.faces.face")

    assert_equal ["reference_target", "ph_composer.zones", 1, "id"],
                 zone.values_at("kind", "owner", "schema_version", "identity_field")
    assert_equal "mm", zone.dig("values", "properties", "ground_depth_mm", "x-unit")
    assert_equal %w[zone_id zone_path], zone.dig("occurrence_reference", "required")
    assert_equal [{ "key" => "attached_zone_id", "target_kind" => "ph_composer.zones.faces.attached_zone",
                    "cardinality" => "one" }], face.fetch("references")
    assert_includes face.dig("values", "properties", "boundary_condition", "enum"), "AttachedZone"
    assert_equal %w[zone_id zone_path entity_path entity_id], face.dig("occurrence_reference", "required")
  end

  def test_every_building_operation_publishes_specific_schemas_and_a_valid_example
    names = building_operations
    assert_operator names.length, :>=, 22

    names.each do |name|
      description = API.describe(:name => name)
      [description.fetch("params"), description.fetch("result")].each do |schema|
        refute_equal ANY_OBJECT, schema, "#{name} publishes an unspecified object"
        assert_equal false, schema["additionalProperties"], "#{name} leaves its fields open"
      end
      refute_empty description.fetch("examples"), "#{name} has no worked example"
      description.fetch("examples").each do |example|
        assert_empty PhComposer::JsonSchema.validate(example, description.fetch("params")), "#{name} example"
      end
    end
  end

  def test_quantities_carry_their_units
    zones = API.describe(:name => "ph_composer.zones.list").fetch("result")
    faces = API.describe(:name => "ph_composer.zones.faces.list").fetch("result")

    assert_equal "mm", zones.dig("properties", "zones", "items", "properties", "values", "properties",
                                 "ground_depth_mm", "x-unit")
    assert_equal "m2", faces.dig("properties", "faces", "items", "properties", "area_m2", "x-unit")
  end

  def test_the_api_reference_is_generated_from_the_registrations
    text = PhComposerTools::ApiReference.markdown(PhComposer::Registry.current)

    refute_match(/[–—]/, text, "docs/ is client-facing: no em or en dashes")
    if FixtureFiles::WRITING
      write_text(REFERENCE, text)
    else
      assert_equal File.read(REFERENCE), text, "docs/API_REFERENCE.md is stale; run `make fixtures`"
    end
  end

  private

  def building_operations
    discovered = API.discover
    %w[queries actions view_commands].flat_map { |key| discovered.fetch(key) }
                                      .select { |row| row.fetch("owner") == "ph_composer.zones" }
                                      .map { |row| row.fetch("name") }
  end

  def write_text(path, text)
    File.write(path, text) unless File.exist?(path) && File.read(path) == text
    assert true
  end
end
