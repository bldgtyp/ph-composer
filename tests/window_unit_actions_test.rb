# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "support/assembly_assignment_fixtures"

class WindowUnitActionsTest < PhComposerTestCase
  include WindowRecordFixtures
  include AssemblyAssignmentFixtures
  U = PhComposer::Windows::Units
  PREFIX = "ph_composer.windows"

  def setup
    super
    assignment_setup
    PhComposer::Registry.install([W]) unless PhComposer::Registry.installed?(W::FEATURE_ID)
    points = [[0, 0, 0], [1000, 0, 0], [1000, 1000, 0], [0, 1000, 0]].map { |point| Geom::Point3d.new(*point) }
    face = Sketchup::Face.new(1001, {}, :points => points)
    @group = Sketchup::Group.new(1000, Sketchup::Entities.new([face]))
    @model.entities << @group
    result = assignment_invoke("ph_composer.zones.make", "parent_path" => [], "entity_ids" => [1000])
    assert_equal "completed", result.fetch("status"), result.inspect
    @face_reference = assignment_faces.first.fetch("reference")
    result = assignment_invoke("#{PREFIX}.types.create", "values" => { "name" => "Synthetic placement" })
    assert_equal "completed", result.fetch("status"), result.inspect
    @type_id = result.fetch("value").fetch("id")
  end

  def params(x = 2.0, anchor = "sill_center")
    { "host" => @face_reference, "type_id" => @type_id, "anchor" => anchor,
      "offsets" => { "x_m" => x, "y_m" => 3.0 }, "user_data" => { "note" => ["retain"] } }
  end

  def place(x = 2.0, anchor = "sill_center")
    result = assignment_invoke("#{PREFIX}.units.place", params(x, anchor))
    assert_equal "completed", result.fetch("status"), result.inspect
    result
  end

  def units
    assignment_query("#{PREFIX}.units.list").fetch("units")
  end

  def type
    PhComposer::Records::Engine.new(@model, PhComposer::Registry.current.catalog).find(W::TYPE_KIND, @type_id)
  end

  def test_preview_changes_nothing_and_place_is_one_native_undo_with_public_readback
    before = U::MutationScope.new.capture(@model)
    preview = API.preview(:context => @context, :name => "#{PREFIX}.units.place", :params => params)
    assert_equal "ok", preview.fetch("code"), preview.inspect
    assert_equal before, U::MutationScope.new.capture(@model)
    operation_count = @model.operations.length
    result = place
    assert_equal operation_count + 1, @model.operations.length
    row = units.first
    assert_equal result.dig("value", "unit_id"), row.fetch("id")
    assert_empty row.fetch("findings")
    assert_equal @face_reference, row.fetch("host")
    assert_equal({ "note" => ["retain"] }, row.fetch("user_data"))
    @model.undo
    assert_empty units
    assert_equal before, U::MutationScope.new.capture(@model)
    @model.redo
    assert_equal row, units.first
  end

  def test_second_placement_shares_definition_and_positive_area_overlap_refuses_without_writes
    place
    before = U::MutationScope.new.capture(@model)
    refused = assignment_invoke("#{PREFIX}.units.place", params)
    assert_equal "window.overlap", refused.fetch("code"), refused.inspect
    assert_equal before, U::MutationScope.new.capture(@model)
    place(5.0)
    assert_equal 2, units.length
    assert_equal 1, U::Occurrences.all(@model).map { |item| item.entity.definition.persistent_id }.uniq.length
    assert_equal 1, @model.definitions.to_a.length
  end

  def test_used_type_resize_keeps_each_world_anchor_and_one_undo_restores_every_unit
    %w[sill_left center head_right].each_with_index { |anchor, index| place(3.0 + index * 5.0, anchor) }
    before_type = type
    before_plan = U::DefinitionPlan.build(before_type)
    points = U::Occurrences.all(@model).to_h do |item|
      [item.path, U::WorldGeometry.anchor(before_plan, item.record.fetch("anchor"), item.transform.to_a)]
    end
    scope = U::MutationScope.new(:definition_ids => U::Occurrences.all(@model).map { |item|
 item.entity.definition.persistent_id })
    before = scope.capture(@model)
    result = assignment_invoke("#{PREFIX}.types.update", "id" => @type_id,
      "values" => { "columns_m" => [1.2] }, "expected_values" => { "columns_m" => before_type.fetch("columns_m") })
    assert_equal "completed", result.fetch("status"), result.inspect
    assert_equal 3, result.dig("value", "unit_count")
    after_plan = U::DefinitionPlan.build(type)
    U::Occurrences.all(@model).each do |item|
      actual = U::WorldGeometry.anchor(after_plan, item.record.fetch("anchor"), item.transform.to_a)
      points.fetch(item.path).zip(actual).each { |expected, value| assert_in_delta expected, value, 1e-12 }
    end
    after = scope.capture(@model)
    @model.undo
    assert_equal before_type, type
    assert_equal before, scope.capture(@model)
    @model.redo
    assert_equal after, scope.capture(@model)
  end

  def test_copied_identity_read_is_pure_and_next_name_change_repairs_inside_the_same_undo
    place
    original = U::Occurrences.all(@model).first
    copy = @group.entities.add_instance(original.entity.definition,
      Geom::Transformation.translation([200, 0, 0]) * original.entity.transformation)
    copy.glued_to = original.entity.glued_to
    U.write(copy, original.record)
    assert units.all? { |row| row.fetch("findings").any? { |finding| finding.fetch("code") == "copy_id_pending" } }
    assert_equal 1, U::Occurrences.all(@model).map { |item| item.record.fetch("id") }.uniq.length
    scope = U::MutationScope.new(:definition_ids => [original.entity.definition.persistent_id])
    before = scope.capture(@model)
    result = assignment_invoke("#{PREFIX}.types.update", "id" => @type_id,
      "values" => { "name" => "Renamed synthetic" }, "expected_values" => { "name" => type.fetch("name") })
    assert_equal "completed", result.fetch("status"), result.inspect
    assert_equal 2, U::Occurrences.all(@model).map { |item| item.record.fetch("id") }.uniq.length
    assert units.all? { |row| row.fetch("user_data") == { "note" => ["retain"] } }
    @model.undo
    assert_equal before, scope.capture(@model)
  end

  def test_read_works_under_locked_parent_but_placement_refuses
    place
    @group.locked = true
    assert_empty units.first.fetch("findings")
    refused = assignment_invoke("#{PREFIX}.units.place", params(7.0))
    assert_equal "target.locked", refused.fetch("code")
    assert_equal 1, units.length
  end

  def test_paged_reads_bind_to_revision_and_preserve_occurrence_identity
    place
    place(7.0)
    first = assignment_query("#{PREFIX}.units.list", "limit" => 1)
    assert_equal 2, first.fetch("total")
    cursor = first.fetch("next_cursor")
    refute_nil cursor
    second = assignment_query("#{PREFIX}.units.list", "limit" => 1, "cursor" => cursor)
    refute_equal first.fetch("units").first.fetch("reference"), second.fetch("units").first.fetch("reference")
    assert_nil second.fetch("next_cursor")
    place(12.0)
    expired = API.query(:context => @context, :name => "#{PREFIX}.units.list",
      :params => { "limit" => 1, "cursor" => cursor })
    assert_equal "query.cursor_expired", expired.fetch("code")
  end

  def test_resizing_past_host_refuses_preview_without_changing_type_or_native_geometry
    place(1.0, "sill_right")
    before_type = type
    scope = U::MutationScope.new(:definition_ids => [U::Occurrences.all(@model).first.entity.definition.persistent_id])
    before = scope.capture(@model)
    result = API.preview(:context => @context, :name => "#{PREFIX}.types.update",
      :params => { "id" => @type_id, "values" => { "columns_m" => [2.0] },
        "expected_values" => { "columns_m" => before_type.fetch("columns_m") } })
    assert_equal "window.overhang", result.fetch("code"), result.inspect
    assert_equal 1, result.dig("detail", "unit_count")
    blocked = result.dig("detail", "blocked_units").map { |row| row.fetch("reference") }
    assert_equal [units.first.fetch("reference")], blocked
    assert_equal before_type, type
    assert_equal before, scope.capture(@model)
  end

  def test_resize_refuses_overlap_with_unglued_canonical_neighbor
    place(2.0, "sill_left")
    place(5.0, "sill_left")
    U::Occurrences.all(@model).last.entity.glued_to = nil
    before = U::MutationScope.new.capture(@model)
    result = assignment_invoke("#{PREFIX}.types.update", "id" => @type_id,
      "values" => { "columns_m" => [4.0] }, "expected_values" => { "columns_m" => [1.0] })
    assert_equal "window.overlap", result.fetch("code"), result.inspect
    assert_equal before, U::MutationScope.new.capture(@model)
  end

  def test_preview_names_units_whose_edited_primary_geometry_will_be_replaced
    place
    item = U::Occurrences.all(@model).first
    item.entity.definition.entities.grep(Sketchup::Face).first.reverse!
    before = U::MutationScope.new(:definition_ids => [item.entity.definition.persistent_id]).capture(@model)
    result = API.preview(:context => @context, :name => "#{PREFIX}.types.update",
      :params => { "id" => @type_id, "values" => { "columns_m" => [1.2] }, "expected_values" => {} })
    assert_equal "ok", result.fetch("code"), result.inspect
    warning = result.fetch("findings").find { |finding| finding.fetch("code") == "window.edited_geometry_replaced" }
    refute_nil warning
    assert_equal [item.reference], warning.fetch("references")
    assert_equal before, U::MutationScope.new(:definition_ids => [item.entity.definition.persistent_id]).capture(@model)
  end

  def test_read_keeps_each_occurrence_under_a_copied_shared_zone
    place
    copy = Sketchup::Group.new(3000, @group.entities)
    PhComposer::Zones::ZONE_STORE.write(copy, PhComposer::Zones::ZONE_STORE.read(@group))
    @model.entities << copy
    rows = units
    assert_equal 2, rows.length
    assert_equal [[1000], [3000]], rows.map { |row| row.fetch("reference").fetch("entity_path")[0...-1] }.sort
    assert rows.all? { |row| row.fetch("findings").any? { |finding| finding.fetch("code") == "copy_id_pending" } }
    assert rows.all? { |row| row.fetch("findings").any? { |finding| finding.fetch("code") == "invalid_host" } }
  end
end
