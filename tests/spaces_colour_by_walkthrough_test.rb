# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/space_fixtures"
require_relative "../tools/examples/authoring/spaces_colour_by_walkthrough"
require_relative "../tools/examples/colour_by/example_colour_by"

class SpacesColourByWalkthroughTest < PhComposerTestCase
  include SpaceFixtures

  def test_the_walkthrough_reads_every_mode_and_readout_and_writes_nothing
    @model = Sketchup.active_model
    reference_model
    PhComposer::Sessions.for(@model)
    operations = @model.operations.length
    result = SpacesColourByWalkthrough.run
    assert result.fetch("passed"), result.inspect
    assert_equal 4, result.dig("legends", "ph_composer.spaces.by_space").length
    assert_equal ["2.4 m", "2.5 m", "3 m", "5 m"],
                 result.dig("legends", "ph_composer.spaces.by_height").map { |row| row.fetch("label") }
    assert_equal operations, @model.operations.length
  end

  def test_another_features_readout_left_on_does_not_fail_it
    PhComposer::Registry.install([ExampleColourBy])
    @model = Sketchup.active_model
    reference_model
    session = PhComposer::Sessions.for(@model)
    PhComposer::ColourBy.for(session).readout(ExampleColourBy::FOOTPRINTS, :on => true)
    assert SpacesColourByWalkthrough.run.fetch("passed")
  end
end
