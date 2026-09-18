# frozen_string_literal: true

require "securerandom"

module PhComposer
  # The callers one Model session has issued handles to. A handle is an opaque random string that the
  # application hands to a trusted in-process caller; the caller's capabilities live here, so nothing
  # a request carries can grant one. Handles end with their session and never survive a restart.
  class CallerRegistry
    CAPABILITIES = %w[read model_write].freeze

    Caller = Struct.new(:handle, :capabilities, :highest_sequence, keyword_init: true)

    def initialize
      @callers = {}
    end

    def issue(capabilities)
      unknown = capabilities - CAPABILITIES
      raise ArgumentError, "Unknown capabilities #{unknown.inspect}." unless unknown.empty?

      handle = SecureRandom.hex(16)
      @callers[handle] = Caller.new(:handle => handle, :capabilities => capabilities.dup.freeze, :highest_sequence => 0)
      handle
    end

    def fetch(handle)
      @callers[handle]
    end

    def count
      @callers.length
    end
  end
end
