# frozen_string_literal: true

module PhComposer
  module AgentAccess
    # The mutation sequences of one token on one Model session (context/AGENT_INTERFACE.md,
    # "User-controlled local access"). An agent never counts: each `invoke` gets the next integer, and an
    # `idempotency_key` keeps the sequence it was first given. A repeated key sends that sequence again,
    # so the caller's retained outcome answers it: the same request replays, another conflicts, and one
    # whose outcome has expired is unavailable. A key is never given a new sequence, so it is kept as
    # long as this binding is, as the caller's own sequence memory is.
    class Sequencer
      MAX_KEY = 64

      def initialize
        @next = 1
        @keys = {}
      end

      # The sequence for one invoke.
      def assign(key)
        return @keys[key] if key && @keys.key?(key)

        sequence = @next
        @next += 1
        @keys[key] = sequence if key
        sequence
      end

      # The sequence a key was given, or nil when this binding never saw it.
      def lookup(key)
        @keys[key]
      end
    end
  end
end
