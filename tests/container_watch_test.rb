# frozen_string_literal: true

require_relative "test_helper"

# The session reports each Group or ComponentInstance added to any container as `container_added`, for
# reconcilers that must see a native copy arrive (context/SKETCHUP_HOST_BEHAVIOR.md, "Observers and edit
# contexts"). The subscriber here is synthetic: the watch names no feature.
class ContainerWatchTest < PhComposerTestCase
  def setup
    super
    @model = Sketchup.active_model
    @nested = Sketchup::Group.new(11, Sketchup::Entities.new([]))
    @model.entities << Sketchup::Group.new(10, Sketchup::Entities.new([@nested]))
    @session = PhComposer::Sessions.for(@model)
    @added = []
    @unsubscribe = PhComposer::Sessions.on_host_event(:container_added) { |_session, entity| @added << entity }
  end

  def teardown
    @unsubscribe.call
    super
  end

  def test_an_addition_at_any_depth_is_reported_with_the_entity
    root = Sketchup::Group.new(20, Sketchup::Entities.new([]))
    @model.entities << root
    @nested.entities << Sketchup::Face.new(30)
    deep = Sketchup::Group.new(31, Sketchup::Entities.new([]))
    @nested.entities << deep
    root.entities << Sketchup::Group.new(32, Sketchup::Entities.new([]))
    assert_equal [20, 31, 32], @added.map(&:persistent_id)
  end

  def test_a_container_that_appears_without_an_addition_is_observed_after_the_next_commit
    later = Sketchup::Group.new(40, Sketchup::Entities.new([]))
    @nested.entities.instance_variable_get(:@values) << later
    @session.host_event(:transaction_committed)
    UI.run_timers
    later.entities << Sketchup::Group.new(41, Sketchup::Entities.new([]))
    assert_equal [41], @added.map(&:persistent_id)
  end

  def test_a_detached_session_reports_nothing
    PhComposer::Sessions.detach(@model)
    @model.entities << Sketchup::Group.new(50, Sketchup::Entities.new([]))
    assert_empty @added
  end
end
