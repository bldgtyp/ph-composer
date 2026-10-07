# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "support/assembly_assignment_fixtures"

class WindowTypeRetargeterTest < PhComposerTestCase
  include WindowRecordFixtures
  include AssemblyAssignmentFixtures

  U = PhComposer::Windows::Units
  PREFIX = "ph_composer.windows.types"

  def setup
    super
    assignment_setup
    PhComposer::Registry.install([W]) unless PhComposer::Registry.installed?(W::FEATURE_ID)
    @source = window_record("columns_m" => [1.0], "rows_m" => [1.0])
    @target = window_record("name" => "Replacement", "columns_m" => [1.2]).merge("id" => "wnt_BBBBBBBBBBBB")
    [@source, @target].each { |type| W::Types::KIND.store.write(@model, type) }
    @definition = U::DefinitionWriter.create(:model => @model, :type => @source,
                                             :plan => U::DefinitionPlan.build(@source))
    U::DefinitionIndex.write(@model, { @source.fetch("id") => @definition.persistent_id }, :expected => {})
  end

  def unit(x = 0, record: nil, entities: @model.entities)
    entity = entities.add_instance(@definition, Geom::Transformation.translation([x / 0.0254, 0, 0]))
    U.write(entity, record || { "id" => window_allocator.call("wun"), "schema_version" => 1,
                                "window_type_id" => @source.fetch("id"), "anchor" => "center",
                                "user_data" => { "literal" => ["keep"] } })
    entity
  end

  def params(replacement = @target.fetch("id"))
    { "id" => @source.fetch("id"), "expected_values" => W::Types::KIND.values(@source),
      "replacement_id" => replacement }
  end

  def capture
    { "native" => U::MutationScope.new.capture(@model),
      "types" => W::Types::KIND.store.ids(@model).to_h { |id| [id, W::Types::KIND.store.read(@model, id)] } }
  end

  def test_registered_replacement_covers_orphans_repairs_copies_and_is_one_exact_undo_redo
    first = unit
    group = @model.entities.add_group
    unit(4, :record => U.read(first), :entities => group.entities)
    before = capture
    preview = API.preview(:context => @context, :name => "#{PREFIX}.delete", :params => params)
    assert_equal "ok", preview.fetch("code"), preview.inspect
    assert_equal before, capture
    operations = @model.operation_starts.length
    result = assignment_invoke("#{PREFIX}.delete", params, preview.fetch("proposal_digest"))
    assert_equal "completed", result.fetch("status"), result.inspect
    rows = U::Occurrences.all(@model)
    assert_equal 2, rows.length
    assert_equal 2, rows.map { |row| row.record.fetch("id") }.uniq.length
    assert rows.all? { |row| row.record.fetch("window_type_id") == @target.fetch("id") }
    assert rows.all? { |row| row.record.fetch("user_data") == { "literal" => ["keep"] } }
    assert_equal [@target.fetch("id")], U::DefinitionIndex.read(@model).keys
    assert_equal 1, @model.definitions.length
    refute_includes W::Types::KIND.store.ids(@model), @source.fetch("id")
    assert_equal operations + 1, @model.operation_starts.length
    after = capture
    assert @model.undo
    assert_equal before, capture
    assert @model.redo
    assert_equal after, capture
  end

  def test_explicit_null_removes_all_occurrences_with_original_preimages_after_identity_repair
    first = unit
    unit(4, :record => U.read(first))
    before = capture
    preview = API.preview(:context => @context, :name => "#{PREFIX}.delete", :params => params(nil))
    assert_equal "ok", preview.fetch("code"), preview.inspect
    assert_equal before, capture
    result = assignment_invoke("#{PREFIX}.delete", params(nil), preview.fetch("proposal_digest"))
    assert_equal "completed", result.fetch("status"), result.inspect
    assert_empty U::Occurrences.all(@model)
    assert_empty U::DefinitionIndex.read(@model)
    assert_empty @model.definitions.to_a
    after = capture
    assert @model.undo
    assert_equal before, capture
    assert @model.redo
    assert_equal after, capture
  end

  def test_unmanaged_native_instances_retain_definition_while_primary_pointer_is_cleared
    unit
    unmanaged = @model.entities.add_instance(@definition, Geom::Transformation.translation([400, 0, 0]))
    result = assignment_invoke("#{PREFIX}.delete", params(nil))
    assert_equal "completed", result.fetch("status"), result.inspect
    assert_includes @model.entities.to_a, unmanaged
    assert_includes @model.definitions.to_a, @definition
    assert_empty U::DefinitionIndex.read(@model)
    assert_nil U.read(unmanaged)
  end

  def test_omitted_replacement_refuses_used_type_without_identity_or_native_writes
    first = unit
    unit(4, :record => U.read(first))
    before = capture
    result = assignment_invoke("#{PREFIX}.delete", params.reject { |key, _| key == "replacement_id" })
    assert_equal "reference.in_use", result.fetch("code"), result.inspect
    assert_equal before, capture
  end

  def test_locked_orphan_and_overlap_refuse_the_whole_delete_before_writes
    entity = unit
    entity.locked = true
    before = capture
    refused = assignment_invoke("#{PREFIX}.delete", params(nil))
    assert_equal "target.locked", refused.fetch("code"), refused.inspect
    assert_equal before, capture
    entity.locked = false
    unit(1.1)
    before = capture
    refused = assignment_invoke("#{PREFIX}.delete", params)
    assert_equal "window.overlap", refused.fetch("code"), refused.inspect
    assert_equal before, capture
  end

  def test_surviving_typed_unit_reference_blocks_removal_but_allows_replacement
    entity = unit
    extension = PhComposer::Records::Extension.new(:namespace => "outside.unit_link", :schema_version => 1,
                                                   :references => [{ "path" => "$.unit",
                                                                     "target_kind" => U::REFERENCE_KIND,
                                                                     "cardinality" => "one" }])
    @target["extension_data"] = { extension.namespace => extension.envelope("unit" => U.read(entity).fetch("id")) }
    W::Types::KIND.store.write(@model, @target)
    before = capture
    result = assignment_invoke("#{PREFIX}.delete", params(nil))
    assert_equal "reference.in_use", result.fetch("code"), result.inspect
    assert_equal before, capture
    result = assignment_invoke("#{PREFIX}.delete", params)
    assert_equal "completed", result.fetch("status"), result.inspect
    assert_equal @target.fetch("extension_data"),
                 W::Types::KIND.store.read(@model, @target.fetch("id"))["extension_data"]
    assert_equal U.read(entity).fetch("id"), @target.dig("extension_data", extension.namespace, "payload", "unit")
  end

  def test_unmanaged_users_inside_unused_definitions_preserve_primary_and_detached_definitions
    unit
    unused = @model.definitions.add("Unused containing definition")
    unmanaged = unused.entities.add_instance(@definition, Geom::Transformation.new)
    detached = U::DefinitionWriter.create(:model => @model, :type => @source,
                                          :plan => U::DefinitionPlan.build(@source))
    result = assignment_invoke("#{PREFIX}.delete", params(nil))
    assert_equal "completed", result.fetch("status"), result.inspect
    assert_includes @model.definitions.to_a, @definition
    assert_includes @model.definitions.to_a, detached
    assert_includes unused.entities.to_a, unmanaged
    assert_empty U::DefinitionIndex.read(@model)
  end

  def test_cleanup_refuses_unplanned_index_or_definition_drift_before_writes
    step = U::TypeCleanupStep.new(:model => @model, :type_id => @source.fetch("id"))
    @definition.name = "Drift"
    before = capture
    error = assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    assert_equal "target.changed", error.code
    assert_equal before, capture
    @definition.name = "PhComposer_Window_#{@source.fetch('name')}"
    step = U::TypeCleanupStep.new(:model => @model, :type_id => @source.fetch("id"))
    target = U::DefinitionWriter.create(:model => @model, :type => @target, :plan => U::DefinitionPlan.build(@target))
    current = U::DefinitionIndex.read(@model)
    U::DefinitionIndex.write(@model, current.merge(@target.fetch("id") => target.persistent_id), :expected => current)
    before = capture
    error = assert_raises(PhComposer::CodedError) { step.apply(@model, {}) }
    assert_equal "target.changed", error.code
    assert_equal before, capture
  end

  def test_active_deleted_definition_refuses_before_removal_and_catalog_deletion
    entity = unit
    @model.active_path = [entity]
    before = capture
    result = assignment_invoke("#{PREFIX}.delete", params(nil))
    assert_equal "window.definition_editing", result.fetch("code"), result.inspect
    assert_equal before, capture
  end

  def test_unused_type_omitting_replacement_releases_primary_in_one_exact_undo_redo
    before = capture
    result = assignment_invoke("#{PREFIX}.delete", params.reject { |key, _| key == "replacement_id" })
    assert_equal "completed", result.fetch("status"), result.inspect
    assert_empty U::DefinitionIndex.read(@model)
    assert_empty @model.definitions.to_a
    refute_includes W::Types::KIND.store.ids(@model), @source.fetch("id")
    after = capture
    assert @model.undo
    assert_equal before, capture
    assert @model.redo
    assert_equal after, capture
  end

  def test_unused_type_omitting_replacement_preserves_unmanaged_definition_users
    entity = @model.entities.add_instance(@definition, Geom::Transformation.new)
    before = capture
    result = assignment_invoke("#{PREFIX}.delete", params.reject { |key, _| key == "replacement_id" })
    assert_equal "completed", result.fetch("status"), result.inspect
    assert_empty U::DefinitionIndex.read(@model)
    assert_includes @model.entities.to_a, entity
    assert_includes @model.definitions.to_a, @definition
    assert_nil U.read(entity)
    after = capture
    assert @model.undo
    assert_equal before, capture
    assert @model.redo
    assert_equal after, capture
  end

  def test_explicit_null_removes_glued_orphan_without_adopting_a_zone
    face = @model.entities.add_face([Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(100, 0, 0),
                                     Geom::Point3d.new(100, 100, 0)])
    entity = unit
    entity.glued_to = face
    result = assignment_invoke("#{PREFIX}.delete", params(nil))
    assert_equal "completed", result.fetch("status"), result.inspect
    assert_equal [face], @model.entities.to_a
    assert_empty U::Occurrences.all(@model)
  end

  def test_reference_between_removed_units_is_evaluated_against_the_complete_removal_plan
    first = unit
    second = unit(4)
    extension = PhComposer::Records::Extension.new(:namespace => "outside.peer", :schema_version => 1,
                                                   :references => [{ "path" => "$.peer",
                                                                     "target_kind" => U::REFERENCE_KIND,
                                                                     "cardinality" => "one" }])
    U.write(second, U.read(second).merge("extension_data" => {
      extension.namespace => extension.envelope("peer" => U.read(first).fetch("id"))
    }))
    result = assignment_invoke("#{PREFIX}.delete", params(nil))
    assert_equal "completed", result.fetch("status"), result.inspect
    assert_empty U::Occurrences.all(@model)
    assert_empty U::DefinitionIndex.read(@model)
  end

  def test_replacement_of_glued_orphan_without_public_host_refuses_atomically
    face = @model.entities.add_face([Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(100, 0, 0),
                                     Geom::Point3d.new(100, 100, 0)])
    unit.glued_to = face
    before = capture
    result = API.preview(:context => @context, :name => "#{PREFIX}.delete", :params => params)
    assert_equal "window.host_required", result.fetch("code"), result.inspect
    assert_equal before, capture
  end

  def test_definition_removal_failure_aborts_catalog_units_and_index_together
    unit
    before = capture
    original = Sketchup::DefinitionList.instance_method(:remove)
    Sketchup::DefinitionList.define_method(:remove) { |_definition| false }
    result = assignment_invoke("#{PREFIX}.delete", params(nil))
    assert_equal "operation.failed", result.fetch("code"), result.inspect
    assert_equal "geometry.failed", result.dig("detail", "cause")
    assert_equal "rolled_back", result.fetch("effect")
    assert_equal before, capture
  ensure
    Sketchup::DefinitionList.define_method(:remove, original) if original
  end
end
