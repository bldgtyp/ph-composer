# frozen_string_literal: true

require_relative "test_helper"
require_relative "../tools/examples/authoring/walkthrough"

# The Zone authoring walkthrough (tools/examples/authoring/walkthrough.rb) reports passed only when its Zone edit
# was applied and reads back. Its native geometry setup needs the host; two named one-Face Groups stand in here.
class AuthoringWalkthroughTest < PhComposerTestCase
  def setup
    super
    @faces_per_zone = 1
  end

  # Two named Groups as the walkthrough's `setup` would leave them, each with `@faces_per_zone` Faces.
  def stand_in_groups
    %w[west east].each_with_index do |name, index|
      base = 100 * (index + 1)
      faces = @faces_per_zone.times.map do |face|
        points = [[0, 0, face], [2, 0, face], [2, 2, face]].map { |x, y, z| Geom::Point3d.new(x + (index * 5), y, z) }
        Sketchup::Face.new(base + face + 1, {}, :points => points)
      end
      group = Sketchup::Group.new(base, Sketchup::Entities.new(faces))
      group.name = "#{AuthoringWalkthrough::PREFIX}#{name}"
      Sketchup.active_model.entities << group
    end
  end

  def test_the_walkthrough_passes_only_when_its_zone_edit_is_applied_and_reads_back
    stand_in_groups
    result = AuthoringWalkthrough.run
    assert result.fetch("zone_edit_applied"), result.inspect
    assert result.fetch("passed"), result.inspect
    west = result.fetch("zone_values").find { |row| row["name"] == "West Zone" }
    assert_in_delta 150.0, west.fetch("ground_depth_mm"), 1e-9
  end

  # Suggest on Make is on by default and classifies every Face of a box, as on the host (6 per box here).
  def test_boxes_whose_faces_make_zone_classifies_still_pass
    @faces_per_zone = 6
    stand_in_groups
    result = AuthoringWalkthrough.run
    assert_equal [12, 12], result.values_at("classified_faces", "expected_classified_faces")
    assert result.fetch("passed"), result.inspect
  end
end
