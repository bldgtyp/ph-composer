# frozen_string_literal: true

module PhComposer
  # Plain structural copy of JSON-shaped data. Marshal is deliberately not used: stored payloads are
  # untrusted input, and a copy must never run code.
  module DeepCopy
    def self.call(value)
      JsonWalk.map(value) { |leaf| leaf.is_a?(String) ? leaf.dup : leaf }
    end

    # The same structure with every Hash key written as a String. Leaves are shared, not copied.
    def self.string_keys(value)
      JsonWalk.map(value, :key => :to_s.to_proc)
    end
  end
end
