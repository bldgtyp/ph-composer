# frozen_string_literal: true

module PhComposer
  module Library
    # A kind owner's callback participates in the caller's proposal. It sees validated detached
    # inputs and the projected catalog, and can stage writes only to that owner's catalog kinds.
    module CallbackInvoker
      module_function

      def call(request, declaration, callback, params, readonly: false)
        validate!(params, callback.params, "params.invalid", "Library callback parameters are invalid.")
        nested = request.dup
        nested.owner = declaration.owner
        nested.params = DeepCopy.call(params)
        nested.proposal = nil if readonly
        nested.engine = ProjectedEngine.new(request.engine, request.registry, declaration.owner,
                                           request.proposal, readonly)
        before = DeepCopy.call(request.proposal&.writes&.map(&:to_h))
        value = callback.handler.call(nested, readonly ? nil : request.proposal)
        validate!(value, callback.result, "library.callback_invalid", "Library callback returned an invalid result.")
        validate_writes!(request, declaration.owner, before)
        DeepCopy.call(value)
      rescue StandardError => error
        request.proposal&.refuse(error)
        raise
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
      private_class_method :validate!, :validate_writes!

      class ProjectedEngine
        def initialize(engine, registry, owner, proposal, readonly = false)
          @engine, @registry, @owner, @proposal = engine, registry, owner, proposal
          @readonly = readonly
        end

        def find(kind, id)
          return @engine.find(kind, id) unless @proposal

          @engine.resolve_reference(kind, id, :change_set => @proposal).record
        end

        def ids(kind)
          staged = @proposal ? @proposal.writes.select { |write| write.kind == kind } : []
          (@engine.ids(kind) + staged.select(&:after).map(&:id) - staged.reject(&:after).map(&:id)).uniq
        end

        def kind(id)
          @engine.kind(id)
        end

        def view(kind, record)
          @engine.view(kind, record)
        end

        %i[propose_create propose_update propose_delete propose_duplicate].each do |method|
          define_method(method) do |kind, *arguments, **keywords, &block|
            proposal = method == :propose_create ? arguments.first : arguments.last
            unless !@readonly && @proposal && proposal.equal?(@proposal) && @registry.owner_of(kind) == @owner
              error = CodedError.new("library.mutation_owner", "Library callback must use its owner's proposal.")
              @proposal&.refuse(error)
              raise error
            end
            @engine.public_send(method, kind, *arguments, **keywords, &block)
          end
        end
      end
    end
  end
end
