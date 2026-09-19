# frozen_string_literal: true

module PhComposer
  # Input coercion for values a user or caller typed. Each raises a UserError naming the field.
  module Coerce
    module_function

    def positive_integer(value, field:)
      number = Integer(value)
      return number if number.positive?

      raise UserError, "#{field} must be a positive whole number."
    rescue ArgumentError, TypeError
      raise UserError, "#{field} must be a positive whole number."
    end

    def positive_float(value, field:)
      number = Float(value)
      return number if number.finite? && number.positive?

      raise UserError, "#{field} must be a number greater than zero."
    rescue ArgumentError, TypeError
      raise UserError, "#{field} must be a number greater than zero."
    end

    def finite_float(value, field:)
      number = Float(value)
      return number if number.finite?

      raise UserError, "#{field} must be a number."
    rescue ArgumentError, TypeError
      raise UserError, "#{field} must be a number."
    end
  end
end
