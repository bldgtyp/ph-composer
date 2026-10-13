# frozen_string_literal: true

# Synthetic, offline review probes. Run with the Makefile-selected Ruby from the repository root:
#   "$(rbenv which ruby)" -Itests planning/code-review/evidence/ruby_feature_probes.rb
# These assertions record the reviewed baseline's mismatches, rather than desired future behavior.
require_relative "../../../tests/test_helper"
require_relative "../../../tests/support/window_record_fixtures"
require_relative "../../../tests/support/assembly_assignment_fixtures"

class RubyFeatureReviewProbes < PhComposerTestCase
  include WindowRecordFixtures
  include AssemblyAssignmentFixtures

  U = PhComposer::Windows::Units
  PREFIX = "ph_composer.windows"

  def setup
    super
    assignment_setup
    PhComposer::Registry.install([W]) unless PhComposer::Registry.installed?(W::FEATURE_ID)
    points = [[0, 0, 0], [1000, 0, 0], [1000, 1000, 0], [0, 1000, 0]].map do |point|
      Geom::Point3d.new(*point)
    end
    face = Sketchup::Face.new(1001, {}, :points => points)
    @group = Sketchup::Group.new(1000, Sketchup::Entities.new([face]))
    @model.entities << @group
    made = assignment_invoke("ph_composer.zones.make", "parent_path" => [], "entity_ids" => [1000])
    assert_equal "completed", made.fetch("status"), made.inspect
    classified = assignment_classify(assignment_faces,
                                     "face_type" => { "mode" => "set", "value" => "Wall" },
                                     "boundary_condition" => { "mode" => "set", "value" => "Outdoors" })
    assert_equal "completed", classified.fetch("status"), classified.inspect
    @face_reference = assignment_faces.first.fetch("reference")
    made_type = assignment_invoke("#{PREFIX}.types.create", "values" => { "name" => "Synthetic placement" })
    assert_equal "completed", made_type.fetch("status"), made_type.inspect
    @type_id = made_type.fetch("value").fetch("id")
  end

  def test_definition_create_repairs_unrelated_copied_units_and_locked_copy_blocks_it
    placed = assignment_invoke("#{PREFIX}.units.place",
                               "host" => @face_reference, "type_id" => @type_id, "anchor" => "sill_center",
                               "offsets" => { "x_m" => 2.0, "y_m" => 3.0 })
    assert_equal "completed", placed.fetch("status"), placed.inspect
    original = U::Occurrences.all(@model).first
    copy = @group.entities.add_instance(original.entity.definition, original.entity.transformation)
    U.write(copy, original.record)
    copy.locked = true
    failed = assignment_invoke("#{PREFIX}.frames.create", "values" => { "name" => "Unrelated frame" })
    assert_equal %w[refused target.locked none], failed.values_at("status", "code", "effect")
    engine = PhComposer::Records::Engine.new(@model, PhComposer::Registry.current.catalog)
    assert_empty engine.ids(W::FRAME_KIND)
    copy.locked = false
    succeeded = assignment_invoke("#{PREFIX}.frames.create", "values" => { "name" => "Unrelated frame" })
    assert_equal %w[completed committed], succeeded.values_at("status", "effect")
    assert_equal 2, U::Occurrences.all(@model).map { |item| item.record.fetch("id") }.uniq.length
    assert_includes succeeded.fetch("affected").map { |row| row.fetch("change") }, "identity_repaired"
  end

  def test_entity_metadata_is_not_addressable_and_extension_status_is_not_returned
    registry = PhComposer::Registry.current
    actions = registry.actions.values.select do |entry|
      entry.owner == "ph_composer.zones" || entry.name.start_with?("#{PREFIX}.units.")
    end
    refute actions.any? { |entry| entry.params.fetch("properties", {}).key?("extension_payloads") }
    metadata_update = actions.any? do |entry|
      entry.name.start_with?("#{PREFIX}.units.") && entry.name != "#{PREFIX}.units.place" &&
        entry.params.fetch("properties", {}).key?("user_data")
    end
    refute metadata_update
    row = assignment_query("ph_composer.zones.list").fetch("zones").first
    failed = assignment_invoke("ph_composer.zones.update",
                               "reference" => row.fetch("reference"), "values" => row.fetch("values"),
                               "expected_values" => row.fetch("values"), "user_data" => { "review" => true })
    assert_equal %w[refused params.invalid none], failed.values_at("status", "code", "effect")
    unknown = { "schema_version" => 99, "payload" => { "keep" => "literal" },
                "references" => [], "export_relevance" => "local_only" }
    record = PhComposer::Zones::ZONE_STORE.read(@group)
    PhComposer::Zones::ZONE_STORE.write(@group,
                                      record.merge("extension_data" => { "outside.review" => unknown }))
    row = assignment_query("ph_composer.zones.list").fetch("zones").first
    assert_equal unknown, row.dig("extension_data", "outside.review")
    refute row.key?("extension_status")
  end
end
