# frozen_string_literal: true

module PhComposer
  # What an operation can refuse with (context/CONTRACTS.md, "Outcomes and codes"). Each operation
  # declares `refuses`, the codes its handler and the dependencies it calls can answer with an outcome
  # that is not `completed`. COMMON holds the codes dispatch answers for every operation of a kind,
  # whatever its handler does, so no operation repeats them. An operation that declares an `approval`
  # also answers the "approval" set. `discover` publishes the sets once and `describe` names the sets
  # one operation answers.
  module Refusals
    ANY_OPERATION = %w[request.malformed request.api_version request.capability_denied session.unknown session.busy
                       params.invalid operation.failed].freeze
    COMMON = {
      "query" => ANY_OPERATION,
      "action" => (ANY_OPERATION + %w[request.pending request.sequence_conflict request.outcome_unavailable
                                      revision.stale proposal.changed operation.rollback_unverified]).freeze,
      "view_command" => ANY_OPERATION,
      "setup_command" => ANY_OPERATION,
      "file_export" => ANY_OPERATION,
      "approval" => %w[access.user_required request.cancelled].freeze
    }.freeze

    class << self
      # A callable receiving `(declaration, code)` for every outcome of a registered operation that is
      # not `completed`. Nil in production; the offline suite installs one that fails a test whose
      # operation answers a code outside its `refuses` and common sets.
      attr_accessor :audit
    end

    module_function

    # Hands `outcome` to the audit when it is a registered operation's refusal, and returns it.
    def report(declaration, outcome)
      audit&.call(declaration, outcome["code"]) if declaration && outcome && outcome["status"] != "completed"
      outcome
    end

    # The names of the COMMON sets one operation answers.
    def common_sets(declaration)
      sets = [Declarations::OPERATION_KINDS.fetch(declaration.class)]
      sets << "approval" if declaration.respond_to?(:approval) && declaration.approval
      sets
    end

    def common(declaration)
      common_sets(declaration).flat_map { |set| COMMON.fetch(set) }
    end
  end
end
