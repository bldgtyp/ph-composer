# frozen_string_literal: true

require "json"
require "socket"

module PhComposer
  module AgentAccess
    # The loopback listener agents connect to (context/AGENT_INTERFACE.md, "User-controlled local
    # access", where the bounds below are recorded). HTTP/1.1 on 127.0.0.1, one JSON-RPC message per
    # `POST /mcp`, authenticated by an agent token.
    #
    # Worker threads read, authenticate and parse plain data and never call Sketchup or UI: the token
    # snapshot they check is handed to them by the main thread. A tool call is queued for the main
    # thread, where a UI-timer pump runs it through the Executor and leaves the answer for the worker.
    # Ruby threads run only while the main thread yields, so the pump ends each tick with a short sleep,
    # as the asset server's does. When the pump has not ticked within STARVATION_SECONDS the worker
    # answers `session.busy` itself; under a native modal no thread runs at all, and the client's own
    # timeout is what the caller sees.
    class Server
      DEFAULT_PORT = 46_110
      REQUEST_TIMEOUT = 5.0
      MAX_HEADER_BYTES = 16_384
      MAX_BODY_BYTES = 1_048_576
      # Above one token's pending limit, so a ninth call from the same agent reaches the queue's own busy
      # answer instead of a closed connection.
      MAX_CONNECTIONS = 16
      MAX_PENDING_PER_TOKEN = 8
      HANDOFF_SECONDS = 30.0
      STARVATION_SECONDS = 10.0
      WAIT_STEP = 0.25
      BUSY_INTERVAL = 0.05
      IDLE_INTERVAL = 0.1
      BUSY_SLICE = 0.005
      IDLE_SLICE = 0.0005
      RING = 64
      PATH = "/mcp"

      # One queued tool call. `state` is :waiting until the pump answers (:done) or the worker gives up
      # (:cancelled); a cancelled entry is never run.
      Entry = Struct.new(:token, :tool, :arguments, :deadline, :result, :state, keyword_init: true)

      attr_reader :port

      # `protocol` answers every JSON-RPC method but `tools/call` on the worker: `answer(message, token)`
      # returns the result Hash, or nil for an unknown method. `executor` runs a tool call on the main
      # thread: `call(token, tool, arguments)` returns the tool result Hash, and `busy(message)` builds the
      # `session.busy` result a worker sends without the main thread.
      # `port` 0 binds a free port, for tests. The two bounds are parameters only so a test need not wait
      # out the real ones.
      def initialize(port:, protocol:, executor:, timer_api: UI, clock: -> { LoopbackHttp.monotonic },
                     starvation_seconds: STARVATION_SECONDS, handoff_seconds: HANDOFF_SECONDS)
        @port = port
        @starvation_seconds = starvation_seconds
        @handoff_seconds = handoff_seconds
        @protocol = protocol
        @executor = executor
        @timer_api = timer_api
        @clock = clock
        @lock = Mutex.new
        @answered = ConditionVariable.new
        @tokens = {}.freeze
        @queue = []
        @clients = []
        @ring = []
        @stopped = true
      end

      # Binds the port and starts accepting. Raises SystemCallError (EADDRINUSE among them) when the port
      # cannot be bound, leaving the server stopped.
      def start
        @lock.synchronize do
          return self unless @stopped

          @socket = TCPServer.new("127.0.0.1", @port)
          @port = @socket.addr[1]
          @stopped = false
          @last_tick = @clock.call
        end
        start_acceptor
        schedule_pump
        self
      end

      # Stops accepting, closes every connection, cancels what waits and the pump. True the first time.
      def stop
        socket = timer = acceptor = nil
        clients = []
        @lock.synchronize do
          return false if @stopped

          @stopped = true
          socket = @socket
          timer = @pump_timer
          acceptor = @acceptor
          clients = @clients.dup
          @socket = @pump_timer = nil
          @queue.each { |entry| entry.state = :cancelled }
          @queue.clear
          @answered.broadcast
        end
        @timer_api.stop_timer(timer) if timer
        close_socket(socket)
        join_or_kill(acceptor)
        clients.each { |thread| join_or_kill(thread) }
        flush_ring
        true
      end

      def stopped?
        @lock.synchronize { @stopped }
      end

      # Replaces the live tokens the workers authenticate against: digest => public row, frozen. Called
      # on the main thread after every token store write.
      def tokens=(snapshot)
        @lock.synchronize { @tokens = snapshot }
      end

      # The main-thread tick: runs every waiting entry, drops the cancelled and the expired unrun, flushes
      # the diagnostics ring, then sleeps a slice so the workers can write their replies.
      def pump
        entries = @lock.synchronize do
          @last_tick = @clock.call
          @queue.slice!(0, @queue.length)
        end
        entries.each { |entry| run(entry) }
        flush_ring
        sleep(entries.empty? ? IDLE_SLICE : BUSY_SLICE)
      end

      # What the server holds and the recent calls, for diagnosis. Holds no token, params or value.
      def snapshot
        @lock.synchronize do
          { "port" => @port, "stopped" => @stopped, "pending" => @queue.length,
            "clients" => @clients.count(&:alive?), "recent" => @ring.map(&:dup) }
        end
      end

      private

      # The listening socket is captured here, so `stop` clearing the field cannot race the loop.
      def start_acceptor
        listener = @socket
        @acceptor = Thread.new do
          loop do
            session = listener.accept
            @lock.synchronize { admit(session) }
          end
        rescue IOError, Errno::EBADF
          nil
        end
      end

      # Called with the lock held.
      def admit(session)
        @clients.select!(&:alive?)
        if @stopped || @clients.length >= MAX_CONNECTIONS
          session.close
        else
          @clients << Thread.new(session) { |client| serve(client) }
        end
      end

      def schedule_pump
        return if stopped?

        delay = @lock.synchronize { @queue.empty? ? IDLE_INTERVAL : BUSY_INTERVAL }
        # The next tick is scheduled whatever this one raised, so one bad call cannot stop the pump.
        timer = @timer_api.start_timer(delay, false) do
          pump
        ensure
          schedule_pump
        end
        @lock.synchronize { @pump_timer = timer unless @stopped }
      end

      def serve(session)
        status, body, extra = answer(LoopbackHttp.read_request(session, :timeout => REQUEST_TIMEOUT,
                                                                        :max_header_bytes => MAX_HEADER_BYTES,
                                                                        :max_body_bytes => MAX_BODY_BYTES))
        LoopbackHttp.respond_json(session, status, body, extra || [])
      rescue StandardError
        begin
          LoopbackHttp.respond_json(session, 500, "")
        rescue StandardError
          nil
        end
      ensure
        @lock.synchronize { @clients.delete(Thread.current) }
        close_socket(session)
      end

      # [status, body, extra headers] for one request, refusing in the receipt's order.
      def answer(request)
        return [request.refusal, ""] if request.refusal
        return [405, "", ["Allow: POST"]] unless request.verb == "POST"
        return [404, ""] unless request.target == PATH
        return [403, ""] if request.headers.key?("origin") || !local_host?(request.headers["host"])

        token = authenticate(request.headers["authorization"])
        return [401, "", ["WWW-Authenticate: Bearer"]] unless token
        return [415, ""] unless json_media_type?(request.headers["content-type"])

        message(request.body, token)
      end

      # `application/json`, in any case, with or without parameters such as a charset.
      def json_media_type?(header)
        header.to_s.split(";", 2).first.to_s.strip.casecmp?("application/json")
      end

      def local_host?(host)
        ["127.0.0.1:#{@port}", "localhost:#{@port}"].include?(host.to_s)
      end

      # The live token's public row, or nil. Every digest is compared in full, so the time taken does not
      # depend on which stored digest a presented token's digest shares a prefix with.
      def authenticate(header)
        presented = header.to_s[/\ABearer ([0-9a-f]{48})\z/, 1]
        return nil unless presented

        digest = Tokens.digest(presented)
        tokens = @lock.synchronize { @tokens }
        tokens.reduce(nil) { |found, (stored, row)| same?(stored, digest) ? row : found }
      end

      # Equal hex digests, compared byte by byte with an accumulated XOR (Ruby 2.7 has no
      # OpenSSL.fixed_length_secure_compare).
      def same?(left, right)
        return false unless left.bytesize == right.bytesize

        left.bytes.zip(right.bytes).reduce(0) { |sum, (a, b)| sum | (a ^ b) }.zero?
      end

      # A request id is a string or an integer (MCP allows no other); a message without one is a
      # notification.
      def message(body, token)
        return rpc_error(nil, -32_700, "The body is not UTF-8 JSON.", 400) unless body.valid_encoding?

        parsed = JSON.parse(body)
        return rpc_error(nil, -32_600, "Batches are not accepted.") if parsed.is_a?(Array)
        unless parsed.is_a?(Hash) && parsed["jsonrpc"] == "2.0" && parsed["method"].is_a?(String) &&
               (!parsed.key?("id") || parsed["id"].is_a?(String) || parsed["id"].is_a?(Integer))
          return rpc_error(nil, -32_600, "Not a JSON-RPC 2.0 request.")
        end
        return [202, ""] unless parsed.key?("id")

        dispatch(parsed, token)
      rescue JSON::ParserError
        rpc_error(nil, -32_700, "The body is not JSON.", 400)
      end

      def dispatch(message, token)
        id = message["id"]
        return tool_call(id, message["params"], token) if message["method"] == "tools/call"

        result = @protocol.answer(message, token)
        result ? rpc_result(id, result) : rpc_error(id, -32_601, "Method not found: #{message['method'][0, 60]}")
      end

      def tool_call(id, params, token)
        unless params.is_a?(Hash) && params["name"].is_a?(String) && (params["arguments"] || {}).is_a?(Hash)
          return rpc_error(id, -32_602, "tools/call needs a tool name and an arguments object.")
        end

        rpc_result(id, handoff(token, params["name"], params["arguments"] || {}))
      end

      # Queues the call and waits for the pump's answer, the handoff deadline or a starved pump.
      def handoff(token, tool, arguments)
        entry = Entry.new(:token => token, :tool => tool, :arguments => arguments,
                          :deadline => @clock.call + @handoff_seconds, :state => :waiting)
        @lock.synchronize do
          if @queue.count { |queued| queued.token.fetch("id") == token.fetch("id") } >= MAX_PENDING_PER_TOKEN
            return @executor.busy("This token already has #{MAX_PENDING_PER_TOKEN} calls waiting for SketchUp.")
          end

          @queue << entry
          wait(entry)
        end
      end

      # Called with the lock held.
      def wait(entry)
        loop do
          return entry.result if entry.state == :done
          return busy(entry, "PH-Composer was stopped.") if @stopped
          return busy(entry, "SketchUp has not answered for #{entry_age(entry)} s.") if @clock.call >= entry.deadline
          if @clock.call - @last_tick >= @starvation_seconds
            return busy(entry, "SketchUp is busy with other work and has not picked this call up.")
          end

          @answered.wait(@lock, WAIT_STEP)
        end
      end

      def entry_age(entry)
        (@handoff_seconds - (entry.deadline - @clock.call)).round
      end

      # Called with the lock held: the entry will not run.
      def busy(entry, message)
        entry.state = :cancelled
        @queue.delete(entry)
        @executor.busy(message)
      end

      # On the main thread. An entry the worker gave up on, or that expired in the queue, never runs.
      def run(entry)
        return if @lock.synchronize { entry.state != :waiting || @clock.call >= entry.deadline }

        started = @clock.call
        result = begin
          @executor.call(entry.token, entry.tool, entry.arguments)
        rescue StandardError => error
          Diagnostics.exception("agent_access_call", error)
          @executor.failed
        end
        @lock.synchronize do
          record(entry, result, started)
          next unless entry.state == :waiting

          entry.result = result
          entry.state = :done
          @answered.broadcast
        end
      end

      # Called with the lock held. No params, value, path or token: the tool, the operation name the
      # arguments carry, the session, the outcome's status and code, and the time it took.
      def record(entry, result, started)
        outcome = result["structuredContent"].is_a?(Hash) ? result["structuredContent"] : {}
        @ring << { "token" => entry.token.fetch("id"), "tool" => entry.tool,
                   "operation" => entry.arguments["name"].is_a?(String) ? entry.arguments["name"][0, 120] : nil,
                   "session" => entry.arguments["session"].is_a?(String) ? entry.arguments["session"][0, 60] : nil,
                   "status" => outcome["status"], "code" => outcome["code"], "error" => result["isError"] == true,
                   "ms" => ((@clock.call - started) * 1000).round }
        @ring.shift while @ring.length > RING
        @unflushed = (@unflushed || 0) + 1
      end

      def flush_ring
        rows = @lock.synchronize do
          count = @unflushed.to_i
          @unflushed = 0
          @ring.last(count)
        end
        rows.each do |row|
          Diagnostics.log("agent_access_call", "operation" => [row["tool"], row["operation"]].compact.join(" "),
                                               "status" => row["error"] ? "error" : row["status"],
                                               "code" => row["code"], "duration_ms" => row["ms"])
        end
      end

      def rpc_result(id, result)
        [200, JSON.generate("jsonrpc" => "2.0", "id" => id, "result" => result)]
      end

      def rpc_error(id, code, message, status = 200)
        [status, JSON.generate("jsonrpc" => "2.0", "id" => id, "error" => { "code" => code, "message" => message })]
      end

      def close_socket(value)
        value.close if value.respond_to?(:close) && !value.closed?
      rescue StandardError
        nil
      end

      def join_or_kill(thread)
        return unless thread.respond_to?(:alive?) && thread.alive?

        thread.join(0.1)
        thread.kill if thread.alive?
      rescue StandardError
        nil
      end
    end
  end
end
