# frozen_string_literal: true

module PhComposer
  module Assemblies
    # Feature handlers read the explicit record target and stage through the public record engine.
    # The dispatcher validates and applies the entire proposal in one native transaction.
    module Operations
      module_function

      # Preview and invoke rebuild the same nested identities at the same revision. The allocator
      # is proposal-local and deterministic; it retains no state across Models or requests.
      def identity_allocator(request)
        sequence = 0
        lambda do |prefix|
          sequence += 1
          Records::Identity.derived(prefix, "session" => request.session.id, "revision" => request.revision,
                                    "params" => request.params, "position" => sequence)
        end
      end

      def records(request, kind)
        request.engine.ids(kind).map { |id| request.engine.find(kind, id) }
      end

      def materials(request)
        records(request, MATERIAL_KIND).to_h { |row| [row.fetch("id"), row] }
      end

      def create(request, proposal, kind)
        values = request.params.fetch("values")
        catalog = records(request, kind)
        Commands.unique_name!(values.fetch("name"), catalog)
        defaults = if kind == MATERIAL_KIND
                     Materials::Schema.defaults(values)
                   else
                     Assembly::Schema.defaults(values, :identity => identity_allocator(request))
                   end
        id = request.engine.propose_create(kind, proposal, :values => defaults,
                                          :user_data => request.params["user_data"])
        { "id" => id }
      end

      def update(request, proposal, kind)
        id = request.params.fetch("id")
        record = request.engine.find(kind, id)
        values = request.params.fetch("values")
        Commands.unique_name!(values["name"], records(request, kind), :except => id) if values["name"]
        result = if kind == MATERIAL_KIND
                   Commands.update_material(record, :values => values)
                 else
                   Commands.update_assembly(record, :values => values, :materials => materials(request))
                 end
        changes = changed_values(request.engine.kind(kind), record, result.record)
        request.engine.propose_update(kind, id, proposal, :values => changes,
          :expected_values => request.params.fetch("expected_values"), :user_data => request.params["user_data"])
        { "id" => id }
      end

      def duplicate(request, proposal, kind)
        id = request.params.fetch("id")
        catalog = records(request, kind)
        mapping = request.engine.propose_duplicate(kind, [id], proposal) do |values|
          if kind == MATERIAL_KIND
            Commands.duplicate_material_values(values, catalog, :name => request.params["name"],
              :copy_datasheets => request.params.fetch("copy_datasheets", false))
          else
            Commands.duplicate_assembly_values(values, catalog, :identity => identity_allocator(request))
          end
        end
        { "id" => mapping.fetch(id) }
      end

      def delete_material(request, proposal)
        id = request.params.fetch("id")
        request.engine.find(MATERIAL_KIND, id)
        replacement_id = request.params["replacement_id"]
        if replacement_id
          raise CodedError.new("params.invalid", "Choose a different replacement Material.") if replacement_id == id

          catalog = materials(request)
          replacement = request.engine.find(MATERIAL_KIND, replacement_id)
          records(request, ASSEMBLY_KIND).each do |record|
            next unless Assembly::Schema::KIND.references.first.ids(record).include?(id)

            result = Commands.replace_material(record, :material_id => id, :replacement => replacement,
                                                :materials => catalog)
            request.engine.propose_update(ASSEMBLY_KIND, record.fetch("id"), proposal,
              :values => changed_values(Assembly::Schema::KIND, record, result.record),
              :expected_values => { "layers" => record.fetch("layers") })
          end
        end
        request.engine.propose_delete(MATERIAL_KIND, id, proposal,
          :expected_values => request.params.fetch("expected_values", {}))
        { "id" => id }
      end

      def delete_assembly(request, proposal)
        id = request.params.fetch("id")
        plan = nil
        if request.params.key?("replacement_id")
          replacement = request.params["replacement_id"]
          if replacement == id
            raise CodedError.new("params.invalid", "Choose a different replacement Assembly.")
          end
          plan = request.retarget_references(ASSEMBLY_KIND, :from => id, :to => replacement)
        end
        request.engine.propose_delete(ASSEMBLY_KIND, id, proposal,
          :expected_values => request.params.fetch("expected_values", {}), :reference_plan => plan)
        { "id" => id }
      end

      def gesture(request, proposal)
        id = request.params.fetch("id")
        record = request.engine.find(ASSEMBLY_KIND, id)
        result = yield record
        request.engine.propose_update(ASSEMBLY_KIND, id, proposal,
          :values => changed_values(Assembly::Schema::KIND, record, result.record),
          :expected_values => request.params.fetch("expected_values"))
        { "id" => id }
      end

      def changed_values(kind, before, after)
        values = kind.values(after)
        (kind.values(before).keys | values.keys).each_with_object({}) do |key, changed|
          changed[key] = values[key] if before[key] != values[key] || before.key?(key) != values.key?(key)
        end
      end
    end
  end
end
