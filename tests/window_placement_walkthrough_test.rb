# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "support/assembly_assignment_fixtures"
require_relative "../tools/examples/authoring/windows_placement_walkthrough"

class WindowPlacementWalkthroughTest < PhComposerTestCase
  include WindowRecordFixtures
  include AssemblyAssignmentFixtures

  def test_public_walkthrough_places_copies_resizes_and_swaps_with_panel_closed
    assignment_setup
    PhComposer::Registry.install([W]) unless PhComposer::Registry.installed?(W::FEATURE_ID)
    face = Sketchup::Face.new(1001, {}, :points => [[0, 0, 0], [1000, 0, 0],
      [1000, 1000, 0], [0, 1000, 0]].map { |point| Geom::Point3d.new(*point) })
    group = Sketchup::Group.new(1000, Sketchup::Entities.new([face]))
    @model.entities << group
    assignment_invoke("ph_composer.zones.make", "parent_path" => [], "entity_ids" => [1000])
    copy = lambda do |reference|
      item = W::Units::Occurrences.resolve(@model, reference)
      @model.start_operation("Native Copy", true)
      entity = group.entities.add_instance(item.entity.definition,
        Geom::Transformation.translation([200, 0, 0]) * item.entity.transformation)
      entity.glued_to = face
      W::Units.write(entity, item.record)
      @model.commit_operation
      W::Units::Occurrences.all(@model).find { |row| row.entity == entity }.reference
    end
    result = WindowPlacementWalkthrough.run(:host => assignment_faces.first.fetch("reference"),
      :offsets => { "x_m" => 3.0, "y_m" => 3.0 }, :copy_unit => copy)
    assert result.fetch("passed"), result.inspect
    assert_equal %w[units.place units.repair_copied_identities types.update types.duplicate units.swap_type],
                 result.fetch("steps").map { |step| step.fetch("step") }
    rows = result.fetch("units")
    @model.undo
    assert_equal 1, W::Units::Occurrences.all(@model).map { |item| item.record.fetch("window_type_id") }.uniq.length
    @model.redo
    assert_equal rows, assignment_query("ph_composer.windows.units.list").fetch("units")
    text = File.read(File.expand_path("../tools/examples/authoring/windows_placement_walkthrough.rb", __dir__))
    refute_match(/PhComposer::Windows|PhComposer::Zones|Sketchup/, text)
  end
end
