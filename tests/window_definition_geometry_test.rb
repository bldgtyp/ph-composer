# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/definition_writer"
require_relative "../src/ph_composer/features/windows/units/definition_geometry"

class WindowDefinitionGeometryTest < PhComposerTestCase
  include WindowRecordFixtures
  U = PhComposer::Windows::Units

  def setup
    super
    @model = Sketchup.active_model
    @type = window_record
    @plan = U::DefinitionPlan.build(@type)
    @definition = U::DefinitionWriter.create(:model => @model, :type => @type, :plan => @plan)
  end

  def matches?
    U::DefinitionGeometry.matches?(@definition, :type_id => @type.fetch("id"), :plan => @plan)
  end

  def test_generated_geometry_matches_but_name_and_material_edits_only_change_drift_capture
    assert matches?
    before = U::DefinitionGeometry.capture(@definition)
    @definition.name = "Native rename"
    assert matches?
    refute_equal before, U::DefinitionGeometry.capture(@definition)
    @definition.entities.grep(Sketchup::Face).first.material = @model.materials.add("Synthetic finish")
    assert matches?
  end

  def test_same_definition_stamp_does_not_hide_missing_or_reversed_pane
    face = @definition.entities.grep(Sketchup::Face).first
    face.reverse!
    refute matches?
    face.reverse!
    assert matches?
    @definition.entities.erase_entities(face)
    refute matches?
  end

  def test_wrong_element_stamp_and_extra_native_geometry_do_not_match
    face = @definition.entities.grep(Sketchup::Face).first
    U::PANE_STORE.write(face, "window_type_id" => @type.fetch("id"), "element_id" => "wel_missing")
    refute matches?
    U::PANE_STORE.write(face, "window_type_id" => @type.fetch("id"), "element_id" => @plan.panes.first.element_id)
    assert matches?
    points = [[100, 100, 0], [110, 100, 0], [110, 110, 0], [100, 110, 0]].map { |point| Geom::Point3d.new(*point) }
    @definition.entities.add_face(points)
    refute matches?
  end

  def test_read_does_not_repair_invalid_stamp_or_start_operations
    @definition.set_attribute(U::DEFINITION_STORE.dictionary, U::DEFINITION_STORE.key, "null")
    before = @model.operation_starts.length
    refute matches?
    assert_equal "null", @definition.get_attribute(U::DEFINITION_STORE.dictionary, U::DEFINITION_STORE.key)
    assert_equal before, @model.operation_starts.length
  end

  def test_collinear_boundary_subdivision_matches_but_an_interior_loose_edge_does_not
    face = @definition.entities.grep(Sketchup::Face).first
    first, last = face.outer_loop.vertices.take(2).map(&:position)
    middle = Geom::Point3d.new((first.x + last.x) / 2.0, (first.y + last.y) / 2.0, 0)
    face.outer_loop.vertices.insert(1, Sketchup::Vertex.new(middle))
    @definition.entities << Sketchup::Edge.new(5000, first, middle)
    @definition.entities << Sketchup::Edge.new(5001, middle, last)
    assert matches?
    inside = Geom::Point3d.new(middle.x, middle.y / 2.0, 0)
    @definition.entities << Sketchup::Edge.new(5002, middle, inside)
    refute matches?
  end

  def test_a_matcher_defect_surfaces_rather_than_reporting_geometry_differs
    def @definition.behavior
      raise TypeError, "synthetic matcher defect"
    end
    occurrence = U::Occurrence.new(:entity => @model.entities.add_instance(@definition, Geom::Transformation.new),
      :path => [1], :transform => Geom::Transformation.new, :parent_transform => Geom::Transformation.new,
      :record => { "id" => "wun_000000000001", "window_type_id" => @type.fetch("id") }, :shared_storage => false,
      :locked => false)
    assert_raises(TypeError) do
      U::State.findings(occurrence, :type => @type, :canonical_definition => @definition)
    end
  end
end
