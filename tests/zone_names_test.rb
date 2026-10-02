# frozen_string_literal: true

require_relative "test_helper"

class ZoneNamesTest < PhComposerTestCase
  API = PhComposer::API
  ZONES = PhComposer::Zones

  class FailingNameGroup < Sketchup::Group
    attr_accessor :fail_restore

    def name=(value)
      raise IOError, "injected native-name failure" if fail_restore && value == "Original"

      super
    end
  end

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
    @group = zone_group(100, "Stored", "Original")
    @state = ZONES::Names.state(@session)
    @state.baseline
  end

  def test_native_name_projects_to_queries_faces_and_colour_by_without_record_writes
    record = ZONES::ZONE_STORE.read(@group)
    native_rename("North")

    assert_equal "North", zone_row.fetch("values").fetch("name")
    faces = API.query(:context => @context, :name => "ph_composer.zones.faces.list")
    assert_equal "North", faces.dig("value", "faces", 0, "zone_name")
    assert_equal "North", ZONES::ColourModes.entries(@model) { |value| [value["id"], value["name"]] }.first.label
    assert_equal record, ZONES::ZONE_STORE.read(@group)
    assert_equal 1, @model.operations.length
    refute @state.pending?
  end

  def test_export_uses_detached_native_name_and_preserves_metadata
    record = ZONES::ZONE_STORE.read(@group).merge("extension_data" => {})
    ZONES::ZONE_STORE.write(@group, record)
    snapshot = PhComposer::Export::GeometrySnapshot.capture(@model, :revision => @session.revision)
    native_rename("Changed later")
    entry = snapshot.entries.find { |row| row.kind == "group" }
    assert_equal "Original", entry.native_name

    section = ZONES::ExportProjection::SECTION
    extraction = PhComposer::Export::Collection.build(@model, :run_id => "names", :contributors => [section])
    exported = extraction.document.dig("sections", section, "records", 0)

    assert_equal "Changed later", exported.fetch("name")
    assert_equal({ "firm.note" => "keep" }, ZONES::ZONE_STORE.read(@group).fetch("user_data"))
    assert_equal "Stored", ZONES::ZONE_STORE.read(@group).fetch("name")
  end

  def test_update_compares_expected_effective_name_and_preserves_other_metadata
    native_rename("North")
    row = zone_row
    values = row.fetch("values")

    result = invoke("ph_composer.zones.update", "reference" => row.fetch("reference"),
                                                "expected_values" => values, "values" => values.merge("level" => "L1"))

    assert_equal "completed", result.fetch("status")
    stored = ZONES::ZONE_STORE.read(@group)
    assert_equal ["North", "L1"], stored.values_at("name", "level")
    assert_equal({ "firm.note" => "keep" }, stored.fetch("user_data"))
    assert_equal({ "test.opaque" => { "schema_version" => 1, "payload" => { "keep" => true } } },
                 stored.fetch("extension_data"))
  end

  def test_old_expected_name_refuses_even_with_current_revision
    row = zone_row
    native_rename("North")

    result = invoke("ph_composer.zones.update", "reference" => row.fetch("reference"),
                                                "expected_values" => row.fetch("values"), "values" => row.fetch("values"))

    assert_equal "target.changed", result.fetch("code")
    assert_equal "none", result.fetch("effect")
    assert_equal "North", @group.name
    assert_equal "Stored", ZONES::ZONE_STORE.read(@group).fetch("name")
  end

  def test_default_make_name_checks_native_names
    native_rename("Zone 1")
    second = Sketchup::Group.new(200)
    @model.entities << second

    result = invoke("ph_composer.zones.make", "parent_path" => [], "entity_ids" => [200])

    assert_equal "completed", result.fetch("status")
    assert_equal "Zone 2", second.name
  end

  def test_clear_restores_last_native_name_deferred_and_joins_one_undo_step
    native_rename("Latest")
    native_rename("")

    assert_equal "", @group.name
    assert @state.pending?
    assert_equal "busy", API.query(:context => @context, :name => "ph_composer.zones.list").fetch("status")
    @state.settle

    assert_equal "Latest", @group.name
    assert_equal "Stored", ZONES::ZONE_STORE.read(@group).fetch("name")
    refute @state.pending?
    assert_equal ["Restore Zone Name", true, false, true], @model.operation_starts.last
    assert @model.undo
    @state.settle
    assert_equal "Latest", current_group.name
    assert @model.undo
    @state.settle
    assert_equal "Original", current_group.name
    assert @model.redo
    @state.settle
    assert_equal "Latest", current_group.name
  end

  def test_rapid_valid_rename_then_clear_keeps_intermediate_name_before_timer_runs
    native_rename("Immediate")
    native_rename("")
    @state.settle

    assert_equal "Immediate", @group.name
  end

  # Synthetic clipboard-paste timing: an authored Group is added with its record and current name.
  # This does not model Group#copy, which does not clone the Zone dictionary on the proving host.
  def test_an_authored_clipboard_copy_is_observed_before_rapid_rename_and_clear
    copy = zone_group(200, "Stored", "Original")
    PhComposer::ModelOperation.perform(@model, "Rename copy") { copy.name = "Copy name" }
    PhComposer::ModelOperation.perform(@model, "Clear copy") { copy.name = "" }
    @state.settle

    assert_equal "Copy name", copy.name
    assert_equal "Original", @group.name
    assert_equal "Stored", ZONES::ZONE_STORE.read(copy).fetch("name")
  end

  def test_empty_name_in_an_opened_file_uses_stored_compatibility_fallback
    @state.detach
    @group.name = ""
    new_state = ZONES::Names::State.new(@session)
    new_state.baseline
    new_state.settle

    assert_equal "Stored", @group.name
    assert_equal "Stored", ZONES::Names.read(@group).fetch("name")
    new_state.detach
  end

  def test_failed_update_rolls_back_native_name_and_record_together
    row = zone_row
    values = row.fetch("values")
    failing = lambda do |_entity, _stamp|
      raise IOError, "injected membership write failure"
    end
    ZONES::STAMP_STORE.write(@group.entities.to_a.first, ZONES::Schema.stamp(ZONES::ZONE_STORE.read(@group)))

    result = ZONES::STAMP_STORE.stub(:write, failing) do
      invoke("ph_composer.zones.update", "reference" => row.fetch("reference"),
                                         "expected_values" => values, "values" => values.merge("name" => "Failed"))
    end

    assert_equal "rolled_back", result.fetch("effect")
    @state.settle
    assert_equal "Original", current_group.name
    assert_equal "Stored", ZONES::ZONE_STORE.read(current_group).fetch("name")
  end

  def test_detaching_stops_name_observation
    @state.detach
    @group.name = ""

    refute @state.pending?
  end

  def test_deleted_native_container_does_not_interrupt_session_cleanup
    @model.entities.define_singleton_method(:remove_observer) do |_observer|
      raise TypeError, "reference to deleted Entities"
    end
    @model.close

    assert_nil PhComposer::Sessions.find(@session.id)
    assert_empty @state.instance_variable_get(:@containers)
    assert_empty @state.instance_variable_get(:@groups)
    refute @state.pending?
  end

  def test_deleted_definition_container_is_pruned_without_interrupting_live_names
    @group.entities.define_singleton_method(:remove_observer) do |_observer|
      raise TypeError, "reference to deleted Entities"
    end
    @model.entities.delete(@group)
    @state.settle

    assert_equal [@model.entities], @state.instance_variable_get(:@containers)
    assert_empty @state.instance_variable_get(:@groups)
  end

  def test_observer_type_errors_other_than_deleted_entities_are_not_suppressed
    error = TypeError.new("wrong observer argument")
    @model.entities.stub(:remove_observer, ->(_observer) { raise error }) do
      assert_same error, assert_raises(TypeError) { @state.detach }
    end
  end

  def test_restoration_failure_closes_transparent_operation_without_aborting_the_source
    failing = FailingNameGroup.new(200, Sketchup::Entities.new, {}, :name => "Original")
    ZONES::ZONE_STORE.write(failing, ZONES::ZONE_STORE.read(@group).merge("id" => "zon_000000000200"))
    @model.entities << failing
    PhComposer::ModelOperation.perform(@model, "Clear name") { failing.name = "" }
    failing.fail_restore = true

    @state.settle

    assert @state.pending?
    assert_equal "", failing.name
    assert_equal ["Restore Zone Name", true, :committed], @model.operations.last
    refute @model.operations.any? { |_name, _disable, result| result == :aborted }
    assert @model.undo
    @state.settle
    restored = @model.entities.to_a.find { |group| group.persistent_id == 200 }
    assert_equal "Original", restored.name
    refute @state.pending?
  end

  def test_repeated_settlement_without_a_name_change_creates_no_operation
    @state.settle
    @state.settle

    assert_empty @model.operations
    refute @state.pending?
  end

  def test_native_name_does_not_repair_invalid_stored_schema_during_read
    record = ZONES::ZONE_STORE.read(@group)
    record.delete("name")
    ZONES::ZONE_STORE.write(@group, record)

    result = API.query(:context => @context, :name => "ph_composer.zones.list")

    assert_equal "validation.failed", result.fetch("code")
    refute ZONES::ZONE_STORE.read(@group).key?("name")
  end

  def test_last_valid_names_are_scoped_to_their_model_even_with_matching_entity_ids
    other_model = Sketchup::Model.new
    other_group = Sketchup::Group.new(100, Sketchup::Entities.new, {}, :name => "Other Model")
    ZONES::ZONE_STORE.write(other_group, ZONES::ZONE_STORE.read(@group))
    other_model.entities << other_group
    other_session = PhComposer::Sessions.for(other_model)
    other_state = ZONES::Names.state(other_session)
    other_state.baseline
    native_rename("Own Model")
    native_rename("")
    @state.settle

    assert_equal "Own Model", @group.name
    assert_equal "Other Model", other_group.name
    assert_empty other_model.operations
    other_state.detach
  end

  def test_deleted_group_is_pruned_before_any_restoration_write
    native_rename("")
    PhComposer::ModelOperation.perform(@model, "Erase Group") { @model.entities.delete(@group) }
    @state.settle

    assert_equal 2, @model.operations.length
    assert_empty @model.entities.to_a
    refute @state.pending?
  end

  private

  def native_rename(name)
    PhComposer::ModelOperation.perform(@model, "Native Rename") { @group.name = name }
  end

  def current_group
    @model.entities.to_a.find { |entity| entity.persistent_id == 100 }
  end

  def zone_row
    API.query(:context => @context, :name => "ph_composer.zones.list").dig("value", "zones", 0)
  end

  def invoke(name, params)
    @sequence += 1
    API.invoke(:context => @context, :name => name, :params => params,
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end

  def zone_group(id, stored_name, native_name)
    face = Sketchup::Face.new(id + 1)
    group = Sketchup::Group.new(id, Sketchup::Entities.new([face]), {}, :name => native_name)
    record = { "id" => "zon_#{id.to_s.rjust(12, '0')}", "schema_version" => 1, "name" => stored_name,
               "building_segment" => "Building", "level" => nil, "ground_depth_mm" => 0.0,
               "user_data" => { "firm.note" => "keep" },
               "extension_data" => { "test.opaque" => { "schema_version" => 1, "payload" => { "keep" => true } } } }
    ZONES::ZONE_STORE.write(group, record)
    ZONES::Faces::FACE_STORE.write(face, "id" => "fac_#{(id + 1).to_s.rjust(12, '0')}", "schema_version" => 1,
                                         "face_type" => "Wall", "boundary_condition" => "Outdoors")
    @model.entities << group
    group
  end
end
