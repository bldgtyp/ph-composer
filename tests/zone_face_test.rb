# frozen_string_literal: true

require_relative "test_helper"

class ZoneFaceTest < PhComposerTestCase
  API = PhComposer::API

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
  end

  def test_panel_closed_make_zone_classify_read_back_undo_redo_and_reopen
    group = box_group(100)
    @model.entities << group
    @model.selection.add(group)

    overview = query("ph_composer.zones.list").fetch("value")
    preview = API.preview(:context => @context, :name => "ph_composer.zones.make",
                          :params => overview.fetch("make_zone"))
    made = invoke("ph_composer.zones.make", overview.fetch("make_zone"), preview.fetch("proposal_digest"))

    assert_equal %w[completed committed], made.values_at("status", "effect")
    assert_equal "grouped", made.dig("affected", 0, "change")
    zone = query("ph_composer.zones.list").dig("value", "zones", 0)
    assert_equal [100], zone.dig("reference", "zone_path")
    assert_equal "Zone 1", zone.dig("values", "name")

    faces = query("ph_composer.face_assignment.list").dig("value", "faces")
    assert_equal 6, faces.length
    first = faces.first
    classified = invoke("ph_composer.face_assignment.classify", {
      "faces" => [first.fetch("reference")],
      "intent" => {
        "face_type" => { "mode" => "set", "value" => "Wall" },
        "boundary_condition" => { "mode" => "set", "value" => "Outdoors" }
      },
      "expected_values" => {}
    })
    assert_equal %w[completed committed], classified.values_at("status", "effect")
    face_id = classified.dig("value", "face_ids", 0)
    read_back = query("ph_composer.face_assignment.list").dig("value", "faces")
      .find { |face| face.dig("reference", "entity_id") == face_id }
    assert_equal({ "face_type" => "Wall", "boundary_condition" => "Outdoors" }, read_back.fetch("values"))

    @model.undo
    current_group = @model.entities.to_a.find { |entity| entity.persistent_id == group.persistent_id }
    assert_nil PhComposer::FaceAssignment::FACE_STORE.read(current_group.entities.to_a.first)
    @model.redo
    current_group = @model.entities.to_a.find { |entity| entity.persistent_id == group.persistent_id }
    assert_equal face_id, PhComposer::FaceAssignment::FACE_STORE.read(current_group.entities.to_a.first).fetch("id")

    @model.save("/tmp/ph-composer-p1b.skp")
    Sketchup.open_file("/tmp/ph-composer-p1b.skp")
    reopened = PhComposer::Sessions.for(Sketchup.active_model)
    reopened_context = API.connect(:session_id => reopened.id)
    result = API.query(:context => reopened_context, :name => "ph_composer.face_assignment.list")
    assert_equal face_id, result.dig("value", "faces", 0, "reference", "entity_id")
  end

  def test_make_zone_groups_loose_geometry_and_preserves_unrelated_dictionaries
    face = Sketchup::Face.new(201, { "other.extension" => { "payload" => "kept" } })
    edge = Sketchup::Edge.new(202, Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(1, 0, 0))
    @model.entities << face << edge
    params = { "parent_path" => [], "entity_ids" => [201, 202], "name" => "Workshop" }

    made = invoke("ph_composer.zones.make", params)

    assert_equal "completed", made.fetch("status")
    group = @model.entities.to_a.find { |entity| entity.is_a?(Sketchup::Group) }
    assert_equal "Workshop", group.name
    assert_equal "kept", face.get_attribute("other.extension", "payload")
    assert_equal [face, edge], group.entities.to_a
  end

  def test_zone_update_preserves_metadata_and_updates_face_stamps
    group = box_group(300)
    @model.entities << group
    zone = make_group_zone(group)
    face = query("ph_composer.face_assignment.list").dig("value", "faces", 0)
    invoke("ph_composer.face_assignment.classify", classify_params(face, "Wall", "Ground"))
    stored = PhComposer::Zones::ZONE_STORE.read(group)
    stored["user_data"] = { "firm.note" => "keep" }
    PhComposer::Zones::ZONE_STORE.write(group, stored)
    before = zone.fetch("values")
    after = before.merge("name" => "North Zone", "building_segment" => "House", "level" => "L1",
                         "ground_depth_mm" => 250.0)

    result = invoke("ph_composer.zones.update", {
      "reference" => zone.fetch("reference"), "values" => after, "expected_values" => before
    })

    assert_equal "completed", result.fetch("status")
    assert_equal({ "firm.note" => "keep" }, PhComposer::Zones::ZONE_STORE.read(group).fetch("user_data"))
    stamp = PhComposer::Zones::STAMP_STORE.read(group.entities.to_a.first)
    assert_equal ["House", "L1"], stamp.values_at("building_segment", "level")
  end

  def test_existing_zone_selection_is_not_offered_as_a_make_target
    group = box_group(350)
    @model.entities << group
    make_group_zone(group)
    @model.selection.add(group)

    assert_nil query("ph_composer.zones.list").dig("value", "make_zone")
  end

  def test_copied_zone_identity_is_reported_ambiguous_and_refuses_mutation
    first = box_group(400)
    second = box_group(500)
    @model.entities << first << second
    zone = make_group_zone(first)
    PhComposer::Zones::ZONE_STORE.write(second, PhComposer::Zones::ZONE_STORE.read(first))

    rows = query("ph_composer.zones.list").dig("value", "zones")
    assert_equal %w[ambiguous ambiguous], rows.map { |row| row.fetch("state") }
    result = invoke("ph_composer.zones.update", {
      "reference" => zone.fetch("reference"), "values" => zone.fetch("values"),
      "expected_values" => zone.fetch("values")
    })
    assert_equal %w[refused target.ambiguous none], result.values_at("status", "code", "effect")
  end

  def test_nested_zone_is_reported_and_refuses_mutation
    inner = box_group(550)
    outer = Sketchup::Group.new(540, Sketchup::Entities.new([inner]))
    @model.entities << outer
    outer_record = zone_record("zon_AAAAAAAAAAAA", "Outer")
    inner_record = zone_record("zon_BBBBBBBBBBBB", "Inner")
    PhComposer::Zones::ZONE_STORE.write(outer, outer_record)
    PhComposer::Zones::ZONE_STORE.write(inner, inner_record)

    rows = query("ph_composer.zones.list").dig("value", "zones")
    nested = rows.find { |row| row.fetch("id") == inner_record.fetch("id") }
    assert_equal "wrong_hierarchy", nested.fetch("state")
    result = invoke("ph_composer.zones.update", {
      "reference" => nested.fetch("reference"), "values" => nested.fetch("values"),
      "expected_values" => nested.fetch("values")
    })
    assert_equal %w[refused target.wrong_hierarchy none], result.values_at("status", "code", "effect")
  end

  def test_classification_uses_explicit_keep_set_clear_and_preserves_metadata
    group = box_group(600)
    @model.entities << group
    make_group_zone(group)
    face = query("ph_composer.face_assignment.list").dig("value", "faces", 0)
    invoke("ph_composer.face_assignment.classify", classify_params(face, "Wall", "Outdoors"))
    entity = group.entities.to_a.first
    record = PhComposer::FaceAssignment::FACE_STORE.read(entity)
    record["user_data"] = { "firm.note" => "keep" }
    record["extension_data"] = { "outside.extension" => { "schema_version" => 3, "payload" => { "x" => 1 } } }
    PhComposer::FaceAssignment::FACE_STORE.write(entity, record)
    current = query("ph_composer.face_assignment.list").dig("value", "faces", 0)

    result = invoke("ph_composer.face_assignment.classify", {
      "faces" => [current.fetch("reference")],
      "intent" => {
        "face_type" => { "mode" => "keep" },
        "boundary_condition" => { "mode" => "set", "value" => "Adiabatic" }
      },
      "expected_values" => current.fetch("values")
    })

    assert_equal "completed", result.fetch("status")
    stored = PhComposer::FaceAssignment::FACE_STORE.read(entity)
    assert_equal ["Wall", "Adiabatic"], stored.values_at("face_type", "boundary_condition")
    assert_equal({ "firm.note" => "keep" }, stored.fetch("user_data"))
    assert_equal 3, stored.dig("extension_data", "outside.extension", "schema_version")
  end

  def test_keep_intent_on_an_unassigned_face_is_a_no_op
    group = box_group(650)
    @model.entities << group
    make_group_zone(group)
    face = query("ph_composer.face_assignment.list").dig("value", "faces", 0)

    result = invoke("ph_composer.face_assignment.classify", {
      "faces" => [face.fetch("reference")],
      "intent" => {
        "face_type" => { "mode" => "keep" },
        "boundary_condition" => { "mode" => "keep" }
      },
      "expected_values" => {}
    })

    entity = group.entities.to_a.first
    assert_equal %w[completed none], result.values_at("status", "effect")
    assert_nil PhComposer::FaceAssignment::FACE_STORE.read(entity)
    assert_nil PhComposer::Zones::STAMP_STORE.read(entity)
  end

  def test_suggestions_use_world_normal_and_zone_ground_depth_without_writing
    face = Sketchup::Face.new(701, {}, :points => [point(0, 0, 0), point(2, 0, 0), point(2, 2, 0)],
                                      :normal => Geom::Vector3d.new(0, 0, 1))
    group = Sketchup::Group.new(700, Sketchup::Entities.new([face]), {},
                                :transformation => Geom::Transformation.translation([0, 0, 20]))
    @model.entities << group
    make_group_zone(group)
    dictionaries = face.attribute_dictionaries

    row = query("ph_composer.face_assignment.list").dig("value", "faces", 0)

    assert_equal({ "face_type" => "RoofCeiling", "boundary_condition" => "Outdoors" }, row.fetch("suggested"))
    assert_same dictionaries, face.attribute_dictionaries
    assert_nil PhComposer::FaceAssignment::FACE_STORE.read(face)
  end

  private

  def invoke(name, params, proposal_digest = nil)
    @sequence += 1
    request = { "sequence" => @sequence, "expected_revision" => @session.revision }
    request["proposal_digest"] = proposal_digest if proposal_digest
    API.invoke(:context => @context, :name => name, :params => params, :request => request)
  end

  def query(name)
    API.query(:context => @context, :name => name)
  end

  def make_group_zone(group)
    @model.selection.clear
    @model.selection.add(group)
    invoke("ph_composer.zones.make", { "parent_path" => [], "entity_ids" => [group.persistent_id] })
    query("ph_composer.zones.list").dig("value", "zones").find do |zone|
      zone.dig("reference", "zone_path") == [group.persistent_id]
    end
  end

  def classify_params(face, type, boundary)
    {
      "faces" => [face.fetch("reference")],
      "intent" => {
        "face_type" => { "mode" => "set", "value" => type },
        "boundary_condition" => { "mode" => "set", "value" => boundary }
      },
      "expected_values" => face.fetch("values")
    }
  end

  def box_group(base)
    faces = 6.times.map do |index|
      Sketchup::Face.new(base + index + 1, {}, :points => [point(0, 0, index), point(2, 0, index),
                                                           point(2, 2, index)])
    end
    Sketchup::Group.new(base, Sketchup::Entities.new(faces))
  end

  def point(x, y, z)
    Geom::Point3d.new(x, y, z)
  end


  def zone_record(id, name)
    {
      "id" => id, "schema_version" => 1, "name" => name, "building_segment" => "Building",
      "level" => nil, "ground_depth_mm" => 0.0, "user_data" => {}, "extension_data" => {}
    }
  end
end
