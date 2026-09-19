# frozen_string_literal: true

module PhComposer
  # One named SketchUp operation: the block's Model changes become one native Undo step, or none.
  module ModelOperation
    class OperationError < InternalError; end

    # Commits the block's changes, or aborts them and re-raises. The caller that needs to know the
    # abort left the Model unchanged verifies that itself (shell/dispatch.rb), because only it knows
    # which data the operation could have touched.
    def self.perform(model, name, transparent: false)
      committed = false
      started = model.start_operation(name.to_s, true, false, transparent)
      raise OperationError, "SketchUp refused to start #{name}" unless started

      result = yield
      committed = model.commit_operation
      raise OperationError, "SketchUp refused to commit #{name}" unless committed

      result
    rescue StandardError
      # Once the commit succeeded there is nothing left to abort; aborting would act on no operation.
      model.abort_operation if started && !committed
      raise
    end
  end
end
