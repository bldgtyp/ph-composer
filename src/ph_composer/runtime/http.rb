# frozen_string_literal: true

require "io/wait"

module PhComposer
  # The HTTP/1.1 the loopback asset server speaks: read one request line within a deadline and a
  # header budget, and write one complete response with the isolation headers the runtime needs.
  module LoopbackHttp
    STATUS_TEXT = {
      200 => "OK",
      400 => "Bad Request",
      403 => "Forbidden",
      404 => "Not Found",
      405 => "Method Not Allowed",
      500 => "Internal Server Error"
    }.freeze

    module_function

    # The request line, or nil when the client sent nothing complete in time or overran the budget.
    def read_request_line(session, timeout:, max_header_bytes:)
      deadline = monotonic + timeout
      buffer = +""
      loop do
        remaining = deadline - monotonic
        return nil if remaining <= 0 || !session.wait_readable(remaining)

        chunk = session.read_nonblock(4096, :exception => false)
        return nil if chunk == :wait_readable || chunk.nil?

        buffer << chunk
        return nil if buffer.bytesize > max_header_bytes
        break if buffer.include?("\r\n\r\n") || buffer.include?("\n\n")
      end
      buffer.lines.first
    end

    def percent_decode(text)
      text.gsub(/%([0-9A-Fa-f]{2})/) { Regexp.last_match(1).hex.chr }
    end

    def respond(session, status, type, body, extra = nil)
      headers = [
        "HTTP/1.1 #{status} #{STATUS_TEXT.fetch(status)}",
        "Content-Type: #{type}",
        "Content-Length: #{body.bytesize}",
        "Cross-Origin-Opener-Policy: same-origin",
        "Cross-Origin-Embedder-Policy: require-corp",
        "Cross-Origin-Resource-Policy: same-origin",
        "X-Content-Type-Options: nosniff",
        "Cache-Control: no-store",
        "Connection: close"
      ]
      headers << extra if extra
      session.write(headers.join("\r\n") + "\r\n\r\n")
      session.write(body)
    end

    def monotonic
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
