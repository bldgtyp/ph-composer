# frozen_string_literal: true

module PhComposer
  # Every attribute dictionary the extension owns starts with this prefix (context/TECH_STACK.md
  # "Namespace").
  DICTIONARY_PREFIX = "ph_composer"

  # The attribute dictionaries the extension owns. The module that owns a dictionary registers it
  # where it names it, so this list names no feature. The Export attribute guard reads it.
  module Dictionaries
    # Whether `name` may be an extension dictionary: a String under the prefix with a name after it.
    # Registration checks this before it publishes, so `register` never raises while publishing.
    def self.valid_name?(name)
      name.is_a?(String) && name.start_with?("#{DICTIONARY_PREFIX}.") && name.length > DICTIONARY_PREFIX.length + 1
    end

    def self.register(name)
      raise ArgumentError, "Dictionary #{name} must start with #{DICTIONARY_PREFIX}." unless valid_name?(name)

      registered << name unless registered.include?(name)
      @names = nil
      name
    end

    # Sorted, so the list does not depend on the order files happened to load in.
    def self.names
      @names ||= registered.sort.freeze
    end

    def self.registered
      @registered ||= []
    end
    private_class_method :registered
  end
end
