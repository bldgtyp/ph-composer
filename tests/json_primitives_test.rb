# frozen_string_literal: true

require_relative "test_helper"

# The JSON primitives every stored record and every retried request passes through.
class JsonPrimitivesTest < PhComposerTestCase
  NS = PhComposer

  def test_canonical_json_sorts_keys_at_every_depth_and_keeps_array_order
    generated = NS::CanonicalJson.generate("b" => nil, "a" => [{ "z" => 2, "y" => 1 }, 3])

    assert_equal '{"a":[{"y":1,"z":2},3],"b":null}', generated
  end

  def test_equal_values_built_in_different_orders_share_one_digest
    first = NS::CanonicalJson.digest("params" => { "id" => "x", "length_mm" => 10 }, "name" => "a")
    second = NS::CanonicalJson.digest("name" => "a", "params" => { "length_mm" => 10, "id" => "x" })

    assert_equal first, second
  end

  def test_deep_copy_is_deep
    value = { "rows" => [{ "name" => +"Frame" }] }
    copy = NS::DeepCopy.call(value)
    copy["rows"][0]["name"] << " changed"

    assert_equal "Frame", value.dig("rows", 0, "name")
  end

  def test_string_keys_rewrites_symbol_keys_at_every_depth
    assert_equal({ "a" => [{ "b" => 1 }] }, NS::DeepCopy.string_keys(:a => [{ :b => 1 }]))
  end

  def test_json_value_accepts_plain_json
    assert_empty NS::JsonValue.problems("a" => [1, 2.5, "x", true, nil, { "b" => false }])
  end

  def test_json_value_names_each_problem_by_path
    value = { "a" => { :b => 1 }, "c" => [Float::NAN], "d" => :symbol }

    assert_equal [
      "$.a has a non-string key :b",
      "$.c[0] is not a finite number",
      "$.d is not a JSON value (Symbol)"
    ], NS::JsonValue.problems(value)
  end

  def test_json_value_check_refuses_with_the_field_name
    error = assert_raises(NS::UserError) { NS::JsonValue.check!({ "a" => Float::INFINITY }, :field => "User data") }

    assert_equal "User data must be plain JSON: $.a is not a finite number.", error.message
  end
end
