# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/assembly_assignment_fixtures"

class AssemblyAssignmentRegistrationTest < PhComposerTestCase
  include AssemblyAssignmentFixtures

  def test_zones_requires_and_composes_real_assemblies
    PhComposer::Registry.reset
    error = assert_raises(PhComposer::RegistrationError) { PhComposer::Registry.install([PhComposer::Zones]) }
    assert_includes error.diagnostics.map(&:code), "registration.missing_dependency"
    PhComposer::Registry.install(PhComposer::FOUNDATION_FEATURES + [PhComposer::Assemblies, PhComposer::Zones])
    registry = PhComposer::Registry.current
    assert_equal ["ph_composer.assemblies"], registry.features.fetch("ph_composer.zones").requires
    target = registry.reference_targets.fetch(PhComposer::Zones::Faces::REFERENCE_KIND)
    assert_includes target.descriptor.references.map { |row| row.target_kind },
                    "ph_composer.assemblies.assembly"
    names = ["#{FACE_PREFIX}.assign_assembly", "#{FACE_PREFIX}.assembly_usage", "#{FACE_PREFIX}.assembly_choices"]
    names.each do |name|
      description = API.describe(:name => name)
      assert_equal false, description.fetch("params").fetch("additionalProperties")
      assert_equal false, description.fetch("result").fetch("additionalProperties")
      refute_empty description.fetch("examples")
      description.fetch("examples").each do |example|
        assert_empty PhComposer::JsonSchema.validate(example, description.fetch("params"))
      end
    end
  end

  def test_full_read_queries_catalog_once_and_reuses_one_zone_face_walk
    assignment_setup
    assignment_zone(100, 3)
    id = assignment_assembly("One read")
    assignment_invoke("#{FACE_PREFIX}.assign_assembly", assignment_params(assignment_faces, id))
    # Counted where a feature asks for another's query, below the registry, whose published
    # declarations cannot be swapped.
    original = PhComposer::HandlerRequest.instance_method(:query)
    queries = 0
    PhComposer::HandlerRequest.define_method(:query) do |name, params = {}|
      queries += 1 if name == "#{ASSEMBLY_PREFIX}.all"
      original.bind(self).call(name, params)
    end
    occurrence = PhComposer::Zones::Occurrences
    old_zones = occurrence.method(:scan_zones)
    old_faces = occurrence.method(:scan_faces)
    scans = { :zones => 0, :faces => 0 }
    occurrence.define_singleton_method(:scan_zones) do |model|
      scans[:zones] += 1
      old_zones.call(model)
    end
    occurrence.define_singleton_method(:scan_faces) do |zone|
      scans[:faces] += 1
      old_faces.call(zone)
    end
    read = assignment_query("#{FACE_PREFIX}.all")
    assert_equal 1, queries
    assert_equal({ :zones => 1, :faces => 1 }, scans)
    assert_equal 3, read.fetch("assembly_usage").first.fetch("face_count")
  ensure
    PhComposer::HandlerRequest.define_method(:query, original) if original
    occurrence.define_singleton_method(:scan_zones, old_zones) if old_zones
    occurrence.define_singleton_method(:scan_faces, old_faces) if old_faces
  end

  def test_panel_selection_and_choices_are_separate_snapshot_reads
    assignment_setup
    id = assignment_assembly("Panel choice")
    sections = PhComposer::Snapshot.build(@context).fetch("sections")
    assert_equal "selection.invalid", sections.fetch("#{FACE_PREFIX}.selected").fetch("code")
    choices = sections.fetch("#{FACE_PREFIX}.assemblies")
    assert_equal "ok", choices.fetch("code")
    assert_equal id, choices.fetch("value").fetch("assemblies").first.fetch("id")
    assert_equal "ok", sections.fetch("#{FACE_PREFIX}.usage").fetch("code")
  end

  def test_paint_preset_can_clear_other_palette_fields_without_a_model_write
    assignment_setup
    id = assignment_assembly("Paint preset")
    name = "#{FACE_PREFIX}.choose"
    API.view(:context => @context, :name => name, :params => { "field" => "face_type", "value" => "RoofCeiling" })
    API.view(:context => @context, :name => name, :params => { "field" => "boundary_condition", "value" => "Ground" })
    result = API.view(:context => @context, :name => name,
                      :params => { "field" => "assembly_id", "value" => id, "reset" => true })
    assert_equal "ok", result.fetch("code")
    assert_equal({ "assembly_id" => id }, result.fetch("value").fetch("palette"))
    assert_equal true, result.fetch("value").fetch("active")
    # Only creating the fixture definition above opened a native Model operation.
    assert_equal 1, Sketchup.active_model.operations.length
  end
end
