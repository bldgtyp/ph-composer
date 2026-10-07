# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/swap_step"
require_relative "../src/ph_composer/features/windows/units/identity_step"

class WindowUnitSwapStepTest < PhComposerTestCase
  include WindowRecordFixtures

  U = PhComposer::Windows::Units
  P = PhComposer::Windows::Placement

  def setup
    super
    @model = Sketchup.active_model
    @source = window_record("columns_m" => [1.0], "rows_m" => [1.5])
    @target = window_record("name" => "Target", "columns_m" => [1.2], "rows_m" => [1.8]).merge(
      "id" => "wnt_BBBBBBBBBBBB"
    )
    [@source, @target].each { |type| W::Types::KIND.store.write(@model, type) }
    @definition = U::DefinitionWriter.create(:model => @model, :type => @source,
                                             :plan => U::DefinitionPlan.build(@source))
    U::DefinitionIndex.write(@model, { @source.fetch("id") => @definition.persistent_id }, :expected => {})
  end

  def unit(anchor = "sill_center", x: 0, definition: @definition, entities: @model.entities)
    item = entities.add_instance(definition, Geom::Transformation.translation([x / 0.0254, 0, 0]))
    U.write(item,
            "id" => window_allocator.call("wun"), "schema_version" => 1,
            "window_type_id" => @source.fetch("id"), "anchor" => anchor,
            "user_data" => { "literal" => [@source.fetch("id"), "unchanged"] },
            "extension_data" => { "outside.fixture" => { "version" => 1, "payload" => { "literal" => "preserved" } } })
    item
  end

  def item_for(item, expected: U.read(item), host: nil, other: [])
    occurrence = U::Occurrences.all(@model).find { |row| row.entity.equal?(item) }
    { :reference => occurrence.reference, :expected_record => expected, :from_type => @source,
      :host => host, :other_polygons_m => other }
  end

  def step(items, **options)
    U::SwapStep.new(:model => @model, :target_type => @target, :items => items, **options)
  end

  def test_three_anchors_share_one_new_definition_and_undo_redo_restore_exact_state
    units = %w[sill_left center head_right].each_with_index.map { |anchor, i| unit(anchor, :x => i * 3) }
    items = units.map { |item| item_for(item) }
    old_plan = U::DefinitionPlan.build(@source)
    old = U::Occurrences.all(@model).to_h do |row|
      [row.path, [row.record, U::WorldGeometry.anchor(old_plan, row.record.fetch("anchor"), row.transform.to_a)]]
    end
    before = capture
    swap = step(items)
    assert_equal before, capture
    @model.start_operation("Swap Window Type")
    swap.apply(@model, {})
    @model.commit_operation
    assert_equal 2, @model.definitions.length
    canonical = U::DefinitionIndex.resolve(@model, @target.fetch("id"))
    plan = U::DefinitionPlan.build(@target)
    U::Occurrences.all(@model).each do |row|
      assert_same canonical, row.entity.definition
      assert_equal old.fetch(row.path).first.merge("window_type_id" => @target.fetch("id")), row.record
      point = U::WorldGeometry.anchor(plan, row.record.fetch("anchor"), row.transform.to_a)
      point.zip(old.fetch(row.path).last).each { |a, b| assert_in_delta b, a, 1e-12 }
    end
    assert_equal units.map(&:persistent_id).sort,
                 swap.affected.map { |row| row.fetch("reference").fetch("entity_path").last }.sort
    after = capture
    assert @model.undo
    assert_equal before, capture
    assert @model.redo
    assert_equal after, capture
    assert_equal 1, @model.operation_starts.length
  end

  def test_existing_valid_canonical_target_is_reused_without_geometry_or_material_writes
    canonical = target_definition
    face = canonical.entities.first
    glass = @model.materials.first
    item = unit
    step([item_for(item)]).apply(@model, {})
    assert_same canonical, item.definition
    assert_same face, canonical.entities.first
    assert_same glass, @model.materials.first
    assert_equal 2, @model.definitions.length
  end

  def test_swap_to_the_same_canonical_type_is_a_native_noop
    @target = @source
    item = unit
    swap = step([item_for(item)])
    before = capture
    refute swap.needed?
    assert_empty swap.affected
    swap.apply(@model, {})
    assert_equal before, capture
    assert_empty @model.operation_starts
  end

  def test_explicit_swap_of_detached_source_uses_authored_source_dimensions_and_preserves_metadata
    detached = U::DefinitionWriter.create(:model => @model, :type => @source,
                                          :plan => U::DefinitionPlan.build(@source))
    item = unit("center", :x => 2, :definition => detached)
    face = detached.entities.first
    detached.entities.first.transform!(Geom::Transformation.scaling(1.5))
    record = U.read(item)
    before = U::WorldGeometry.anchor(U::DefinitionPlan.build(@source), "center", item.transformation.to_a)
    step([item_for(item)]).apply(@model, {})
    after = U::WorldGeometry.anchor(U::DefinitionPlan.build(@target), "center", item.transformation.to_a)
    before.zip(after).each { |a, b| assert_in_delta a, b, 1e-12 }
    assert_equal record.merge("window_type_id" => @target.fetch("id")), U.read(item)
    assert_same face, detached.entities.first
    refute_same detached, item.definition
  end

  def test_unknown_source_type_and_duplicate_batch_paths_refuse_without_writes
    item = unit
    values = item_for(item)
    before = capture
    assert_equal "window.unknown_type", refusal { step([values.merge(:from_type => nil)]) }
    W::Types::KIND.store.delete(@model, @source.fetch("id"))
    assert_equal "window.unknown_type", refusal { step([values]) }
    W::Types::KIND.store.write(@model, @source)
    assert_equal "params.invalid", refusal { step([values, values]) }
    assert_equal before, capture
  end

  def test_missing_source_type_uses_generated_full_rectangle_including_empty_regions
    @source.fetch("elements").first["kind"] = "empty"
    U::DefinitionWriter.rewrite(:model => @model, :definition => @definition, :type => @source,
                                :plan => U::DefinitionPlan.build(@source))
    W::Types::KIND.store.delete(@model, @source.fetch("id"))
    items = %w[sill_right center head_left].each_with_index.map do |anchor, i|
      item = unit(anchor, :x => i * 3)
      item_for(item).merge(:from_type => nil)
    end
    old_plan = U::DefinitionPlan.build(@source)
    before = U::Occurrences.all(@model).to_h do |item|
      [item.path, U::WorldGeometry.anchor(old_plan, item.record.fetch("anchor"), item.transform.to_a)]
    end
    assert_empty @definition.entities.to_a
    swap = step(items)
    assert_equal [@source.fetch("id")], swap.descriptor.fetch("missing_source_types")
    swap.apply(@model, {})
    U::Occurrences.all(@model).each do |item|
      actual = U::WorldGeometry.anchor(U::DefinitionPlan.build(@target), item.record.fetch("anchor"),
                                       item.transform.to_a)
      actual.zip(before.fetch(item.path)).each { |a, b| assert_in_delta b, a, 1e-12 }
      assert_equal @target.fetch("id"), item.record.fetch("window_type_id")
    end
  end

  def test_missing_source_type_without_generated_dimensions_refuses_without_bounds_inference
    item = unit
    W::Types::KIND.store.delete(@model, @source.fetch("id"))
    U::DEFINITION_STORE.write(@definition, "window_type_id" => @source.fetch("id"))
    before = capture
    assert_equal "window.type_geometry_unknown", refusal { step([item_for(item).merge(:from_type => nil)]) }
    assert_equal before, capture
    assert_equal 1, @model.definitions.length
  end

  def test_json_null_type_row_does_not_count_as_an_absent_source_type
    item = unit
    @model.attribute_dictionary(W::Types::KIND.store.dictionary)[@source.fetch("id")] = "null"
    assert_equal "window.unknown_type", refusal { step([item_for(item).merge(:from_type => nil)]) }
    assert_equal 1, @model.definitions.length
  end

  def test_reappeared_source_type_or_changed_generated_dimensions_refuses_before_swap
    item = unit
    W::Types::KIND.store.delete(@model, @source.fetch("id"))
    swap = step([item_for(item).merge(:from_type => nil)])
    W::Types::KIND.store.write(@model, @source)
    before = capture
    assert_equal "target.changed", refusal { swap.apply(@model, {}) }
    assert_equal before, capture
    W::Types::KIND.store.delete(@model, @source.fetch("id"))
    stamp = U::DEFINITION_STORE.read(@definition)
    U::DEFINITION_STORE.write(@definition, stamp.merge("generated_size_m" => { "width_m" => 2.0, "height_m" => 3.0 }))
    before = capture
    assert_equal "target.changed", refusal { swap.apply(@model, {}) }
    assert_equal before, capture
  end

  def test_edited_target_geometry_behavior_and_active_edit_context_refuse_without_adoption
    canonical = target_definition
    item = unit
    canonical.entities.first.reverse!
    assert_equal "window.definition_changed", refusal { step([item_for(item)]) }
    canonical.entities.first.reverse!
    canonical.behavior.no_scale_mask = 0
    assert_equal "window.definition_changed", refusal { step([item_for(item)]) }
    canonical.behavior.no_scale_mask = 127
    target_instance = @model.entities.add_instance(canonical, Geom::Transformation.new)
    @model.active_path = [target_instance]
    assert_equal "window.definition_editing", refusal { step([item_for(item)]) }
    assert_equal @source.fetch("id"), U.read(item).fetch("window_type_id")
  end

  def test_stale_type_definition_matrix_record_and_glue_refuse_before_writes
    item = unit
    mutations = [-> { W::Types::KIND.store.write(@model, @target.merge("notes" => "changed")) },
                 -> { W::Types::KIND.store.write(@model, @source.merge("notes" => "changed")) },
                 -> { @definition.entities.first.reverse! },
                 -> { item.transformation = Geom::Transformation.translation([1, 0, 0]) },
                 -> { U.write(item, U.read(item).merge("user_data" => { "literal" => "changed" })) },
                 -> { item.glued_to = host_face }]
    mutations.each do |mutate|
      swap = step([item_for(item)])
      @model.start_operation("Drift")
      mutate.call
      after_drift = capture
      assert_equal "target.changed", refusal { swap.apply(@model, {}) }
      assert_equal after_drift, capture
      @model.abort_operation
      @definition = @model.definitions.first
      item = @model.entities.grep(Sketchup::ComponentInstance).first
    end
  end

  def test_preceding_identity_step_and_swap_are_one_atomic_undo
    first = unit("head_left")
    copy = unit("center", :x => 3)
    U.write(copy, U.read(first).merge("anchor" => "center", "extension_data" => {}))
    before = capture
    updates = U::IdentityPlan.build(U::Occurrences.all(@model), :identity => window_allocator)
    expected = updates.to_h { |update| [update.reference.fetch("entity_path"), update.after] }
    items = [item_for(first), item_for(copy, :expected => updates.first.after)]
    swap = step(items, :expected_records => expected)
    @model.start_operation("Repair and swap")
    U::IdentityStep.new(updates).apply(@model, {})
    swap.apply(@model, {})
    @model.commit_operation
    refute_equal U.read(first).fetch("id"), U.read(copy).fetch("id")
    assert_equal [@target.fetch("id")], U::Occurrences.all(@model).map { |row| row.record["window_type_id"] }.uniq
    after = capture
    assert @model.undo
    assert_equal before, capture
    assert @model.redo
    assert_equal after, capture
  end

  def test_glued_batch_and_unglued_neighbor_overlap_are_checked_before_definition_creation
    glued = unit("head_left")
    neighbor = unit("head_left", :x => 1.1)
    glued.glued_to = host_face
    before = capture
    code = refusal do
      step([item_for(glued, :host => host_for(glued)), item_for(neighbor)])
    end
    assert_equal "window.overlap", code
    assert_equal before, capture
    glued.glued_to = nil
    assert_equal "window.overlap", refusal { step([item_for(glued), item_for(neighbor)]) }
  end

  def test_glued_host_required_and_containment_holes_other_outlines_refuse
    item = unit("head_left")
    item.glued_to = host_face(1.05)
    assert_equal "window.host_required", refusal { step([item_for(item)]) }
    assert_equal "window.overhang", refusal { step([item_for(item, :host => host_for(item))]) }
    item.glued_to = host_face(4, :hole => [[1.1, -1, 0], [1.15, -1, 0], [1.15, -0.5, 0], [1.1, -0.5, 0]])
    assert_equal "window.overhang", refusal { step([item_for(item, :host => host_for(item))]) }
    item.glued_to = host_face
    other = [[1.1, -1, 0], [1.3, -1, 0], [1.3, -0.5, 0], [1.1, -0.5, 0]]
    assert_equal "window.overlap", refusal { step([item_for(item, :host => host_for(item), :other => [other])]) }
  end

  def test_glue_is_preserved_and_host_geometry_drift_is_guarded
    item = unit("head_left")
    item.glued_to = host_face
    face = item.glued_to
    swap = step([item_for(item, :host => host_for(item))])
    face.reverse!
    assert_equal "target.changed", refusal { swap.apply(@model, {}) }
    face.reverse!
    swap.apply(@model, {})
    assert_same face, item.glued_to
  end

  def test_projected_reference_entries_preserve_paths_and_all_metadata
    items = [unit("head_left"), unit("head_right", :x => 4)].map { |item| item_for(item) }
    swap = step(items)
    assert_equal items.map { |item| item.fetch(:reference).fetch("entity_path") }, swap.reference_entries.map(&:key)
    items.zip(swap.reference_entries).each do |item, entry|
      assert_equal U::REFERENCE_KIND, entry.kind
      assert_equal item.fetch(:expected_record).merge("window_type_id" => @target.fetch("id")), entry.record
    end
    entries = swap.reference_entries
    entries.first.record.fetch("user_data")["literal"] << "mutated"
    refute_includes swap.reference_plan.entries.first.record.fetch("user_data").fetch("literal"), "mutated"
  end

  def test_native_definition_or_glue_failure_can_abort_the_whole_batch_and_new_catalog_entry
    ["definition", "glue"].each do |mode|
      first = unit("head_left")
      second = unit("head_left", :x => 3)
      first.glued_to = second.glued_to = host_face
      swap = step([item_for(first, :host => host_for(first)), item_for(second, :host => host_for(second))])
      before = capture
      @model.start_operation("Failed swap")
      if mode == "definition"
        second.define_singleton_method(:definition=) { |_definition| nil }
      else
        second.define_singleton_method(:glued_to=) { |_face| @glued_to = nil }
      end
      assert_equal "geometry.failed", refusal { swap.apply(@model, {}) }
      @model.abort_operation
      assert_equal before, capture
      assert_nil U::DefinitionIndex.resolve(@model, @target.fetch("id"))
      @definition = @model.definitions.first
      @model.entities.to_a.grep(Sketchup::ComponentInstance).each { |item| @model.entities.delete(item) }
    end
  end

  private

  def capture
    U::MutationScope.new(:definition_ids => @model.definitions.map(&:persistent_id)).capture(@model)
  end

  def refusal
    assert_raises(PhComposer::CodedError) { yield }.code
  end

  def target_definition
    definition = U::DefinitionWriter.create(:model => @model, :type => @target,
                                            :plan => U::DefinitionPlan.build(@target))
    index = U::DefinitionIndex.read(@model)
    U::DefinitionIndex.write(@model, index.merge(@target.fetch("id") => definition.persistent_id), :expected => index)
    definition
  end

  def host_face(width = 8, hole: nil)
    loops = [[[0, 0, 0], [width, 0, 0], [width, -3, 0], [0, -3, 0]]]
    loops << hole if hole
    points = loops.map { |loop| loop.map { |point| Geom::Point3d.new(*point.map { |value| value / 0.0254 }) } }
    face = Sketchup::Face.new(Sketchup::Entities.allocate_persistent_id, {}, :points => points.first,
                                                                             :holes => points.drop(1))
    @model.entities << face
    face
  end

  def host_for(item)
    P::Host.new(:entity => item.glued_to, :parent_path => [], :transform => Geom::Transformation.new,
                :reference => {}, :values => {},
                :geometry => PhComposer::FaceGeometry.capture(item.glued_to, Geom::Transformation.new))
  end
end
