# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/areas"

class WindowAreasTest < PhComposerTestCase
  include WindowRecordFixtures

  def setup
    super
    @face = { "zone_id" => "zon_a", "zone_path" => [10], "entity_path" => [20], "entity_id" => "fac_a" }
    @type = window_record("rows_m" => [1.0], "columns_m" => [1.0, 2.0])
    @type["elements"] = [W::Types.blank(0, 0, :identity => window_allocator),
      W::Types.blank(0, 1, :identity => window_allocator)]
    @type.fetch("elements").last["kind"] = "empty"
  end

  def test_glazed_opening_area_excludes_empty_and_counts_occurrences_not_ids
    result = measure([unit([10, 30]), unit([10, 31])])
    face = result.fetch("faces").first
    assert_equal 2, face.fetch("unit_count")
    assert_in_delta 2.0, face.fetch("glazed_area_m2"), 1e-9
    assert_in_delta 10.0, face.fetch("net_opaque_area_m2"), 1e-9
    assert_empty face.fetch("findings")
    assert_empty result.fetch("unhosted_units")
    # Thermal incompleteness does not make an authored opening area unavailable.
    assert_nil @type.fetch("elements").first["glazing_id"]
  end

  def test_native_uncertainty_withholds_area_instead_of_using_type_dimensions
    %w[detached_definition geometry_differs scaled sheared mirrored off_host overlapping unknown_type].each do |code|
      item = unit([10, 30])
      item["findings"] = [{ "code" => code }]
      face = measure([item]).fetch("faces").first
      assert_nil face.fetch("glazed_area_m2"), code
      assert_nil face.fetch("net_opaque_area_m2"), code
      assert_includes face.fetch("findings"), code
    end
  end

  def test_unknown_type_and_unhosted_occurrences_do_not_become_zero_area
    item = unit([10, 30])
    item["values"]["window_type_id"] = "wnt_unknown"
    face = measure([item]).fetch("faces").first
    assert_nil face.fetch("net_opaque_area_m2")
    assert_includes face.fetch("findings"), "unknown_type"
    item["host"] = nil
    result = measure([item])
    assert_equal [item.fetch("reference")], result.fetch("unhosted_units")
    assert_equal 12.0, result.fetch("faces").first.fetch("net_opaque_area_m2")
  end

  def test_host_matching_uses_occurrence_path_and_no_units_preserve_gross_area
    other = @face.merge("zone_path" => [11])
    rows = [{ "reference" => @face, "area_m2" => 12.0 }, { "reference" => other, "area_m2" => 8.0 }]
    result = W::Units::Areas.measure(rows, [unit([10, 30])], { @type.fetch("id") => @type })
    assert_equal [11.0, 8.0], result.fetch("faces").map { |row| row.fetch("net_opaque_area_m2") }
    assert_equal [1, 0], result.fetch("faces").map { |row| row.fetch("unit_count") }
  end

  def test_negative_net_area_is_unknown_and_reports_inconsistent_openings
    units = 13.times.map { |i| unit([10, 30 + i]) }
    row = measure(units).fetch("faces").first
    assert_nil row.fetch("net_opaque_area_m2")
    assert_includes row.fetch("findings"), "opening_area_exceeds_host"
  end

  def test_public_area_query_and_snapshot_are_declared_read_only_with_valid_contracts
    PhComposer::Registry.install([W]) unless PhComposer::Registry.installed?(W::FEATURE_ID)
    context = PhComposer::API.connect(:session_id => PhComposer::Sessions.current.id)
    before = Sketchup.active_model.operations.length
    result = PhComposer::API.query(:context => context, :name => W::Units::Areas::QUERY)
    assert_equal "ok", result.fetch("code"), result.inspect
    assert_equal({ "faces" => [], "unhosted_units" => [] }, result.fetch("value"))
    assert_equal before, Sketchup.active_model.operations.length
    registry = PhComposer::Registry.current
    query = registry.queries.fetch(W::Units::Areas::QUERY)
    assert_empty PhComposer::JsonSchema.validate(result.fetch("value"), query.result)
    refute_equal W::Units::Areas::QUERY, W::Units::Areas::SECTION
  end

  private

  def unit(path)
    { "reference" => { "unit_id" => "wun_same", "entity_path" => path },
      "values" => { "window_type_id" => @type.fetch("id") }, "host" => @face, "findings" => [] }
  end

  def measure(units)
    W::Units::Areas.measure([{ "reference" => @face, "area_m2" => 12.0 }], units, { @type.fetch("id") => @type })
  end
end
