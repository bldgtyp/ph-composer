# frozen_string_literal: true

module PhComposer
  # Runs public queries and operations for every client: the panel, Ruby scripts and, later, external
  # adapters (CONTRACTS.md C2 to C4). It owns the host execution boundary: one mutation at a time per
  # session, validation before any operation opens, one native operation per accepted change, and a
  # verified rollback when that operation fails. Handlers only read and propose.
  class Dispatch
    REQUEST_KEYS = %w[sequence expected_revision proposal_digest].freeze

    # What a query or action handler receives.
    Request = Struct.new(:session, :model, :params, :engine, :revision, :registry, keyword_init: true) do
      def participant(name)
        declaration = registry.proposal_participants[name]
        raise CodedError.new("operation.participant_missing", "No proposal participant named #{name} is installed.") \
          unless declaration

        declaration.handler
      end
    end

    def initialize(registry = Registry.current)
      @registry = registry
    end

    def query(context, name, params)
      answer(context, "read", name, @registry.queries, params)
    end

    # File export has its own grant and never enters a Model mutation. Polling and cancellation
    # use the same explicit session as starting the task, even when another Model is foreground.
    def export_task(context, operation, arguments)
      session, = resolve(context, "export", nil, nil)
      tasks = Export::Tasks.for(session)
      value = case operation
              when :start then tasks.start(**arguments)
              when :status then tasks.status(arguments.fetch(:task_id))
              when :cancel then tasks.cancel(arguments.fetch(:task_id))
              when :latest then tasks.latest
              else raise InternalError, "Unknown export task operation."
              end
      Outcome.completed(:revision => session.revision, :value => value)
    rescue CodedError => error
      coded_outcome(error, session)
    rescue UserError => error
      Outcome.refused("export.refused", error.message, :revision => session&.revision)
    rescue StandardError => error
      unexpected_outcome(error, session, "export.#{operation}")
    end

    def export_preflight(context)
      session, = resolve(context, "read", nil, nil)
      value = { "findings" => [], "repairs" => [] }
      @registry.export_contributors.values.sort_by(&:name).each do |contributor|
        next unless contributor.preflight

        outcome = query(context, contributor.preflight, {})
        return outcome unless outcome["status"] == "completed"

        declared = outcome.fetch("value")
        value["findings"].concat(declared.fetch("findings"))
        declared.fetch("repairs").each do |repair|
          action = @registry.actions[repair["action"]]
          unless action&.owner == contributor.owner
            raise InternalError, "Preflight repair needs its owner's public action."
          end

          value["repairs"] << repair
        end
      end
      Outcome.completed(:revision => session.revision, :value => DeepCopy.call(value))
    rescue CodedError => error
      coded_outcome(error, session)
    rescue StandardError => error
      unexpected_outcome(error, session, "export.preflight")
    end

    # A change to what the host shows and nothing else (Declarations::ViewCommand). It carries no
    # sequence number and returns no proposal, because there is nothing to retry and nothing to undo.
    # It refuses while the session is busy, as a read does, so it cannot move the camera or the
    # selection out from under an operation that is still running.
    def view(context, name, params)
      answer(context, "view", name, @registry.view_commands, params)
    end

    # What an operation would change, without changing anything. The result is bound to the revision
    # it reports; applying it later still revalidates everything.
    def preview(context, name, params)
      session, _caller, action = resolve(context, "read", name, @registry.actions)
      check_params!(action, params, session)
      refuse_if_busy!(session)
      proposal = Operations::Proposal.new
      value = action.handler.call(request_for(session, params), proposal)
      raise proposal.refusal if proposal.refusal
      check_result!(action, value)
      Outcome.completed(:revision => session.revision, :value => value, :affected => proposal.affected,
                        :findings => proposal.findings, :proposal_digest => proposal.digest,
                        :message => "Preview only.")
    rescue CodedError => error
      coded_outcome(error, session)
    rescue StandardError => error
      unexpected_outcome(error, session, name)
    end

    # R-D3: a request whose params are not plain JSON is refused before acceptance. It cannot be
    # digested, so it consumes no sequence and retains no outcome; the caller resends it corrected
    # under the same sequence.
    def invoke(context, name, params, request)
      session, caller, action = resolve(context, "model_write", name, @registry.actions)
      sequence, expected_revision, proposal_digest = read_request!(request, session)
      check_json!(params, session)
      retained = retained_outcome(session, caller, sequence, name, params, expected_revision, proposal_digest)
      return retained if retained

      refuse_if_busy!(session)
      # Digested before the sequence is taken, so anything that cannot be canonicalized still leaves
      # the caller's sequence free.
      digest = request_digest(name, params, expected_revision, proposal_digest)
      caller.highest_sequence = sequence
      session.outcomes.begin(caller.handle, sequence, digest)
      outcome = session.exclusive { run(session, action, params, expected_revision, proposal_digest) }
      session.outcomes.finish(caller.handle, sequence, outcome)
    rescue CodedError => error
      coded_outcome(error, session, :mutation => true)
    rescue StandardError => error
      unexpected_outcome(error, session, name)
    end

    # The retained outcome of an earlier mutation request, without running it again.
    def outcome(context, request)
      session, caller, = resolve(context, "model_write", nil, nil)
      sequence = request.is_a?(Hash) ? request["sequence"] : nil
      raise CodedError.new("request.malformed", "The request needs an integer sequence.") unless sequence.is_a?(Integer)

      entry = session.outcomes.lookup(caller.handle, sequence)
      return pending(session) if entry&.pending?
      return session.outcomes.retained(caller.handle, sequence) if entry

      raise CodedError.new("request.outcome_unavailable", "No retained outcome for sequence #{sequence}; " \
                                                          "inspect the Model before issuing new work.")
    rescue CodedError => error
      coded_outcome(error, session)
    end

    private

    # ---------------------------------------------------------------- acceptance

    # A read and a view command run the same way: validate, refuse while busy, call the handler, check
    # the result against its declared schema. They differ in the capability they need and in what the
    # handler is allowed to touch, which is the declaration's business rather than this method's.
    def answer(context, capability, name, declarations, params)
      session, _caller, declaration = resolve(context, capability, name, declarations)
      check_params!(declaration, params, session)
      refuse_if_busy!(session)
      value = declaration.handler.call(request_for(session, params))
      check_result!(declaration, value)
      Outcome.completed(:revision => session.revision, :value => value)
    rescue CodedError => error
      coded_outcome(error, session)
    rescue UserError => error
      # A handler that refuses what it was asked for says why, as an operation does: "There is no
      # Colour-by mode named ..." is the answer, not a generic failure.
      Outcome.refused("validation.failed", error.message, :revision => session&.revision)
    rescue StandardError => error
      unexpected_outcome(error, session, name)
    end

    def resolve(context, capability, name, declarations)
      unless context.is_a?(OperationContext)
        raise CodedError.new("request.malformed", "The context must come from PhComposer::API.connect.")
      end
      unless context.api_major == API::MAJOR
        raise CodedError.new("request.api_version", "This build answers API #{API::MAJOR}, " \
                                                    "not #{context.api_major.inspect}.")
      end

      session = Sessions.find(context.session_id)
      raise CodedError.new("session.unknown", "That Model session is closed or was never opened.") unless session

      caller = session.callers.fetch(context.caller)
      raise CodedError.new("session.unknown", "This caller was not connected to that Model session.") unless caller

      declaration = declarations && declarations[name]
      if declarations && !declaration
        raise CodedError.new("request.unknown_operation", "There is no operation named #{name.inspect}.")
      end
      unless caller.capabilities.include?(capability)
        raise CodedError.new("request.capability_denied", "This caller was not granted #{capability} access.")
      end

      [session, caller, declaration]
    end

    def read_request!(request, session)
      unless request.is_a?(Hash) && (request.keys - REQUEST_KEYS).empty?
        raise CodedError.new("request.malformed", "The request may hold only #{REQUEST_KEYS.join(' and ')}.")
      end

      sequence = request["sequence"]
      expected_revision = request["expected_revision"]
      unless sequence.is_a?(Integer) && sequence.positive? && expected_revision.is_a?(Integer)
        raise CodedError.new("request.malformed", "The request needs a positive integer sequence and an " \
                                                  "integer expected_revision.", "revision" => session.revision)
      end

      proposal_digest = request["proposal_digest"]
      unless proposal_digest.nil? || proposal_digest.is_a?(String)
        raise CodedError.new("request.malformed", "proposal_digest must be a string when supplied.")
      end

      [sequence, expected_revision, proposal_digest]
    end

    # CONTRACTS.md C4: a sequence at or below the caller's highest accepted one is a retry, never new work.
    def retained_outcome(session, caller, sequence, name, params, expected_revision, proposal_digest)
      entry = session.outcomes.lookup(caller.handle, sequence)
      if entry
        return pending(session) if entry.pending?
        same_request = entry.digest == request_digest(name, params, expected_revision, proposal_digest)
        return session.outcomes.retained(caller.handle, sequence) if same_request

        raise CodedError.new("request.sequence_conflict", "Sequence #{sequence} was already used for a different " \
                                                          "request.")
      end
      return nil if sequence > caller.highest_sequence

      raise CodedError.new("request.outcome_unavailable", "Sequence #{sequence} was already used and its outcome " \
                                                          "has expired; inspect the Model before issuing new work.")
    end

    def request_digest(name, params, expected_revision, proposal_digest = nil)
      CanonicalJson.digest("name" => name, "params" => params, "expected_revision" => expected_revision,
                           "proposal_digest" => proposal_digest)
    end

    def pending(session)
      Outcome.refused("request.pending", "That request is still running.", :status => "pending",
                                                                            :revision => session.revision)
    end

    def refuse_if_busy!(session)
      reason = session.busy_reason
      raise CodedError.new("session.busy", reason, "reason" => reason) if reason
    end

    def check_params!(declaration, params, session)
      check_json!(params, session)
      findings = JsonSchema.validate(params, declaration.params)
      return if findings.empty?

      raise CodedError.new("params.invalid", "The request is not valid: #{findings.first}.", "findings" => findings)
    end

    def check_json!(params, session)
      return if params.is_a?(Hash) && JsonValue.problems(params).empty?

      raise CodedError.new("request.malformed", "Params must be a plain JSON object.", "revision" => session.revision)
    end

    def check_result!(declaration, value)
      findings = JsonSchema.validate(value, declaration.result)
      return if findings.empty? && JsonValue.problems(value).empty?

      raise InternalError, "#{declaration.name} returned a result outside its schema: #{findings.first}"
    end

    def request_for(session, params)
      Request.new(:session => session, :model => session.model, :params => DeepCopy.call(params),
                  :engine => Records::Engine.new(session.model, @registry.catalog), :revision => session.revision,
                  :registry => @registry)
    end

    # ---------------------------------------------------------------- the mutation

    def run(session, action, params, expected_revision, expected_proposal_digest)
      check_params!(action, params, session)
      if expected_revision != session.revision
        raise CodedError.new("revision.stale", "The Model has changed since revision #{expected_revision}; it is " \
                                               "now #{session.revision}.", "revision" => session.revision)
      end

      request = request_for(session, params)
      proposal = Operations::Proposal.new
      value = action.handler.call(request, proposal)
      # A handler that rescued a refusal still proposed an incomplete change; it is refused whole.
      raise proposal.refusal if proposal.refusal

      check_result!(action, value)
      if expected_proposal_digest && expected_proposal_digest != proposal.digest
        raise CodedError.new("proposal.changed", "The proposed change no longer matches the preview.")
      end
      if proposal.empty?
        # Nothing to write is not nothing to say. A handler that only had findings, such as a Solve
        # whose every candidate was a sliver, still has to hand them back.
        return Outcome.completed(:revision => session.revision, :value => value,
                                 :findings => proposal.findings, :message => "Nothing to change.")
      end

      commit(session, action, request.engine, proposal, value)
    rescue CodedError => error
      coded_outcome(error, session, :mutation => true)
    rescue UserError => error
      Outcome.refused("validation.failed", error.message, :revision => session.revision, :mutation => true)
    rescue StandardError => error
      Diagnostics.log("operation_failed", "operation" => action.name, "code" => "operation.failed",
                                          "error_class" => error.class.name)
      Outcome.refused("operation.failed", "The change could not be prepared.", :status => "failed",
                                                                                :revision => session.revision,
                                                                                :mutation => true)
      # `failed` with effect `none`: the error came before any operation opened.
    end

    def commit(session, action, engine, proposal, value)
      proposal.capture(session.model)
      session.mutate do
        ModelOperation.perform(session.model, action.undo_name) { proposal.apply(session.model, engine) }
        true
      end
      session.changed(:action, action.name)
      Outcome.completed(:revision => session.revision, :value => value, :effect => "committed",
                        :affected => proposal.affected, :findings => proposal.findings,
                        :proposal_digest => proposal.digest)
    rescue StandardError => error
      effect = verified_unchanged?(session.model, engine, proposal) ? "rolled_back" : "unknown"
      Diagnostics.log("operation_failed", "operation" => action.name, "status" => effect,
                                          "error_class" => error.class.name)
      reason = error.is_a?(CodedError) ? error : nil
      Outcome.failed(:effect => effect, :revision => session.revision, :reason => reason)
    end

    def verified_unchanged?(model, engine, proposal)
      proposal.unchanged?(model, engine)
    rescue StandardError
      false
    end

    # A read or a view command that failed unexpectedly (a handler bug, a result outside its schema)
    # answers every client with the same failed outcome; the error goes to the log. Neither opens an
    # operation, so `effect` is "none": the Model is unchanged. A view command may still have moved the
    # viewport part-way, which is why a client re-reads what it shows rather than assuming.
    def unexpected_outcome(error, session, name)
      Diagnostics.log("operation_failed", "operation" => name, "code" => "operation.failed",
                                          "error_class" => error.class.name)
      Outcome.refused("operation.failed", "The request could not be answered.", :status => "failed",
                                                                                 :revision => session&.revision)
    end

    def coded_outcome(error, session, mutation: false)
      revision = session&.revision || (error.detail.is_a?(Hash) ? error.detail["revision"] : nil)
      status = { "session.busy" => "busy", "request.pending" => "pending" }.fetch(error.code, "refused")
      findings = error.detail.is_a?(Hash) ? Array(error.detail["findings"]) : []
      Outcome.refused(error.code, error.message, :status => status, :revision => revision,
                                                 :mutation => mutation, :findings => findings, :detail => error.detail)
    end
  end
end
