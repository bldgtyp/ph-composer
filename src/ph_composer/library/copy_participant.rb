# frozen_string_literal: true

module PhComposer
  module Library
    # The library copy as a proposal participant: the same resolution and owner callbacks join another
    # feature's proposal. The foundation's invocation (shell/participant_invocation.rb) has already
    # checked the caller's dependency, its `participants` edge, the active proposal and the params,
    # and validates the result. No nested dispatch or native transaction is started.
    module CopyParticipant
      module_function

      def call(request, proposal)
        Coordinator.copy(request, proposal)
      end
    end
  end
end
