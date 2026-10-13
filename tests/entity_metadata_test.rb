# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "support/assembly_assignment_fixtures"

# Entity metadata through the owners' public operations (context/CONTRACTS.md, "Records and extension
# data"): Zone, Face and Window Unit reads report each envelope's status as a catalog read does, and
# each owner's update_metadata action replaces user_data and installed payloads under a pre-image, in
# one step and one Undo entry.
class EntityMetadataTest < PhComposerTestCase
  include WindowRecordFixtures
  include AssemblyAssignmentFixtures

  ZONES = "ph_composer.zones"
  WINDOWS = "ph_composer.windows"
  REVIEW = "probe.notes.review"
  EMPTY = { "user_data" => {}, "extension_data" => {} }.freeze

  # A maintained extension at version 2, valid when its status is draft or checked, optionally naming a
  # Zone.
  module Review
    module_function

    def name
      "Review"
    end

    def install(registry)
      registry.feature("probe.notes", :contract_version => 1, :requires => ["ph_composer.zones"]).extension(
        PhComposer::Records::Extension.new(
          :namespace => REVIEW, :schema_version => 2, :export_relevance => "local_only",
          :references => [{ "path" => "$.zone", "target_kind" => "ph_composer.zones.zone", "cardinality" => "one" }],
          :migrations => { 1 => ->(payload) { payload } },
          :validate => ->(payload) { %w[draft checked].include?(payload["status"]) ? [] : ["status is unknown"] }
        )
      )
    end
  end

  def setup
    super
    assignment_setup
    PhComposer::Registry.install([W]) unless PhComposer::Registry.installed?(W::FEATURE_ID)
    PhComposer::Registry.install([Review])
    points = [[0, 0, 0], [3000, 0, 0], [3000, 3000, 0], [0, 3000, 0]].map { |point| Geom::Point3d.new(*point) }
    @group = Sketchup::Group.new(1000, Sketchup::Entities.new([Sketchup::Face.new(1001, {}, :points => points)]))
    @model.entities << @group
    assert_equal "completed", assignment_invoke("#{ZONES}.make", "parent_path" => [],
                                                                 "entity_ids" => [1000]).fetch("status")
    assignment_classify(assignment_faces, "face_type" => { "mode" => "set", "value" => "Wall" },
                                          "boundary_condition" => { "mode" => "set", "value" => "Outdoors" })
    type_id = assignment_invoke("#{WINDOWS}.types.create", "values" => { "name" => "Metadata" }).dig("value", "id")
    placed = assignment_invoke("#{WINDOWS}.units.place", "host" => face.fetch("reference"), "type_id" => type_id,
                                                         "anchor" => "sill_center",
                                                         "offsets" => { "x_m" => 0.8, "y_m" => 1.0 })
    assert_equal "completed", placed.fetch("status"), placed.inspect
  end

  def zone
    assignment_query("#{ZONES}.all").fetch("zones").first
  end

  def face
    assignment_faces.first
  end

  def unit
    assignment_query("#{WINDOWS}.units.list").fetch("units").first
  end

  def envelope(version, payload)
    { "schema_version" => version, "payload" => payload,
      "references" => [{ "path" => "$.zone", "target_kind" => "ph_composer.zones.zone", "cardinality" => "one" }],
      "export_relevance" => "local_only" }
  end

  def update(name, reference, read, **fields)
    assignment_invoke(name, "updates" => [{ "reference" => reference,
                                            "expected_metadata" => read.slice("user_data", "extension_data") }
                                            .merge(fields.transform_keys(&:to_s))])
  end

  def test_entity_reads_report_each_envelope_status_and_absent_metadata_as_empty
    assert_equal({}, zone.fetch("extension_status"))
    assert_equal({}, unit.fetch("extension_status"))
    extension_data = { REVIEW => envelope(2, { "status" => "draft" }), "absent.extension" => envelope(1, {}) }
    record = PhComposer::Zones::ZONE_STORE.read(@group).merge("extension_data" => extension_data)
    PhComposer::Zones::ZONE_STORE.write(@group, record)
    revision = @session.revision
    read = zone
    assert_equal({ REVIEW => "understood", "absent.extension" => "unavailable" }, read.fetch("extension_status"))
    read.fetch("extension_status").clear
    assert_equal "understood", zone.dig("extension_status", REVIEW), "a read hands out a detached map"
    assert_equal revision, @session.revision
  end

  # The five statuses, as an older or newer build or another installation would have stored them, read
  # through each entity owner and compared with what a catalog read reports for the same envelopes.
  def test_every_status_word_on_a_zone_face_and_unit_matches_a_catalog_read
    stored = { "a.understood" => envelope(2, { "status" => "draft" }) }
    statuses = { "understood" => envelope(2, { "status" => "draft" }), "invalid" => envelope(2, {}),
                 "outdated" => envelope(1, {}), "unsupported" => envelope(3, {}) }
    catalog = PhComposer::Registry.current.catalog
    statuses.each do |word, row|
      assert_equal word, PhComposer::Records::Extension.status(row, catalog.extension(REVIEW)), word
    end
    stored = { REVIEW => statuses.fetch("invalid"), "absent.extension" => envelope(1, {}) }
    expected = { REVIEW => "invalid", "absent.extension" => "unavailable" }
    zone_record = PhComposer::Zones::ZONE_STORE.read(@group).merge("extension_data" => stored)
    PhComposer::Zones::ZONE_STORE.write(@group, zone_record)
    face_entity = PhComposer::Zones::Occurrences.resolve_face(@model, face.fetch("reference")).entity
    face_record = PhComposer::Zones::Faces::FACE_STORE.read(face_entity).merge("extension_data" => stored)
    PhComposer::Zones::Faces::FACE_STORE.write(face_entity, face_record)
    unit_item = PhComposer::Windows::Units::Occurrences.all(@model).first
    PhComposer::Windows::Units.write(unit_item.entity, unit_item.record.merge("extension_data" => stored))
    assert_equal expected, zone.fetch("extension_status")
    assert_equal expected, face.fetch("extension_status")
    assert_equal expected, unit.fetch("extension_status")
    assert_equal expected, PhComposer::Records::Metadata.status_map({ "extension_data" => stored }, catalog)
  end

  def test_a_zone_update_replaces_user_data_and_a_payload_in_one_undo_and_reads_back
    before = zone
    result = update("#{ZONES}.update_metadata", before.fetch("reference"), before,
                    :user_data => { "firm" => { "note" => "checked" } },
                    :extension_payloads => { REVIEW => { "status" => "checked" } })
    assert_equal "committed", result.fetch("effect"), result.inspect
    assert_equal({ REVIEW => "understood" }, result.dig("value", "updates", 0, "extension_status"))
    after = zone
    assert_equal({ "firm" => { "note" => "checked" } }, after.fetch("user_data"))
    assert_equal({ "status" => "checked" }, after.dig("extension_data", REVIEW, "payload"))
    assert_equal before.fetch("values"), after.fetch("values")
    @model.undo
    assert_equal before.slice("user_data", "extension_data"), zone.slice("user_data", "extension_data")
  end

  def test_a_face_and_a_unit_update_through_their_owners
    face_before = face
    assert_equal "committed", update("#{ZONES}.faces.update_metadata", face_before.fetch("reference"), face_before,
                                     :user_data => { "firm" => { "tag" => "F1" } }).fetch("effect")
    assert_equal({ "firm" => { "tag" => "F1" } }, face.fetch("user_data"))
    assert_equal face_before.fetch("values"), face.fetch("values")
    unit_before = unit
    result = update("#{WINDOWS}.units.update_metadata", unit_before.fetch("reference"), unit_before,
                    :user_data => { "firm" => { "tag" => "W1" } })
    assert_equal "committed", result.fetch("effect"), result.inspect
    assert_equal({ "firm" => { "tag" => "W1" } }, unit.fetch("user_data"))
    assert_equal unit_before.fetch("values"), unit.fetch("values")
  end

  def test_refusals_write_nothing
    read = zone
    reference = read.fetch("reference")
    cases = {
      "validation.failed" => { :extension_payloads => { REVIEW => { "status" => "unknown" } } },
      "extension.unavailable" => { :extension_payloads => { "absent.extension" => {} } },
      "reference.invalid" => { :extension_payloads => { REVIEW => { "status" => "draft", "zone" => "zon_missing" } } }
    }
    cases.each do |code, fields|
      result = update("#{ZONES}.update_metadata", reference, read, **fields)
      assert_equal code, result.fetch("code"), "#{code}: #{result.inspect}"
      assert_equal read.slice("user_data", "extension_data"), zone.slice("user_data", "extension_data")
    end
    stale = update("#{ZONES}.update_metadata", reference, read.merge("user_data" => { "old" => true }),
                   :user_data => { "new" => true })
    assert_equal "target.changed", stale.fetch("code")
    [%w[outdated 1 extension.migration_required], %w[newer 3 extension.schema_unsupported]].each do |_, version, code|
      record = PhComposer::Zones::ZONE_STORE.read(@group)
      record["extension_data"] = { REVIEW => envelope(version.to_i, { "status" => "draft" }) }
      PhComposer::Zones::ZONE_STORE.write(@group, record)
      current = zone
      result = update("#{ZONES}.update_metadata", reference, current,
                      :extension_payloads => { REVIEW => { "status" => "checked" } })
      assert_equal code, result.fetch("code"), result.inspect
    end
  end

  def test_a_batch_collapses_repeats_refuses_conflicts_and_writes_nothing_for_a_no_op
    read = zone
    entry = { "reference" => read.fetch("reference"), "user_data" => { "a" => 1 },
              "expected_metadata" => EMPTY }
    conflicting = entry.merge("user_data" => { "a" => 2 })
    assert_equal "params.invalid", assignment_invoke("#{ZONES}.update_metadata",
                                                     "updates" => [entry, conflicting]).fetch("code")
    assert_equal "params.invalid", assignment_invoke("#{ZONES}.update_metadata",
                                                     "updates" => [entry.reject { |key, _| key == "user_data" }])
      .fetch("code")
    assert_equal "committed", assignment_invoke("#{ZONES}.update_metadata", "updates" => [entry, entry])
      .fetch("effect")
    revision = @session.revision
    again = { "reference" => read.fetch("reference"), "user_data" => { "a" => 1 },
              "expected_metadata" => { "user_data" => { "a" => 1 }, "extension_data" => {} } }
    result = assignment_invoke("#{ZONES}.update_metadata", "updates" => [again])
    assert_equal "none", result.fetch("effect"), "writing what is stored opens no step"
    assert_equal revision, @session.revision
  end

  def test_a_face_in_a_locked_zone_and_an_unrecorded_face_refuse_and_an_ordinary_edit_keeps_metadata
    read = zone
    update("#{ZONES}.update_metadata", read.fetch("reference"), read, :user_data => { "keep" => true })
    edited = zone
    assignment_invoke("#{ZONES}.update", "reference" => edited.fetch("reference"),
                                         "values" => edited.fetch("values").merge("name" => "Renamed"),
                                         "expected_values" => edited.fetch("values"))
    assert_equal({ "keep" => true }, zone.fetch("user_data"))
    # Each owner's resolver decides: a Face inside a locked Zone is not writable.
    @group.locked = true
    locked = update("#{ZONES}.faces.update_metadata", face.fetch("reference"), face, :user_data => {})
    assert_equal "target.locked", locked.fetch("code")
    @group.locked = false
    unrecorded = face.fetch("reference").merge("entity_id" => "fac_Zz99Zz99Zz99")
    result = update("#{ZONES}.faces.update_metadata", unrecorded, face, :user_data => {})
    assert_includes %w[target.changed target.not_found], result.fetch("code"), result.inspect
  end

  def test_the_unit_action_repairs_a_copied_unit_first
    original = PhComposer::Windows::Units::Occurrences.all(@model).first
    copy = @group.entities.add_instance(original.entity.definition,
                                        Geom::Transformation.translation([200, 0, 0]) * original.entity.transformation)
    copy.glued_to = original.entity.glued_to
    PhComposer::Windows::Units.write(copy, original.record)
    read = unit
    result = update("#{WINDOWS}.units.update_metadata", read.fetch("reference"), read, :user_data => { "x" => 1 })
    assert_equal "committed", result.fetch("effect"), result.inspect
    ids = PhComposer::Windows::Units::Occurrences.all(@model).map { |item| item.record.fetch("id") }
    assert_equal 2, ids.uniq.length, "the copy got its own identity in the same step"
  end
end
