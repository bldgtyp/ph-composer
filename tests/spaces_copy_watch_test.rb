# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/space_fixtures"

# A native copy of a Space Group is made independent in the copy's own Undo step (context/CONTRACTS.md,
# "Reconciliation"). Copies arrive as the host delivers them: the commit, then the added Group already
# carrying its instance dictionaries (context/SKETCHUP_HOST_BEHAVIOR.md, "Observers and edit contexts").
class SpacesCopyWatchTest < PhComposerTestCase
  include SpaceFixtures

  API = PhComposer::API

  def setup
    super
    @model = Sketchup.active_model
    @volume = volume_group(111, volume_record("A"), [floor_face(112, rectangle(0, 0, 2, 2), segment_record("A"))])
    @space = space_group(110, space_record("S", :number => "1"), [@volume])
    @zone = zone_group(100, "Z", [@space])
    @model.entities << @zone
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @notices = []
    @unsubscribe = PhComposer::Sessions.on_notice { |_session, message, tone| @notices << [tone, message] }
  end

  def teardown
    @unsubscribe.call
    super
  end

  def watcher
    SPACES::CopyWatch.state(@session)
  end

  # What a native copy leaves: a new Group over the same entities with the original's dictionaries.
  def copy_natively(group, persistent_id, parent = @zone)
    copy = Sketchup::Group.new(persistent_id, group.entities, {}, :transformation => group.transformation)
    Array(group.attribute_dictionaries).each do |dictionary|
      dictionary.each { |key, value| copy.set_attribute(dictionary.name, key, value) }
    end
    @session.host_event(:transaction_committed)
    parent.entities << copy
    copy
  end

  def spaces
    API.query(:context => @context, :name => "ph_composer.spaces.all").dig("value", "spaces")
  end

  def test_a_native_copy_is_made_independent_in_the_copys_undo_step
    copy_natively(@space, 120)
    assert watcher.pending?
    UI.run_timers
    refute watcher.pending?
    original, copy = spaces
    assert_equal %w[spc_SSSSSSSSSSSS 1], [original["id"], original.dig("values", "number")]
    refute_equal "spc_SSSSSSSSSSSS", copy["id"]
    assert_equal "2", copy.dig("values", "number")
    refute_equal "vol_AAAAAAAAAAAA", copy.dig("volumes", 0, "id")
    assert_equal ["Make Space Independent", true, false, true], @model.operation_starts.last
    assert_equal [[:success, "Made the copied Space independent."]], @notices
  end

  def test_an_array_of_copies_takes_the_next_free_numbers
    5.times { |index| copy_natively(@space, 120 + index) }
    UI.run_timers
    assert_equal %w[1 2 3 4 5 6], spaces.map { |row| row.dig("values", "number") }
    assert_equal 6, spaces.map { |row| row["id"] }.uniq.length
    assert_equal [[:success, "Made the 5 copied Spaces independent."]], @notices
  end

  def test_a_cut_and_paste_leaves_no_duplicate_and_nothing_is_queued
    @zone.entities.delete(@space)
    @session.host_event(:transaction_committed)
    @zone.entities << @space
    refute watcher.pending?
  end

  def test_undo_and_redo_drop_a_pending_pass
    copy_natively(@space, 120)
    @session.host_event(:transaction_undone)
    refute watcher.pending?
    UI.run_timers
    assert_equal %w[spc_SSSSSSSSSSSS spc_SSSSSSSSSSSS], spaces.map { |row| row["id"] }
  end

  # Two occurrences already sharing the id are both originals: a third copy of them is not guessed at.
  def test_two_pre_existing_holders_are_never_rewritten
    existing = Sketchup::Group.new(130, @space.entities)
    SPACES::SPACE_STORE.write(existing, SPACES::SPACE_STORE.read(@space))
    @zone.entities << existing
    treat_duplicates_as_existing(@model)
    copy_natively(@space, 120)
    UI.run_timers
    assert_equal ["spc_SSSSSSSSSSSS"] * 3, spaces.map { |row| row["id"] }
    assert_empty @notices
  end

  # A copy inside a component keeps the finding and gets one notice.
  def test_a_copy_inside_a_component_keeps_its_finding_with_one_notice
    @zone.entities.delete(@space)
    definition = Sketchup::ComponentDefinition.new(Sketchup::Entities.new([@space]))
    @zone.entities << Sketchup::ComponentInstance.new(140, definition)
    @session.host_event(:transaction_committed)
    @zone.entities << Sketchup::ComponentInstance.new(141, definition)
    UI.run_timers
    assert_equal ["spc_SSSSSSSSSSSS"] * 2, spaces.map { |row| row["id"] }
    assert_equal 1, @notices.length
    assert_equal :warning, @notices.first.first
  end

  # A copied plain Group holding a Space may be a Zone, whose copy Zones handles: no pass, no notice.
  def test_a_copied_plain_group_holding_a_space_is_left_to_its_finding
    wrapper = Sketchup::Group.new(150, Sketchup::Entities.new([]))
    @zone.entities.delete(@space)
    wrapper.entities << @space
    @zone.entities << wrapper
    copy_natively(wrapper, 151)
    refute watcher.pending?
  end
end
