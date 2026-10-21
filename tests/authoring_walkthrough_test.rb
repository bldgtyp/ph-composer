# frozen_string_literal: true

require_relative "test_helper"
require_relative "../tools/examples/authoring/walkthrough"

# The Zone authoring walkthrough (tools/examples/authoring/walkthrough.rb) reports passed only when its Zone edit
# was applied and reads back. Its native geometry setup needs the host; two named one-Face Groups stand in here.
class AuthoringWalkthroughTest < PhComposerTestCase
  def setup
    super
    %w[west east].each_with_index do |name, index|
      base = 100 * (index + 1)
      points = [[0, 0, 0], [2, 0, 0], [2, 2, 0]].map { |x, y, z| Geom::Point3d.new(x + (index * 5), y, z) }
      group = Sketchup::Group.new(base, Sketchup::Entities.new([Sketchup::Face.new(base + 1, {}, :points => points)]))
      group.name = "#{AuthoringWalkthrough::PREFIX}#{name}"
      Sketchup.active_model.entities << group
    end
  end

  def test_the_walkthrough_passes_only_when_its_zone_edit_is_applied_and_reads_back
    result = AuthoringWalkthrough.run
    assert result.fetch("zone_edit_applied"), result.inspect
    assert result.fetch("passed"), result.inspect
    west = result.fetch("zone_values").find { |row| row["name"] == "West Zone" }
    assert_in_delta 150.0, west.fetch("ground_depth_mm"), 1e-9
  end
end
