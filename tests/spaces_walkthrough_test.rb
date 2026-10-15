# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/space_fixtures"
require_relative "../tools/examples/authoring/spaces_walkthrough"

class SpacesWalkthroughTest < PhComposerTestCase
  include SpaceFixtures

  def test_the_walkthrough_runs_as_written_with_the_panel_closed
    @model = Sketchup.active_model
    @model.entities << zone_group(100, "Z", []) << zone_group(200, "Y", [])
    before = @model.operations.length
    result = SpacesWalkthrough.run
    assert result.fetch("passed"), result.fetch("steps").inspect
    assert_in_delta 3.0, result.dig("metrics", "weighted_area_m2"), 1e-9
    committed = result.fetch("steps").count { |step| step["code"] == "ok" }
    assert_equal 9, committed
    assert_equal committed, @model.operations.length - before, "one Undo step per committed write"
  end

  def test_a_model_with_one_zone_is_refused_before_anything_is_written
    @model = Sketchup.active_model
    @model.entities << zone_group(100, "Z", [])
    before = @model.operations.length
    error = assert_raises(ArgumentError) { SpacesWalkthrough.run }
    assert_match(/two Zones/, error.message)
    assert_equal before, @model.operations.length
  end

  def test_the_walkthrough_names_no_feature_module
    text = File.read(File.expand_path("../tools/examples/authoring/spaces_walkthrough.rb", __dir__))
    refute_match(/PhComposer::(Spaces|Zones)::/, text)
  end
end
