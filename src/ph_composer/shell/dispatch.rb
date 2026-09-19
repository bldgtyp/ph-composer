# frozen_string_literal: true

module PhComposer
  # Runs public queries and operations for every client: the panel, Ruby scripts and, later, external
  # adapters (CONTRACTS.md C2 to C4). It owns the host execution boundary: one mutation at a time per
  # session, validation before any operation opens, one native operation per accepted change, and a
  # verified rollback when that operation fails. Handlers only read and propose.
  class Dispatch
    REQUEST_KEYS = %w[sequence expected_revision].freeze

    # What a query or action handler receives.
    Request = Struct.new(:session, :model, :params, :engine, :revision, keyword_init: true)

    def initialize(registry = Registry.current)
      @registry = registry
    end

    def query(context, name, params)
      session, _caller, query = resolve(context, "read", name, @registry.queries)
      check_params!(query, params, session)
      refuse_if_busy!(session)
      value = query.handler.call(request_for(session, params))
      check_result!(query, value)
      Outcome.completed(:revision => session.revision, :value => value)
    rescue CodedError => error
      coded_outcome(error, session)
    rescue StandardError => error
      unexpected_outcome(error, session, name)
    end

    # What an operation would change, without changing anything. The result is bound to the revision
    # it reports; applying it later still revalidates everything.
    def preview(context, name, params)
      session, _caller, action = resolve(context, "read", name, @registry.actions)
      check_params!(action, params, session)
      refuse_if_busy!(session)
      changes = Records::ChangeSet.new
      value = action.handler.call(request_for(session, params), changes)
      check_result!(action, value)
      Outcome.completed(:revision => session.revision, :value => value, :affected => changes.affected,
                        :message => "Preview only.")
    rescue CodedError => error
      coded_outcome(error, session)
    rescue StandardError => error
      unexpected_outcome(error, session, name)
    end

    def invoke(context, name, params, request)
      session, caller, action = resolve(context, "model_write", name, @registry.actions)
      sequence, expected_revision = read_request!(request, session)
      retained = retained_outcome(session, caller, sequence, name, params, expected_revision)
      return retained if retained

      refuse_if_busy!(session)
      caller.highest_sequence = sequence
      session.outcomes.begin(caller.handle, sequence, request_digest(name, params, expected_revision))
      outcome = session.exclusive { run(session, action, params, expected_revision) }
      session.outcomes.finish(caller.handle, sequence, outcome)
    rescue CodedError => error
      coded_outcome(error, session, :mutation => true)
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

      [sequence, expected_revision]
    end

    # CONTRACTS.md C4: a sequence at or below the caller's highest accepted one is a retry, never new work.
    def retained_outcome(session, caller, sequence, name, params, expected_revision)
      entry = session.outcomes.lookup(caller.handle, sequence)
      if entry
        return pending(session) if entry.pending?
        same_request = entry.digest == request_digest(name, params, expected_revision)
        return session.outcomes.retained(caller.handle, sequence) if same_request

        raise CodedError.new("request.sequence_conflict", "Sequence #{sequence} was already used for a different " \
                                                          "request.")
      end
      return nil if sequence > caller.highest_sequence

      raise CodedError.new("request.outcome_unavailable", "Sequence #{sequence} was already used and its outcome " \
                                                          "has expired; inspect the Model before issuing new work.")
    end

    def request_digest(name, params, expected_revision)
      CanonicalJson.digest("name" => name, "params" => params, "expected_revision" => expected_revision)
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
      unless params.is_a?(Hash) && JsonValue.problems(params).empty?
        raise CodedError.new("request.malformed", "Params must be a plain JSON object.", "revision" => session.revision)
      end

      findings = JsonSchema.validate(params, declaration.params)
      return if findings.empty?

      raise CodedError.new("params.invalid", "The request is not valid: #{findings.first}.", "findings" => findings)
    end

    def check_result!(declaration, value)
      findings = JsonSchema.validate(value, declaration.result)
      return if findings.empty? && JsonValue.problems(value).empty?

      raise InternalError, "#{declaration.name} returned a result outside its schema: #{findings.first}"
    end

    def request_for(session, params)
      Request.new(:session => session, :model => session.model, :params => DeepCopy.call(params),
                  :engine => Records::Engine.new(session.model, @registry.catalog), :revision => session.revision)
    end

    # ---------------------------------------------------------------- the mutation

    def run(session, action, params, expected_revision)
      check_params!(action, params, session)
      if expected_revision != session.revision
        raise CodedError.new("revision.stale", "The Model has changed since revision #{expected_revision}; it is " \
                                               "now #{session.revision}.", "revision" => session.revision)
      end

      request = request_for(session, params)
      changes = Records::ChangeSet.new
      value = action.handler.call(request, changes)
      # A handler that rescued a refusal still proposed an incomplete change; it is refused whole.
      raise changes.refusal if changes.refusal

      check_result!(action, value)
      if changes.empty?
        return Outcome.completed(:revision => session.revision, :value => value, :message => "Nothing to change.")
      end

      commit(session, action, request.engine, changes, value)
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

    def commit(session, action, engine, changes, value)
      session.mutate do
        ModelOperation.perform(session.model, action.undo_name) { engine.apply(changes) }
        true
      end
      session.changed(:action, action.name)
      Outcome.completed(:revision => session.revision, :value => value, :effect => "committed",
                        :affected => changes.affected)
    rescue StandardError => error
      effect = verified_unchanged?(engine, changes) ? "rolled_back" : "unknown"
      Diagnostics.log("operation_failed", "operation" => action.name, "status" => effect,
                                          "error_class" => error.class.name)
      Outcome.failed(:effect => effect, :revision => session.revision)
    end

    def verified_unchanged?(engine, changes)
      engine.unchanged?(changes)
    rescue StandardError
      false
    end

    # A read that failed unexpectedly (a handler bug, a result outside its schema) answers every client
    # with the same failed outcome; the error goes to the log. Reads open no operation, so nothing changed.
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
