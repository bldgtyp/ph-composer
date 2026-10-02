# frozen_string_literal: true

module PhComposer
  # A small subset of JSON Schema, used to declare every public query and action's input and output.
  # The same declaration validates a request in Ruby, is published by discovery for external clients
  # and pins the panel's contract fixture, so there is no second hand-kept catalog. Keeping to
  # standard keywords means a client can read the schema without learning a private vocabulary.
  #
  # `x-unit` is the one extension: the SI unit a number is stored and exchanged in, such as "mm".
  # `pattern` is an ECMA-262 regular expression a string must match; declarations keep to the subset
  # Ruby reads the same way, and a leading `^` and trailing `$` anchor the whole string.
  module JsonSchema
    TYPES = %w[object array string integer number boolean null].freeze
    KEYWORDS = %w[
      type description title examples properties required additionalProperties items enum
      minimum maximum exclusiveMinimum exclusiveMaximum minItems maxItems minLength maxLength pattern x-unit
    ].freeze

    module_function

    # Problems with the schema itself, found at registration so a malformed declaration never
    # becomes available. Empty means the schema is usable.
    def schema_problems(schema, path = "$")
      return ["#{path} must be a JSON object"] unless schema.is_a?(Hash)

      found = (schema.keys - KEYWORDS).map { |key| "#{path} uses unsupported keyword #{key.inspect}" }
      types = Array(schema["type"])
      found << "#{path} needs a type" if types.empty?
      found.concat((types - TYPES).map { |type| "#{path} has unknown type #{type.inspect}" })
      found.concat(value_problems(schema, path))
      properties = schema["properties"]
      return found << "#{path}.properties must be an object" unless properties.nil? || properties.is_a?(Hash)

      (properties || {}).each { |name, child| found.concat(schema_problems(child, "#{path}.#{name}")) }
      found.concat(schema_problems(schema["items"], "#{path}[]")) if schema.key?("items")
      additional = schema["additionalProperties"]
      found.concat(schema_problems(additional, "#{path}.*")) if additional.is_a?(Hash)
      found
    end

    COUNTS = %w[minItems maxItems minLength maxLength].freeze
    BOUNDS = %w[minimum maximum exclusiveMinimum exclusiveMaximum].freeze
    TEXTS = %w[description title x-unit].freeze

    # Each keyword's own value: counts are whole numbers, bounds are finite numbers, text is text,
    # an enum lists something, and a closed object requires only properties it declares.
    def value_problems(schema, path)
      found = []
      types = Array(schema["type"])
      COUNTS.each do |key|
        next unless schema.key?(key) && !(schema[key].is_a?(Integer) && schema[key] >= 0)

        found << "#{path}.#{key} must be a whole number of at least 0"
      end
      BOUNDS.each do |key|
        found << "#{path}.#{key} must be a finite number" if schema.key?(key) && !type?(schema[key], "number")
      end
      TEXTS.each { |key| found << "#{path}.#{key} must be text" if schema.key?(key) && !schema[key].is_a?(String) }
      found << "#{path}.pattern must be a regular expression" if schema.key?("pattern") && !pattern(schema)
      if schema.key?("enum") && !(schema["enum"].is_a?(Array) && !schema["enum"].empty?)
        found << "#{path}.enum must list at least one value"
      elsif schema.key?("enum") && schema["enum"].any? { |value| types.none? { |type| type?(value, type) } }
        found << "#{path}.enum lists a value its type does not allow"
      end
      found.concat(range_problems(schema, path))
      found << "#{path}.examples must be a list" if schema.key?("examples") && !schema["examples"].is_a?(Array)
      additional = schema["additionalProperties"]
      unless additional.nil? || additional == true || additional == false || additional.is_a?(Hash)
        found << "#{path}.additionalProperties must be true, false or a schema"
      end
      found.concat(required_problems(schema, path))
    end

    # A lower bound above its upper bound admits nothing.
    def range_problems(schema, path)
      [%w[minimum maximum], %w[minItems maxItems], %w[minLength maxLength]].filter_map do |low, high|
        next unless schema[low].is_a?(Numeric) && schema[high].is_a?(Numeric) && schema[low] > schema[high]

        "#{path}.#{low} is above #{high}"
      end
    end

    def required_problems(schema, path)
      return [] unless schema.key?("required")

      required = schema["required"]
      return ["#{path}.required must list property names"] unless required.is_a?(Array) &&
                                                                   required.all? { |name| name.is_a?(String) }
      return [] unless schema["additionalProperties"] == false

      undeclared = required - (schema["properties"] || {}).keys
      undeclared.map { |name| "#{path} requires #{name}, which it does not declare" }
    end

    # What is wrong with `value` against `schema`, one finding per problem, each naming its path.
    def validate(value, schema, path = "$")
      types = Array(schema.fetch("type"))
      return ["#{path} must be #{types.join(' or ')}"] unless types.any? { |type| type?(value, type) }

      found = []
      if schema.key?("enum") && !schema["enum"].include?(value)
        found << "#{path} must be one of #{schema['enum'].inspect}"
      end
      found.concat(number_problems(value, schema, path)) if value.is_a?(Numeric)
      found.concat(string_problems(value, schema, path)) if value.is_a?(String)
      found.concat(array_problems(value, schema, path)) if value.is_a?(Array)
      found.concat(object_problems(value, schema, path)) if value.is_a?(Hash)
      found
    end

    def type?(value, type)
      case type
      when "object" then value.is_a?(Hash)
      when "array" then value.is_a?(Array)
      when "string" then value.is_a?(String)
      when "integer" then value.is_a?(Integer)
      when "number" then value.is_a?(Integer) || (value.is_a?(Float) && value.finite?)
      when "boolean" then value == true || value == false
      when "null" then value.nil?
      else false
      end
    end

    def number_problems(value, schema, path)
      found = []
      found << "#{path} must be at least #{schema['minimum']}" if schema.key?("minimum") && value < schema["minimum"]
      found << "#{path} must be at most #{schema['maximum']}" if schema.key?("maximum") && value > schema["maximum"]
      if schema.key?("exclusiveMinimum") && value <= schema["exclusiveMinimum"]
        found << "#{path} must be greater than #{schema['exclusiveMinimum']}"
      end
      if schema.key?("exclusiveMaximum") && value >= schema["exclusiveMaximum"]
        found << "#{path} must be less than #{schema['exclusiveMaximum']}"
      end
      found
    end

    def string_problems(value, schema, path)
      found = []
      found << "#{path} must not be empty" if schema.key?("minLength") && value.length < schema["minLength"]
      found << "#{path} is too long" if schema.key?("maxLength") && value.length > schema["maxLength"]
      found << "#{path} must match #{schema['pattern']}" if schema.key?("pattern") && !pattern(schema).match?(value)
      found
    end

    # The Ruby expression for a schema's pattern, anchored at the whole string where the pattern is,
    # or nil when the pattern is not one.
    def pattern(schema)
      text = schema["pattern"]
      return nil unless text.is_a?(String)

      Regexp.new(text.sub(/\A\^/, "\\A").sub(/(?<!\\)\$\z/, "\\z"))
    rescue RegexpError
      nil
    end

    def array_problems(value, schema, path)
      found = []
      found << "#{path} needs at least #{schema['minItems']} items" if value.length < schema.fetch("minItems", 0)
      maximum = schema.fetch("maxItems", value.length)
      found << "#{path} allows at most #{maximum} items" if value.length > maximum
      return found unless schema.key?("items")

      value.each_with_index { |item, index| found.concat(validate(item, schema["items"], "#{path}[#{index}]")) }
      found
    end

    def object_problems(value, schema, path)
      properties = schema["properties"] || {}
      found = Array(schema["required"]).reject { |name| value.key?(name) }.map { |name| "#{path}.#{name} is required" }
      value.each do |name, item|
        child = properties[name]
        child ||= schema["additionalProperties"] if schema["additionalProperties"].is_a?(Hash)
        if child
          found.concat(validate(item, child, "#{path}.#{name}"))
        elsif schema["additionalProperties"] == false
          found << "#{path}.#{name} is not a known field"
        end
      end
      found
    end
  end
end
