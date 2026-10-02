# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/read_context"
require_relative "../src/ph_composer/features/windows/units/reset_step"

class WindowUnitReadContextTest < PhComposerTestCase
  include WindowRecordFixtures
  U = PhComposer::Windows::Units

  Engine = Struct.new(:model) do
    def ids(_kind)
      PhComposer::Windows::Types::KIND.store.ids(model)
    end

    def find(_kind, id)
      PhComposer::Windows::Types::KIND.store.read(model, id)
    end
  end

  Request = Struct.new(:model, :engine) do
    def query(name)
      { "ph_composer.zones.faces.all" => { "faces" => [] },
        "ph_composer.zones.all" => { "zones" => [] } }.fetch(name)
    end
  end

  def setup
    super
    @model = Sketchup.active_model
    @type = window_record("columns_m" => [1.0])
    W::Types::KIND.store.write(@model, @type)
    @old = definition(@type.merge("columns_m" => [4.0]))
    @canonical = definition(@type)
    U::DefinitionIndex.write(@model, { @type.fetch("id") => @canonical.persistent_id }, :expected => {})
    @outside = unit(@old, 9, "wun_BBBBBBBBBBBB")
    @selected = unit(@canonical, 12.2, "wun_AAAAAAAAAAAA")
  end

  def definition(type)
    U::DefinitionWriter.create(:model => @model, :type => type, :plan => U::DefinitionPlan.build(type))
  end

  def unit(definition, x_m, id)
    entity = @model.entities.add_instance(definition, Geom::Transformation.translation([x_m / 0.0254, 0, 0]))
    U.write(entity, "id" => id, "schema_version" => 1, "window_type_id" => @type.fetch("id"),
                    "anchor" => "sill_left", "user_data" => {})
    entity
  end

  def reads
    U::ReadContext.new(Request.new(@model, Engine.new(@model)))
  end

  def occurrence(context, entity)
    context.occurrences.find { |item| item.entity == entity }
  end

  # Placing on one explicit host needs the other outlines and nothing from Zones.
  def test_other_outlines_for_a_placement_make_no_zones_read
    request = Request.new(@model, Engine.new(@model))
    def request.query(name, _params = {})
      raise "unexpected Zones read #{name}"
    end
    assert_equal 2, U::ReadContext.new(request).other_polygons.length
  end

  def test_detached_old_width_blocks_reset_overlap_with_current_narrow_type
    @selected.transformation *= Geom::Transformation.scaling(2, 1, 1)
    context = reads
    polygon = context.polygon(occurrence(context, @outside))
    assert_in_delta 9, polygon.map(&:first).min, 1e-10
    assert_in_delta 13, polygon.map(&:first).max, 1e-10
    selected = occurrence(context, @selected)
    inventory = context.occurrences.to_h { |item| [item.path, context.polygon(item)] }
    error = assert_raises(PhComposer::CodedError) do
      U::ResetStep.new(:model => @model, :type => @type,
                       :items => [{ :reference => selected.reference, :expected_record => selected.record }],
                       :outline_inventory_m => inventory)
    end
    assert_equal "window.overlap", error.code
    assert_same @old, @outside.definition
    assert_empty @model.operation_starts
  end

  def test_native_extensions_refuse_mutation_outlines_but_read_keeps_geometry_differs_finding
    extra = [[0, 0, 0], [6, -1, 0], [0, -1, 0]].map do |point|
      Geom::Point3d.new(*point.map { |value| value / 0.0254 })
    end
    @old.entities.add_face(extra)
    context = reads
    item = occurrence(context, @outside)
    assert_equal "window.type_geometry_unknown", assert_raises(PhComposer::CodedError) { context.polygon(item) }.code
    assert_nil context.read_polygon(item)
    findings = U::State.findings(item, :type => @type, :canonical_definition => @canonical)
    assert_includes findings.map { |finding| finding.fetch("code") }, "window.geometry_differs"
    assert_includes context.occurrences, item
  end

  def test_detached_and_stale_primary_all_empty_footprints_use_generated_dimensions
    empty = @type.merge("elements" => @type.fetch("elements").map { |cell| cell.merge("kind" => "empty") })
    W::Types::KIND.store.write(@model, empty)
    empty_old = definition(empty.merge("columns_m" => [4.0]))
    @outside.definition = empty_old
    context = reads
    assert_in_delta 13, context.polygon(occurrence(context, @outside)).map(&:first).max, 1e-10
    U::DefinitionIndex.write(@model, { @type.fetch("id") => empty_old.persistent_id },
                             :expected => U::DefinitionIndex.read(@model))
    context = reads
    assert_in_delta 13, context.polygon(occurrence(context, @outside)).map(&:first).max, 1e-10
  end

  def test_legacy_primary_can_use_matching_authored_geometry_and_malformed_stamp_is_not_hidden
    stamp = U::DEFINITION_STORE.read(@canonical)
    U::DEFINITION_STORE.write(@canonical, stamp.reject { |key, _value| key == "generated_size_m" })
    context = reads
    item = occurrence(context, @selected)
    assert_in_delta 13.2, context.polygon(item).map(&:first).max, 1e-10
    @canonical.set_attribute(U::DEFINITION_STORE.dictionary, U::DEFINITION_STORE.key, "{malformed")
    assert_equal "record.unreadable", assert_raises(PhComposer::CodedError) { context.read_polygon(item) }.code
  end

  def test_absent_type_keeps_trustworthy_generated_footprint_and_unknown_legacy_record_readable
    W::Types::KIND.store.delete(@model, @type.fetch("id"))
    context = reads
    item = occurrence(context, @outside)
    assert_nil context.type(item)
    assert_in_delta 13, context.polygon(item).map(&:first).max, 1e-10
    U::DEFINITION_STORE.write(@old, "window_type_id" => @type.fetch("id"))
    assert_equal "window.type_geometry_unknown", assert_raises(PhComposer::CodedError) { context.polygon(item) }.code
    assert_nil context.read_polygon(item)
    assert_includes context.occurrences, item
  end
end
