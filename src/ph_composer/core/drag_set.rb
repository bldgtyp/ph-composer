# frozen_string_literal: true

module PhComposer
  # A pointer gesture's accumulating target set: deduplicated by an explicit key, in the order the
  # pointer first reached each target. A viewport tool collects into one of these while the button
  # is down and hands the values to its operation at mouse-up.
  #
  # It stops one past the limit rather than at it. A gesture that ran over the ceiling then arrives at
  # its operation over the ceiling and is refused by the one rule that owns the ceiling, instead of
  # arriving full and legal-looking and silently painting part of what the pointer crossed.
  #
  # It names no feature and knows nothing about Faces: the Classify tool and Spaces' Mark floor both collect
  # with it.
  class DragSet
    attr_reader :limit

    def initialize(limit:)
      @limit = limit
      @entries = {}
    end

    # Collects one target unless it is already here or the set has already run one past the limit.
    # Answers whether this call changed the set.
    def add(key, value)
      return false if @entries.key?(key) || full?

      @entries[key] = value
      true
    end

    # One past the limit: the point at which the operation will refuse and collecting more would
    # change nothing.
    def full?
      @entries.length > @limit
    end

    def include?(key)
      @entries.key?(key)
    end

    def values
      @entries.values
    end

    def length
      @entries.length
    end

    def empty?
      @entries.empty?
    end
  end
end
