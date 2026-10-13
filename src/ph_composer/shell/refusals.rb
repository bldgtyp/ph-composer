# frozen_string_literal: true

require_relative "../library/refuses"

module PhComposer
  # What an operation can refuse with (context/CONTRACTS.md, "Outcomes and codes"). Each operation
  # declares `refuses`, the codes its handler and the dependencies it calls can answer with an outcome
  # that is not `completed`. COMMON holds the codes dispatch answers for every operation of a kind,
  # whatever its handler does, so no operation repeats them. An operation that declares an `approval`
  # also answers the "approval" set, and the "location" set when an approved location may answer it.
  # `discover` publishes the sets once and `describe` names the sets one operation answers.
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
      # What the foundation's invocation answers for any participant (shell/participant_invocation.rb).
      "participant" => (ANY_OPERATION + %w[operation.proposal_required operation.participant_cycle
                                           proposal.foreign_write proposal.contribution_replaced]).freeze,
      "approval" => %w[access.user_required request.cancelled].freeze,
      "location" => %w[location.unknown location.revoked location.used location.kind_mismatch location.unavailable
                       location.setup_unreadable location.setup_unavailable].freeze
    }.freeze
    # Codes no handler raises: an unknown name never reaches one, and only dispatch or a native client
    # answers for an approval. An operation's `refuses` never lists them.
    DISPATCH_ONLY = (%w[request.unknown_operation] + COMMON.fetch("approval")).freeze

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

    # Discovery, generated references and the offline audit use this one projection: the operation's
    # own codes, the installed library callback codes it runs, and everything every participant it
    # names can answer (its own codes and the `participant` set), through their own `participants`.
    # The library service contributes its callback codes without naming any receiving feature.
    def declared(declaration, registry = Registry.current)
      effective(declaration, registry, [declaration.name]).uniq - common(declaration)
    end

    def effective(declaration, registry, seen)
      codes = declaration.refuses + Library::Refuses.callback_codes(registry, declaration.name)
      Array(declaration.respond_to?(:participants) ? declaration.participants : nil).each do |name|
        participant = registry.proposal_participants[name]
        next if participant.nil? || seen.include?(name)

        codes += effective(participant, registry, seen + [name]) + COMMON.fetch("participant")
      end
      codes
    end
    private_class_method :effective

    # The names of the COMMON sets one operation answers. A participant answers what any operation
    # does; the action that calls it adds its own set.
    def common_sets(declaration)
      return ["participant"] if declaration.is_a?(Declarations::ProposalParticipant)

      sets = [Declarations::OPERATION_KINDS.fetch(declaration.class)]
      approval = declaration.respond_to?(:approval) && declaration.approval
      sets << "approval" if approval
      sets << "location" if approval && !approval.standing
      sets
    end

    def common(declaration)
      common_sets(declaration).flat_map { |set| COMMON.fetch(set) }
    end
  end
end
