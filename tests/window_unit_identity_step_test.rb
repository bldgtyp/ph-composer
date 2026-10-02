# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/identity_step"

class WindowUnitIdentityStepTest < PhComposerTestCase
  U = PhComposer::Windows::Units

  def seed
    model = Sketchup.active_model
    record = { "id" => "wun_AAAAAAAAAAAA", "schema_version" => 1, "window_type_id" => "wnt_AAAAAAAAAAAA",
               "anchor" => "sill_center", "user_data" => { "note" => ["preserve"] } }
    definition = model.definitions.add("Synthetic")
    2.times do
      unit = model.entities.add_instance(definition, Geom::Transformation.new)
      U.write(unit, record)
    end
    [model, U::Occurrences.all(model)]
  end

  def step(items)
    U::IdentityStep.new(U::IdentityPlan.build(items, :identity => ->(_prefix) { "wun_BBBBBBBBBBBB" }))
  end

  def test_copied_id_repair_is_one_enclosing_undo_and_retains_occurrence_metadata
    model, items = seed
    before = items.map(&:record)
    repair = step(items)
    model.start_operation("Synthetic Window edit", true)
    repair.apply(model, {})
    model.commit_operation
    assert_equal %w[wun_AAAAAAAAAAAA wun_BBBBBBBBBBBB], U::Occurrences.all(model).map { |item| item.record.fetch("id") }
    assert_equal before.map { |record| record.fetch("user_data") },
                 U::Occurrences.all(model).map { |item| item.record.fetch("user_data") }
    model.undo
    assert_equal before, U::Occurrences.all(model).map(&:record)
    model.redo
    assert_equal 2, U::Occurrences.all(model).map { |item| item.record.fetch("id") }.uniq.length
  end

  def test_stale_copied_record_is_refused_before_any_repair_write
    model, items = seed
    repair = step(items)
    copied = items.last
    U.write(copied.entity, copied.record.merge("anchor" => "head_left"))
    before = U::Occurrences.all(model).map(&:record)
    assert_raises(PhComposer::CodedError) { repair.apply(model, {}) }
    assert_equal before, U::Occurrences.all(model).map(&:record)
  end

  def test_step_descriptors_detach_input_and_report_repaired_reference
    _model, items = seed
    repair = step(items)
    description = repair.descriptor
    description.fetch("updates").first.fetch("after")["anchor"] = "head_left"
    assert_equal "sill_center", repair.descriptor.fetch("updates").first.fetch("after").fetch("anchor")
    assert_equal "wun_BBBBBBBBBBBB", repair.affected.first.dig("reference", "unit_id")
    assert_equal ["wun_BBBBBBBBBBBB"], repair.temporary_ids
  end
end
