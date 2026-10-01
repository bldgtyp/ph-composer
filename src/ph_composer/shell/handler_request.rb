# frozen_string_literal: true

module PhComposer
  # What a query or action handler receives.
  HandlerRequest = Struct.new(:session, :model, :params, :engine, :revision, :registry, :owner, :proposal, :query_stack,
                              keyword_init: true) do
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
      entries = rows.flat_map do |declaration|
        nested = dup
        nested.owner = declaration.owner
        plan = declaration.handler.call(nested, proposal, :from => from, :to => to)
        unless plan.is_a?(Records::ReferencePlan)
          raise InternalError, "#{declaration.name} must return a ReferencePlan."
        end

        unless plan.entries.all? { |entry| registry.owner_of(entry.kind) == declaration.owner }
          raise InternalError, "#{declaration.name} may project only its owner's entity targets."
        end

        plan.entries
      end
      Records::ReferencePlan.new(:entries => entries)
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
