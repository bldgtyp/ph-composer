# frozen_string_literal: true

require_relative "test_helper"

# A Group inside a Zone that carries a Zone stamp is a nested authoring container
# (context/CONTRACTS.md, "Zones geometry rules"): its Faces are not the Zone's Faces.
# A feature requiring Zones that groups one Face of a Zone in its own step and has Zones stamp the Group.
module ContainerFixture
  ID = "test.container"
  OBJECT = { "type" => "object" }.freeze

  module_function

  def install(registry)
    feature = registry.feature(ID, :contract_version => 1, :requires => ["ph_composer.zones"])
    feature.action("#{ID}.make", :description => "Group one Zone Face and stamp the Group.", :params => OBJECT,
                                 :result => OBJECT, :undo_name => "Make container", :side_effects => "Groups a Face.",
                                 :refuses => [], :participants => ["ph_composer.zones.stamp_container"]) do |
                                   request, proposal|
      zone = request.params.fetch("zone")
      context = request.params.fetch("context_path", zone.fetch("zone_path"))
      proposal.add_step(GroupStep.new(context, request.params.fetch("face_id")),
                        :scopes => [PhComposer::Operations::EntityScope.new(context)])
      request.participate("ph_composer.zones.stamp_container", "zone" => zone, "slot" => "container")
    end
  end

  class GroupStep
    attr_reader :affected

    def initialize(zone_path, face_id)
      @zone_path = zone_path
      @face_id = face_id
      @affected = []
    end

    def descriptor
      { "name" => "test_group", "zone_path" => @zone_path, "face_id" => @face_id }
    end

    def apply(model, slots)
      entities = PhComposer::Operations::EntityScope.new(@zone_path).resolve(model)
      group = entities.add_group([entities.to_a.find { |entity| entity.persistent_id == @face_id }])
      slots["container"] = { "entity_path" => @zone_path + [group.persistent_id] }
    end
  end
end

