# frozen_string_literal: true

module PhComposer
  # Plain structural copy of JSON-shaped data. Marshal is deliberately not used: stored payloads are
  # untrusted input, and a copy must never run code.
  module DeepCopy
    def self.call(value)
      JsonWalk.map(value) { |leaf| leaf.is_a?(String) ? leaf.dup : leaf }
    end

    # A copy in which every Hash, Array and String is frozen, so an in-place edit raises FrozenError.
    def self.frozen(value)
      JsonWalk.map(value) { |leaf| leaf.is_a?(String) ? leaf.dup.freeze : leaf }.then { |copy| freeze_tree(copy) }
    end

    def self.freeze_tree(value)
      case value
      when Hash then value.each_value { |item| freeze_tree(item) }
      when Array then value.each { |item| freeze_tree(item) }
      end
      value.freeze
    end
    private_class_method :freeze_tree

    # The same structure with every Hash key written as a String. Leaves are shared, not copied.
    def self.string_keys(value)
      JsonWalk.map(value, :key => :to_s.to_proc)
    end
  end
end
