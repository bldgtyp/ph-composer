# frozen_string_literal: true

module PhComposer
  module Windows
    # Operations are the persistence boundary: pure type transformations return detached values;
    # the supplied engine validates all records and references in one native proposal. Each takes
    # its inputs as arguments, so a library assignment calls the same operation its action does.
    module Operations
      module_function

      # `inputs` are the operation's arguments, so two edits at one revision derive different ids.
      def allocator(request, inputs)
        position = 0
        lambda do |prefix|
          position += 1
          Records::Identity.derived(prefix, "session" => request.session.id, "revision" => request.revision,
            "params" => inputs, "position" => position)
        end
      end

      def records(request, kind)
        request.engine.ids(kind.id).map { |id| request.engine.find(kind.id, id) }
      end

      def kind(collection)
        collection == "types" ? Types::KIND : Products::KINDS.fetch(collection)
      end

      def unique_name!(name, rows, except: nil)
        if name.strip.empty? || rows.any? { |row| row["id"] != except && row["name"].strip.casecmp(name.strip).zero? }
          raise CodedError.new("validation.failed", "Give the record a unique, nonempty name.")
        end
      end

      def duplicate_name(name, rows)
        stem = name.strip
        existing = rows.map { |row| row.fetch("name").strip.downcase }
        index = 1
        loop do
          candidate = index == 1 ? "#{stem} (copy)" : "#{stem} (copy #{index})"
          return candidate unless existing.include?(candidate.downcase)
          index += 1
        end
      end

      def create(request, proposal, collection, values:, user_data: nil)
        Units::Mutation.prepare(request, proposal)
        definition = kind(collection)
        unique_name!(values.fetch("name"), records(request, definition))
        values = if collection == "types"
                   Types.defaults(values, :identity => allocator(request, "values" => values))
                 else
                   Products.defaults(collection, values)
                 end
        id = request.engine.propose_create(definition.id, proposal, :values => values, :user_data => user_data)
        { "id" => id }
      end

      def update(request, proposal, collection, id:, values:, expected_values:, user_data: nil)
        Units::Mutation.prepare(request, proposal)
        definition = kind(collection)
        before = request.engine.find(definition.id, id)
        values = DeepCopy.call(values)
        if values["name"]
          values["name"] = values["name"].strip
          unique_name!(values["name"], records(request, definition), :except => id)
        end
        request.engine.propose_update(definition.id, id, proposal, :values => values,
          :expected_values => expected_values, :user_data => user_data)
        if collection == "types"
          after = proposal.find(definition.id, id)&.after || before
          Units::Changes.type(request, proposal, :before => before, :after => after)
          return { "id" => id, "unit_count" => Units::Changes.count(request.model, id) }
        end
        { "id" => id }
      end

      def duplicate(request, proposal, collection, id:, name: nil, copy_datasheets: false)
        Units::Mutation.prepare(request, proposal)
        definition = kind(collection)
        rows = records(request, definition)
        identity = allocator(request, "id" => id)
        mapping = request.engine.propose_duplicate(definition.id, [id], proposal) do |values|
          values["name"] = (name || duplicate_name(values.fetch("name"), rows)).strip
          unique_name!(values["name"], rows)
          values["source"] = { "kind" => "derived" }
          values["datasheet_links"] = [] unless copy_datasheets
          if collection == "types"
            values["product_photos"] = []
            values.fetch("elements").each { |element| element["id"] = identity.call("wel") }
          end
          values
        end
        { "id" => mapping.fetch(id) }
      end

      # `retarget` moves every use to `replacement_id` first; for Window Types a nil replacement
      # removes their Windows. Without it, a remaining use refuses, and a Window Type's own Windows go.
      def delete(request, proposal, collection, id:, expected_values: {}, retarget: false, replacement_id: nil)
        Units::Mutation.prepare(request, proposal)
        definition = kind(collection)
        current = request.engine.find(definition.id, id)
        replacement = replacement_id
        plan = nil
        if retarget
          raise CodedError.new("params.invalid", "Choose a different replacement record.") if replacement == id
          request.engine.find(definition.id, replacement) if replacement
          replace_products(request, proposal, definition, current, replacement) unless collection == "types"
          plan = request.retarget_references(definition.id, :from => id, :to => replacement)
        end
        request.engine.propose_delete(definition.id, id, proposal,
          :expected_values => expected_values, :reference_plan => plan)
        if collection == "types" && !retarget
          Units::TypeRetargeter.cleanup(request, proposal, current)
        end
        { "id" => id }
      end

      def replace_products(request, proposal, definition, current, replacement)
        replacement_row = replacement && request.engine.find(definition.id, replacement)
        spec = Products::SPECS.values.find { |entry| entry.fetch(:id) == definition.id }
        if replacement_row && spec.fetch(:numbers).keys.any? { |field|
 !current[field].nil? && replacement_row[field].nil? }
          raise CodedError.new("validation.failed", "The replacement is missing an authored thermal input.")
        end
        references = Types::KIND.references.select { |reference| reference.target_kind == definition.id }
        records(request, Types::KIND).each do |type|
          next unless references.any? { |reference| reference.ids(type).include?(current.fetch("id")) }
          after = references.reduce(type) { |value, reference|
 reference.remap(value, current.fetch("id") => replacement) }
          request.engine.propose_update(TYPE_KIND, type.fetch("id"), proposal,
            :values => { "elements" => after.fetch("elements") },
            :expected_values => { "elements" => type.fetch("elements") })
        end
      end

      # One grid gesture (GridRegistration::GESTURES) on one Window Type; `values` are its own params.
      def grid(request, proposal, command:, id:, values:, expected_values:)
        Units::Mutation.prepare(request, proposal)
        before = request.engine.find(TYPE_KIND, id)
        after = GridOperations.apply(before, command, values,
                                     :identity => allocator(request, values.merge("command" => command, "id" => id)))
        changed = Types::KIND.values(after).select { |key, value| before[key] != value }
        request.engine.propose_update(TYPE_KIND, id, proposal, :values => changed, :expected_values => expected_values)
        Units::Changes.type(request, proposal, :before => before,
          :after => proposal.find(TYPE_KIND, id)&.after || before)
        { "id" => id, "unit_count" => Units::Changes.count(request.model, id) }
      end
    end
  end
end