class ZoneNestedContainerTest < PhComposerTestCase
  API = PhComposer::API
  Zones = PhComposer::Zones

  def setup
    super
    @model = Sketchup.active_model
    settings = Zones::Faces::Settings
    settings::STORE.write(@model, settings::DEFAULTS.merge("suggest_on_make" => false))
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
  end

  # Zone 100 holds wall 101, a plain Group 110 with Face 111, and a Group 120 with floor Face 121.
  def fixture
    @wall = Sketchup::Face.new(101)
    @plain = Sketchup::Group.new(110, Sketchup::Entities.new([Sketchup::Face.new(111)]))
    @floor = Sketchup::Face.new(121)
    @container = Sketchup::Group.new(120, Sketchup::Entities.new([@floor]))
    @zone_group = Sketchup::Group.new(100, Sketchup::Entities.new([@wall, @plain, @container]))
    @model.entities << @zone_group
    result = invoke("ph_composer.zones.make", "parent_path" => [], "entity_ids" => [100])
    assert_equal "completed", result["status"], result.inspect
    @zone = query("ph_composer.zones.list").dig("value", "zones", 0)
  end

  def stamp!(group, zone_id = nil)
    record = Zones::ZONE_STORE.read(@zone_group)
    record = record.merge("id" => zone_id) if zone_id
    Zones::STAMP_STORE.write(group, Zones::Schema.stamp(record))
  end

  def face_paths
    query("ph_composer.zones.faces.list").dig("value", "faces").map { |row| row.dig("reference", "entity_path") }
  end

  def test_a_stamped_group_is_left_out_of_the_face_list_suggest_and_the_index
    fixture
    assert_equal [[101], [110, 111], [120, 121]], face_paths
    stamp!(@container)
    assert_equal [[101], [110, 111]], face_paths
    assert_equal 2, query("ph_composer.zones.list").dig("value", "zones", 0, "face_count")
    zone = Zones::Occurrences.zones(@model).first
    assert_equal [[101], [110, 111]], Zones::Index.new(@model).faces(zone).map(&:path)
    result = invoke("ph_composer.zones.faces.auto_classify", "zone" => @zone.fetch("reference"))
    assert_equal "completed", result["status"], result.inspect
    assert_equal 2, result.dig("value", "classified")
    assert_nil Zones::Faces::FACE_STORE.read(@floor)
    Zones::STAMP_STORE.delete(@container)
    assert_includes face_paths, [120, 121]
  end

  def test_a_stamp_naming_another_zone_still_makes_a_container
    fixture
    stamp!(@container, "zon_OTHER0000001")
    assert_equal [[101], [110, 111]], face_paths
  end

  def test_containers_two_deep_and_under_a_rotated_wrapper_are_skipped
    rotation = Geom::Transformation.new([0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1])
    deep = Sketchup::Group.new(131, Sketchup::Entities.new([Sketchup::Face.new(132)]))
    wrapper = Sketchup::Group.new(130, Sketchup::Entities.new([deep]), :transformation => rotation)
    fixture
    @zone_group.entities << wrapper
    stamp!(@container)
    stamp!(deep)
    assert_equal [[101], [110, 111]], face_paths
    inner = Sketchup::Group.new(122, Sketchup::Entities.new([Sketchup::Face.new(123)]))
    @container.entities << inner
    assert_equal [[101], [110, 111]], face_paths
  end

  def test_an_explicit_path_or_pick_through_a_container_refuses_and_writes_nothing
    fixture
    stamp!(@container)
    reference = @zone.fetch("reference").merge("entity_path" => [120, 121], "entity_id" => nil)
    error = assert_raises(PhComposer::CodedError) do
      Zones::Occurrences.resolve_face(@model, reference, :allow_unassigned => true)
    end
    assert_equal "target.wrong_hierarchy", error.code
    result = invoke("ph_composer.zones.faces.classify",
                    "faces" => [reference], "expected_values" => {},
                    "intent" => { "face_type" => { "mode" => "set", "value" => "Floor" } })
    assert_equal %w[refused target.wrong_hierarchy none], result.values_at("status", "code", "effect")
    assert_nil Zones::Occurrences.occurrence_for_path([@zone_group, @container, @floor])
    tool = Zones::Faces.classify_tool(@session)
    tool.choose("face_type", "Floor")
    view = @model.active_view
    view.picks[[10, 10]] = [@zone_group, @container, @floor]
    before = @model.operations.length
    tool.onLButtonDown(CONSTRAIN_MODIFIER_MASK, 10, 10, view)
    tool.onLButtonUp(0, 10, 10, view)
    assert_equal before, @model.operations.length
    assert_nil Zones::Faces::FACE_STORE.read(@floor)
  end

  def test_export_keeps_container_faces_in_the_snapshot_but_not_in_the_zone
    fixture
    stamp!(@container)
    snapshot = PhComposer::Export::GeometrySnapshot.capture(@model, :revision => @session.revision)
    assert_includes snapshot.entries.select { |entry| entry.kind == "face" }.map(&:path), [100, 120, 121]
    zone_entry = snapshot.entry_at([100], :kind => "group")
    assert_equal [[100, 101], [100, 110, 111]], Zones::ExportProjection.zone_faces(snapshot, zone_entry).map(&:path)
    floor = snapshot.entry_at([100, 120, 121], :kind => "face")
    wall = snapshot.entry_at([100, 101], :kind => "face")
    assert_nil Zones::ExportProjection.zone_owner(snapshot, floor)
    assert_equal zone_entry, Zones::ExportProjection.zone_owner(snapshot, wall).first
  end

  def test_a_classified_face_inside_a_container_is_left_out_of_the_face_export
    fixture
    result = invoke("ph_composer.zones.faces.auto_classify", "zone" => @zone.fetch("reference"))
    assert_equal "completed", result["status"], result.inspect
    assert Zones::Faces::FACE_STORE.read(@floor)
    stamp!(@container)
    snapshot = PhComposer::Export::GeometrySnapshot.capture(@model, :revision => @session.revision)
    engine = PhComposer::Records::Engine.new(@model, PhComposer::Registry.current.catalog)
    records = PhComposer::Export::RecordReader.new(engine, PhComposer::Registry.current.catalog)
    reader = PhComposer::Export::SnapshotReader.new(records, snapshot)
    exported = Zones::Faces::ExportProjection.records(reader).map { |row| row.fetch("id") }
    assert_equal 2, exported.length
    refute_includes exported, Zones::Faces::FACE_STORE.read(@floor).fetch("id")
  end

  def test_an_unreadable_record_left_in_a_container_does_not_block_the_face_export
    fixture
    stamp!(@container)
    @floor.set_attribute(Zones::Faces::FACE_DICTIONARY, "record", "{not json")
    snapshot = PhComposer::Export::GeometrySnapshot.capture(@model, :revision => @session.revision)
    engine = PhComposer::Records::Engine.new(@model, PhComposer::Registry.current.catalog)
    records = PhComposer::Export::RecordReader.new(engine, PhComposer::Registry.current.catalog)
    reader = PhComposer::Export::SnapshotReader.new(records, snapshot)
    assert_empty Zones::Faces::ExportProjection.records(reader)
    contexts = Zones::Faces::ExportProjection.contexts(reader)
    assert_equal [[100, 101], [100, 110, 111]], contexts.map { |row| row["path"] }
  end

  def test_live_reads_and_export_agree_on_a_stamp_that_does_not_read
    fixture
    @container.set_attribute(Zones::STAMP_DICTIONARY, Zones::STAMP_STORE.key, false)
    assert_equal [[101], [110, 111]], face_paths
    snapshot = PhComposer::Export::GeometrySnapshot.capture(@model, :revision => @session.revision)
    zone_entry = snapshot.entry_at([100], :kind => "group")
    assert_equal [[100, 101], [100, 110, 111]], Zones::ExportProjection.zone_faces(snapshot, zone_entry).map(&:path)
  end

  def test_a_requiring_feature_has_zones_stamp_the_group_its_step_created_in_one_undo_step
    PhComposer::Registry.install([ContainerFixture])
    fixture
    loose = Sketchup::Face.new(141)
    @zone_group.entities << loose
    before = @model.operations.length
    result = invoke("test.container.make", "zone" => @zone.fetch("reference"), "face_id" => 141)
    assert_equal "completed", result["status"], result.inspect
    assert_equal({ "zone_id" => @zone.dig("reference", "zone_id") }, result["value"])
    assert_equal before + 1, @model.operations.length
    group = @zone_group.entities.to_a.find { |entity| entity.is_a?(Sketchup::Group) && entity.entities.include?(loose) }
    assert_equal Zones::Schema.stamp(Zones::ZONE_STORE.read(@zone_group)), Zones::STAMP_STORE.read(group)
    refute_includes face_paths, [group.persistent_id, 141]
  end

  def test_the_participant_refuses_a_container_under_a_locked_group
    PhComposer::Registry.install([ContainerFixture])
    fixture
    loose = Sketchup::Face.new(141)
    @plain.entities << loose
    @plain.locked = true
    result = invoke("test.container.make", "zone" => @zone.fetch("reference"), "context_path" => [100, 110],
                                           "face_id" => 141)
    refute_equal "completed", result["status"], result.inspect
    stamped = Zones::Occurrences.zones(@model).map { |zone| Zones::Occurrences.containers(zone) }.flatten(1)
    assert_empty stamped
  end

  def test_the_participant_refuses_a_container_inside_another_container
    PhComposer::Registry.install([ContainerFixture])
    fixture
    stamp!(@container)
    @container.entities << Sketchup::Face.new(142)
    result = invoke("test.container.make", "zone" => @zone.fetch("reference"), "context_path" => [100, 120],
                                           "face_id" => 142)
    refute_equal "completed", result["status"], result.inspect
    inner = @container.entities.grep(Sketchup::Group)
    assert(inner.none? { |group| Zones::STAMP_STORE.read(group) })
  end

  def test_the_zone_edit_step_rewrites_the_stamps_of_its_containers
    fixture
    stamp!(@container)
    before = Zones::ZONE_STORE.read(@zone_group)
    after = before.merge("level_id" => "lvl_Ab12Cd34Ef56")
    step = Zones::UpdateZoneStep.new(:reference => @zone.fetch("reference"), :before => before, :after => after)
    step.apply(@model, {})
    assert_equal "lvl_Ab12Cd34Ef56", Zones::STAMP_STORE.read(@container).fetch("level_id")
  end

  # A copied Zone made independent, or repaired, stamps the copy's containers with its new id and leaves
  # the original's stamps naming the original.
  def test_make_independent_and_repair_rewrite_the_stamps_of_the_copys_containers
    fixture
    stamp!(@container)
    original_id = Zones::ZONE_STORE.read(@zone_group).fetch("id")
    [["ph_composer.zones.make_independent", 500, false], ["ph_composer.zones.repair_identity", 600, true]]
      .each do |name, persistent_id, unique|
        copy = Sketchup::Group.new(persistent_id, @zone_group.entities)
        Zones::ZONE_STORE.write(copy, Zones::ZONE_STORE.read(@zone_group))
        @model.entities << copy
        treat_duplicates_as_existing(@model)
        copy.make_unique if unique
        result = invoke(name, "zone_path" => [persistent_id])
        assert_equal "completed", result["status"], "#{name}: #{result.inspect}"
        copied = copy.entities.to_a.find { |entity| Zones::STAMP_STORE.read(entity) }
        assert_equal Zones::ZONE_STORE.read(copy).fetch("id"), Zones::STAMP_STORE.read(copied).fetch("zone_id"), name
        assert_equal original_id, Zones::STAMP_STORE.read(@container).fetch("zone_id"), name
      end
  end

  # Storage a step cannot give the copy alone, on the way to a container, refuses before any stamp is
  # written: a wrapper the copy still shares for the repair, a component for Make Zone independent.
  def test_a_container_in_storage_the_copy_shares_refuses_and_leaves_the_original_stamp
    fixture
    wrapper = Sketchup::Group.new(130, Sketchup::Entities.new([]))
    @zone_group.entities.delete(@container)
    wrapper.entities << @container
    @zone_group.entities << wrapper
    stamp!(@container)
    original = Zones::STAMP_STORE.read(@container)
    copy = shared_zone_copy(500)
    copy.make_unique
    result = invoke("ph_composer.zones.repair_identity", "zone_path" => [500])
    assert_equal %w[refused target.shared_definition], result.values_at("status", "code")
    assert_equal original, Zones::STAMP_STORE.read(@container)
  end

  def test_a_container_inside_a_component_refuses_make_independent
    fixture
    @zone_group.entities.delete(@container)
    definition = Sketchup::ComponentDefinition.new(Sketchup::Entities.new([@container]))
    @zone_group.entities << Sketchup::ComponentInstance.new(140, definition)
    stamp!(@container)
    original = Zones::STAMP_STORE.read(@container)
    shared_zone_copy(500)
    result = invoke("ph_composer.zones.make_independent", "zone_path" => [500])
    assert_equal %w[refused target.shared_definition], result.values_at("status", "code")
    assert_equal original, Zones::STAMP_STORE.read(@container)
  end

  def test_a_locked_container_refuses_make_independent
    fixture
    stamp!(@container)
    @container.locked = true
    shared_zone_copy(500)
    result = invoke("ph_composer.zones.make_independent", "zone_path" => [500])
    assert_equal %w[refused target.locked], result.values_at("status", "code")
  end

  # Presence decides a container, even of a stamp that does not read: an exploded Zone's unreadable
  # container is opaque to Restore and does not fail the inventory.
  def test_an_unreadable_container_stamp_left_by_an_exploded_zone_does_not_fail_the_inventory
    fixture
    @container.set_attribute(Zones::STAMP_DICTIONARY, Zones::STAMP_STORE.key, "{not json")
    @zone_group.explode
    assert_equal "completed", query("ph_composer.zones.list")["status"]
  end

  # Restore puts back the stamp attribute as it was, present even when its value is JSON false, so the
  # Group is still a container and its Faces are still not the Zone's.
  def test_restore_keeps_a_container_stamp_present_as_it_was
    fixture
    @container.set_attribute(Zones::STAMP_DICTIONARY, Zones::STAMP_STORE.key, "false")
    copy = shared_zone_copy(500)
    zone = Zones::Repair.occurrence_at(@model, [500])
    plan = Zones::Repair.identity_plan(@model, zone, @session.revision, PhComposer::Registry.current.catalog, nil,
                                       :isolating => true)
    step = Zones::MakeIndependentStep.new(:reference => zone.reference, :plan => plan,
                                          :catalog => PhComposer::Registry.current.catalog)
    step.apply(@model, {})
    step.restore
    container = copy.entities.to_a.find { |entity| entity.get_attribute(Zones::STAMP_DICTIONARY, "record") }
    assert_equal "false", container.get_attribute(Zones::STAMP_DICTIONARY, Zones::STAMP_STORE.key)
  end

  private

  def shared_zone_copy(persistent_id)
    copy = Sketchup::Group.new(persistent_id, @zone_group.entities)
    Zones::ZONE_STORE.write(copy, Zones::ZONE_STORE.read(@zone_group))
    @model.entities << copy
    treat_duplicates_as_existing(@model)
    copy
  end

  def query(name)
    API.query(:context => @context, :name => name)
  end

  def invoke(name, params)
    @sequence += 1
    API.invoke(:context => @context, :name => name, :params => params,
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end
end
