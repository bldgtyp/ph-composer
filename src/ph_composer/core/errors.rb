# frozen_string_literal: true

module PhComposer
  class Error < StandardError; end

  # The message is written for the user and may be shown verbatim.
  class UserError < Error; end

  # A user-facing error that also carries a stable code a caller can key behavior on. The codes are
  # listed in planning/archive/phase-zero/CONTRACTS.md, "Outcome vocabulary".
  class CodedError < UserError
    attr_reader :code, :detail

    # `detail` is structured data a caller needs to act on the refusal, so that it reads values
    # rather than parsing them back out of the message.
    def initialize(code, message, detail = nil)
      @code = code.to_s
      @detail = detail
      super(message)
    end
  end

  # The message is for diagnostics. The user sees a generic line; the class name goes to the log.
  class InternalError < Error; end
end
