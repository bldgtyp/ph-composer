# frozen_string_literal: true

module PhComposer
  # What every dispatch path checks before a handler runs, and how it builds the handler's request.
  # Shared by Dispatch and HostFollowUp; the includer provides `@registry`.
  module RequestChecks
    private

    def check_params!(declaration, params, session)
      check_json!(params, session)
      findings = JsonSchema.validate(params, declaration.params)
      return if findings.empty?

      raise CodedError.new("params.invalid", "The request is not valid: #{findings.first}.", "findings" => findings)
    end

    def check_json!(params, session)
      return if params.is_a?(Hash) && JsonValue.problems(params).empty?

      raise CodedError.new("request.malformed", "Params must be a plain JSON object.", "revision" => session.revision)
    end

    def request_for(session, params, declaration, proposal = nil, approval: nil)
      HandlerRequest.for(session, :owner => declaration.owner, :name => declaration.name, :registry => @registry,
                                  :params => params, :proposal => proposal, :approval => approval)
    end
  end
end
