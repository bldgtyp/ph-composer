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
        parents(values).flat_map { |parent| Array(parent[key.split(".").last]).compact }
      end

      # `values` with every id in `mapping` replaced by its counterpart; ids outside it are kept.
      def remap(values, mapping)
        copy = DeepCopy.call(values)
        leaf = key.split(".").last
        parents(copy).each do |parent|
          next unless parent.key?(leaf)

          current = parent[leaf]
          parent[leaf] = current.is_a?(Array) ? current.map { |id|
 mapping.fetch(id, id) } : mapping.fetch(current, current)
        end
        copy
      end

      # Registration checks the declaration against the shape, so a typo cannot make
      # an incoming reference invisible. Entity targets with an open schema retain
      # their existing validator-owned contract.
      def declaration_problems(values_schema)
        unless key.is_a?(String) && /\A[a-z][a-z0-9_]*(\[\])?(\.[a-z][a-z0-9_]*(\[\])?)*\z/.match?(key)
          return ["reference key must be a dotted field path with optional [] array steps"]
        end
        return ["reference leaf must be a field; cardinality describes its ids"] if key.end_with?("[]")
        return ["reference cardinality must be one or many"] unless %w[one many].include?(cardinality)
        return [] unless values_schema.key?("properties")

        shape = values_schema
        key.split(".").each do |part|
          array = part.end_with?("[]")
          name = array ? part[0...-2] : part
          shape = shape.fetch("properties", {})[name]
          return ["reference #{key} is absent from the values schema"] unless shape
          next unless array

          return ["reference #{key} traverses a non-array field"] unless Array(shape["type"]).include?("array")

          shape = shape.fetch("items", {})
        end
        types = Array(shape["type"]) - ["null"]
        expected = cardinality == "many" ? "array" : "string"
        return ["reference #{key} must name a #{expected} field"] unless types == [expected]
        return [] unless cardinality == "many"
        return [] if Array(shape.fetch("items", {})["type"]) == ["string"]

        ["reference #{key} must contain string ids"]
      end

      private

      # Dotted keys traverse objects; [] traverses every member of an array. Only the
      # declared leaf is a reference, never another string with the same value.
      def parents(values)
        key.split(".")[0...-1].reduce([values]) do |nodes, part|
          array = part.end_with?("[]")
          name = array ? part[0...-2] : part
          nodes.flat_map do |node|
            next [] unless node.is_a?(Hash)

            child = node[name]
            array ? (child.is_a?(Array) ? child : []) : [child]
          end
        end.select { |node| node.is_a?(Hash) }
      end
    end
  end
end
