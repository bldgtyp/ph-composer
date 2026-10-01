# frozen_string_literal: true

require_relative "test_helper"

class ZoneSettingsTest < PhComposerTestCase
  SETTINGS = PhComposer::Zones::Faces::Settings

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = PhComposer::API.connect(:session_id => @session.id)
    @sequence = 0
  end

  def test_defaults_are_read_without_writing_or_advancing_revision
    before = @session.revision

    assert_equal SETTINGS::DEFAULTS, read.fetch("value")
    assert_nil SETTINGS::STORE.read(@model)
    assert_equal before, @session.revision
  end

  def test_settings_are_per_model_and_undo_redo_preserve_the_values
    values = SETTINGS::DEFAULTS.merge("suggest_on_make" => false, "roof_angle_deg" => 45.0)

    assert_equal "committed", update(values).fetch("effect")
    assert_equal values, read.fetch("value")
    assert_equal SETTINGS::DEFAULTS, SETTINGS.read(Sketchup::Model.new)
    @model.undo
    assert_equal SETTINGS::DEFAULTS, read.fetch("value")
    @model.redo
    assert_equal values, read.fetch("value")
  end

  def test_unchanged_settings_do_not_open_an_operation
    assert_equal "none", update(SETTINGS::DEFAULTS).fetch("effect")
    assert_nil SETTINGS::STORE.read(@model)
  end

  def test_invalid_and_crossed_thresholds_refuse_without_write
    [
      SETTINGS::DEFAULTS.merge("roof_angle_deg" => -1),
      SETTINGS::DEFAULTS.merge("floor_angle_deg" => 181),
      SETTINGS::DEFAULTS.merge("roof_angle_deg" => 130),
      SETTINGS::DEFAULTS.merge("suggest_on_make" => "yes")
    ].each do |values|
      result = update(values)
      assert_equal "refused", result.fetch("status")
      assert_equal "none", result.fetch("effect")
      assert_nil SETTINGS::STORE.read(@model)
    end
  end

  def test_current_revision_with_old_expected_settings_refuses
    values = SETTINGS::DEFAULTS.merge("suggest_on_make" => false)
    update(values)

    result = update(SETTINGS::DEFAULTS, SETTINGS::DEFAULTS)

    assert_equal "target.changed", result.fetch("code")
    assert_equal values, read.fetch("value")
  end

  def test_settings_survive_save_and_reopen
    values = SETTINGS::DEFAULTS.merge("roof_angle_deg" => 40.0, "floor_angle_deg" => 140.0)
    update(values)
    @model.save("/tmp/ph-composer-settings.skp")
    Sketchup.open_file("/tmp/ph-composer-settings.skp")

    assert_equal values, SETTINGS.read(Sketchup.active_model)
  end

  def test_make_suggests_by_default_and_one_undo_removes_both_zone_and_face_records
    group = make_fixture

    result = make(group)

    assert_equal "committed", result.fetch("effect")
    assert PhComposer::Zones::ZONE_STORE.read(group)
    assert PhComposer::Zones::Faces::FACE_STORE.read(group.entities.to_a.first)
    @model.undo
    current = @model.entities.to_a.first
    assert_nil PhComposer::Zones::ZONE_STORE.read(current)
    assert_nil PhComposer::Zones::Faces::FACE_STORE.read(current.entities.to_a.first)
    @model.redo
    current = @model.entities.to_a.first
    assert PhComposer::Zones::ZONE_STORE.read(current)
    assert PhComposer::Zones::Faces::FACE_STORE.read(current.entities.to_a.first)
  end

  def test_make_with_suggestions_disabled_leaves_faces_for_hand_entry
    update(SETTINGS::DEFAULTS.merge("suggest_on_make" => false))
    group = make_fixture

    assert_equal "completed", make(group).fetch("status")
    assert_nil PhComposer::Zones::Faces::FACE_STORE.read(group.entities.to_a.first)
  end

  def test_model_thresholds_change_read_suggestions_and_make_classification
    update(SETTINGS::DEFAULTS.merge("roof_angle_deg" => 30.0))
    angle = 45.0 * Math::PI / 180.0
    face = Sketchup::Face.new(111, {}, :normal => Geom::Vector3d.new(Math.sin(angle), 0, Math.cos(angle)))
    group = Sketchup::Group.new(110, Sketchup::Entities.new([face]))
    @model.entities << group

    assert_equal "completed", make(group).fetch("status")
    assert_equal "Wall", PhComposer::Zones::Faces::FACE_STORE.read(face).fetch("face_type")
    rows = PhComposer::API.query(:context => @context, :name => "ph_composer.zones.faces.list")
    assert_equal "Wall", rows.dig("value", "faces", 0, "suggested", "face_type")
  end

  def test_suggestion_write_failure_rolls_back_make_as_well
    group = make_fixture
    store = PhComposer::Zones::Faces::FACE_STORE
    result = store.stub(:write, ->(*_args) { raise PhComposer::InternalError, "synthetic Face write fault" }) do
      make(group)
    end

    assert_equal "rolled_back", result.fetch("effect")
    current = @model.entities.to_a.first
    assert_nil PhComposer::Zones::ZONE_STORE.read(current)
    assert_nil PhComposer::Zones::Faces::FACE_STORE.read(current.entities.to_a.first)
  end

  private

  def make_fixture
    group = Sketchup::Group.new(100, Sketchup::Entities.new([Sketchup::Face.new(101)]))
    @model.entities << group
    group
  end

  def make(group)
    @sequence += 1
    PhComposer::API.invoke(:context => @context, :name => "ph_composer.zones.make",
                           :params => { "parent_path" => [], "entity_ids" => [group.persistent_id] },
                           :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end

  def read
    PhComposer::API.query(:context => @context, :name => "ph_composer.zones.settings.get")
  end

  def update(values, expected = SETTINGS.read(@model))
    @sequence += 1
    PhComposer::API.invoke(:context => @context, :name => "ph_composer.zones.settings.update",
                           :params => { "values" => values, "expected_values" => expected },
                           :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end
end
