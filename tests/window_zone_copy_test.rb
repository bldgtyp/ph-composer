# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/zone_child_fixture"

# Window Units follow their Zone when it becomes independent: the copy's Units get new ids in the
# Zone's own proposal, by the explicit action and by the copy watcher, alongside a second child
# feature. The copy is made as the host makes one (a second Group over the same contents carrying the
# Zone record), and Make Unique gives every member a new entity, as measured (ZC-01).
class WindowZoneCopyTest < PhComposerTestCase
  API = PhComposer::API
  U = PhComposer::Windows::Units
  ZONE_STORE = PhComposer::Zones::ZONE_STORE
  FACE_STORE = PhComposer::Zones::Faces::FACE_STORE
  MAKE_INDEPENDENT = "ph_composer.zones.make_independent"

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
    @notices = []
    PhComposer::Sessions.on_notice { |_session, message, tone| @notices << [message, tone] }
    @original = zone(300)
  end

  def teardown
    ZoneChildFixture.fail_restore = false
    super
  end

  def test_make_independent_gives_the_copied_units_new_ids_and_keeps_types_anchors_and_originals
    copy = shared_copy(@original, 400)
    before = units_under(@original)

    result = invoke(MAKE_INDEPENDENT, { "zone_path" => [copy.persistent_id] })

    assert_equal %w[completed committed], result.values_at("status", "effect"), result.inspect
    assert_equal before, units_under(@original)
    copied = units_under(copy)
    assert_equal 2, copied.length
    assert_empty copied.map { |row| row.fetch("id") } & before.map { |row| row.fetch("id") }
    assert_equal(before.map { |row| row.slice("window_type_id", "anchor", "user_data") },
                 copied.map { |row| row.slice("window_type_id", "anchor", "user_data") })
    repaired = result.fetch("affected").select { |row| row["kind"] == U::REFERENCE_KIND }
    assert_equal copied.map { |row| row.fetch("id") }.sort, repaired.map { |row| row.fetch("id") }.sort
  end

  def test_the_copy_watcher_makes_both_children_follow_in_one_follow_up
    PhComposer::Registry.install([ZoneChildFixture])
    tag(@original, "tag_000000000001")
    copy = native_copy(@original, 400)

    UI.run_timers

    independent = @model.operation_starts.select { |start| start.first == "Make Zone Independent" }
    assert_equal [["Make Zone Independent", true, false, true]], independent, "one transparent follow-up"
    assert_empty units_under(copy).map { |row| row["id"] } & units_under(@original).map { |row| row["id"] }
    refute_equal tags_under(@original), tags_under(copy)
    assert_equal ["tag_000000000001"], tags_under(@original)
    assert_equal [["Made the copied Zone independent.", :success]], @notices
  end

  def test_a_child_restore_failure_still_restores_the_others_and_reports_unrestored
    PhComposer::Registry.install([ZoneChildFixture])
    tag(@original, "tag_000000000001")
    native_copy(@original, 400)
    ZoneChildFixture.fail_restore = true
    calls = 0
    with_unit_write_fault(-> { (calls += 1) == 2 }) { UI.run_timers }

    copy = zone_groups.last
    assert_equal ZONE_STORE.read(@original).fetch("id"), ZONE_STORE.read(copy).fetch("id"), "the Zone restored"
    assert_equal units_under(@original).map { |row| row["id"] }, units_under(copy).map { |row| row["id"] }
    assert_equal :error, @notices.last.last, "the failed child restore is reported"
    refute(@model.operations.any? { |_name, _disable, result| result == :aborted })
  end

  def test_a_fault_after_the_parent_write_restores_the_zone_and_every_child_in_the_follow_up
    PhComposer::Registry.install([ZoneChildFixture])
    tag(@original, "tag_000000000001")
    native_copy(@original, 400)
    calls = 0
    with_unit_write_fault(-> { (calls += 1) == 2 }) { UI.run_timers }

    copy = zone_groups.last
    assert_equal ZONE_STORE.read(@original).fetch("id"), ZONE_STORE.read(copy).fetch("id")
    assert_equal units_under(@original).map { |row| row["id"] }, units_under(copy).map { |row| row["id"] }
    assert_equal ["tag_000000000001"], tags_under(copy)
    refute(@model.operations.any? { |_name, _disable, result| result == :aborted })
  end

  def test_an_unsupported_extension_payload_on_a_copied_unit_refuses_the_whole_transition
    unit = @original.entities.to_a.grep(Sketchup::ComponentInstance).first
    U.write(unit, U.read(unit).merge("extension_data" => { "outside.vendor" => { "schema_version" => 1,
                                                                                 "payload" => { "x" => 1 } } }))
    copy = shared_copy(@original, 400)
    zone_before = ZONE_STORE.read(copy)

    result = invoke(MAKE_INDEPENDENT, { "zone_path" => [copy.persistent_id] })

    refute_equal "completed", result.fetch("status")
    assert_equal "none", result.fetch("effect")
    assert_equal zone_before, ZONE_STORE.read(copy)
    assert_equal 2, @original.definition.instances.length, "storage is still shared"
  end

  def test_undo_removes_the_unit_ids_with_the_zone_and_redo_repeats_them
    copy = shared_copy(@original, 400)
    invoke(MAKE_INDEPENDENT, { "zone_path" => [copy.persistent_id] })
    repaired = units_in_model.map { |row| row["id"] }

    assert @model.undo
    assert_equal 2, units_in_model.map { |row| row["id"] }.uniq.length, "the copy shares its Unit ids again"
    assert @model.redo
    assert_equal repaired, units_in_model.map { |row| row["id"] }
  end

  private

  def invoke(name, params)
    @sequence += 1
    API.invoke(:context => @context, :name => name, :params => params,
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end

  # A classified box Zone with two glued Units of two Types on two of its Faces.
  def zone(base)
    faces = 3.times.map do |index|
      Sketchup::Face.new(base + index + 1, {}, :points => [Geom::Point3d.new(0, 0, index),
                                                           Geom::Point3d.new(2, 0, index),
                                                           Geom::Point3d.new(2, 2, index)])
    end
    group = Sketchup::Group.new(base, Sketchup::Entities.new(faces))
    @model.entities << group
    invoke("ph_composer.zones.make", { "parent_path" => [], "entity_ids" => [base] })
    definition = @model.definitions.add("Synthetic window")
    faces.first(2).each_with_index do |face, index|
      unit = Sketchup::ComponentInstance.new(base + 20 + index, definition, {}, :glued_to => face)
      U.write(unit, { "id" => "wun_00000000000#{index + 1}", "schema_version" => 1,
                      "window_type_id" => "wnt_00000000000#{index + 1}", "anchor" => "sill_center",
                      "user_data" => { "note" => ["kept"] } })
      group.entities << unit
    end
    group
  end

  def tag(group, id)
    child = Sketchup::Group.new(group.persistent_id + 30, Sketchup::Entities.new([]))
    ZoneChildFixture::STORE.write(child, { "id" => id })
    group.entities << child
  end

  # A copy already in the Model, which the watcher leaves for the explicit command.
  def shared_copy(group, base)
    copy = Sketchup::Group.new(base, group.entities)
    copy.set_attribute("ph_composer.zone", "record", group.get_attribute("ph_composer.zone", "record"))
    @model.entities << copy
    treat_duplicates_as_existing(@model)
    copy
  end

  # A native copy made during the session, which the watcher repairs on its deferred pass.
  def native_copy(group, base)
    PhComposer::ModelOperation.perform(@model, "Paste") { true }
    copy = Sketchup::Group.new(base, group.entities)
    copy.set_attribute("ph_composer.zone", "record", group.get_attribute("ph_composer.zone", "record"))
    @model.entities << copy
    copy
  end

  def units_under(group)
    group.entities.to_a.grep(Sketchup::ComponentInstance).map { |entity| U.read(entity) }.compact
  end

  def units_in_model
    U::Occurrences.all(@model).map(&:record)
  end

  def tags_under(group)
    group.entities.to_a.grep(Sketchup::Group).map { |entity| ZoneChildFixture::STORE.read(entity)&.fetch("id") }.compact
  end

  def zone_groups
    @model.entities.to_a.select { |entity| entity.is_a?(Sketchup::Group) && ZONE_STORE.read(entity) }
  end

  # Fails the Unit write `fault` names, then restores the real writer.
  def with_unit_write_fault(fault)
    U.singleton_class.send(:alias_method, :__zone_copy_write, :write)
    U.define_singleton_method(:write) do |entity, record|
      raise IOError, "injected" if fault.call

      __zone_copy_write(entity, record)
    end
    yield
  ensure
    U.singleton_class.send(:remove_method, :write)
    U.singleton_class.send(:alias_method, :write, :__zone_copy_write)
    U.singleton_class.send(:remove_method, :__zone_copy_write)
  end
end
