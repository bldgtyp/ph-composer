# frozen_string_literal: true

require "delegate"
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

  def test_an_addition_the_host_deleted_before_the_walk_is_passed_by_and_other_errors_are_logged
    logged = []
    watch = PhComposer::ContainerWatch.for(@session)
    PhComposer::Diagnostics.stub(:exception, ->(event, error, *_rest) { logged << [event, error.message] }) do
      gone = Sketchup::Group.new(40, Sketchup::Entities.new([]))
      gone.define_singleton_method(:entities) { raise TypeError, "reference to deleted Entities" }
      watch.added(gone)
      assert_empty logged, "a copy undone before its callback ran is nothing to report"
      broken = Sketchup::Group.new(41, Sketchup::Entities.new([]))
      broken.define_singleton_method(:entities) { raise TypeError, "wrong argument type" }
      watch.added(broken)
    end
    assert_equal [["container_added", "wrong argument type"]], logged
  end

  def test_a_container_that_appears_without_an_addition_is_observed_after_the_next_commit
    later = Sketchup::Group.new(40, Sketchup::Entities.new([]))
    @nested.entities.instance_variable_get(:@values) << later
    @session.host_event(:transaction_committed)
    UI.run_timers
    later.entities << Sketchup::Group.new(41, Sketchup::Entities.new([]))
    assert_equal [41], @added.map(&:persistent_id)
  end

  # The host answers a new Ruby wrapper from every Group#entities call (context/SKETCHUP_HOST_BEHAVIOR.md,
  # "Observers and edit contexts"); a definition two placements share is still observed once.
  def test_a_shared_definition_is_observed_once_through_fresh_wrappers
    inner = Sketchup::Entities.new([])
    placements = [60, 61].map { |id| Sketchup::Group.new(id, inner) }
    placements.each { |group| group.define_singleton_method(:entities) { SimpleDelegator.new(inner) } }
    @model.entities << Sketchup::Group.new(62, Sketchup::Entities.new(placements))
    2.times do
      @session.host_event(:transaction_committed)
      UI.run_timers
    end
    observers = inner.instance_variable_get(:@observers)
    assert_equal 1, observers.count { |observer| observer.is_a?(PhComposer::ContainerWatch::Observer) }
  end

  def test_observer_type_errors_other_than_deleted_entities_are_not_suppressed
    error = TypeError.new("wrong observer argument")
    @model.entities.stub(:remove_observer, ->(_observer) { raise error }) do
      assert_same error, assert_raises(TypeError) { PhComposer::ContainerWatch.for(@session).detach }
    end
  end

  def test_a_detached_session_reports_nothing
    PhComposer::Sessions.detach(@model)
    @model.entities << Sketchup::Group.new(50, Sketchup::Entities.new([]))
    assert_empty @added
  end
end
