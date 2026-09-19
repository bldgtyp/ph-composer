# frozen_string_literal: true

require "digest"
require "json"

module PhComposer
  # One serialization for values that are digested or compared: Hash keys sorted at every depth,
  # Arrays kept in order, numbers written as given. A retried request is matched to its first
  # attempt by this form, so two equal requests must serialize to the same bytes.
  module CanonicalJson
    module_function

    def value(input)
      case input
      when Hash then input.keys.sort.to_h { |key| [key, value(input.fetch(key))] }
      when Array then input.map { |item| value(item) }
      else input
      end
    end

    def generate(input)
      JSON.generate(value(input))
    end

    def digest(input)
      Digest::SHA256.hexdigest(generate(input))
    end
  end
end
