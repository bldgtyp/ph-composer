# frozen_string_literal: true

require "json"

module PhComposer
  # The messages between the panel page and Ruby. The panel is one client of the public interface
  # (CONTRACTS.md C2): it sends `action.invoke` and reads snapshot sections, and nothing here carries
  # business behavior. Every message is `{"type": ..., "payload": {...}}`.
  module PanelMessages
    INBOUND = {
      "panel.ready" => [],
      # `session` names the Model session the panel showed; `expected_revision` the revision it rendered.
      "action.invoke" => %w[request_id session name params expected_revision],
      "preferences.set" => %w[request_id key value scope system],
      # The Export command for the Model the panel showed. It is the shell's own command, not a Model action.
      "export.start" => %w[request_id session]
    }.freeze

    OUTBOUND = {
      "panel.snapshot" => %w[product version session revision file_name edit_path preferences sections],
      "action.result" => %w[request_id session outcome],
      "preferences.result" => %w[request_id status message preferences],
      "export.result" => %w[request_id session outcome],
      "panel.notice" => %w[session message tone],
      "panel.failure" => %w[message]
    }.freeze

    class Malformed < UserError; end

    module_function

    # The type and payload of one message from the page, or Malformed.
    def parse(raw)
      message = JSON.parse(raw.to_s)
      raise Malformed, "The panel message is not an object." unless message.is_a?(Hash)

      type = message["type"]
      payload = message.fetch("payload", {})
      raise Malformed, "The panel message type #{type.inspect} is not accepted." unless INBOUND.key?(type)
      raise Malformed, "The #{type} payload must be an object." unless payload.is_a?(Hash)

      stray = payload.keys - INBOUND.fetch(type)
      raise Malformed, "The #{type} payload carries #{stray.join(', ')}." unless stray.empty?

      [type, payload]
    rescue JSON::ParserError
      raise Malformed, "The panel message is not JSON."
    end

    # The script that delivers one message to the page.
    def script(type, payload)
      declared = OUTBOUND.fetch(type) { raise ArgumentError, "#{type} is not an outbound panel message." }
      stray = payload.keys - declared
      raise ArgumentError, "#{type} does not declare #{stray.join(', ')}." unless stray.empty?

      "PhComposerUI.get(\"panel\").receive(#{JSON.generate('type' => type, 'payload' => payload)})"
    end
  end
end
