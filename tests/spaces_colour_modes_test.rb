# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/space_fixtures"

# P3a-07 step 11: By weighting factor colours each Floor Segment face by its factor, one band per value in
# use, through the shared service and with no change under colour_by/.
class SpacesColourModesTest < PhComposerTestCase
  include SpaceFixtures

  MODE = "ph_composer.spaces.by_weighting_factor"

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
  end

  def test_each_floor_segment_face_is_one_entry_banded_by_its_factor
    reference_model
    entries = PhComposer::Spaces::ColourModes.entries(@model)
    assert_equal 5, entries.length, "one per Floor Segment of the reference model"
    assert_equal %w[0.00 1.00], entries.map(&:value).uniq.sort
    assert(entries.all? { |entry| entry.entity.is_a?(Sketchup::Face) && entry.label == entry.value })
  end

  def test_the_mode_registers_through_the_shared_service_and_writes_nothing
    reference_model
    operations = @model.operations.length
    service = PhComposer::ColourBy.for(@session)
    service.activate(MODE)
    assert_equal %w[0.00 1.00], service.rows.map { |row| row.value }.sort
    service.deactivate
    assert_equal operations, @model.operations.length
  end

  def test_nothing_under_colour_by_names_the_spaces_mode
    root = File.expand_path("../src/ph_composer/colour_by", __dir__)
    Dir.glob(File.join(root, "*.rb")).each do |path|
      source = File.read(path)
      refute_includes source, "by_weighting_factor", path
      refute_includes source, "Spaces::", path
    end
  end
end
