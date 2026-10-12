# frozen_string_literal: true

module PhComposer
  # The internal entry for host-caused follow-up work. It shares the dispatcher's params check and
  # request construction (RequestChecks) and is not registered anywhere a caller can reach.
  class HostFollowUp
    include RequestChecks

    def self.run(session, name, params_list, registry: Registry.current)
      new(registry).run_follow_up(session, name, params_list)
    end

    def initialize(registry)
      @registry = registry
    end

    # Host-caused follow-up work, never reachable from the panel or the API: runs one registered
    # action's handler for each params into one proposal and joins the user's last native step as a
    # transparent operation (context/TECH_STACK.md, "Join the user's Undo step"). A refusal from any
    # member declines the whole gesture before anything is written.
    #
    # It never aborts: aborting a transparent operation undoes the native step it joined (measured,
    # context/SKETCHUP_HOST_BEHAVIOR.md). So every step must answer `restore`, writing back what its
    # apply wrote; on a failure the applied steps restore in reverse and the operation commits. Record
    # changes cannot be restored this way and are not accepted. The answer is an internal hash for the
    # caller's notice, not a public outcome: after a restore, work such as storage isolation remains.
    def run_follow_up(session, name, params_list)
      raise CodedError.new("session.unknown", "That Model session is closed.") unless session.valid?

      action = @registry.actions.fetch(name)
      proposal = Operations::Proposal.new
      engine = nil
      values = params_list.map do |params|
        check_params!(action, params, session)
        request = request_for(session, params, action, proposal)
        engine = request.engine
        action.handler.call(request, proposal)
      end
      raise proposal.refusal if proposal.refusal
      return { "status" => "completed", "values" => values } if proposal.empty?
      unless proposal.record_changes.empty? && proposal.steps.all? { |step| step.respond_to?(:restore) }
        raise InternalError, "#{name} cannot join a native step: a step it proposes cannot be restored."
      end

      failure = nil
      session.exclusive do
        session.mutate do
          failure = join(session.model, action.undo_name, proposal, engine)
          true
        end
      end
      return { "status" => "completed", "values" => values } unless failure

      Diagnostics.log("follow_up_failed", "operation" => name, "error_class" => failure.fetch(:error).class.name,
                                          "status" => failure.fetch(:restored) ? "restored" : "unrestored")
      { "status" => "failed", "restored" => failure.fetch(:restored), "message" => failure.fetch(:error).message }
    rescue CodedError => error
      { "status" => "refused", "code" => error.code, "message" => error.message }
    end

    private

    # Applies the proposal in one transparent operation and always closes it by committing. Answers
    # nil, or the failure and whether every applied step restored what it wrote.
    def join(model, name, proposal, engine)
      raise ModelOperation::OperationError, "SketchUp refused to start #{name}" unless
        model.start_operation(name.to_s, true, false, true)

      failure = nil
      begin
        proposal.apply(model, engine)
      rescue StandardError => error
        failure = { :error => error, :restored => restore_steps(proposal) }
      end
      raise ModelOperation::OperationError, "SketchUp refused to commit #{name}" unless model.commit_operation

      failure
    end

    def restore_steps(proposal)
      proposal.steps.reverse_each(&:restore)
      true
    rescue StandardError => error
      Diagnostics.exception("follow_up_restore", error)
      false
    end
  end
end
