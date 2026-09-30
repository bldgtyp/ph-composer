# frozen_string_literal: true

module PhComposer
  # What may be stored as JSON: Hashes with String keys, Arrays, Strings, finite numbers, booleans
  # and nil. `user_data` and extension payloads are checked with this before they are written, so a
  # Symbol, a NaN or a Ruby object never reaches a Model dictionary.
  module JsonValue
    module_function

    # Each problem names the JSON path it was found at. Empty means the value may be stored.
    def problems(value)
      found = []
      JsonWalk.each(value) do |path, node|
        case node
        when Hash
          node.each_key { |key| found << "#{path} has a non-string key #{key.inspect}" unless key.is_a?(String) }
        when Float
          found << "#{path} is not a finite number" unless node.finite?
        when String
          utf8 = node.valid_encoding? && (node.encoding == Encoding::UTF_8 || node.ascii_only?)
          found << "#{path} is not valid UTF-8 text" unless utf8
        when JsonWalk::CYCLE
          found << "#{path} contains itself"
        when Array, Integer, true, false, nil
          nil
        else
          found << "#{path} is not a JSON value (#{node.class})"
        end
      end
      found
    end

    def check!(value, field:)
      found = problems(value)
      raise UserError, "#{field} must be plain JSON: #{found.first}." unless found.empty?

      value
    end
  end
end
