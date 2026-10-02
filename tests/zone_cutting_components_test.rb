# frozen_string_literal: true

require_relative "test_helper"

class ZoneCuttingComponentsTest < PhComposerTestCase
  API = PhComposer::API
  Zones = PhComposer::Zones

  def setup
    super
    @model = Sketchup.active_model
    settings = Zones::Faces::Settings
    settings::STORE.write(@model, settings::DEFAULTS.merge("suggest_on_make" => false))
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
  end

  def fixture
    @wall = Sketchup::Face.new(101)
    @pane = Sketchup::Face.new(301)
    @definition = Sketchup::ComponentDefinition.new(Sketchup::Entities.new([@pane]))
    @definition.behavior.cuts_opening = true
    @instance = Sketchup::ComponentInstance.new(201, @definition)
    @group = Sketchup::Group.new(100, Sketchup::Entities.new([@wall, @instance]))
    @model.entities << @group
    result = invoke("ph_composer.zones.make", "parent_path" => [], "entity_ids" => [100])
    assert_equal "completed", result["status"], result.inspect
    @zone = query("ph_composer.zones.list").dig("value", "zones", 0)
  end

  def test_registered_reads_and_suggest_ignore_cutting_descendants_but_keep_other_components
    fixture
    rows = query("ph_composer.zones.faces.list").dig("value", "faces")
    assert_equal [[101]], rows.map { |row| row.dig("reference", "entity_path") }
    assert_equal 1, rows.count { |row| row["state"] == "unclassified" }
    assert_equal 1, @zone.fetch("face_count")
    result = invoke("ph_composer.zones.faces.auto_classify", "zone" => @zone.fetch("reference"))
    assert_equal "completed", result["status"], result.inspect
    assert_equal 1, result.dig("value", "classified")
    assert_nil Zones::Faces::FACE_STORE.read(@pane)
    @definition.behavior.cuts_opening = false
    rows = query("ph_composer.zones.faces.list").dig("value", "faces")
    assert_equal [[101], [201, 301]], rows.map { |row| row.dig("reference", "entity_path") }
  end

  def test_explicit_read_classification_and_shift_pick_cannot_bypass_exclusion
    fixture
    reference = @zone.fetch("reference").merge("entity_path" => [201, 301], "entity_id" => nil)
    error = assert_raises(PhComposer::CodedError) do
      Zones::Occurrences.resolve_face(@model, reference, :allow_unassigned => true)
    end
    assert_equal "target.wrong_kind", error.code
    result = invoke("ph_composer.zones.faces.classify", "faces" => [reference], "expected_values" => {},
                                                        "intent" => { "face_type" => { "mode" => "set", "value" => "Wall" } })
    assert_equal %w[refused target.wrong_kind none], result.values_at("status", "code", "effect")
    tool = Zones::Faces.classify_tool(@session)
    tool.choose("face_type", "Wall")
    view = @model.active_view
    view.picks[[10, 10]] = [@group, @instance, @pane]
    before = @model.operations.length
    tool.onLButtonDown(CONSTRAIN_MODIFIER_MASK, 10, 10, view)
    tool.onLButtonUp(0, 10, 10, view)
    assert_nil Zones::Occurrences.occurrence_for_path([@group, @instance, @pane])
    assert_equal before, @model.operations.length
    assert_nil Zones::Faces::FACE_STORE.read(@pane)
    assert_nil Zones::Faces::FACE_STORE.read(@wall)
  end

  def test_export_snapshot_retains_cutting_instance_records_and_suppresses_descendant_faces
    fixture
    marker = "ph_composer.test_window_unit"
    PhComposer::Records::EntityStore.new(marker).write(@instance, "id" => "unit-synthetic")
    child = Sketchup::Group.new(401, Sketchup::Entities.new([Sketchup::Face.new(402)]))
    @definition.entities << child
    snapshot = PhComposer::Export::GeometrySnapshot.capture(@model, :revision => @session.revision)
    entry = snapshot.entry_at([100, 201], :kind => "component_instance")
    assert_equal({ "id" => "unit-synthetic" }, entry.record(marker))
    assert_empty snapshot.descendants(entry, :kind => "face")
    assert_equal [[100, 201, 401]], snapshot.descendants(entry).map(&:path)
    assert_equal [[100, 101]], snapshot.entries.select { |row| row.kind == "face" }.map(&:path)
  end

  private

  def query(name)
    API.query(:context => @context, :name => name)
  end

  def invoke(name, params)
    @sequence += 1
    API.invoke(:context => @context, :name => name, :params => params,
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end
end
