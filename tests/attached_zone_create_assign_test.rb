# frozen_string_literal: true

require_relative "test_helper"

class AttachedZoneCreateAssignTest < PhComposerTestCase
  API = PhComposer::API
  KIND = PhComposer::Zones::Faces::AttachedZone::KIND_ID
  ACTION = "#{KIND}.create_and_assign"
  FACE_STORE = PhComposer::Zones::Faces::FACE_STORE

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
    make_zone(100, 3)
  end

  def test_creates_one_record_and_assigns_multiple_faces_with_one_undo
    selected = faces.first(2)
    result = invoke(params(selected, :intent => { "face_type" => { "mode" => "set", "value" => "Wall" } },
                                     :user_data => { "firm.note" => "inspect garage" }))

    assert_equal %w[completed committed], result.values_at("status", "effect")
    id = result.dig("value", "id")
    assert_equal 2, result.dig("value", "face_ids").length
    assert_equal id, records.first.fetch("id")
    assert_equal({ "firm.note" => "inspect garage" }, records.first.fetch("user_data"))
    assert_in_delta 0.95, records.first.dig("values", "temperature_reduction_factor")
    assert_equal [id, id], faces.first(2).map { |face| face.dig("values", "attached_zone_id") }
    assert_equal %w[Wall Wall], faces.first(2).map { |face| face.dig("values", "face_type") }
    assert_equal "resolved", faces.first.fetch("attached_zone_state")
    assert_empty faces.last.fetch("values")

    @model.undo

    assert_empty records
    assert faces.all? { |face| face.fetch("values").empty? }
    @model.redo
    assert_equal [id, id], faces.first(2).map { |face| face.dig("values", "attached_zone_id") }
  end

  def test_existing_face_identity_type_and_metadata_survive
    first = faces.first
    classified = invoke_named("ph_composer.zones.faces.classify", {
      "faces" => [first.fetch("reference")],
      "intent" => { "face_type" => { "mode" => "set", "value" => "Floor" },
                    "boundary_condition" => { "mode" => "set", "value" => "Ground" } }
    })
    assert_equal "completed", classified.fetch("status")
    entity = @model.entities.to_a.first.entities.to_a.first
    before = FACE_STORE.read(entity)
    before["user_data"] = { "firm.note" => "keep" }
    before["extension_data"] = { "example.extension" => { "schema_version" => 1, "payload" => { "x" => 7 } } }
    FACE_STORE.write(entity, before)
    current = faces.first

    result = invoke(params([current], :expected_values => current.fetch("values")))

    assert_equal "completed", result.fetch("status")
    after = FACE_STORE.read(entity)
    assert_equal before.fetch("id"), after.fetch("id")
    assert_equal "Floor", after.fetch("face_type")
    assert_equal before.fetch("user_data"), after.fetch("user_data")
    assert_equal before.fetch("extension_data"), after.fetch("extension_data")
    assert_equal "AttachedZone", after.fetch("boundary_condition")
    assert_equal result.dig("value", "id"), after.fetch("attached_zone_id")
  end

  def test_invalid_record_or_pending_face_proposal_refuses_before_writes
    invalid_record = invoke(params([faces.first], :values => { "name" => "Garage", "kind" => "unknown" }))
    assert_equal %w[refused validation.failed none], invalid_record.values_at("status", "code", "effect")

    invalid_face = invoke(params([faces.first], :intent => {
      "face_type" => { "mode" => "set", "value" => "AirBoundary" }
    }))
    assert_equal %w[refused params.invalid none], invalid_face.values_at("status", "code", "effect")
    assert_empty records
    assert faces.all? { |face| face.fetch("values").empty? }
  end

  def test_stale_face_value_refuses_whole_creation
    first = faces.first
    invoke_named("ph_composer.zones.faces.classify", {
      "faces" => [first.fetch("reference")],
      "intent" => { "face_type" => { "mode" => "set", "value" => "Floor" } }
    })

    result = invoke(params([faces.first, faces.last], :expected_values => { "face_type" => "Wall" }))

    assert_equal %w[refused target.changed none], result.values_at("status", "code", "effect")
    assert_empty records
    assert_equal "Floor", faces.first.dig("values", "face_type")
    assert_empty faces.last.fetch("values")
  end

  def test_preview_is_read_only_and_refuses_stale_digest
    selected = faces.first(2)
    proposal = API.preview(:context => @context, :name => ACTION, :params => params(selected))
    assert_equal "completed", proposal.fetch("status")
    assert_empty records
    assert faces.all? { |face| face.fetch("values").empty? }

    changed = invoke_named("ph_composer.zones.faces.classify", {
      "faces" => [selected.last.fetch("reference")],
      "intent" => { "face_type" => { "mode" => "set", "value" => "Floor" } }
    })
    assert_equal "completed", changed.fetch("status")
    result = invoke(params(selected), proposal.fetch("proposal_digest"))

    assert_equal "refused", result.fetch("status")
    assert_empty records
    assert_empty faces.first.fetch("values")
    assert_equal "Floor", faces[1].dig("values", "face_type")
  end

  def test_unchanged_preview_digest_commits_with_fresh_record_id
    planned = params([faces.first])
    preview = API.preview(:context => @context, :name => ACTION, :params => planned)

    result = invoke(planned, preview.fetch("proposal_digest"))

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_equal preview.fetch("proposal_digest"), result.fetch("proposal_digest")
    assert_equal result.dig("value", "id"), faces.first.dig("values", "attached_zone_id")
  end

  def test_second_face_host_failure_rolls_back_faces_and_record
    entity = @model.entities.to_a.first.entities.to_a[1]
    entity.define_singleton_method(:set_attribute) do |dictionary, key, value|
      raise "host refused second Face" if dictionary == PhComposer::Zones::Faces::FACE_DICTIONARY

      super(dictionary, key, value)
    end

    result = invoke(params(faces.first(2)))

    assert_equal %w[failed operation.failed rolled_back], result.values_at("status", "code", "effect")
    assert_empty records
    assert faces.all? { |face| face.fetch("values").empty? }
  end

  def test_surface_counterpart_is_retired_in_the_same_operation
    left, right = make_solved_pair
    before_id = right.dig("reference", "entity_id")

    result = invoke(params([left], :expected_values => left.fetch("values")))

    assert_equal %w[completed committed], result.values_at("status", "effect")
    paired = faces.select { |face| [left, right].map { |row| row.dig("reference", "entity_id") }
                                         .include?(face.dig("reference", "entity_id")) }
    attached = paired.find { |face| face.dig("values", "boundary_condition") == "AttachedZone" }
    counterpart = paired.find { |face| face.dig("reference", "entity_id") == before_id }
    assert_equal result.dig("value", "id"), attached.dig("values", "attached_zone_id")
    assert_nil counterpart.dig("values", "boundary_condition")
    assert_nil counterpart.dig("values", "adjacency")
    assert_equal "Wall", counterpart.dig("values", "face_type")

    @model.undo

    assert_empty records
    assert_equal %w[Surface Surface], faces.select { |face|
      [left, right].map { |row| row.dig("reference", "entity_id") }.include?(face.dig("reference", "entity_id"))
    }.map { |face| face.dig("values", "boundary_condition") }
  end

  def test_locked_target_refuses_before_writes
    @model.entities.to_a.first.locked = true

    result = invoke(params(faces.first(2)))

    assert_equal %w[refused target.locked none], result.values_at("status", "code", "effect")
    assert_empty records
    assert faces.all? { |face| face.fetch("values").empty? }
  end

  private

  def invoke(params, digest = nil)
    invoke_named(ACTION, params, digest)
  end

  def invoke_named(name, params, digest = nil)
    @sequence += 1
    request = { "sequence" => @sequence, "expected_revision" => @session.revision }
    request["proposal_digest"] = digest if digest
    API.invoke(:context => @context, :name => name, :params => params, :request => request)
  end

  def params(selected, values: { "name" => "Garage", "kind" => "garage" }, intent: nil,
             user_data: nil, expected_values: {})
    result = { "faces" => selected.map { |face| face.fetch("reference") }, "values" => values,
               "expected_values" => expected_values }
    result["intent"] = intent if intent
    result["user_data"] = user_data if user_data
    result
  end

  def records
    API.query(:context => @context, :name => "ph_composer.records.list", :params => { "kind" => KIND })
      .dig("value", "records")
  end

  def faces
    API.query(:context => @context, :name => "ph_composer.zones.faces.list").dig("value", "faces")
  end

  def make_zone(base, count)
    entities = count.times.map do |index|
      Sketchup::Face.new(base + index + 1, {},
                         :points => [Geom::Point3d.new(0, 0, index), Geom::Point3d.new(2, 0, index),
                                     Geom::Point3d.new(2, 2, index)])
    end
    @model.entities << Sketchup::Group.new(base, Sketchup::Entities.new(entities))
    invoke_named("ph_composer.zones.make", { "parent_path" => [], "entity_ids" => [base] })
  end

  def make_solved_pair
    metres = 1.0 / 0.0254
    outline = [Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(0, 4 * metres, 0),
               Geom::Point3d.new(0, 4 * metres, 3 * metres), Geom::Point3d.new(0, 0, 3 * metres)]
    left = Sketchup::Face.new(801, {}, :points => outline, :normal => Geom::Vector3d.new(1, 0, 0))
    right = Sketchup::Face.new(811, {}, :points => outline.reverse, :normal => Geom::Vector3d.new(-1, 0, 0))
    [[800, left], [810, right]].each do |id, face|
      @model.entities << Sketchup::Group.new(id, Sketchup::Entities.new([face]))
      invoke_named("ph_composer.zones.make", { "parent_path" => [], "entity_ids" => [id] })
    end
    pair = faces.select { |face| [800, 810].include?(face.dig("reference", "zone_path", 0)) }
    invoke_named("ph_composer.zones.faces.classify", {
      "faces" => pair.map { |face| face.fetch("reference") },
      "intent" => { "face_type" => { "mode" => "set", "value" => "Wall" },
                    "boundary_condition" => { "mode" => "set", "value" => "Outdoors" } }
    })
    zones = API.query(:context => @context, :name => "ph_composer.zones.list").dig("value", "zones")
    invoke_named("ph_composer.zones.solve_adjacency", {
      "zones" => zones.select { |zone| [800, 810].include?(zone.dig("reference", "zone_path", 0)) }
                     .map { |zone| zone.fetch("reference") }
    })
    paired = faces.select { |face| [800, 810].include?(face.dig("reference", "zone_path", 0)) }
    assert_equal %w[Surface Surface], paired.map { |face| face.dig("values", "boundary_condition") }
    paired
  end
end
