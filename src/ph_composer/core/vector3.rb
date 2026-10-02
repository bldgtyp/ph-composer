# frozen_string_literal: true

require_relative "errors"

module PhComposer
  # Arithmetic on detached three-component arrays: metre points, metre offsets and dimensionless
  # directions. Nothing here reads SketchUp, so geometry built from captured values stays testable
  # without the host. A caller that must refuse malformed input validates it before calling.
  module Vector3
    module_function

    def subtract(left, right)
      left.zip(right).map { |a, b| a - b }
    end

    def dot(left, right)
      left.zip(right).sum { |a, b| a * b }
    end

    def cross(a, b)
      [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
    end

    # Nested `hypot` keeps a very large or very small component from overflowing or underflowing.
    def length(vector)
      Math.hypot(Math.hypot(vector[0], vector[1]), vector[2])
    end

    # The unit vector along `vector`. A zero or non-finite length has no direction, so it refuses
    # with `geometry.invalid` and `message` rather than returning NaN components.
    def normalize(vector, message: "A direction has no length.")
      size = length(vector)
      raise CodedError.new("geometry.invalid", "#{message} Nothing was written.") unless size.positive? && size.finite?

      vector.map { |value| value / size }
    end
  end
end
