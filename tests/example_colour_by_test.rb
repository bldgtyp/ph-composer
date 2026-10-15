# frozen_string_literal: true

require_relative "test_helper"
require_relative "../tools/examples/colour_by/example_colour_by"

# The example a contributor copies: derived geometry and a readout from an outside feature, through the
# public Colour-by contract and nothing under colour_by/ (context/EXTENSIBILITY.md, "Colour-by derived
# geometry" and "Colour-by readouts").
class ExampleColourByTest < PhComposerTestCase
  ColourBy = PhComposer::ColourBy
  INCHES = 1.0 / 0.0254

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    corners = [[0, 0, 0], [4, 0, 0], [4, 3, 0], [0, 3, 3]].map { |x, y, z|
      Geom::Point3d.new(x * INCHES, y * INCHES, z * INCHES)
    }
    @group = Sketchup::Group.new(100, Sketchup::Entities.new([Sketchup::Face.new(101, {}, :points => corners)]),
                                 :name => "Hall")
    @model.entities << @group
    PhComposer::Registry.install([ExampleColourBy])
  end

  def test_the_prism_mode_draws_a_closed_prism_and_counts_its_group
    service = ColourBy.for(@session).activate(ExampleColourBy::BY_HEIGHT)
    assert_equal [["High", 1]], service.rows.map { |row| [row.label, row.count] }
    assert_equal 36, service.fills.values.sum(&:length), "six rectangles, two triangles each"
  end

  def test_the_readout_labels_the_group_and_counts_the_selection
    ColourBy.for(@session).readout(ExampleColourBy::FOOTPRINTS, :on => true)
    @model.selection.add(@group)
    view = @model.active_view
    view.texts.clear
    @model.overlays.to_a.each { |overlay| overlay.draw(view) }
    assert_equal ["Hall 12 m²", "1 selected"], view.texts.map { |_point, text, _options| text }
  end
end
