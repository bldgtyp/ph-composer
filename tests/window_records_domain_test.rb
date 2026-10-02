# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"

class WindowRecordsDomainTest < PhComposerTestCase
  include WindowRecordFixtures

  def test_thermal_proof_exact_and_missing_terms_are_withheld
    record, input = thermal_proof
    calc = W::Thermal.calculate(record, input, input.fetch("default_install_id"))
    assert_in_delta 6.92448, calc["h_construction_w_k"], 1e-10
    assert_in_delta 1.0134, calc["u_effective"], 1e-10
    assert_in_delta 0.9617333333333333, calc["u_w"], 1e-10
    assert calc["complete"]
    input["frames"]["left"]["uf_w_m2k"] = nil
    calc = W::Thermal.calculate(record, input, input.fetch("default_install_id"))
    assert_nil calc["u_w"]
    assert_nil calc["u_effective"]
    assert_in_delta 0.372, calc["h_install_w_k"], 1e-10
    refute calc["complete"]
    assert calc["elements"].all? { |element| !element["complete"] }
  end

  def test_shared_partial_and_empty_edges_preserve_construction_value
    record, input = thermal_proof
    top = record["elements"][0]
    top["column_span"] = [0, 1]
    record["elements"].delete_at(1)
    assert_equal [:perimeter, :perimeter, :shared, :perimeter], W::Grid.new(record).classify(top)
    calc = W::Thermal.calculate(record, input, input["default_install_id"])
    assert_in_delta 7.2, calc["area_m2"], 1e-10
    refute_nil calc["u_w"]
    record["elements"].last["kind"] = "empty"
    assert_equal :partial, W::Grid.new(record).classify(top)[2]
    calc = W::Thermal.calculate(record, input, input["default_install_id"])
    assert_nil calc["u_effective"]
    refute_nil calc["u_w"]
    assert_operator calc["empty_area_m2"], :>, 0
  end

  def test_edge_resolution_painted_default_zero_missing_and_partial
    cell = window_values["elements"].first
    cell["installs"]["left"] = "psi_painted"
    assert_equal [:assigned, "psi_painted"], W::EdgeResolution.resolve(cell, "left", :perimeter, "psi_default")
      .to_h.values_at(:source, :effective_id)
    assert_equal [:default, "psi_default"], W::EdgeResolution.resolve(cell, "right", :perimeter, "psi_default")
      .to_h.values_at(:source, :effective_id)
    assert_nil W::EdgeResolution.resolve(cell, "right", :perimeter, nil).effective_id
    assert_equal [:shared, nil], W::EdgeResolution.resolve(cell, "left", :shared, "psi_default")
      .to_h.values_at(:source, :effective_id)
    assert_equal [:partial, nil], W::EdgeResolution.resolve(cell, "left", :partial, "psi_default")
      .to_h.values_at(:source, :effective_id)
  end

  def test_grid_insert_merge_split_remove_and_flip_are_detached
    record = window_values
    original = PhComposer::DeepCopy.call(record)
    added = W::GridOperations.apply(record, "insert", { "axis" => "rows_m", "index" => 1, "value" => 1.5 },
      :identity => window_allocator)
    assert_equal original, record
    assert_equal 2, added["elements"].length
    merged = W::GridOperations.apply(added, "merge", { "ids" => added["elements"].map { |cell| cell["id"] } },
      :identity => window_allocator)
    assert_equal [0, 1], merged["elements"].first["row_span"]
    split = W::GridOperations.apply(merged, "split", { "element_id" => merged["elements"].first["id"] },
      :identity => window_allocator)
    assert_equal 2, split["elements"].length
    removed = W::GridOperations.apply(split, "remove", { "axis" => "rows_m", "index" => 0 },
      :identity => window_allocator)
    assert_equal [0, 0], removed["elements"].first["row_span"]
    assert_raises(PhComposer::CodedError) do
      W::GridOperations.apply(removed, "remove", { "axis" => "rows_m", "index" => 0 }, :identity => window_allocator)
    end
    removed["elements"][0]["operation"] = { "type" => "swing", "directions" => %w[left up] }
    flipped = W::GridOperations.apply(removed, "flip", {}, :identity => window_allocator)
    assert_equal %w[right up], flipped["elements"][0]["operation"]["directions"]
    assert_equal removed, W::GridOperations.apply(flipped, "flip", {}, :identity => window_allocator)
  end

  def test_insert_clear_only_new_shared_edges_and_merge_refuses_install_loss
    record = window_values
    cell = record["elements"].first
    cell["installs"].merge!("top" => "psi_top", "right" => "psi_right")
    added = W::GridOperations.apply(record, "insert", { "axis" => "rows_m", "index" => 0, "value" => 0.5 },
      :identity => window_allocator)
    original = added["elements"].find { |entry| entry["id"] == cell["id"] }
    assert_nil original["installs"]["top"]
    assert_equal "psi_right", original["installs"]["right"]
    assert_raises(PhComposer::CodedError) do
      W::GridOperations.apply(added, "merge", { "ids" => added["elements"].map { |entry| entry["id"] } },
        :identity => window_allocator)
    end
  end

  def test_installs_paint_apply_copy_guard_topology_and_shared_slots
    source = window_values
    added = W::GridOperations.apply(source, "insert", { "axis" => "columns_m", "index" => 1, "value" => 1 },
      :identity => window_allocator)
    painted = W::Installs.apply_all(added, "psi_test")
    assert_nil painted["elements"][0]["installs"]["right"]
    assert_equal "psi_test", painted["elements"][0]["installs"]["left"]
    assert_raises(PhComposer::CodedError) { W::Installs.paint(added, added["elements"][0]["id"], "right", "psi_test") }
    copy = W::Installs.copy(painted, added)
    assert_equal painted["elements"].map { |entry| entry["installs"] }, copy["elements"].map { |entry|
 entry["installs"] }
    assert_raises(PhComposer::CodedError) { W::Installs.copy(painted, source) }
    assert_empty W::Types::KIND.problems(copy.merge("id" => "wnt_AAAAAAAAAAAA", "schema_version" => 1))
  end
  def test_paste_installs_requires_matching_topology_and_empty_clears_all_assignments
    record = window_values
    added = W::GridOperations.apply(record, "insert", { "axis" => "columns_m", "index" => 1, "value" => 1 },
      :identity => window_allocator)
    added["elements"][0].merge!("glazing_id" => "glz_AAAAAAAAAAAA",
      "operation" => { "type" => "fixed", "directions" => [] })
    copied = W::GridOperations.apply(added, "paste", { "source_id" => added["elements"][0]["id"],
      "ids" => [added["elements"][1]["id"]] }, :identity => window_allocator)
    assert_equal "glz_AAAAAAAAAAAA", copied["elements"][1]["glazing_id"]
    copied["elements"][0]["installs"]["left"] = "psi_AAAAAAAAAAAA"
    assert_raises(PhComposer::CodedError) do
      W::GridOperations.apply(copied, "paste", { "source_id" => copied["elements"][0]["id"],
        "ids" => [copied["elements"][1]["id"]] }, :identity => window_allocator)
    end
    empty = W::GridOperations.apply(copied, "kind", { "ids" => [copied["elements"][0]["id"]], "kind" => "empty" },
      :identity => window_allocator)
    cell = empty["elements"][0]
    assert_nil cell["glazing_id"]
    assert_nil cell["operation"]
    assert cell["frames"].values.none?
    assert cell["installs"].values.none?
  end

  def test_frame_operation_mismatch_is_informational_and_missing_default_is_not_zero
    record, input = thermal_proof
    input["frames"].each_value { |frame| frame["operation"] = "swing" }
    calculated = W::Thermal.calculate(record, input, input.fetch("default_install_id"))
    assert calculated.fetch("complete")
    assert calculated.fetch("elements").first.fetch("findings").any? do |finding|
      finding.fetch("code") == "window_type.frame_operation_mismatch"
    end
    missing = W::Thermal.calculate(record, input, nil)
    assert_nil missing["u_effective"]
    refute_nil missing["u_w"]
    refute missing.fetch("complete")
  end

end
