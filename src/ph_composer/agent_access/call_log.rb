# frozen_string_literal: true

require "time"

module PhComposer
  module AgentAccess
    # The listener's record of recent tool calls, for diagnosis and for each token's latest call. A row
    # holds the token's id, the tool, the operation name and session the arguments carry, how the call
    # ended and how long it took; never params, a value, a path or the token. Not thread safe: the
    # Server holds its lock around every call.
    class CallLog
      SIZE = 64

      def initialize
        @rows = []
        @unread = 0
      end

      def add(token, tool, arguments, result, milliseconds)
        outcome = result["structuredContent"].is_a?(Hash) ? result["structuredContent"] : {}
        @rows << { "token" => token.fetch("id"), "tool" => tool, "operation" => text(arguments["name"], 120),
                   "session" => text(arguments["session"], 60), "status" => outcome["status"] || "completed",
                   "code" => outcome["code"], "error" => result["isError"] == true, "ms" => milliseconds,
                   "at" => Time.now.utc.iso8601 }
        @rows.shift while @rows.length > SIZE
        @unread = [@unread + 1, SIZE].min
      end

      # The rows added since the last call, oldest first.
      def take_unread
        rows = @rows.last(@unread)
        @unread = 0
        rows
      end

      def recent
        @rows.map(&:dup)
      end

      private

      def text(value, length)
        value.is_a?(String) ? value[0, length] : nil
      end
    end
  end
end
