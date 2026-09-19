# frozen_string_literal: true

require_relative "test_helper"

class JsonSchemaTest < PhComposerTestCase
  Schema = PhComposer::JsonSchema

  PART = {
    "type" => "object",
    "required" => %w[id length_mm],
    "additionalProperties" => false,
    "properties" => {
      "id" => { "type" => "string", "minLength" => 1 },
      "length_mm" => { "type" => "number", "exclusiveMinimum" => 0, "x-unit" => "mm" },
      "tags" => { "type" => "array", "items" => { "type" => "string" }, "maxItems" => 2 },
      "state" => { "type" => "string", "enum" => %w[draft final] }
    }
  }.freeze

  def test_a_valid_value_has_no_findings
    assert_empty Schema.validate({ "id" => "p", "length_mm" => 12.5, "tags" => ["a"] }, PART)
  end

  def test_each_violation_names_its_path
    value = { "length_mm" => 0, "tags" => ["a", 1, "c"], "state" => "gone", "extra" => true }

    assert_equal [
      "$.id is required",
      "$.length_mm must be greater than 0",
      "$.tags allows at most 2 items",
      "$.tags[1] must be string",
      "$.state must be one of [\"draft\", \"final\"]",
      "$.extra is not a known field"
    ], Schema.validate(value, PART)
  end

  def test_integer_and_number_are_distinct_and_booleans_are_neither
    assert_empty Schema.validate(3, "type" => "integer")
    refute_empty Schema.validate(3.5, "type" => "integer")
    refute_empty Schema.validate(true, "type" => "number")
    refute_empty Schema.validate(Float::NAN, "type" => "number")
  end

  def test_a_schema_using_an_unsupported_keyword_or_type_is_refused_at_registration
    properties = { "a" => { "type" => "text" }, "b" => { "type" => "string", "pattern" => "x" } }
    problems = Schema.schema_problems("type" => "object", "properties" => properties)

    assert_equal ['$.a has unknown type "text"', '$.b uses unsupported keyword "pattern"'], problems
    assert_empty Schema.schema_problems(PART)
  end
end
