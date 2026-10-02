# frozen_string_literal: true

module PhComposer
  module Library
    # A kind owner's callback participates in the caller's proposal. It sees validated detached
    # inputs and the projected catalog, and can stage writes only to that owner's catalog kinds.
    module CallbackInvoker
      module_function

      def call(request, declaration, callback, params, readonly: false)
        validate!(params, callback.params, "params.invalid", "Library callback parameters are invalid.")
        writable = readonly ? [] : owned_kinds(request.registry, declaration.owner)
        engine = request.engine.projected(request.proposal, :writable_kinds => writable,
                                                            :refusal_code => "library.mutation_owner")
        nested = request.with(:params => params, :owner => declaration.owner,
                              :proposal => readonly ? nil : request.proposal, :engine => engine)
        before = DeepCopy.call(request.proposal&.writes&.map(&:to_h))
        value = callback.handler.call(nested, readonly ? nil : request.proposal)
        validate!(value, callback.result, "library.callback_invalid", "Library callback returned an invalid result.")
        validate_writes!(request, declaration.owner, before)
        DeepCopy.call(value)
      rescue StandardError => error
        request.proposal&.refuse(error)
        raise
      end

      def owned_kinds(registry, owner)
        registry.catalog.kinds.map(&:id).select { |kind| registry.owner_of(kind) == owner }
      end

      def validate!(value, schema, code, message)
        return if JsonValue.problems(value).empty? && JsonSchema.validate(value, schema).empty?

        raise CodedError.new(code, message)
      end

      def validate_writes!(request, owner, before)
        return unless request.proposal

        writes = request.proposal.writes
        preserved = writes.first(before.length).map(&:to_h) == before
        owned = writes.drop(before.length).all? { |write| request.registry.owner_of(write.kind) == owner }
        return if preserved && owned

        raise CodedError.new("library.mutation_owner", "Library callback changed another owner's proposal.")
      end
      private_class_method :owned_kinds, :validate!, :validate_writes!
    end
  end
end
