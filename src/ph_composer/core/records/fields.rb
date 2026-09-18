# frozen_string_literal: true

module PhComposer
  module Records
    # One stored value of a record kind, declared as a JSON Schema (core/json_schema.rb). A number
    # carries its SI unit as `x-unit`, and its key names the unit too: `length_mm`.
    Field = Struct.new(:key, :schema, :required, keyword_init: true) do
      def reference?
        false
      end
    end

    # A field that names other records by id. `cardinality` is "one" (a string id) or "many" (a list
    # of ids). The engine checks that each target exists and remaps the ids when a duplicated
    # collection contains the target; nothing else about a string is ever read as a reference.
    Reference = Struct.new(:key, :target_kind, :cardinality, :required, keyword_init: true) do
      def reference?
        true
      end

      def schema
        id = { "type" => "string", "description" => "Id of a #{target_kind} record." }
        cardinality == "many" ? { "type" => "array", "items" => id } : id
      end

      # The ids this field holds in `values`, as a list whatever the cardinality.
      def ids(values)
        Array(values[key]).compact
      end

      # `values` with every id in `mapping` replaced by its counterpart; ids outside it are kept.
      def remap(values, mapping)
        return values unless values.key?(key)

        current = values[key]
        remapped = current.is_a?(Array) ? current.map { |id| mapping.fetch(id, id) } : mapping.fetch(current, current)
        values.merge(key => remapped)
      end
    end
  end
end
