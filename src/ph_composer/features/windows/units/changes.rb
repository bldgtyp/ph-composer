# frozen_string_literal: true

require_relative "identity_step"
require_relative "type_change_step"
require_relative "read_context"

module PhComposer
  module Windows
    module Units
      module Changes
        module_function

        def count(model, type_id)
          Occurrences.all(model).count { |item| item.record.fetch("window_type_id") == type_id }
        end

        def type(request, proposal, before:, after:)
          return unless DefinitionIndex.resolve(request.model, before.fetch("id"))

          expected = Occurrences.all(request.model).to_h { |item| [item.path, Mutation.record(proposal, item)] }
          geometry_changed = DefinitionPlan.build(before).signature != DefinitionPlan.build(after).signature
          hosts = {}
          others = {}
          if geometry_changed
            reads = ReadContext.new(request)
            definition = DefinitionIndex.resolve(request.model, before.fetch("id"))
            canonical = reads.occurrences.select { |item|
              item.entity.definition.persistent_id == definition.persistent_id
            }
            polygons = reads.other_polygons(:except => canonical.map(&:path))
            canonical.each do |item|
              next unless item.entity.glued_to

              hosts[item.path] = reads.host(item)
              others[item.path] = polygons
            end
          end
          step = TypeChangeStep.new(:model => request.model, :before => before, :after => after,
                                    :expected_records => expected, :hosts => hosts, :other_polygons_m => others)
          step.findings.each { |finding| proposal.add_finding(finding) }
          proposal.add_step(step, :scopes => [step.scope]) if step.needed?
        end
      end
    end
  end
end
