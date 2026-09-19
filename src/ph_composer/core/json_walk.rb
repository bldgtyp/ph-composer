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

    # Visits every node, containers included, with its JSON path from the root (`$`, `$.a`, `$.a[0]`).
    def each(value, path = "$", &visit)
      visit.call(path, value)
      case value
      when Hash then value.each { |name, item| each(item, "#{path}.#{name}", &visit) }
      when Array then value.each_with_index { |item, index| each(item, "#{path}[#{index}]", &visit) }
      end
    end
  end
end
