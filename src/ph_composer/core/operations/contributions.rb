# frozen_string_literal: true

module PhComposer
  module Operations
    # What a proposal held before a nested contributor ran, so the foundation can check the contributor
    # only added to it. A participant may stage new writes, steps and findings; it may not remove or
    # change one an earlier contributor made. New writes are already confined to the contributor's
    # owner by the projected engine it writes through, so this checks the prefix alone. A bare
    # Records::ChangeSet, which has writes only, is accepted as a proposal without steps or findings.
    module Contributions
      Snapshot = Struct.new(:writes, :steps, :findings, keyword_init: true)

      module_function

      def snapshot(proposal)
        Snapshot.new(:writes => DeepCopy.call(proposal.writes.map { |write| write_value(write) }),
                     :steps => steps(proposal).dup, :findings => DeepCopy.call(findings(proposal)))
      end

      # Raises `proposal.contribution_replaced` unless every earlier write, step and finding is still
      # there, in order: writes and findings by value, steps by identity.
      def preserved!(proposal, before)
        writes = proposal.writes.first(before.writes.length).map { |write| write_value(write) }
        steps = steps(proposal).first(before.steps.length)
        kept = writes == before.writes && findings(proposal).first(before.findings.length) == before.findings &&
               steps.length == before.steps.length && steps.zip(before.steps).all? { |now, was| now.equal?(was) }
        return if kept

        raise CodedError.new("proposal.contribution_replaced",
                             "A participant removed or changed what an earlier contributor proposed.")
      end

      def write_value(write)
        { "kind" => write.kind, "id" => write.id, "before" => write.before, "after" => write.after }
      end

      def steps(proposal)
        proposal.respond_to?(:steps) ? proposal.steps : []
      end

      def findings(proposal)
        proposal.respond_to?(:findings) ? proposal.findings : []
      end
      private_class_method :write_value, :steps, :findings
    end
  end
end
