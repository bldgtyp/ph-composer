# frozen_string_literal: true

require_relative "test_helper"

class ModelOperationTest < PhComposerTestCase
  Operation = PhComposer::ModelOperation

  def test_commits_one_named_operation
    model = Sketchup::Model.new
    Operation.perform(model, "Create Probe") { model.set_attribute("test", "value", 1) }
    assert_equal [["Create Probe", true, :committed]], model.operations
    assert_equal 1, model.get_attribute("test", "value")
  end

  def test_aborts_and_reraises
    model = Sketchup::Model.new
    assert_raises(IOError) do
      Operation.perform(model, "Broken Probe") do
        model.set_attribute("test", "value", 1)
        raise IOError, "broken"
      end
    end
    assert_nil model.get_attribute("test", "value")
    assert_equal :aborted, model.operations.last.last
  end
end
