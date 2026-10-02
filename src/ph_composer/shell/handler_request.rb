# frozen_string_literal: true

module PhComposer
  # What a query or action handler receives. Colour-by projections and native menu tests receive the
  # same shape as a read: no params and no proposal (context/CONTRACTS.md, "Handler-side dependency
  # reads"). `approval` is the location the user chose for a declaration that needs one
  # (Declarations::Approval), as a NativeApproval::Granted; it is nil everywhere else.
  HandlerRequest = Struct.new(:session, :model, :params, :engine, :revision, :registry, :owner, :proposal, :query_stack,
                              :memos, :approval, keyword_init: true) do
    # The one place a request is built from a session. `name` is the declaration the request runs
    # for, so a nested read of the same name is refused as recursive.
    def self.for(session, owner:, name:, registry: Registry.current, params: {}, proposal: nil, approval: nil)
      new(:session => session, :model => session.model, :params => DeepCopy.call(params),
          :engine => Records::Engine.new(session.model, registry.catalog), :revision => session.revision,
          :registry => registry, :owner => owner, :proposal => proposal, :query_stack => [name],
          :memos => {}.compare_by_identity, :approval => approval)
    end

    # A value computed once per request, shared with the nested reads and callbacks it makes. Keys
    # are scoped to the current owner, so two features cannot collide, and to the current engine, so
    # a value read through one engine is never reused under a projected one.
    def memo(key)
      self.memos ||= {}.compare_by_identity
      slot = (memos[engine] ||= {})
      return slot[[owner, key]] if slot.key?([owner, key])

      slot[[owner, key]] = yield
    end

    # Reads a declared dependency within the current read/proposal phase, without
    # re-entering the public dispatcher or bypassing the query's schemas.
    def query(name, params = {})
      declaration = registry.queries[name]
      raise CodedError.new("operation.query_missing", "No query named #{name} is installed.") unless declaration
      unless declaration.owner == owner || registry.features.fetch(owner).requires.include?(declaration.owner)
        raise CodedError.new("operation.dependency_missing", "#{owner} does not require #{declaration.owner}.")
      end
      if query_stack.include?(name)
        raise CodedError.new("operation.query_cycle", "Recursive query #{name} was refused.")
      end
      unless params.is_a?(Hash) && JsonValue.problems(params).empty? &&
             JsonSchema.validate(params, declaration.params).empty?
        raise CodedError.new("params.invalid", "#{name} params do not match its schema.")
      end

      nested = dup
      nested.owner = declaration.owner
      nested.proposal = nil
      nested.params = DeepCopy.call(params)
      nested.query_stack = query_stack + [name]
      value = declaration.handler.call(nested)
      unless JsonValue.problems(value).empty? && JsonSchema.validate(value, declaration.result).empty?
        raise InternalError, "#{name} returned a result outside its schema."
      end

      DeepCopy.call(value)
    end

    def retarget_references(kind, from:, to:)
      raise InternalError, "Reference retargeting needs an action proposal." unless proposal

      engine.resolve_reference(kind, from)
      engine.resolve_reference(kind, to) unless to.nil?
      rows = registry.reference_retargeters.values.select { |item| item.target_kind == kind }.sort_by(&:name)
      plans = rows.map do |declaration|
        nested = dup
        nested.owner = declaration.owner
        plan = declaration.handler.call(nested, proposal, :from => from, :to => to)
        unless plan.is_a?(Records::ReferencePlan)
          raise InternalError, "#{declaration.name} must return a ReferencePlan."
        end

        unless (plan.entries + plan.removals).all? { |entry| registry.owner_of(entry.kind) == declaration.owner }
          raise InternalError, "#{declaration.name} may project only its owner's entity targets."
        end

        plan
      end
      Records::ReferencePlan.new(:entries => plans.flat_map(&:entries), :removals => plans.flat_map(&:removals))
    rescue StandardError => error
      proposal&.refuse(error)
      raise
    end

    def participant(name)
      declaration = registry.proposal_participants[name]
      raise CodedError.new("operation.participant_missing", "No proposal participant named #{name} is installed.") \
        unless declaration

      declaration.handler
    end
  end
end
