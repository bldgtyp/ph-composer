# frozen_string_literal: true

module PhComposer
  # Retained mutation outcomes for one Model session, so a retried request returns its first result
  # instead of running again (CONTRACTS.md C4). Bounded: at most CAPACITY entries across every caller,
  # each kept for at most LIFETIME_SECONDS, the oldest evicted first. An evicted or expired entry is
  # gone; the caller registry still remembers that its sequence was used.
  class OutcomeStore
    CAPACITY = 256
    LIFETIME_SECONDS = 15 * 60

    # `outcome` is nil while the request is still running.
    Entry = Struct.new(:caller, :sequence, :digest, :outcome, :recorded_at, keyword_init: true) do
      def pending?
        outcome.nil?
      end
    end

    attr_writer :clock

    def initialize(clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
      @clock = clock
      @entries = {}
    end

    def lookup(caller, sequence)
      expire
      @entries[[caller, sequence]]
    end

    def begin(caller, sequence, digest)
      expire
      @entries.delete(@entries.keys.first) while @entries.length >= CAPACITY
      @entries[[caller, sequence]] = Entry.new(
        :caller => caller, :sequence => sequence, :digest => digest, :outcome => nil, :recorded_at => @clock.call
      )
    end

    # Keeps its own copy, so nothing a caller does to the returned outcome reaches a later retry.
    def finish(caller, sequence, outcome)
      entry = @entries[[caller, sequence]]
      entry.outcome = DeepCopy.call(outcome) if entry
      outcome
    end

    # A copy of the retained outcome for `caller` and `sequence`, or nil.
    def retained(caller, sequence)
      outcome = lookup(caller, sequence)&.outcome
      outcome && DeepCopy.call(outcome)
    end

    def count
      expire
      @entries.length
    end

    private

    # Entries are kept in insertion order, so the expired ones are always at the front.
    def expire
      cutoff = @clock.call - LIFETIME_SECONDS
      @entries.shift while !@entries.empty? && @entries.first[1].recorded_at <= cutoff && !@entries.first[1].pending?
    end
  end
end
