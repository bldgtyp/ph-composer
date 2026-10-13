# frozen_string_literal: true

require_relative "identity_plan"
require_relative "mutation_scope"

module PhComposer
  module Windows
    module Units
      # Identity repair is part of the caller's proposal, never a read or observer side effect.
      class IdentityStep
        attr_reader :updates, :affected

        def initialize(updates)
          @updates = updates.map do |update|
            { "reference" => DeepCopy.call(update.reference), "before" => DeepCopy.call(update.before),
              "after" => DeepCopy.call(update.after) }
          end
          @affected = @updates.map { |row|
            { "kind" => REFERENCE_KIND, "id" => row.fetch("after").fetch("id"),
              "change" => "identity_repaired", "reference" => row.fetch("reference").merge(
                "unit_id" => row.fetch("after").fetch("id")
              ) }
          }
        end

        def descriptor
          { "name" => "repair_window_copy_identities", "updates" => DeepCopy.call(updates) }
        end

        def temporary_ids
          updates.map { |row| row.fetch("after").fetch("id") }
        end

        def apply(model, _slots)
          resolved = updates.map do |row|
            item = Occurrences.resolve(model, row.fetch("reference"), :mutable => true)
            unless item.record == row.fetch("before")
              raise CodedError.new("target.changed", "A copied Window record changed after preview.")
            end

            [item.entity, row.fetch("after")]
          end
          @captured = resolved.map { |entity, _record| [entity, Units.read(entity)] }
          resolved.each { |entity, record| Units.write(entity, record) }
        end

        # Writes back what apply replaced, for a host follow-up that cannot abort. Nothing when apply
        # did not reach its writes.
        def restore
          Units.restore_all(@captured)
        end
      end

      module Mutation
        module_function

        def prepare(request, proposal, identity: nil)
          existing = proposal.steps.find { |step| step.is_a?(IdentityStep) }
          return existing if existing

          # A constant seed: the repair depends on the Model, not on the action that triggers it. Ids
          # stay unique because a proposal holds one IdentityStep and each commit moves the revision.
          allocator = identity || Records::Identity.allocator(request, "repair" => "unit_identity")
          changes = IdentityPlan.build(Occurrences.all(request.model),
                                       :identity => allocator,
                                       :catalog => request.registry.catalog, :engine => request.engine)
          return nil if changes.empty?

          proposal.add_step(IdentityStep.new(changes), :scopes => [MutationScope.new])
        end

        # The identities this proposal's repair leaves, for resolving a reference while it is staged.
        def reference_plan(proposal)
          step = proposal.steps.find { |item| item.is_a?(IdentityStep) }
          return nil unless step

          Records::ReferencePlan.new(:entries => step.updates.map do |row|
            Records::ReferenceEntry.new(:kind => REFERENCE_KIND, :key => row.fetch("reference").fetch("entity_path"),
                                        :record => row.fetch("after"))
          end)
        end

        def record(proposal, occurrence)
          step = proposal.steps.find { |item| item.is_a?(IdentityStep) }
          update = step&.updates&.find { |row| row.fetch("reference").fetch("entity_path") == occurrence.path }
          DeepCopy.call(update ? update.fetch("after") : occurrence.record)
        end
      end
    end
  end
end
