# frozen_string_literal: true

module PhComposer
  module Windows
    # Operations are the persistence boundary: pure type transformations return detached values;
    # the supplied engine validates all records and references in one native proposal.
    module Operations
      module_function

      def allocator(request)
        position = 0
        lambda do |prefix|
          position += 1
          Records::Identity.derived(prefix, "session" => request.session.id, "revision" => request.revision,
            "params" => request.params, "position" => position)
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

      def create(request, proposal, collection)
        Units::Mutation.prepare(request, proposal)
        definition = kind(collection)
        values = request.params.fetch("values")
        unique_name!(values.fetch("name"), records(request, definition))
        values = collection == "types" ? Types.defaults(values, :identity => allocator(request),
          :unit_system => Preferences.unit_system) : Products.defaults(collection, values)
        id = request.engine.propose_create(definition.id, proposal, :values => values,
          :user_data => request.params["user_data"])
        { "id" => id }
      end

      def update(request, proposal, collection)
        Units::Mutation.prepare(request, proposal)
        definition = kind(collection)
        id = request.params.fetch("id")
        before = request.engine.find(definition.id, id)
        values = DeepCopy.call(request.params.fetch("values"))
        if values["name"]
          values["name"] = values["name"].strip
          unique_name!(values["name"], records(request, definition), :except => id)
        end
        request.engine.propose_update(definition.id, id, proposal, :values => values,
          :expected_values => request.params.fetch("expected_values"), :user_data => request.params["user_data"])
        if collection == "types"
          after = proposal.find(definition.id, id)&.after || before
          Units::Changes.type(request, proposal, :before => before, :after => after)
          return { "id" => id, "unit_count" => Units::Changes.count(request.model, id) }
        end
        { "id" => id }
      end

      def duplicate(request, proposal, collection)
        Units::Mutation.prepare(request, proposal)
        definition = kind(collection)
        rows = records(request, definition)
        id = request.params.fetch("id")
        identity = allocator(request)
        mapping = request.engine.propose_duplicate(definition.id, [id], proposal) do |values|
          values["name"] = (request.params["name"] || duplicate_name(values.fetch("name"), rows)).strip
          unique_name!(values["name"], rows)
          values["source"] = { "kind" => "derived" }
          values["datasheet_links"] = [] unless request.params.fetch("copy_datasheets", false)
          if collection == "types"
            values["product_photos"] = []
            values.fetch("elements").each { |element| element["id"] = identity.call("wel") }
          end
          values
        end
        { "id" => mapping.fetch(id) }
      end

      def delete(request, proposal, collection)
        Units::Mutation.prepare(request, proposal)
        definition = kind(collection)
        id = request.params.fetch("id")
        current = request.engine.find(definition.id, id)
        replacement = request.params["replacement_id"]
        plan = nil
        if request.params.key?("replacement_id")
          raise CodedError.new("params.invalid", "Choose a different replacement record.") if replacement == id
          request.engine.find(definition.id, replacement) if replacement
          replace_products(request, proposal, definition, current, replacement) unless collection == "types"
          plan = request.retarget_references(definition.id, :from => id, :to => replacement)
        end
        request.engine.propose_delete(definition.id, id, proposal,
          :expected_values => request.params.fetch("expected_values", {}), :reference_plan => plan)
        if collection == "types" && !request.params.key?("replacement_id")
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

      def grid(request, proposal, command)
        Units::Mutation.prepare(request, proposal)
        id = request.params.fetch("id")
        before = request.engine.find(TYPE_KIND, id)
        values = request.params.reject { |key, _| %w[id expected_values].include?(key) }
        after = GridOperations.apply(before, command, values, :identity => allocator(request))
        changed = Types::KIND.values(after).select { |key, value| before[key] != value }
        request.engine.propose_update(TYPE_KIND, id, proposal, :values => changed,
          :expected_values => request.params.fetch("expected_values"))
        Units::Changes.type(request, proposal, :before => before,
          :after => proposal.find(TYPE_KIND, id)&.after || before)
        { "id" => id, "unit_count" => Units::Changes.count(request.model, id) }
      end
    end
  end
end
