# frozen_string_literal: true

require_relative "swap_step"
require_relative "remove_step"
require_relative "read_context"
require_relative "identity_step"
require_relative "type_cleanup_step"

module PhComposer
  module Windows
    module Units
      module TypeRetargeter
        module_function

        def install(feature)
          feature.reference_retargeter("#{FEATURE_ID}.units.retarget_type", :target_kind => TYPE_KIND) do |request,
 proposal, from:, to:|
            retarget(request, proposal, :from => from, :to => to)
          end
        end

        # Types::Operations.delete has already prepared identity repairs. Reference removals retain
        # the original inventory preimages; native steps consume the projected post-repair records.
        def retarget(request, proposal, from:, to:)
          occurrences = Occurrences.all(request.model)
          items = occurrences.select { |item| item.record.fetch("window_type_id") == from }
          expected = occurrences.to_h { |item| [item.path, Mutation.record(proposal, item)] }
          target = to && request.engine.find(TYPE_KIND, to)
          plan = if target && !items.empty?
                   swap(request, proposal, items, expected, target)
                 else
                   remove(request, proposal, occurrences, items, expected)
                 end
          cleanup(request, proposal, request.engine.find(TYPE_KIND, from),
                  :moved_ids => items.map { |item| item.entity.persistent_id }, :target_type => target)
          plan
        end

        def cleanup(request, proposal, type, moved_ids: [], target_type: nil)
          step = TypeCleanupStep.new(:model => request.model, :type_id => type.fetch("id"),
                                     :moved_ids => moved_ids, :target_type => target_type)
          proposal.add_step(step, :scopes => [step.scope]) if step.needed?
        end

        def swap(request, proposal, items, expected, target)
          reads = ReadContext.new(request)
          others = reads.other_polygons(:except => items.map(&:path))
          source = request.engine.find(TYPE_KIND, items.first.record.fetch("window_type_id"))
          step = SwapStep.new(:model => request.model, :target_type => target, :expected_records => expected,
                              :items => items.map do |item|
                                          { :reference => item.reference, :expected_record => expected.fetch(item.path), :from_type => source,
                                            :host => reads.host(item), :other_polygons_m => others }
                                        end)
          proposal.add_step(step, :scopes => [step.scope]) if step.needed?
          step.reference_plan
        end

        def remove(request, proposal, occurrences, items, expected)
          steps = items.map do |item|
            RemoveStep.new(:model => request.model, :reference => item.reference,
                           :expected_record => expected.fetch(item.path))
          end
          removed_paths = items.map(&:path)
          plan = Records::ReferencePlan.new(:entries => occurrences.reject { |item|
                                                          removed_paths.include?(item.path)
                                                        }.map do |item|
                                                          Records::ReferenceEntry.new(:kind => REFERENCE_KIND, :key => item.path,
                                                                                      :record => expected.fetch(item.path))
                                                        end, :removals => steps.zip(items).map { |step, item|
                                                                            step.removal(:before_record => item.record)
                                                                          })
          steps.each do |step|
            request.engine.check_identity_removal!(REFERENCE_KIND, step.affected.first.fetch("id"),
                                                   :change_set => proposal.record_changes, :reference_plan => plan)
          end
          steps.each do |step|
            path = step.affected.first.fetch("reference").fetch("entity_path")
            proposal.add_step(step, :scopes => [MutationScope.new,
                                                PhComposer::Operations::EntityScope.new(path[0...-1])])
          end
          plan
        end
        private_class_method :swap, :remove
      end
    end
  end
end
