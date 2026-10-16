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

  def test_height_from_solid_sets_the_first_volumes_height_from_a_drawn_solid
    @model = Sketchup.active_model
    @model.entities << zone_group(100, "Z", []) << zone_group(200, "Y", [])
    SpacesWalkthrough.run
    api = PhComposer::API
    space = api.query(:context => api.connect(:session_id => PhComposer::Sessions.for(@model).id),
                      :name => "ph_composer.spaces.all").dig("value", "spaces")
               .find { |row| row.dig("values", "name") == "Kitchen" }
    path = space.dig("reference", "entity_path")
    container = path.reduce(nil) do |found, id|
      (found ? found.entities : @model.entities).to_a.find { |entity| entity.persistent_id == id }
    end
    solid = Sketchup::Group.new(9900)
    solid.solid_volume = 5.4 * (1 / 0.0254)**3
    container.entities << solid
    result = SpacesWalkthrough.height_from_solid(path + [9900])
    area = result.dig("preview", "net_floor_area_m2")
    assert_in_delta 5.4 / area, result.fetch("height_m"), 1e-9
  end
end
