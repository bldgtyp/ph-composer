# frozen_string_literal: true

require_relative "remove_step"
require_relative "rehost_step"
require_relative "swap_step"
require_relative "reset_step"
require_relative "flip_step"
require_relative "restore_step"
require_relative "read_context"
require_relative "identity_step"

module PhComposer
  module Windows
    module Units
      module Repairs
        module_function

        def targets(request)
          references = request.params.fetch("units")
          unless references.map { |reference| reference.fetch("entity_path") }.uniq.length == references.length
            raise CodedError.new("params.invalid", "Choose each Window occurrence once.")
          end
          references.map { |reference| Occurrences.resolve(request.model, reference, :mutable => true) }
        end

        def projected_records(request, proposal)
          Occurrences.all(request.model).to_h { |item| [item.path, Mutation.record(proposal, item)] }
        end

        def restore(request, proposal)
          identity = Operations.allocator(request)
          Mutation.prepare(request, proposal, :identity => identity)
          reads = ReadContext.new(request)
          host = reads.host_reference(request.params.fetch("host"))
          type = request.engine.find(TYPE_KIND, request.params.fetch("type_id"))
          record = { "id" => identity.call("wun"), "schema_version" => 1,
            "window_type_id" => type.fetch("id"), "anchor" => Anchors::DEFAULT }
          step = RestoreStep.new(:model => request.model, :host => host, :type => type, :record => record,
            :pane_paths => request.params.fetch("pane_paths"), :existing_polygons_m => reads.other_polygons)
          proposal.add_step(step, :scopes => step.scopes)
          { "unit_id" => record.fetch("id") }
        end

        def new_flipped_type(request, proposal)
          item = Occurrences.resolve(request.model, request.params.fetch("unit"), :mutable => true)
          Mutation.prepare(request, proposal)
          expected = projected_records(request, proposal)
          reads = ReadContext.new(request)
          source = request.engine.find(TYPE_KIND, item.record.fetch("window_type_id"))
          target = flipped_type(request, proposal, source)
          step = FlipStep.new(:model => request.model, :source_type => source, :target_type => target,
            :reference => item.reference, :expected_record => expected.fetch(item.path), :expected_records => expected,
            :host => reads.host(item), :other_polygons_m => reads.other_polygons(:except => [item.path]))
          proposal.add_step(step, :scopes => [step.scope])
          step.findings.each { |finding| proposal.add_finding(finding) }
          { "unit_id" => expected.fetch(item.path).fetch("id"), "type_id" => target.fetch("id") }
        end

        def flipped_type(request, proposal, source)
          identity = Operations.allocator(request)
          rows = Operations.records(request, Types::KIND)
          name = request.params["name"] || Operations.duplicate_name("#{source.fetch('name')} (flipped)", rows)
          Operations.unique_name!(name, rows)
          mapping = request.engine.propose_duplicate(TYPE_KIND, [source.fetch("id")], proposal) do |values|
            values["name"] = name.strip
            values["source"] = { "kind" => "derived" }
            values["datasheet_links"] = []
            values["product_photos"] = []
            values.fetch("elements").each { |element| element["id"] = identity.call("wel") }
            GridOperations.apply(values, "flip", {}, :identity => identity)
          end
          proposal.find(TYPE_KIND, mapping.fetch(source.fetch("id"))).after
        end
        private_class_method :flipped_type

        def swap_type(request, proposal)
          items = targets(request)
          Mutation.prepare(request, proposal)
          expected = projected_records(request, proposal)
          reads = ReadContext.new(request)
          type = request.engine.find(TYPE_KIND, request.params.fetch("type_id"))
          others = reads.other_polygons(:except => items.map(&:path))
          step = SwapStep.new(:model => request.model, :target_type => type, :expected_records => expected,
            :items => items.map do |item|
              { :reference => item.reference, :expected_record => expected.fetch(item.path),
                :from_type => reads.type(item), :host => reads.host(item), :other_polygons_m => others }
            end)
          proposal.add_step(step, :scopes => [step.scope]) if step.needed?
          { "unit_ids" => items.map { |item| expected.fetch(item.path).fetch("id") } }
        end

        def reset_to_type(request, proposal)
          items = targets(request)
          ids = items.map { |item| item.record.fetch("window_type_id") }.uniq
          unless ids.length == 1
            raise CodedError.new("params.invalid", "Reset one Window Type at a time.")
          end
          Mutation.prepare(request, proposal)
          expected = projected_records(request, proposal)
          reads = ReadContext.new(request)
          type = request.engine.find(TYPE_KIND, ids.first)
          rows = reads.occurrences.select { |item| item.record.fetch("window_type_id") == ids.first }
          hosts = rows.to_h { |item| [item.path, reads.host(item, :writable => false)] }
          outlines = reads.occurrences.to_h { |item| [item.path, reads.read_polygon(item)] }
          step = ResetStep.new(:model => request.model, :type => type, :expected_records => expected,
            :items => items.map { |item| { :reference => item.reference,
              :expected_record => expected.fetch(item.path) } }, :hosts => hosts, :outline_inventory_m => outlines)
          proposal.add_step(step, :scopes => [step.scope]) if step.needed?
          step.findings.each { |finding| proposal.add_finding(finding) }
          { "unit_ids" => items.map { |item| expected.fetch(item.path).fetch("id") } }
        end

        def remove(request, proposal)
          items = targets(request)
          Mutation.prepare(request, proposal)
          expected = projected_records(request, proposal)
          steps = items.map do |item|
            RemoveStep.new(:model => request.model, :reference => item.reference,
              :expected_record => expected.fetch(item.path))
          end
          removed_paths = items.map(&:path)
          remaining = Occurrences.all(request.model).reject { |item| removed_paths.include?(item.path) }
          plan = Records::ReferencePlan.new(:entries => remaining.map do |item|
            Records::ReferenceEntry.new(:kind => REFERENCE_KIND, :key => item.path,
              :record => expected.fetch(item.path))
          end, :removals => steps.zip(items).map { |step, item| step.removal(:before_record => item.record) })
          steps.each do |step|
            id = step.affected.first.fetch("id")
            request.engine.check_identity_removal!(REFERENCE_KIND, id, :change_set => proposal.record_changes,
              :reference_plan => plan)
          end
          steps.each do |step|
            reference = step.affected.first.fetch("reference")
            proposal.add_step(step, :scopes => [MutationScope.new,
              PhComposer::Operations::EntityScope.new(reference.fetch("entity_path")[0...-1])])
          end
          { "unit_ids" => steps.map { |step| step.affected.first.fetch("id") } }
        end

        def rehost(request, proposal)
          item = Occurrences.resolve(request.model, request.params.fetch("unit"), :mutable => true)
          Mutation.prepare(request, proposal)
          expected = projected_records(request, proposal)
          reads = ReadContext.new(request)
          host = reads.host_reference(request.params.fetch("host"))
          type = request.engine.find(TYPE_KIND, item.record.fetch("window_type_id"))
          definition_ids = reads.occurrences.map { |row| row.entity.definition.persistent_id }
          scope = MutationScope.new(:definition_ids => definition_ids)
          guard = scope.capture(request.model, :expected_records => expected)
          step = RehostStep.new(:model => request.model, :reference => item.reference,
            :expected_record => expected.fetch(item.path), :host => host, :type => type,
            :existing_polygons_m => reads.other_polygons(:except => [item.path]),
            :expected_scope => scope, :expected_state => guard)
          proposal.add_step(step, :scopes => [scope])
          { "unit_id" => expected.fetch(item.path).fetch("id") }
        end
      end
    end
  end
end
