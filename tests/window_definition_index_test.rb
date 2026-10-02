# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/records"
require_relative "../src/ph_composer/features/windows/units/definition_index"

class WindowDefinitionIndexTest < PhComposerTestCase
  U = PhComposer::Windows::Units
  INDEX = U::DefinitionIndex
  TYPE_ID = "wnt_AAAAAAAAAAAA"

  def definition(type_id = TYPE_ID)
    item = Sketchup.active_model.definitions.add("Synthetic")
    U::DEFINITION_STORE.write(item, "window_type_id" => type_id)
    item
  end

  def test_primary_pointer_ignores_names_and_same_type_stamped_copies
    model = Sketchup.active_model
    original = definition
    copy = definition
    INDEX.write(model, { TYPE_ID => original.persistent_id }, :expected => {})
    original.name = "Renamed"
    assert_same original, INDEX.resolve(model, TYPE_ID)
    refute_same copy, INDEX.resolve(model, TYPE_ID)
    INDEX.read(model).clear
    assert_equal({ TYPE_ID => original.persistent_id }, INDEX.read(model))
  end

  def test_missing_primary_never_silently_adopts_matching_copy
    model = Sketchup.active_model
    original = definition
    definition
    INDEX.write(model, { TYPE_ID => original.persistent_id }, :expected => {})
    model.definitions.remove(original)
    error = assert_raises(PhComposer::CodedError) { INDEX.resolve(model, TYPE_ID) }
    assert_equal "window.definition_missing", error.code
  end

  def test_stale_index_and_different_stamp_refuse_without_pointer_write
    model = Sketchup.active_model
    original = definition
    mapping = { TYPE_ID => original.persistent_id }
    INDEX.write(model, mapping, :expected => {})
    assert_raises(PhComposer::CodedError) { INDEX.write(model, {}, :expected => {}) }
    U::DEFINITION_STORE.write(original, "window_type_id" => "wnt_BBBBBBBBBBBB")
    assert_raises(PhComposer::CodedError) { INDEX.write(model, mapping, :expected => mapping) }
    assert_equal mapping, INDEX.read(model)
  end

  def test_index_and_definition_creation_share_enclosing_undo
    model = Sketchup.active_model
    model.start_operation("Synthetic Window definition", true)
    original = definition
    INDEX.write(model, { TYPE_ID => original.persistent_id }, :expected => {})
    model.commit_operation
    assert_same original, INDEX.resolve(model, TYPE_ID)
    model.undo
    assert_empty INDEX.read(model)
    assert_empty model.definitions.to_a
    model.redo
    assert_equal original.persistent_id, INDEX.resolve(model, TYPE_ID).persistent_id
  end

  def test_malformed_index_is_refused_and_absent_index_is_read_only
    model = Sketchup.active_model
    assert_nil INDEX.resolve(model, TYPE_ID)
    assert_nil model.get_attribute(INDEX::STORE.dictionary, INDEX::STORE.key)
    INDEX::STORE.write(model, "schema_version" => 2, "definitions" => {})
    assert_raises(PhComposer::CodedError) { INDEX.read(model) }
    model.set_attribute(INDEX::STORE.dictionary, INDEX::STORE.key, "null")
    assert_raises(PhComposer::CodedError) { INDEX.read(model) }
  end
end
