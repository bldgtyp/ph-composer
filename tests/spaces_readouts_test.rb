# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/space_fixtures"

# The Spaces readouts on the reference model: Space labels with their default and optional lines, and the
# selection totals, each Space counted once (context/EXTENSIBILITY.md, "Colour-by readouts").
class SpacesReadoutsTest < PhComposerTestCase
  include SpaceFixtures

  API = PhComposer::API
  LABELS = "ph_composer.spaces.labels"
  TOTALS = "ph_composer.spaces.selection_totals"
  INCHES = 1.0 / 0.0254

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    reference_model
    @service = PhComposer::ColourBy.for(@session)
  end

  def test_labels_name_each_space_at_its_largest_segments_centroid
    @service.readout(LABELS, :on => true)
    anchors = @service.readout_drawings.fetch(LABELS).first
    assert_equal ["101 Living", "102 Bath", "103 Hall", "201 Loft"], anchors.map { |anchor| anchor.parts.first }.sort
    living = anchors.find { |anchor| anchor.parts.first == "101 Living" }
    assert_equal [1.5, 2.0, 0.0], [living.point.x, living.point.y, living.point.z].map { |value|
      (value / INCHES).round(9)
    }
    loft = anchors.find { |anchor| anchor.parts.first == "201 Loft" }
    assert_in_delta 1.0, loft.point.z / INCHES, 1e-9, "a sloped segment's label sits at its mean height"
  end

  def test_each_option_adds_its_line_and_the_view_command_redraws_them
    @service.readout(LABELS, :on => true)
    result = API.view(:context => @context, :name => "ph_composer.spaces.labels.set_options",
                      :params => { "weighted_area" => true, "net_volume" => true, "airflows" => true })
    assert_equal "completed", result.fetch("status"), result.inspect
    living = @service.readout_drawings.fetch(LABELS).first.find { |anchor| anchor.parts.first == "101 Living" }
    assert_equal ["101 Living", "  ", ["area", 12.0], "  ", ["volume", 30.0], "  ", ["airflow", 60.0], " / ",
                  ["airflow", 0.0]], living.parts
    loft = @service.readout_drawings.fetch(LABELS).first.find { |anchor| anchor.parts.first == "201 Loft" }
    refute_includes loft.parts.flatten, "airflow", "an inheriting Space has no rates to show"
  end

  def test_a_space_with_no_floor_segment_has_no_label
    @model.entities.to_a.first.entities << space_group(1400, space_record("E", :number => "104"), [])
    @service.readout(LABELS, :on => true)
    refute(@service.readout_drawings.fetch(LABELS).first.any? { |anchor| anchor.parts.first.start_with?("104") })
  end

  def test_selection_totals_sum_two_spaces_and_count_a_space_and_its_own_volume_once
    @service.readout(TOTALS, :on => true)
    assert_equal [], @service.readout_drawings.fetch(TOTALS).last, "nothing selected, no lines"
    zone = @model.entities.to_a.first
    living, bath = zone.entities.to_a[0, 2]
    @model.active_path = [zone] # Spaces are selected inside their Zone's edit context
    @model.selection.add(living)
    @model.selection.add(bath)
    @service.selection_changed
    hud = @service.readout_drawings.fetch(TOTALS).last
    assert_equal ["2 Spaces selected"], hud[0]
    assert_in_delta 16.0, hud[1].last.last, 1e-9
    assert_in_delta 39.6, hud[2].last.last, 1e-9
    @model.selection.clear
    @model.selection.add(living)
    @model.selection.add(living.entities.to_a.first)
    @service.selection_changed
    assert_equal ["1 Space selected"], @service.readout_drawings.fetch(TOTALS).last.first
  end

  def test_turning_the_readouts_and_options_on_writes_nothing
    operations = @model.operations.length
    revision = @session.revision
    @service.readout(LABELS, :on => true)
    @service.readout(TOTALS, :on => true)
    API.view(:context => @context, :name => "ph_composer.spaces.labels.set_options",
             :params => { "net_volume" => true })
    assert_equal [operations, revision], [@model.operations.length, @session.revision]
  end
end
