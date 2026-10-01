# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/records"
require_relative "../src/ph_composer/features/windows/units/occurrences"

class WindowUnitRecordsTest < PhComposerTestCase
  U = PhComposer::Windows::Units

  def record
    { "id" => "wun_AAAAAAAAAAAA", "schema_version" => 1, "window_type_id" => "wnt_AAAAAAAAAAAA",
      "anchor" => "sill_center", "user_data" => { "tags" => ["synthetic"] },
      "extension_data" => { "outside.example" => { "version" => 1, "payload" => [2] } } }
  end

  def add_unit(entities = Sketchup.active_model.entities)
    definition = Sketchup::ComponentDefinition.new
    unit = entities.add_instance(definition, Geom::Transformation.new)
    U.write(unit, record)
    unit
  end

  def test_entity_round_trip_preserves_structured_metadata_and_read_is_detached
    unit = add_unit
    assert_equal record, U.read(unit)
    U.read(unit).fetch("user_data").fetch("tags") << "changed"
    assert_equal record, U.read(unit)
    assert_equal [PhComposer::Windows::TYPE_KIND, record.fetch("window_type_id")],
      [U::RECORD_KIND.references.first.target_kind, U::RECORD_KIND.references.first.ids(record).first]
  end

  def test_invalid_anchor_version_metadata_and_entity_kind_refuse_before_write
    unit = add_unit
    [{ "anchor" => "invented" }, { "schema_version" => 2 }, { "user_data" => [] },
     { "window_type_id" => nil }].each do |patch|
      assert_raises(PhComposer::CodedError) { U.write(unit, record.merge(patch)) }
      assert_equal record, U.read(unit)
    end
    assert_raises(PhComposer::CodedError) { U.write(Sketchup.active_model.entities.add_group, record) }
  end

  def test_orphan_copies_keep_distinct_occurrences_without_identity_repair
    first = add_unit
    second = add_unit
    model = Sketchup.active_model
    before = [U.read(first), U.read(second)]
    entries = U::TARGET.entries(model)
    assert_equal [[first.persistent_id], [second.persistent_id]], entries.map(&:key)
    assert_equal [record.fetch("id")], entries.map { |entry| entry.record.fetch("id") }.uniq
    assert_equal before, [U.read(first), U.read(second)]
    assert_equal second, U::Occurrences.resolve(model,
      { "unit_id" => record.fetch("id"), "entity_path" => [second.persistent_id] }).entity
  end

  def test_shared_parent_storage_is_readable_but_not_mutable
    model = Sketchup.active_model
    definition = Sketchup::ComponentDefinition.new
    child = add_unit(definition.entities)
    parents = 2.times.map { model.entities.add_instance(definition, Geom::Transformation.new) }
    occurrences = U::Occurrences.all(model)
    assert_equal parents.map { |parent| [parent.persistent_id, child.persistent_id] }, occurrences.map(&:path)
    occurrences.each do |item|
      assert item.shared_storage
      assert_equal child, U::Occurrences.resolve(model, item.reference).entity
      error = assert_raises(PhComposer::CodedError) { U::Occurrences.resolve(model, item.reference, :mutable => true) }
      assert_equal "target.shared_definition", error.code
    end
  end

  def test_stale_identity_and_missing_path_are_refused
    unit = add_unit
    reference = U::Occurrences.all(Sketchup.active_model).first.reference
    U.write(unit, record.merge("id" => "wun_BBBBBBBBBBBB"))
    error = assert_raises(PhComposer::CodedError) { U::Occurrences.resolve(Sketchup.active_model, reference) }
    assert_equal "target.changed", error.code
    error = assert_raises(PhComposer::CodedError) do
      U::Occurrences.resolve(Sketchup.active_model, reference.merge("entity_path" => [999999]))
    end
    assert_equal "target.not_found", error.code
  end

  def test_locked_ancestor_refuses_mutation_and_nested_unit_references_remain_visible
    model = Sketchup.active_model
    group = model.entities.add_group
    parent = add_unit(group.entities)
    child = add_unit(parent.definition.entities)
    group.locked = true
    items = U::Occurrences.all(model)
    assert_equal [parent, child], items.map(&:entity)
    assert items.all?(&:locked)
    error = assert_raises(PhComposer::CodedError) do
      U::Occurrences.resolve(model, items.first.reference, :mutable => true)
    end
    assert_equal "target.locked", error.code
    assert items.last.shared_storage
  end

  def test_json_null_stamp_is_invalid_rather_than_an_absent_unit
    unit = add_unit
    unit.set_attribute(U::STORE.dictionary, U::STORE.key, "null")
    assert_raises(PhComposer::CodedError) { U.read(unit) }
    assert_raises(PhComposer::CodedError) { U::TARGET.entries(Sketchup.active_model) }
  end
end
