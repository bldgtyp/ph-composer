# frozen_string_literal: true

require_relative "test_helper"

# The edit-context writer and the deferred-work primitive, driven by a synthetic caller that is no
# feature (context/TECH_STACK.md, "Treat the active editing path as data" and "Observers report;
# deferred work mutates").
class EditContextTest < PhComposerTestCase
  EDIT = PhComposer::EditContext
  ASSIGNMENT = /\.active_path\s*=(?!=)/

  def setup
    super
    @model = Sketchup.active_model
    @inner = Sketchup::Group.new(11, Sketchup::Entities.new([]))
    @outer = Sketchup::Group.new(10, Sketchup::Entities.new([@inner]))
    @model.entities << @outer
  end

  def test_exactly_one_file_assigns_the_active_path
    files = Dir[File.join(SOURCE_ROOT, "ph_composer", "**", "*.rb")].select do |path|
      File.read(path, :encoding => "UTF-8").match?(ASSIGNMENT)
    end
    assert_equal ["session/edit_context.rb"], files.map { |path| path.delete_prefix("#{SOURCE_ROOT}/ph_composer/") }
  end

  def test_every_boundary_runs_with_the_path_left_and_entered_before_the_path_changes
    seen = []
    EDIT.boundary(:probe) { |model, from, to|
      seen << [from.map(&:persistent_id), to.map(&:persistent_id), model.active_path]
    }
    EDIT.enter(@model, [@outer, @inner])
    EDIT.enter(@model, [@outer])
    EDIT.enter_root(@model)
    assert_equal [[[], [10, 11], nil], [[10, 11], [10], [@outer, @inner]], [[10], [], [@outer]]], seen
    assert_empty EDIT.current(@model)
  end

  def test_entering_the_current_path_assigns_nothing
    EDIT.enter(@model, [@outer])
    assigned = 0
    @model.stub(:active_path=, ->(_value) { assigned += 1 }) { EDIT.enter(@model, [@outer]) }
    assert_equal 0, assigned
  end

  def test_a_reregistered_boundary_replaces_the_first
    calls = []
    EDIT.boundary(:probe) { calls << :first }
    EDIT.boundary(:probe) { calls << :second }
    EDIT.enter(@model, [@outer])
    assert_equal [:second], calls
  end

  def test_deferred_work_coalesces_merges_settles_and_cancels
    runs = []
    work = PhComposer::DeferredWork.new { |jobs| runs << jobs }
    work.queue(:a, [1])
    work.queue(:a, [2]) { |existing, job| existing + job }
    work.queue(:b, [3])
    assert work.pending?
    UI.run_timers
    assert_equal [{ :a => [1, 2], :b => [3] }], runs
    refute work.pending?
    work.queue(:c, [4])
    work.cancel
    UI.run_timers
    assert_equal 1, runs.length
    work.queue(:d, [5])
    work.settle
    assert_equal({ :d => [5] }, runs.last)
    work.queue(:e, [6])
    work.detach
    refute work.pending?
  end

  def test_a_failing_pass_leaves_the_work_settled_and_not_pending
    work = PhComposer::DeferredWork.new { |_jobs| raise ArgumentError, "boom" }
    work.queue(:a, 1)
    assert_raises(ArgumentError) { work.settle }
    refute work.pending?
  end
end
