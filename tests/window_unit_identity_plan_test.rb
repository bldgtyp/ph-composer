# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/records"
require_relative "../src/ph_composer/features/windows/units/occurrences"
require_relative "../src/ph_composer/features/windows/units/identity_plan"

class WindowUnitIdentityPlanTest < PhComposerTestCase
  include WindowRecordFixtures
  U = PhComposer::Windows::Units

  def occurrence(path, overrides = {})
    U::Occurrence.new(:path => path, :shared_storage => false, :locked => false,
      :record => { "id" => "wun_AAAAAAAAAAAA", "schema_version" => 1,
        "window_type_id" => "wnt_AAAAAAAAAAAA", "anchor" => "sill_center",
        "user_data" => { "note" => "wun_AAAAAAAAAAAA" },
        "extension_data" => {} })
      .tap { |item| overrides.each { |key, value| item.public_send("#{key}=", value) } }
  end

  def test_copy_reidentification_is_occurrence_specific_pure_and_preserves_metadata
    original = occurrence([10, 20])
    copy = occurrence([10, 30])
    before = PhComposer::DeepCopy.call([original.record, copy.record])
    updates = U::IdentityPlan.build([copy, original], :identity => ->(_prefix) { "wun_BBBBBBBBBBBB" })
    assert_equal 1, updates.length
    assert_equal copy.reference, updates.first.reference
    assert_equal copy.record.merge("id" => "wun_BBBBBBBBBBBB"), updates.first.after
    assert_equal before, [original.record, copy.record]
    updates.first.after.fetch("user_data")["note"] = "changed"
    assert_equal before, [original.record, copy.record]
  end

  def test_unique_id_does_not_allocate_or_write
    assert_empty U::IdentityPlan.build([occurrence([10])], :identity => ->(_prefix) { raise "Unexpected allocation" })
  end

  def test_shared_parent_aliases_and_locked_copy_refuse
    [[occurrence([10, 20]), occurrence([30, 20])],
     [occurrence([10]), occurrence([30], :shared_storage => true)],
     [occurrence([10]), occurrence([30], :locked => true)]].each do |items|
      assert_raises(PhComposer::CodedError) do
        U::IdentityPlan.build(items, :identity => ->(_prefix) { "wun_BBBBBBBBBBBB" })
      end
    end
  end

  def test_allocator_collision_or_invalid_identity_refuses
    items = [occurrence([10]), occurrence([20])]
    ["wun_AAAAAAAAAAAA", "invalid"].each do |id|
      assert_raises(PhComposer::CodedError) { U::IdentityPlan.build(items, :identity => ->(_prefix) { id }) }
    end
  end

  def test_unavailable_extension_copy_refuses_and_keeps_original_payloads
    items = [occurrence([10]), occurrence([20])]
    items.last.record["extension_data"] = { "outside" => { "schema_version" => 1, "payload" => {} } }
    before = PhComposer::DeepCopy.call(items.map(&:record))
    error = assert_raises(PhComposer::CodedError) do
      U::IdentityPlan.build(items, :identity => ->(_prefix) { "wun_BBBBBBBBBBBB" },
        :catalog => PhComposer::Registry.current.catalog,
        :engine => PhComposer::Records::Engine.new(Sketchup.active_model, PhComposer::Registry.current.catalog))
    end
    assert_equal "copy.rule_missing", error.code
    assert_equal before, items.map(&:record)
  end

  def test_installed_copy_local_unit_reference_remaps_and_shared_type_reference_stays
    references = [{ "path" => "$.self", "target_kind" => U::REFERENCE_KIND, "cardinality" => "one" },
                  { "path" => "$.type", "target_kind" => PhComposer::Windows::TYPE_KIND, "cardinality" => "one" }]
    extension = PhComposer::Records::Extension.new(:namespace => "test.window_copy", :schema_version => 1,
      :references => references)
    model = Sketchup.active_model
    type = window_record
    PhComposer::Windows::Types::KIND.store.write(model, type)
    payload = { "self" => "wun_AAAAAAAAAAAA", "type" => type.fetch("id") }
    data = { extension.namespace => extension.envelope(payload) }
    2.times do
      instance = model.entities.add_instance(Sketchup::ComponentDefinition.new, Geom::Transformation.new)
      U.write(instance, occurrence([1]).record.merge("extension_data" => data))
    end
    catalog = PhComposer::Records::Catalog.new(:kinds => [PhComposer::Windows::Types::KIND],
      :extensions => [extension], :reference_targets => [U::TARGET])
    engine = PhComposer::Records::Engine.new(model, catalog)
    updates = U::IdentityPlan.build(U::Occurrences.all(model), :identity => ->(_prefix) { "wun_BBBBBBBBBBBB" },
      :catalog => catalog, :engine => engine)
    copied = updates.first.after.dig("extension_data", extension.namespace, "payload")
    assert_equal({ "self" => "wun_BBBBBBBBBBBB", "type" => type.fetch("id") }, copied)
    assert_equal payload, data.dig(extension.namespace, "payload")
    assert U::Occurrences.all(model).all? { |item|
      item.record.dig("extension_data", extension.namespace) == data[extension.namespace] }
  end
end
