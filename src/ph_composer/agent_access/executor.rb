# frozen_string_literal: true

require "json"

module PhComposer
  module AgentAccess
    # Runs one agent tool call on the main thread, where every PhComposer::API call belongs. The tool
    # table is the allowlist: each tool names its capability, the fixed schema its arguments must meet,
    # whether it acts on a Model session, and the one API call it makes. Nothing a request names is
    # called otherwise.
    #
    # A token acts on a session through one caller handle, issued by `API.connect` with the token's
    # capabilities the first time the token names that session and kept while both live, so its
    # sequences and retained outcomes carry across calls. Dispatch enforces the grants as for any caller.
    class Executor
      # `run` receives the caller's OperationContext (nil for a tool that names no session), the validated
      # arguments, the token's public row and that binding's Sequencer, and returns the API's answer.
      Tool = Struct.new(:name, :description, :capability, :input_schema, :session, :annotations, :run,
                        keyword_init: true)
      # Serialized `structuredContent` larger than this is refused, never truncated: both target clients
      # fail a larger result (context/AGENT_INTERFACE.md, "User-controlled local access").
      MAX_RESULT_BYTES = 24 * 1024
      # The most of a caller's own text (a name, a schema path) an error message repeats back.
      MAX_ECHO = 160
      SESSION_UNKNOWN = "That Model session is closed or was never opened. Call discover for the open ones."

      Binding = Struct.new(:context, :sequencer)

      # `bindings` outlives this Executor (AgentAccess.bindings), so a listener restarted on another port
      # keeps each token's caller handle, sequences and keys.
      def initialize(tools:, bindings: AgentAccess.bindings)
        @tools = tools
        @bindings = bindings
      end

      # The tool result for one call by `token` (its public row from the snapshot it authenticated with).
      def call(token, name, arguments)
        live = Tokens.snapshot.values.find { |row| row.fetch("id") == token.fetch("id") }
        unless live
          prune
          return error("This token was revoked; nothing ran.", "access.revoked")
        end

        tool = @tools[name]
        return error("There is no tool named #{name.to_s[0, MAX_ECHO].inspect}.") unless tool && granted?(live, tool)

        findings = JsonSchema.validate(arguments, tool.input_schema)
        return error("The arguments are not valid: #{findings.first.to_s[0, MAX_ECHO]}.") unless findings.empty?

        prune
        binding = Binding.new(nil, nil)
        if tool.session
          session = Sessions.find(arguments["session"])
          unless session && Tokens.serves?(live, session)
            return result(Outcome.refused("session.unknown", SESSION_UNKNOWN, :revision => nil))
          end

          binding = binding_for(live, session)
        end
        result(tool.run.call(binding.context, arguments, live, binding.sequencer))
      rescue CodedError => error
        result(Outcome.refused(error.code, error.message, :revision => nil, :detail => error.detail))
      end

      # The answer a worker gives without the main thread: no SketchUp call, only an Outcome.
      def busy(message)
        result(Outcome.refused("session.busy", message, :status => "busy", :revision => nil))
      end

      # The answer for a call that raised unexpectedly; the cause is in the diagnostics log only.
      def failed
        result(Outcome.failed(:effect => "unknown", :revision => nil))
      end

      def granted?(token, tool)
        token.fetch("capabilities").include?(tool.capability)
      end

      private

      # One caller handle and one Sequencer per token and session, so sequences and keys carry across calls.
      def binding_for(token, session)
        @bindings[[token.fetch("id"), session.id]] ||=
          Binding.new(API.connect(:session_id => session.id, :capabilities => token.fetch("capabilities")),
                      Sequencer.new)
      end

      # Forgets the handles of closed sessions and revoked tokens.
      def prune
        open = Sessions.all.map(&:id)
        live = Tokens.snapshot.values.map { |row| row.fetch("id") }
        @bindings.delete_if { |(token, session), _context| !open.include?(session) || !live.include?(token) }
      end

      # The MCP tool result: the answer as `structuredContent` and one line of text, not a second copy of
      # the JSON, which a client that shows both would count twice. Every result passes through here or
      # `error`, so none leaves larger than the budget.
      def result(value)
        text = JSON.generate(value)
        value = trimmed(value) if text.bytesize > MAX_RESULT_BYTES && changed_model?(value)
        text = JSON.generate(value)
        if text.bytesize > MAX_RESULT_BYTES
          return error("The result is #{text.bytesize} bytes, over the #{MAX_RESULT_BYTES}-byte limit. Ask for " \
                       "less: a smaller page, fewer fields or one owner's operations.",
                       "request.response_too_large")
        end

        { "content" => [{ "type" => "text", "text" => summary(value) }], "structuredContent" => value,
          "isError" => false }
      end

      def changed_model?(value)
        value.is_a?(Hash) && value["status"] && value["effect"] && value["effect"] != "none"
      end

      # A change that happened is never reported as refused because its answer was large: the outcome keeps
      # its status, code, effect, revision and sequence, and drops the value and the lists, which the
      # caller reads back from the Model.
      def trimmed(outcome)
        outcome.merge("message" => "#{outcome['message']} The full result was over the reply limit; read the " \
                                   "changed records back.",
                      "value" => nil, "affected" => [], "findings" => [],
                      "detail" => { "omitted" => %w[value affected findings] })
      end

      def summary(value)
        return "Result in structuredContent." unless value.is_a?(Hash) && value["status"]

        [value["status"], value["code"], value["message"]].compact.join(": ")
      end

      # A tool error still carries the whole Outcome envelope `discover` publishes.
      def error(message, code = nil)
        outcome = Outcome.refused(code || "request.malformed", message[0, 2 * MAX_ECHO], :revision => nil)
        { "content" => [{ "type" => "text", "text" => outcome["message"] }], "structuredContent" => outcome,
          "isError" => true }
      end
    end
  end
end
