# frozen_string_literal: true

module PhComposer
  # The one route by which an action's handler calls a proposal participant another feature declared
  # (context/CONTRACTS.md, "Compound proposals"). The foundation checks, in order: the participant is
  # installed, the caller has an active proposal, the caller's feature owns or requires the participant's
  # owner, the calling declaration names the participant in `participants`, the call is not recursive,
  # and the params match the participant's schema. It then runs the handler under the participant's owner
  # with an engine that stages writes only to that owner's catalog kinds; however the handler writes,
  # through that engine or `proposal.put`, a record write outside them refuses (Records::ChangeSet
  # #guarded), and a kind owner it delegates to is confined to that owner's kinds for its own call. It
  # then checks nothing earlier in the proposal was removed or changed, and validates the result. Any
  # failure refuses the whole proposal,
  # so a caller that rescues still cannot apply it. The outer dispatcher keeps the transaction, retry and
  # outcome; nothing here opens an operation.
  module ParticipantInvocation
    module_function

    def call(request, name, params)
      declaration = request.registry.proposal_participants[name]
      refuse!(request, "operation.participant_missing", "No proposal participant named #{name} is installed.") \
        unless declaration
      refuse!(request, "operation.proposal_required", "#{name} needs the caller's active proposal.") \
        unless request.proposal
      dependency!(request, declaration)
      edge!(request, declaration)
      if request.query_stack.include?(name)
        refuse!(request, "operation.participant_cycle", "Recursive participant #{name} was refused.")
      end
      unless params.is_a?(Hash) && JsonValue.problems(params).empty? &&
             JsonSchema.validate(params, declaration.params).empty?
        refuse!(request, "params.invalid", "#{name} params do not match its schema.")
      end

      run(request, declaration, params)
    rescue StandardError => error
      request.proposal&.refuse(error)
      raise
    end

    def run(request, declaration, params)
      proposal = request.proposal
      writable = owned_kinds(request.registry, declaration.owner)
      engine = request.engine.projected(proposal, :writable_kinds => writable,
                                                  :refusal_code => "proposal.foreign_write")
      nested = request.with(:params => DeepCopy.call(params), :owner => declaration.owner, :engine => engine,
                            :query_stack => request.query_stack + [declaration.name])
      before = Operations::Contributions.snapshot(proposal)
      value = proposal.guarded(writable, "proposal.foreign_write") { declaration.handler.call(nested, proposal) }
      Operations::Contributions.preserved!(proposal, before)
      unless JsonValue.problems(value).empty? && JsonSchema.validate(value, declaration.result).empty?
        raise InternalError, "#{declaration.name} returned a result outside its schema."
      end

      DeepCopy.call(value)
    end

    def dependency!(request, declaration)
      return if declaration.owner == request.owner ||
                request.registry.features.fetch(request.owner).requires.include?(declaration.owner)

      refuse!(request, "operation.dependency_missing", "#{request.owner} does not require #{declaration.owner}.")
    end

    # The calling declaration is the last name on the request's stack: the operation the request was
    # built for, or the participant that is calling on.
    def edge!(request, declaration)
      registry = request.registry
      caller_name = request.query_stack.last
      calling = registry.actions[caller_name] || registry.queries[caller_name] ||
                registry.proposal_participants[caller_name]
      return if calling.respond_to?(:participants) && Array(calling.participants).include?(declaration.name)

      refuse!(request, "operation.participant_missing",
              "#{caller_name} does not name #{declaration.name} in its participants.")
    end

    def owned_kinds(registry, owner)
      registry.catalog.kinds.map(&:id).select { |kind| registry.owner_of(kind) == owner }
    end

    def refuse!(request, code, message)
      error = CodedError.new(code, message)
      request.proposal&.refuse(error)
      raise error
    end
    private_class_method :run, :dependency!, :edge!, :owned_kinds, :refuse!
  end
end
