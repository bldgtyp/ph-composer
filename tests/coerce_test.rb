# frozen_string_literal: true

require_relative "test_helper"

class CoerceTest < PhComposerTestCase
  Coerce = PhComposer::Coerce
  UserError = PhComposer::UserError

  def test_positive_integer_accepts_strings_and_numbers
    assert_equal 12, Coerce.positive_integer("12", :field => "Count")
    assert_equal 7, Coerce.positive_integer(7, :field => "Count")
  end

  def test_positive_integer_rejects_invalid_values_with_the_field_name
    assert_user_error(:positive_integer, [nil, "abc", "-1", "0", "NaN", "Infinity"])
  end

  def test_positive_float_accepts_strings_and_numbers
    assert_equal 2.5, Coerce.positive_float("2.5", :field => "Height")
    assert_equal 3.0, Coerce.positive_float(3, :field => "Height")
  end

  def test_positive_float_rejects_invalid_values_with_the_field_name
    assert_user_error(:positive_float, [nil, "abc", "-1", "0", "NaN", "Infinity"])
  end

  def test_finite_float_accepts_strings_and_numbers
    assert_equal 2.5, Coerce.finite_float("2.5", :field => "Weight")
    assert_equal(-1.0, Coerce.finite_float(-1, :field => "Weight"))
  end

  def test_finite_float_rejects_invalid_values_with_the_field_name
    assert_user_error(:finite_float, [nil, "abc", "NaN", "Infinity"])
  end

  private

  def assert_user_error(method, values)
    values.each do |value|
      error = assert_raises(UserError) { Coerce.public_send(method, value, :field => "Test field") }
      assert_includes error.message, "Test field"
    end
  end
end
