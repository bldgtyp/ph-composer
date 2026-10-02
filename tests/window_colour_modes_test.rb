# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "support/assembly_assignment_fixtures"
require_relative "../src/ph_composer/features/windows/colour_modes"

class WindowColourModesTest < PhComposerTestCase
  include WindowRecordFixtures
  include AssemblyAssignmentFixtures
  U = PhComposer::Windows::Units

  def setup
    super
    assignment_setup
    PhComposer::Registry.install([W]) unless PhComposer::Registry.installed?(W::FEATURE_ID)
    points = [[0, 0, 0], [1000, 0, 0], [1000, 1000, 0], [0, 1000, 0]].map { |p| Geom::Point3d.new(*p) }
    @group = Sketchup::Group.new(9510, Sketchup::Entities.new([Sketchup::Face.new(9511, {}, :points => points)]))
    @model.entities << @group
    assignment_invoke("ph_composer.zones.make", "parent_path" => [], "entity_ids" => [9510])
    @host = assignment_faces.first.fetch("reference")
    result = assignment_invoke("ph_composer.windows.types.create", "values" => { "name" => "Colour test" })
    @type_id = result.dig("value", "id")
    [3.0, 7.0].each do |x|
      result = assignment_invoke("ph_composer.windows.units.place", "host" => @host, "type_id" => @type_id,
                                                                    "anchor" => "sill_center", "offsets" => { "x_m" => x, "y_m" => 3.0 })
      assert_equal "ok", result.fetch("code"), result.inspect
    end
  end

  def test_projection_uses_occurrences_native_transforms_and_detached_units_type
    unit = U::Occurrences.all(@model).first
    unit.entity.definition = @model.definitions.add("Detached colour fixture")
    entries = W::ColourModes.entries(read)
    assert_equal [@type_id, @type_id], entries.map(&:value)
    assert_equal ["Colour test", "Colour test"], entries.map(&:label)
    assert_equal U::Occurrences.all(@model).map(&:path), entries.map(&:path)
    assert_equal U::Occurrences.all(@model).map { |row| row.transform.to_a }, entries.map { |row| row.transform.to_a }
  end

  def test_missing_type_is_unclassified_without_adopting_or_repairing_it
    unit = U::Occurrences.all(@model).first
    U::STORE.write(unit.entity, unit.record.merge("window_type_id" => "wnt_Unknown00000"))
    before = U::MutationScope.new.capture(@model)
    entries = W::ColourModes.entries(read)
    assert_nil entries.first.value
    assert_equal @type_id, entries.last.value
    assert_equal before, U::MutationScope.new.capture(@model)
  end

  def test_shared_service_hides_ancestor_geometry_but_retains_record_counts_without_model_write
    before = U::MutationScope.new.capture(@model)
    operations = @model.operations.length
    service = PhComposer::ColourBy.for(@session)
    service.activate(W::ColourModes::BY_TYPE)
    assert_equal 2, service.rows.first.count
    refute_empty service.fills.values.flatten
    @group.hidden = true
    service.invalidate!(:force => true)
    assert_equal 2, service.rows.first.count
    assert_empty service.fills.values.flatten
    assert_empty service.outlines.values.flatten
    service.deactivate
    assert_equal operations, @model.operations.length
    @group.hidden = false
    assert_equal before, U::MutationScope.new.capture(@model)
  end

  private

  def read
    PhComposer::HandlerRequest.for(@session, :owner => W::FEATURE_ID, :name => W::ColourModes::BY_TYPE)
  end
end
