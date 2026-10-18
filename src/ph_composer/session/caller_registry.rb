# frozen_string_literal: true

require "securerandom"

module PhComposer
  # The callers one Model session has issued handles to. A handle is an opaque random string that the
  # application hands to a trusted in-process caller; the caller's capabilities live here, so nothing
  # a request carries can grant one. Handles end with their session and never survive a restart.
  class CallerRegistry
    # `view` sits between `read` and `model_write`: it changes what the host shows, the selection, the
    # camera and the active Colour-by mode, and never reaches the SKP (Declarations::ViewCommand).
    # `setup` changes session or machine state, never the SKP (Declarations::SetupCommand).
    CAPABILITIES = %w[read view model_write setup export].freeze

    Caller = Struct.new(:handle, :capabilities, :highest_sequence, keyword_init: true)

    def initialize
      @callers = {}
      @revoked = {}
    end

    # The registry keeps its own frozen copy of the capabilities and returns a frozen handle, so nothing
    # the caller later does to its Array, its Strings or the handle changes a grant or a lookup.
    def issue(capabilities)
      owned = DeepCopy.frozen(capabilities)
      unknown = owned - CAPABILITIES
      raise ArgumentError, "Unknown capabilities #{unknown.inspect}." unless unknown.empty?

      handle = SecureRandom.hex(16).freeze
      @callers[handle] = Caller.new(:handle => handle, :capabilities => owned, :highest_sequence => 0)
      handle
    end

    def fetch(handle)
      @callers[handle]
    end

    # Ends a handle for good: dispatch refuses it from the next call on, and work it started checks it
    # before it writes (an export's commit). The handle is remembered, so its refusal says why.
    def revoke(handle)
      @revoked[handle] = true if @callers.delete(handle)
    end

    def revoked?(handle)
      @revoked.key?(handle)
    end

    def count
      @callers.length
    end
  end
end
