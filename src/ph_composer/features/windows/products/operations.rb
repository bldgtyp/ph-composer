# frozen_string_literal: true

module PhComposer
  module Windows
    module Products
      # Frames, Glazings and Psi-Install Types share one persistence path, chosen by collection
      # name. Each operation takes its inputs as arguments, so a library callback calls the same
      # operation its action does; the supplied engine validates the whole proposal.
      module Operations
        module_function

        def create(request, proposal, collection, values:, user_data: nil)
          Units::Mutation.prepare(request, proposal)
          kind = KINDS.fetch(collection)
          Catalog.unique_name!(values.fetch("name"), Catalog.records(request, kind))
          id = request.engine.propose_create(kind.id, proposal, :values => Products.defaults(collection, values),
                                                                :user_data => user_data)
          { "id" => id }
        end

        def update(request, proposal, collection, id:, values:, expected_values:, user_data: nil)
          Units::Mutation.prepare(request, proposal)
          kind = KINDS.fetch(collection)
          request.engine.find(kind.id, id)
          values = DeepCopy.call(values)
          if values["name"]
            values["name"] = values["name"].strip
            Catalog.unique_name!(values["name"], Catalog.records(request, kind), :except => id)
          end
          request.engine.propose_update(kind.id, id, proposal, :values => values,
            :expected_values => expected_values, :user_data => user_data)
          { "id" => id }
        end

        def duplicate(request, proposal, collection, id:, name: nil, copy_datasheets: false)
          Units::Mutation.prepare(request, proposal)
          kind = KINDS.fetch(collection)
          rows = Catalog.records(request, kind)
          mapping = request.engine.propose_duplicate(kind.id, [id], proposal) do |values|
            values["name"] = (name || Catalog.duplicate_name(values.fetch("name"), rows)).strip
            Catalog.unique_name!(values["name"], rows)
            values["source"] = { "kind" => "derived" }
            values["datasheet_links"] = [] unless copy_datasheets
            values
          end
          { "id" => mapping.fetch(id) }
        end

        # `retarget` moves every Window Type and default using the product to `replacement_id` first.
        # Without it, a remaining use refuses the delete.
        def delete(request, proposal, collection, id:, expected_values: {}, retarget: false, replacement_id: nil)
          Units::Mutation.prepare(request, proposal)
          kind = KINDS.fetch(collection)
          current = request.engine.find(kind.id, id)
          plan = nil
          if retarget
            raise CodedError.new("params.invalid", "Choose a different replacement record.") if replacement_id == id

            replacement = replacement_id && request.engine.find(kind.id, replacement_id)
            replace_in_types(request, proposal, collection, current, replacement)
            plan = request.retarget_references(kind.id, :from => id, :to => replacement_id)
          end
          request.engine.propose_delete(kind.id, id, proposal,
            :expected_values => expected_values, :reference_plan => plan)
          { "id" => id }
        end

        # Every Window Type element using `current` takes `replacement` instead, or none when it is nil.
        def replace_in_types(request, proposal, collection, current, replacement)
          if replacement && Products.number_keys(collection).any? { |key| !current[key].nil? && replacement[key].nil? }
            raise CodedError.new("validation.failed", "The replacement is missing an authored thermal input.")
          end
          kind_id = KINDS.fetch(collection).id
          references = Types::KIND.references.select { |reference| reference.target_kind == kind_id }
          remap = { current.fetch("id") => replacement && replacement.fetch("id") }
          Catalog.records(request, Types::KIND).each do |type|
            next unless references.any? { |reference| reference.ids(type).include?(current.fetch("id")) }

            after = references.reduce(type) { |value, reference| reference.remap(value, remap) }
            request.engine.propose_update(TYPE_KIND, type.fetch("id"), proposal,
              :values => { "elements" => after.fetch("elements") },
              :expected_values => { "elements" => type.fetch("elements") })
          end
        end
      end
    end
  end
end
