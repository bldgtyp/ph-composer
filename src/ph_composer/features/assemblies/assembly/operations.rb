# frozen_string_literal: true

module PhComposer
  module Assemblies
    module Assembly
      # Assembly persistence. Each operation takes its inputs as arguments: a declaration unpacks its
      # params once, and a library callback calls the same operation with its own
      # (context/EXTENSIBILITY.md, "Organization and dependencies").
      module Operations
        module_function

        def create(request, proposal, values:, user_data: nil)
          Commands.unique_name!(values.fetch("name"), Catalog.records(request, ASSEMBLY_KIND))
          defaults = Schema.defaults(values, :identity => Catalog.identity_allocator(request, "values" => values))
          id = request.engine.propose_create(ASSEMBLY_KIND, proposal, :values => defaults, :user_data => user_data)
          { "id" => id }
        end

        def update(request, proposal, id:, values:, expected_values:, user_data: nil)
          record = request.engine.find(ASSEMBLY_KIND, id)
          if values["name"]
            Commands.unique_name!(values["name"], Catalog.records(request, ASSEMBLY_KIND), :except => id)
          end
          result = Commands.update_assembly(record, :values => values, :materials => Catalog.materials(request))
          request.engine.propose_update(ASSEMBLY_KIND, id, proposal,
            :values => Catalog.changed_values(Schema::KIND, record, result.record),
            :expected_values => expected_values, :user_data => user_data)
          { "id" => id }
        end

        def duplicate(request, proposal, id:)
          catalog = Catalog.records(request, ASSEMBLY_KIND)
          identity = Catalog.identity_allocator(request, "id" => id)
          mapping = request.engine.propose_duplicate(ASSEMBLY_KIND, [id], proposal) do |values|
            Commands.duplicate_assembly_values(values, catalog, :identity => identity)
          end
          { "id" => mapping.fetch(id) }
        end

        # `retarget` moves every Face using the Assembly to `replacement_id` first; a nil replacement
        # clears their Assembly. Without it, any remaining use refuses the delete.
        def delete(request, proposal, id:, expected_values: {}, retarget: false, replacement_id: nil)
          plan = nil
          if retarget
            if replacement_id == id
              raise CodedError.new("params.invalid", "Choose a different replacement Assembly.")
            end
            plan = request.retarget_references(ASSEMBLY_KIND, :from => id, :to => replacement_id)
          end
          request.engine.propose_delete(ASSEMBLY_KIND, id, proposal, :expected_values => expected_values,
                                                                     :reference_plan => plan)
          { "id" => id }
        end

        # One Builder gesture on one Assembly: the block returns the command result for the stored record.
        def gesture(request, proposal, id:, expected_values:)
          record = request.engine.find(ASSEMBLY_KIND, id)
          result = yield record
          request.engine.propose_update(ASSEMBLY_KIND, id, proposal,
            :values => Catalog.changed_values(Schema::KIND, record, result.record),
            :expected_values => expected_values)
          { "id" => id }
        end
      end
    end
  end
end
