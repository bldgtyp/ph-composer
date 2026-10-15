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
      result = assignment_invoke("ph_composer.windows.units.place",
                                 "host" => @host, "type_id" => @type_id,
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

  # Slice B of P3a-05: a swing element pointing left carries two mark segments from the pane's right
  # corners to its left midpoint, placed by the Unit's transform and drawn in the Type's colour; a Type
  # with no operation draws none.
  def test_by_type_draws_each_elements_operation_marks_in_the_types_colour
    assert(W::ColourModes.entries(read).all? { |entry| entry.derived.nil? })
    values = assignment_query("ph_composer.windows.types.list", "ids" => [@type_id])["records"].first["values"]
    element = values["elements"].first["id"]
    result = assignment_invoke("ph_composer.windows.types.grid.set_element_operation",
                               "id" => @type_id, "element_id" => element, "expected_values" => values,
                               "operation" => { "type" => "swing", "directions" => ["left"] })
    assert_equal "ok", result.fetch("code"), result.inspect
    unit = U::Occurrences.all(@model).first
    entry = W::ColourModes.entries(read).first
    pane = U::DefinitionPlan.build(assignment_query("ph_composer.windows.types.list",
                                                    "ids" => [@type_id])["records"].first["values"]).panes.first
    left, bottom, right, top = [pane.polygon_m.map(&:first).min, pane.polygon_m.map { |point| point[1] }.min,
                                pane.polygon_m.map(&:first).max, pane.polygon_m.map { |point| point[1] }.max]
    xyz = ->(point) { [point.x, point.y, point.z] }
    inches = ->(x, y) { xyz.call(Geom::Point3d.new(x / 0.0254, y / 0.0254, 0).transform(unit.transform)) }
    expected = [[inches.call(right, top), inches.call(left, (top + bottom) / 2.0)],
                [inches.call(left, (top + bottom) / 2.0), inches.call(right, bottom)]]
    actual = entry.derived.segments.map { |segment| segment.map(&xyz) }
    expected.flatten.zip(actual.flatten).each { |e, a| assert_in_delta e, a, 1e-9 }
    service = PhComposer::ColourBy.for(@session)
    service.activate(W::ColourModes::BY_TYPE)
    assert_equal 8, service.lines.values.sum(&:length), "two Units, two segments each"
  end

  # A Unit made unique keeps its panes when its Type later changes size; its marks would land outside
  # them, so it draws none while the Units still on the Type's definition draw the new size.
  def test_a_unique_unit_left_behind_by_a_type_change_draws_no_marks
    values = type_values
    assignment_invoke("ph_composer.windows.types.grid.set_element_operation",
                      "id" => @type_id, "element_id" => values["elements"].first["id"], "expected_values" => values,
                      "operation" => { "type" => "swing", "directions" => ["left"] })
    values = type_values
    # What Make Unique leaves: a second definition holding the Type's panes as they were.
    U::Occurrences.all(@model).first.entity.definition =
      U::DefinitionWriter.create(:model => @model, :type => values.merge("id" => @type_id),
                                 :plan => U::DefinitionPlan.build(values))
    assert_equal 2, W::ColourModes.entries(read).first.derived.segments.length
    result = assignment_invoke("ph_composer.windows.types.update", "id" => @type_id,
                               "values" => { "columns_m" => values["columns_m"].map { |width| width * 2 } },
                               "expected_values" => { "columns_m" => values["columns_m"] })
    assert_equal "completed", result.fetch("status"), result.inspect
    entries = W::ColourModes.entries(read)
    assert_equal [@type_id, @type_id], entries.map(&:value)
    assert_nil entries.first.derived
    assert_equal 2, entries.last.derived.segments.length
  end

  private

  def type_values
    assignment_query("ph_composer.windows.types.list", "ids" => [@type_id])["records"].first["values"]
  end

  def read
    PhComposer::HandlerRequest.for(@session, :owner => W::FEATURE_ID, :name => W::ColourModes::BY_TYPE)
  end
end
