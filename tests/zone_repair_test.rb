# frozen_string_literal: true

require_relative "test_helper"

# P1-D D3: the two explicit Zone repairs. Identity repair gives a copied occurrence an identity of
# its own without touching the Zone it came from. Restore regroups an exploded Zone's stamped
# members and recovers only what a stamp can carry.
class ZoneRepairTest < PhComposerTestCase
  API = PhComposer::API
  ZONE_STORE = PhComposer::Zones::ZONE_STORE
  STAMP_STORE = PhComposer::Zones::STAMP_STORE
  FACE_STORE = PhComposer::FaceAssignment::FACE_STORE

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
  end

  def test_repair_gives_the_copy_a_new_identity_and_leaves_the_original_untouched
    original, copy = copied_zone
    before = ZONE_STORE.read(original)
    before_faces = original.entities.to_a.map { |face| FACE_STORE.read(face) }

    result = invoke("ph_composer.zones.repair_identity", { "zone_path" => [copy.persistent_id] })

    assert_equal %w[completed committed], result.values_at("status", "effect")
    repaired = ZONE_STORE.read(copy)

    refute_equal before.fetch("id"), repaired.fetch("id")
    assert_equal before.fetch("id"), ZONE_STORE.read(original).fetch("id")
    assert_equal before_faces, original.entities.to_a.map { |face| FACE_STORE.read(face) }
    assert_equal %w[found found], zone_states
  end

  def test_repair_gives_every_copied_face_a_new_id_and_rewrites_its_stamp
    original, copy = copied_zone
    original_ids = original.entities.to_a.map { |face| FACE_STORE.read(face).fetch("id") }

    invoke("ph_composer.zones.repair_identity", { "zone_path" => [copy.persistent_id] })

    repaired_id = ZONE_STORE.read(copy).fetch("id")
    copy.entities.to_a.each do |face|
      refute_includes original_ids, FACE_STORE.read(face).fetch("id")
      assert_equal repaired_id, STAMP_STORE.read(face).fetch("zone_id")
    end
  end

  def test_repair_preserves_face_payloads_and_discloses_copied_extension_data
    original, copy = copied_zone
    [original, copy].each do |group|
      face = group.entities.to_a.first
      record = FACE_STORE.read(face).merge("user_data" => { "firm.note" => "keep" },
                                           "extension_data" => { "other.ext" => { "payload" => 1 } })
      FACE_STORE.write(face, record)
    end

    result = invoke("ph_composer.zones.repair_identity", { "zone_path" => [copy.persistent_id] })

    repaired = FACE_STORE.read(copy.entities.to_a.first)

    assert_equal({ "firm.note" => "keep" }, repaired.fetch("user_data"))
    assert_equal({ "other.ext" => { "payload" => 1 } }, repaired.fetch("extension_data"))
    assert_equal ["zone.copied_extension_data"], result.fetch("findings").map { |row| row.fetch("code") }
  end

  def test_repair_retires_the_copied_pair_without_changing_the_original_pair
    left, right = solved_pair
    copy = duplicate_group(right, 900)

    result = invoke("ph_composer.zones.repair_identity", { "zone_path" => [copy.persistent_id] })

    assert_equal 1, result.dig("value", "retired_pairs")
    repaired_face = FACE_STORE.read(copy.entities.to_a.first)

    refute repaired_face.key?("adjacency")
    refute repaired_face.key?("boundary_condition")
    [left, right].each do |group|
      record = FACE_STORE.read(group.entities.to_a.first)

      assert_equal "Surface", record.fetch("boundary_condition")
      assert record.fetch("adjacency").fetch("pair_id")
    end
  end

  def test_repair_refuses_a_zone_whose_identity_is_already_unique
    group = box_group(100, 2)
    @model.entities << group
    make_zone(group)

    result = invoke("ph_composer.zones.repair_identity", { "zone_path" => [group.persistent_id] })

    assert_equal %w[refused zone.identity_unique none], result.values_at("status", "code", "effect")
  end

  def test_repair_refuses_a_copy_held_in_shared_component_storage
    group = box_group(200, 2)
    @model.entities << group
    make_zone(group)
    @model.entities.delete(group)
    definition = Sketchup::ComponentDefinition.new(Sketchup::Entities.new([group]), :name => "copied")
    instance = @model.entities.add_instance(definition, Geom::Transformation.new)
    @model.entities.add_instance(definition, Geom::Transformation.new)

    result = invoke("ph_composer.zones.repair_identity",
                    { "zone_path" => [instance.persistent_id, group.persistent_id] })

    assert_equal %w[refused target.shared_definition none], result.values_at("status", "code", "effect")
  end

  def test_an_exploded_zone_is_offered_for_restore_with_its_recoverable_fields
    group, zone_id = exploded_zone

    offer = restorable.first

    assert_equal zone_id, offer.fetch("zone_id")
    assert_equal 3, offer.fetch("member_count")
    assert_nil offer.fetch("refusal")
    assert_equal %w[extension_data ground_depth_mm name user_data], offer.fetch("unrecoverable").sort
    assert_equal [], offer.fetch("parent_path")
    refute_includes @model.entities.to_a, group
  end

  def test_restore_regroups_the_stamped_members_and_recovers_only_the_stamp
    _group, zone_id = exploded_zone

    result = invoke("ph_composer.zones.restore", { "parent_path" => [], "zone_id" => zone_id })

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_equal zone_id, result.dig("value", "zone_id")
    restored = @model.entities.to_a.find { |entity| entity.is_a?(Sketchup::Group) }
    record = ZONE_STORE.read(restored)

    assert_equal zone_id, record.fetch("id")
    assert_equal "Attic", record.fetch("building_segment")
    assert_equal "L2", record.fetch("level")
    # The name went with the Group. Restore takes a fresh default rather than claiming recovery.
    assert_equal "Zone 1", record.fetch("name")
    assert_equal 3, restored.entities.to_a.length
    assert_equal ["zone.restore_is_limited"], result.fetch("findings").map { |row| row.fetch("code") }
    assert_empty restorable
  end

  def test_restore_preserves_every_member_payload_and_reverts_in_one_undo
    _group, zone_id = exploded_zone
    face = @model.entities.to_a.find { |entity| entity.is_a?(Sketchup::Face) }
    FACE_STORE.write(face, FACE_STORE.read(face).merge("user_data" => { "firm.note" => "keep" }))

    invoke("ph_composer.zones.restore", { "parent_path" => [], "zone_id" => zone_id })

    restored = @model.entities.to_a.find { |entity| entity.is_a?(Sketchup::Group) }

    assert_equal({ "firm.note" => "keep" }, FACE_STORE.read(restored.entities.to_a.first).fetch("user_data"))

    @model.undo

    assert_empty @model.entities.to_a.select { |entity| entity.is_a?(Sketchup::Group) }
    assert_equal 3, @model.entities.to_a.count { |entity| entity.is_a?(Sketchup::Face) }
  end

  def test_restore_refuses_conflicting_stamps_and_writes_nothing
    _group, zone_id = exploded_zone
    face = @model.entities.to_a.find { |entity| entity.is_a?(Sketchup::Face) }
    STAMP_STORE.write(face, STAMP_STORE.read(face).merge("level" => "L9"))

    assert_equal "stamps_conflict", restorable.first.fetch("refusal")

    result = invoke("ph_composer.zones.restore", { "parent_path" => [], "zone_id" => zone_id })

    assert_equal %w[refused zone.restore_unsafe none], result.values_at("status", "code", "effect")
    assert_empty @model.entities.to_a.select { |entity| entity.is_a?(Sketchup::Group) }
  end

  def test_restore_refuses_stamped_members_spread_across_parent_contexts
    _group, zone_id = exploded_zone
    face = @model.entities.to_a.find { |entity| entity.is_a?(Sketchup::Face) }
    @model.entities.delete(face)
    @model.entities << Sketchup::Group.new(700, Sketchup::Entities.new([face]))

    assert_equal "mixed_context", restorable.first.fetch("refusal")

    result = invoke("ph_composer.zones.restore", { "parent_path" => [], "zone_id" => zone_id })

    assert_equal %w[refused zone.restore_unsafe none], result.values_at("status", "code", "effect")
  end

  def test_restore_refuses_when_a_bounding_edge_is_shared_with_unstamped_geometry
    _group, zone_id = exploded_zone
    stamped = @model.entities.to_a.select { |entity| entity.is_a?(Sketchup::Face) }
    shared = Sketchup::Edge.new(800, point(0, 0, 0), point(2, 0, 0))
    @model.entities << shared
    shared.attach_face(stamped.first)
    stamped.first.edges << shared
    # An unstamped Face on the same Edge: regrouping would drag it along.
    outsider = Sketchup::Face.new(801, {}, :points => [point(0, 0, 9), point(2, 0, 9), point(2, 2, 9)],
                                           :edges => [shared])
    @model.entities << outsider

    assert_equal "shared_edge", restorable.first.fetch("refusal")

    result = invoke("ph_composer.zones.restore", { "parent_path" => [], "zone_id" => zone_id })

    assert_equal %w[refused zone.restore_unsafe none], result.values_at("status", "code", "effect")
    assert_empty @model.entities.to_a.select { |entity| entity.is_a?(Sketchup::Group) }
  end

  def test_restore_accepts_an_edge_shared_only_between_stamped_members
    _group, zone_id = exploded_zone
    stamped = @model.entities.to_a.select { |entity| entity.is_a?(Sketchup::Face) }
    shared = Sketchup::Edge.new(810, point(0, 0, 0), point(2, 0, 0))
    @model.entities << shared
    stamped.first(2).each do |face|
      shared.attach_face(face)
      face.edges << shared
    end

    assert_nil restorable.first.fetch("refusal")
    assert_equal "completed", invoke("ph_composer.zones.restore",
                                     { "parent_path" => [], "zone_id" => zone_id }).fetch("status")
  end

  def test_the_restore_offer_reports_every_remembered_member_even_when_it_refuses
    _group, zone_id = exploded_zone
    face = @model.entities.to_a.find { |entity| entity.is_a?(Sketchup::Face) }
    @model.entities.delete(face)
    @model.entities << Sketchup::Group.new(710, Sketchup::Entities.new([face]))

    offer = restorable.first

    assert_equal "mixed_context", offer.fetch("refusal")
    assert_equal offer.fetch("member_count"), offer.fetch("entity_ids").length
    assert_equal zone_id, offer.fetch("zone_id")
  end

  def test_restore_refuses_a_zone_id_that_is_back_in_the_model
    _group, zone_id = exploded_zone
    invoke("ph_composer.zones.restore", { "parent_path" => [], "zone_id" => zone_id })

    result = invoke("ph_composer.zones.restore", { "parent_path" => [], "zone_id" => zone_id })

    assert_equal %w[refused zone.identity_in_use none], result.values_at("status", "code", "effect")
  end

  private

  def invoke(name, params)
    @sequence += 1
    API.invoke(:context => @context, :name => name, :params => params,
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end

  def zones_value
    API.query(:context => @context, :name => "ph_composer.zones.list").fetch("value")
  end

  def zone_states
    zones_value.fetch("zones").map { |zone| zone.fetch("state") }
  end

  def restorable
    zones_value.fetch("restorable")
  end

  def make_zone(group)
    invoke("ph_composer.zones.make", { "parent_path" => [], "entity_ids" => [group.persistent_id] })
  end

  def classify_all
    faces = API.query(:context => @context, :name => "ph_composer.face_assignment.list").dig("value", "faces")
    invoke("ph_composer.face_assignment.classify", {
      "faces" => faces.map { |face| face.fetch("reference") },
      "intent" => { "face_type" => { "mode" => "set", "value" => "Wall" },
                    "boundary_condition" => { "mode" => "set", "value" => "Outdoors" } },
      "expected_values" => {}
    })
  end

  # A Zone with classified Faces, copied the way SketchUp copies one: every dictionary duplicated.
  def copied_zone
    original = box_group(300, 3)
    @model.entities << original
    make_zone(original)
    classify_all
    [original, duplicate_group(original, 400)]
  end

  def duplicate_group(group, base)
    faces = group.entities.to_a.each_with_index.map do |face, index|
      copy = Sketchup::Face.new(base + index + 1, {}, :points => face.outer_loop.vertices.map(&:position),
                                                      :normal => face.normal)
      %w[ph_composer.face_assignment ph_composer.zone_stamp].each do |dictionary|
        value = face.get_attribute(dictionary, "record")
        copy.set_attribute(dictionary, "record", value) if value
      end
      copy
    end
    copy = Sketchup::Group.new(base, Sketchup::Entities.new(faces))
    copy.set_attribute("ph_composer.zone", "record", group.get_attribute("ph_composer.zone", "record"))
    @model.entities << copy
    copy
  end

  def solved_pair
    metres = 1.0 / 0.0254
    outline = [point(0, 0, 0), point(0, 4 * metres, 0), point(0, 4 * metres, 3 * metres), point(0, 0, 3 * metres)]
    left = Sketchup::Face.new(501, {}, :points => outline, :normal => Geom::Vector3d.new(1, 0, 0))
    right = Sketchup::Face.new(502, {}, :points => outline.reverse, :normal => Geom::Vector3d.new(-1, 0, 0))
    groups = [Sketchup::Group.new(500, Sketchup::Entities.new([left])),
              Sketchup::Group.new(510, Sketchup::Entities.new([right]))]
    groups.each do |group|
      @model.entities << group
      make_zone(group)
    end
    classify_all
    references = zones_value.fetch("zones").map { |zone| zone.fetch("reference") }
    invoke("ph_composer.zones.solve_adjacency", { "zones" => references })
    groups
  end

  # Explode: the Group goes, its stamped Faces stay in the parent context with their payloads.
  def exploded_zone
    group = box_group(600, 3)
    @model.entities << group
    make_zone(group)
    invoke("ph_composer.zones.update", {
      "reference" => zones_value.dig("zones", 0, "reference"),
      "values" => { "name" => "Loft", "building_segment" => "Attic", "level" => "L2",
                    "ground_depth_mm" => 0.0 },
      "expected_values" => zones_value.dig("zones", 0, "values")
    })
    classify_all
    zone_id = ZONE_STORE.read(group).fetch("id")
    members = group.entities.to_a
    @model.entities.delete(group)
    members.each { |face| @model.entities << face }
    [group, zone_id]
  end

  def box_group(base, face_count)
    faces = face_count.times.map do |index|
      Sketchup::Face.new(base + index + 1, {}, :points => [point(0, 0, index), point(2, 0, index),
                                                           point(2, 2, index)])
    end
    Sketchup::Group.new(base, Sketchup::Entities.new(faces))
  end

  def point(x, y, z)
    Geom::Point3d.new(x, y, z)
  end
end
