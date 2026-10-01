# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/definition_writer"
require_relative "../src/ph_composer/features/windows/units/generated_geometry"

class WindowGeneratedGeometryTest < PhComposerTestCase
  include WindowRecordFixtures
  U = PhComposer::Windows::Units

  def test_all_empty_generation_retains_dimensions_without_inventing_pane_bounds
    type = window_record
    type.fetch("elements").each { |element| element["kind"] = "empty" }
    authored = U::DefinitionPlan.build(type)
    definition = U::DefinitionWriter.create(:model => Sketchup.active_model, :type => type, :plan => authored)
    assert_empty definition.entities.to_a
    generated = U::GeneratedGeometry.plan(definition, :type_id => type.fetch("id"))
    assert_equal authored.outer_polygon_m, generated.outer_polygon_m
    assert_equal [1.0, 1.5], [generated.width_m, generated.height_m]
    assert_empty generated.panes
    assert generated.frozen?
    assert generated.outer_polygon_m.all?(&:frozen?)
  end

  def test_missing_legacy_or_invalid_generation_data_refuses_without_repair
    model = Sketchup.active_model
    definition = model.definitions.add("Synthetic orphan")
    invalid = [nil, {}, { "width_m" => 0, "height_m" => 1 }, { "width_m" => 1, "height_m" => "2" },
      { "width_m" => 1, "height_m" => 2, "extra" => 1 }]
    invalid.each do |size|
      stamp = { "window_type_id" => "wnt_AAAAAAAAAAAA" }
      stamp["generated_size_m"] = size if size
      U::DEFINITION_STORE.write(definition, stamp)
      error = assert_raises(PhComposer::CodedError) do
        U::GeneratedGeometry.plan(definition, :type_id => "wnt_AAAAAAAAAAAA")
      end
      assert_equal "window.type_geometry_unknown", error.code
      assert_equal stamp, U::DEFINITION_STORE.read(definition)
    end
    assert_empty model.operation_starts
  end

  def test_different_type_stamp_cannot_supply_the_old_anchor_dimensions
    type = window_record
    definition = U::DefinitionWriter.create(:model => Sketchup.active_model, :type => type,
      :plan => U::DefinitionPlan.build(type))
    error = assert_raises(PhComposer::CodedError) do
      U::GeneratedGeometry.plan(definition, :type_id => "wnt_BBBBBBBBBBBB")
    end
    assert_equal "window.type_geometry_unknown", error.code
  end

  def test_native_faces_outside_generated_rectangle_or_off_plane_refuse_the_dimension_datum
    type = window_record
    [[2, -1, 0], [0.5, -1, 0.2]].each do |extra|
      definition = U::DefinitionWriter.create(:model => Sketchup.active_model, :type => type,
        :plan => U::DefinitionPlan.build(type))
      points = [[0, 0, 0], extra, [0, -1, 0]].map do |point|
        Geom::Point3d.new(*point.map { |value| value / 0.0254 })
      end
      definition.entities.add_face(points)
      error = assert_raises(PhComposer::CodedError) do
        U::GeneratedGeometry.plan(definition, :type_id => type.fetch("id"))
      end
      assert_equal "window.type_geometry_unknown", error.code
    end
  end

  def test_nested_native_geometry_cannot_be_guessed_from_the_parent_generation_stamp
    type = window_record
    definition = U::DefinitionWriter.create(:model => Sketchup.active_model, :type => type,
      :plan => U::DefinitionPlan.build(type))
    definition.entities.add_group
    error = assert_raises(PhComposer::CodedError) do
      U::GeneratedGeometry.plan(definition, :type_id => type.fetch("id"))
    end
    assert_equal "window.type_geometry_unknown", error.code
  end

  def test_valid_in_rectangle_edits_and_empty_regions_keep_the_full_generated_footprint
    type = window_record
    definition = U::DefinitionWriter.create(:model => Sketchup.active_model, :type => type,
      :plan => U::DefinitionPlan.build(type))
    definition.entities.first.reverse!
    plan = U::GeneratedGeometry.plan(definition, :type_id => type.fetch("id"))
    assert_equal U::DefinitionPlan.build(type).outer_polygon_m, plan.outer_polygon_m
    definition.set_attribute(U::DEFINITION_STORE.dictionary, U::DEFINITION_STORE.key, "{malformed")
    assert_equal "record.unreadable", assert_raises(PhComposer::CodedError) {
      U::GeneratedGeometry.plan(definition, :type_id => type.fetch("id"))
    }.code
  end
end
