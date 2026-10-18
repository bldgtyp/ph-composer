# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/space_fixtures"

# Faces a client can make into Floor Segments or new Volumes, found by a read rather than a private walk
# (context/AGENT_INTERFACE.md, "Focused reads"), and the typed values the Spaces edits take.
class SpacesCandidateFacesTest < PhComposerTestCase
  include SpaceFixtures

  API = PhComposer::API
  SPACE = { "space_id" => "spc_SSSSSSSSSSSS", "entity_path" => [1000, 1100] }.freeze
  VOLUME = { "volume_id" => "vol_VVVVVVVVVVVV", "entity_path" => [1000, 1100, 1110] }.freeze

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
    marked = floor_face(1111, rectangle(0, 0, 3, 4), segment_record("M"))
    @unmarked = floor_face(1112, rectangle(3, 0, 2, 2))
    @loose = floor_face(1120, rectangle(0, 4, 2, 2))
    volume = volume_group(1110, volume_record("V"), [marked, @unmarked])
    @space = space_group(1100, space_record("S", :number => "101"), [volume, @loose])
    @zone = zone_group(1000, "A", [@space])
    @model.entities << @zone
  end

  def test_a_space_lists_its_unmarked_volume_face_and_its_loose_face
    rows = candidates("space" => SPACE)

    assert_equal [[1000, 1100, 1110, 1112], [1000, 1100, 1120]], rows.map { |row| row["entity_path"] }
    assert_equal %w[floor volume], rows.map { |row| row["candidate"] }
    assert_equal %w[ph_composer.spaces.floors.mark ph_composer.spaces.volumes.create],
                 rows.map { |row| row["operation"] }
    assert_equal [nil, nil], rows.map { |row| row["refusal"] }
    assert_in_delta 4.0, rows.first["plan_area_m2"], 1e-9
    refute rows.first.key?("loops_m")
    assert_equal [[1000, 1100, 1110, 1112]], candidates("volume" => VOLUME).map { |row| row["entity_path"] }
  end

  def test_marking_the_candidate_removes_it_and_unmarking_brings_it_back
    path = candidates("volume" => VOLUME).first.fetch("entity_path")
    marked = invoke("ph_composer.spaces.floors.mark", "faces" => [path], "weighting_factor" => 1.0)
    segment = { "floor_segment_id" => marked.dig("value", "floor_segment_ids", 0), "entity_path" => path }

    assert_equal "committed", marked["effect"]
    assert_empty candidates("volume" => VOLUME)
    invoke("ph_composer.spaces.floors.unmark", "floor_segments" => [segment])
    assert_equal [path], candidates("volume" => VOLUME).map { |row| row["entity_path"] }
  end

  def test_the_loose_face_becomes_a_new_volume_once_the_space_is_open
    loose = candidates("space" => SPACE).last
    @model.active_path = [@zone, @space]

    created = invoke(loose["operation"], "space" => SPACE, "faces" => [loose["entity_path"]])

    assert_equal "committed", created["effect"], created.inspect
    assert_equal ["floor"], candidates("space" => SPACE).map { |row| row["candidate"] }
  end

  def test_a_locked_space_refuses_as_its_action_would_and_reading_changes_nothing
    @space.locked = true
    before = [@model.active_path, @model.selection.to_a, @session.revision]

    rows = candidates("space" => SPACE)
    mark = invoke("ph_composer.spaces.floors.mark", "faces" => [rows.first["entity_path"]], "weighting_factor" => 1.0)

    assert_equal %w[target.locked target.locked], rows.map { |row| row.dig("refusal", "code") }
    assert_equal "target.locked", mark["code"]
    assert_equal before, [@model.active_path, @model.selection.to_a, @session.revision]
  end

  def test_a_face_in_a_volume_outside_every_space_refuses_as_floors_mark_does
    stray = volume_group(2110, volume_record("O"), [floor_face(2111, rectangle(10, 0, 2, 2))])
    @model.entities << zone_group(2000, "B", [stray])
    reference = { "volume_id" => "vol_OOOOOOOOOOOO", "entity_path" => [2000, 2110] }

    row = candidates("volume" => reference).first
    mark = invoke("ph_composer.spaces.floors.mark", "faces" => [row["entity_path"]], "weighting_factor" => 1.0)

    assert_equal ["target.wrong_hierarchy"] * 2, [row.dig("refusal", "code"), mark["code"]]
  end

  def test_a_scope_names_one_parent
    assert_equal "params.invalid", query({})["code"]
    assert_equal "target.changed", query("space" => SPACE.merge("space_id" => "spc_XXXXXXXXXXXX"))["code"]
  end

  def test_edits_are_typed_with_units_and_a_cross_kind_or_mistyped_value_refuses
    values = API.describe(:name => "ph_composer.spaces.update").dig("params", "properties", "values", "properties")
    volume = VOLUME

    assert_equal "m", values.dig("avg_ceiling_height_m", "x-unit")
    assert_equal %w[number null], values.dig("v_sup_m3h", "type")
    assert_equal "params.invalid", update(volume, { "weighting_factor" => 0.5 }, {})["code"]
    assert_equal "params.invalid", update(volume, { "avg_ceiling_height_m" => "tall" }, {})["code"]
    raised = update(volume, { "avg_ceiling_height_m" => 2.7 }, { "avg_ceiling_height_m" => 2.5 })
    assert_equal "committed", raised["effect"]
    cleared = update(volume, { "avg_ceiling_height_m" => nil }, { "avg_ceiling_height_m" => 2.7 })
    assert_equal "committed", cleared["effect"]
    refute PhComposer::Spaces::VOLUME_STORE.read(@space.entities.to_a.first).key?("avg_ceiling_height_m")
  end

  private

  def query(params)
    API.query(:context => @context, :name => "ph_composer.spaces.candidate_faces.list", :params => params)
  end

  def candidates(params)
    result = query(params)
    assert_equal "completed", result["status"], result.inspect
    result.dig("value", "candidate_faces")
  end

  def update(reference, values, expected)
    invoke("ph_composer.spaces.update", "reference" => reference, "values" => values, "expected_values" => expected)
  end

  def invoke(name, params)
    @sequence += 1
    API.invoke(:context => @context, :name => name, :params => params,
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end
end
