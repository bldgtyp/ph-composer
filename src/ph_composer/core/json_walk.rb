# frozen_string_literal: true

module PhComposer
  # The one recursion over JSON-shaped data (Hash, Array and leaves). Callers supply only what
  # differs: how a key is written, which entries are kept, what a leaf becomes.
  module JsonWalk
    module_function

    # Rebuilds `value`. Each Hash key passes through `key`; an entry whose written key fails `keep`
    # is dropped; each leaf passes through the block.
    def map(value, key: nil, keep: nil, &leaf)
      case value
      when Hash
        value.each_with_object({}) do |(name, item), result|
          written = key ? key.call(name) : name
          next if keep && !keep.call(written)

          result[written] = map(item, :key => key, :keep => keep, &leaf)
        end
      when Array
        value.map { |item| map(item, :key => key, :keep => keep, &leaf) }
      else
        leaf ? leaf.call(value) : value
      end
    end

    # Stands in for a container that contains itself. JSON cannot express one, and following it
    # would never end, so `each` visits CYCLE at that path instead of descending again.
    CYCLE = Object.new.freeze

    # Visits every node, containers included, with its JSON path from the root (`$`, `$.a`, `$.a[0]`).
    def each(value, path = "$", ancestors = [], &visit)
      container = value.is_a?(Hash) || value.is_a?(Array)
      return visit.call(path, CYCLE) if container && ancestors.any? { |ancestor| ancestor.equal?(value) }

      visit.call(path, value)
      return unless container

      inside = ancestors + [value]
      if value.is_a?(Hash)
        value.each { |name, item| each(item, "#{path}.#{name}", inside, &visit) }
      else
        value.each_with_index { |item, index| each(item, "#{path}[#{index}]", inside, &visit) }
      end
    end
  end
end
