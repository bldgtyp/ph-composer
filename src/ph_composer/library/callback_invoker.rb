# frozen_string_literal: true

module PhComposer
  module Library
    # A kind owner's callback participates in the caller's proposal. It sees validated detached
    # inputs and the projected catalog, and can stage writes only to that owner's catalog kinds
    # (`proposal.foreign_write`); it may not remove or change what was proposed before it
    # (`proposal.contribution_replaced`).
    module CallbackInvoker
      module_function

      def call(request, declaration, callback, params, readonly: false)
        validate!(params, callback.params, "params.invalid", "Library callback parameters are invalid.")
        writable = readonly ? [] : ParticipantInvocation.owned_kinds(request.registry, declaration.owner)
        engine = request.engine.projected(request.proposal, :writable_kinds => writable,
                                                            :refusal_code => "proposal.foreign_write")
        nested = request.with(:params => params, :owner => declaration.owner,
                              :proposal => readonly ? nil : request.proposal, :engine => engine)
        proposal = request.proposal
        before = proposal && Operations::Contributions.snapshot(proposal)
        call = -> { callback.handler.call(nested, readonly ? nil : proposal) }
        value = proposal ? proposal.guarded(writable, "proposal.foreign_write", &call) : call.call
        validate!(value, callback.result, "library.callback_invalid", "Library callback returned an invalid result.")
        Operations::Contributions.preserved!(request.proposal, before) if before
        DeepCopy.call(value)
      rescue StandardError => error
        request.proposal&.refuse(error)
        raise
      end

      def validate!(value, schema, code, message)
        return if JsonValue.problems(value).empty? && JsonSchema.validate(value, schema).empty?

        raise CodedError.new(code, message)
      end

      private_class_method :validate!
    end
  end
end
