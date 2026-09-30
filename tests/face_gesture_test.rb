# frozen_string_literal: true

require_relative "test_helper"

# P1-D gestures: one Classify covering many Faces, the named Suggest classification for a Zone, and
# the Reverse face repair. Each asserts the atomic boundary, not just the happy path.
class FaceGestureTest < PhComposerTestCase
  API = PhComposer::API
  LIMIT = PhComposer::Zones::Faces::GESTURE_FACE_LIMIT

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
  end

  def test_one_gesture_paints_every_face_and_reverts_in_one_undo
    make_box_zone(100, 6)
    faces = list_faces

    result = invoke("ph_composer.zones.faces.classify", gesture(faces, "Wall", "Outdoors"))

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_equal 6, result.dig("value", "face_ids").length
    assert_equal 6, list_faces.count { |face| face.dig("values", "boundary_condition") == "Outdoors" }

    @model.undo

    assert_empty list_faces.reject { |face| face.fetch("values").empty? }
  end

  def test_repeated_references_in_one_gesture_deduplicate_to_one_target
    make_box_zone(200, 3)
    face = list_faces.first
    params = gesture([face, face, face], "Wall", "Outdoors")

    result = invoke("ph_composer.zones.faces.classify", params)

    assert_equal 1, result.dig("value", "face_ids").length
    assert_equal 1, result.fetch("affected").length
  end

  def test_gesture_at_the_accepted_limit_commits_and_one_face_beyond_it_refuses_whole
    make_box_zone(1_000, LIMIT + 1)
    faces = list_faces

    accepted = invoke("ph_composer.zones.faces.classify", gesture(faces.first(LIMIT), "Wall", "Outdoors"))

    assert_equal "completed", accepted.fetch("status")
    assert_equal LIMIT, accepted.dig("value", "face_ids").length

    @model.undo
    refused = invoke("ph_composer.zones.faces.classify", gesture(faces, "Wall", "Outdoors"))

    assert_equal %w[refused gesture.too_large none], refused.values_at("status", "code", "effect")
    assert_empty list_faces.reject { |face| face.fetch("values").empty? }
  end

  # The ceiling counts the counterparts a gesture's retirements drag in, not just what the user
  # pointed at. Driven at a reduced bound: reaching 1,000 through real pairs needs a thousand-Face
  # model whose per-Face resolution makes the check take tens of seconds offline.
  def test_reciprocal_retirement_targets_count_towards_the_ceiling
    left = solved_pairs(900, 2).select { |face| face.dig("reference", "zone_path") == [900] }
    # Set after the fixture, so building it is not itself bounded by the reduced ceiling.
    PhComposer::Zones::Faces.gesture_face_limit = 3

    assert_equal 2, left.length

    accepted = invoke("ph_composer.zones.faces.classify", gesture(left.first(1), nil, "Ground"))

    assert_equal "completed", accepted.fetch("status")
    assert_equal 2, accepted.fetch("affected").length

    @model.undo
    refused = invoke("ph_composer.zones.faces.classify", gesture(left, nil, "Ground"))

    assert_equal %w[refused gesture.too_large none], refused.values_at("status", "code", "effect")
    assert_equal %w[Surface Surface Surface Surface], list_faces.map { |face| face.dig("values", "boundary_condition") }
  end

  def test_classifying_both_endpoints_of_one_pair_writes_each_face_once
    left, right = solved_pair(300)

    result = invoke("ph_composer.zones.faces.classify", gesture([left, right], nil, "Ground"))

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_equal 2, result.fetch("affected").length
    values = list_faces.map { |face| face.dig("values", "boundary_condition") }

    assert_equal %w[Ground Ground], values
    assert(list_faces.none? { |face| face.dig("values", "adjacency") })
  end

  def test_a_target_that_changed_after_preview_aborts_the_whole_gesture
    make_box_zone(400, 3)
    faces = list_faces
    preview = API.preview(:context => @context, :name => "ph_composer.zones.faces.classify",
                          :params => gesture(faces, "Wall", "Outdoors"))
    invoke("ph_composer.zones.faces.classify", gesture([faces.last], "Floor", "Ground"))

    result = invoke("ph_composer.zones.faces.classify", gesture(faces, "Wall", "Outdoors"),
                    preview.fetch("proposal_digest"))

    assert_equal "refused", result.fetch("status")
    assert_equal({ "face_type" => "Floor", "boundary_condition" => "Ground" }, list_faces.last.fetch("values"))
    assert(list_faces.first(2).all? { |face| face.fetch("values").empty? })
  end

  def test_a_host_failure_after_the_first_face_rolls_the_whole_gesture_back
    make_box_zone(800, 3)
    faces = list_faces
    group = @model.entities.to_a.find { |entity| entity.persistent_id == 800 }
    group.entities.to_a.last.define_singleton_method(:set_attribute) do |dictionary, key, value|
      raise "the host refused the write" if dictionary == PhComposer::Zones::Faces::FACE_DICTIONARY

      super(dictionary, key, value)
    end

    result = invoke("ph_composer.zones.faces.classify", gesture(faces, "Wall", "Outdoors"))

    assert_equal %w[failed operation.failed rolled_back], result.values_at("status", "code", "effect")
    assert_empty list_faces.reject { |face| face.fetch("values").empty? }
  end

  def test_suggest_classification_writes_only_unrecorded_faces_in_one_step
    zone = make_box_zone(500, 4)
    first = list_faces.first
    invoke("ph_composer.zones.faces.classify", gesture([first], "Floor", "Ground"))

    result = invoke("ph_composer.zones.faces.auto_classify", { "zone" => zone.fetch("reference") })

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_equal({ "classified" => 3, "kept" => 1 }, result.fetch("value"))
    assert_equal({ "face_type" => "Floor", "boundary_condition" => "Ground" }, list_faces.first.fetch("values"))
    assert(list_faces.drop(1).all? { |face| face.dig("values", "face_type") == "RoofCeiling" })

    @model.undo

    assert_equal 1, list_faces.count { |face| !face.fetch("values").empty? }
  end

  def test_suggest_classification_on_a_fully_recorded_zone_writes_nothing
    zone = make_box_zone(600, 2)
    invoke("ph_composer.zones.faces.classify", gesture(list_faces, "Wall", "Outdoors"))

    result = invoke("ph_composer.zones.faces.auto_classify", { "zone" => zone.fetch("reference") })

    assert_equal "none", result.fetch("effect")
    assert_equal({ "classified" => 0, "kept" => 2 }, result.fetch("value"))
  end

  def test_reverse_face_keeps_the_record_and_leaves_the_pair_stale
    left, = solved_pair(700)

    result = invoke("ph_composer.zones.faces.reverse", { "face" => left.fetch("reference") })

    assert_equal %w[completed committed], result.values_at("status", "effect")
    reversed = list_faces.find { |face| face.dig("reference", "entity_id") == left.dig("reference", "entity_id") }

    assert_equal "Surface", reversed.dig("values", "boundary_condition")
    assert_equal "stale", reversed.fetch("adjacency_state")
  end

  private

  def invoke(name, params, proposal_digest = nil)
    @sequence += 1
    request = { "sequence" => @sequence, "expected_revision" => @session.revision }
    request["proposal_digest"] = proposal_digest if proposal_digest
    API.invoke(:context => @context, :name => name, :params => params, :request => request)
  end

  def list_faces
    API.query(:context => @context, :name => "ph_composer.zones.faces.list").dig("value", "faces")
  end

  def gesture(faces, face_type, boundary)
    intent = {}
    intent["face_type"] = { "mode" => "set", "value" => face_type } if face_type
    intent["boundary_condition"] = { "mode" => "set", "value" => boundary } if boundary
    { "faces" => faces.map { |face| face.fetch("reference") }, "intent" => intent, "expected_values" => {} }
  end

  def make_box_zone(base, face_count)
    faces = face_count.times.map do |index|
      Sketchup::Face.new(base + index + 1, {}, :points => [point(0, 0, index), point(2, 0, index),
                                                           point(2, 2, index)])
    end
    group = Sketchup::Group.new(base, Sketchup::Entities.new(faces))
    @model.entities << group
    invoke("ph_composer.zones.make", { "parent_path" => [], "entity_ids" => [base] })
    API.query(:context => @context, :name => "ph_composer.zones.list").dig("value", "zones")
      .find { |zone| zone.dig("reference", "zone_path") == [base] }
  end

  # Two Zones sharing `count` full walls, classified and solved, so a gesture has real pairs to
  # retire. Each wall sits at its own height so one solve produces exactly `count` pairs.
  def solved_pairs(base, count)
    metres = 1.0 / 0.0254
    lefts = []
    rights = []
    count.times do |index|
      low = index * 5 * metres
      high = (index * 5 + 3) * metres
      outline = [point(0, 0, low), point(0, 4 * metres, low), point(0, 4 * metres, high), point(0, 0, high)]
      lefts << Sketchup::Face.new(base + 1 + index, {}, :points => outline,
                                  :normal => Geom::Vector3d.new(1, 0, 0))
      rights << Sketchup::Face.new(base + 101 + index, {}, :points => outline.reverse,
                                   :normal => Geom::Vector3d.new(-1, 0, 0))
    end
    [[base, lefts], [base + 10, rights]].each do |persistent_id, faces|
      @model.entities << Sketchup::Group.new(persistent_id, Sketchup::Entities.new(faces))
      invoke("ph_composer.zones.make", { "parent_path" => [], "entity_ids" => [persistent_id] })
    end
    invoke("ph_composer.zones.faces.classify", gesture(list_faces, "Wall", "Outdoors"))
    zones = API.query(:context => @context, :name => "ph_composer.zones.list").dig("value", "zones")
    invoke("ph_composer.zones.solve_adjacency", { "zones" => zones.map { |zone| zone.fetch("reference") } })
    list_faces
  end

  def solved_pair(base)
    solved_pairs(base, 1)
  end

  def point(x, y, z)
    Geom::Point3d.new(x, y, z)
  end
end
