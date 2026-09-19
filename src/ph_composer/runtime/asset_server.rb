# frozen_string_literal: true

require "digest"
require "securerandom"
require "socket"

module PhComposer
  # Serves the runtime's assets on a loopback port under a per-server secret token, so only the page
  # the extension opened can load them. It serves exactly what the pinned manifest declares, refuses
  # anything whose bytes do not match, and sends the isolation headers Pyodide needs.
  #
  # The token authorizes loading runtime assets from this process and nothing else. It is not an
  # agent credential; the external-agent adapter defines its own grants (context/AGENT_INTERFACE.md).
  #
  # Connections are accepted and served on Ruby threads. SketchUp runs Ruby threads only while the
  # main thread yields, so a UI timer "pump" sleeps briefly on each tick to let them run.
  class AssetServer
    BUSY_INTERVAL = 0.02
    IDLE_INTERVAL = 0.1
    BUSY_SLICE = 0.005
    IDLE_SLICE = 0.0005
    REQUEST_TIMEOUT = 5.0
    MAX_CLIENTS = 32
    MAX_HEADER_BYTES = 16_384
    TEXT = "text/plain; charset=utf-8"

    Request = Struct.new(:method, :relative, :entry, :body)
    # Checked in order: the first check that names an outcome refuses the request with the route's
    # status, body and extra header. `names_asset` records the asset in the ledger.
    Route = Struct.new(:status, :body, :check, :header, :names_asset)
    ROUTES = [
      Route.new(400, "bad request", :incomplete),
      Route.new(405, "method not allowed", :not_get, "Allow: GET"),
      Route.new(403, "forbidden", :wrong_token),
      Route.new(404, "not found", :undeclared),
      Route.new(500, "asset integrity failed", :integrity_failure, nil, true)
    ].freeze

    attr_reader :port

    def initialize(root, timer_api: UI, token: nil, request_timeout: REQUEST_TIMEOUT)
      @root = File.expand_path(root)
      @timer_api = timer_api
      @token = token || SecureRandom.hex(16)
      @request_timeout = request_timeout
      @lock = Mutex.new
      @ledger = []
      @log = []
      @clients = []
      @served = 0
      @busy = 0
      @max_pump_ms = 0.0
      @stopped = true
      @assets = RuntimeManifest.read(@root).fetch("assets").dup
      manifest_bytes = File.binread(File.join(@root, RuntimeManifest::PATH))
      @assets[RuntimeManifest::PATH] = {
        "bytes" => manifest_bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(manifest_bytes),
        "mime" => "application/json"
      }
      @invalid_assets = RuntimeManifest.invalid_assets(@root, @assets)
    end

    def start
      @lock.synchronize do
        return self unless @stopped

        @socket = TCPServer.new("127.0.0.1", 0)
        @port = @socket.addr[1]
        @stopped = false
      end
      start_acceptor
      schedule_pump
      self
    rescue StandardError
      stop
      raise
    end

    # The URL of a declared asset on this server.
    def url(asset, query = {})
      raise IOError, "asset server is stopped" if stopped?
      raise ArgumentError, "asset is not declared" unless @assets.key?(asset)

      suffix = query.empty? ? "" : "?" + query.map { |key, value| "#{key}=#{value}" }.join("&")
      "http://127.0.0.1:#{@port}/#{@token}/#{asset}#{suffix}"
    end

    # Stops accepting, closes every connection and cancels the pump. True the first time.
    def stop
      socket = timer = acceptor = nil
      clients = []
      @lock.synchronize do
        return false if @stopped

        @stopped = true
        socket = @socket
        @socket = nil
        timer = @pump_timer
        @pump_timer = nil
        acceptor = @acceptor
        clients = @clients.dup
      end
      @timer_api.stop_timer(timer) if timer
      # Closing the listening socket ends the acceptor's `accept`; a worker still reading a request
      # ends at its deadline or is killed.
      close_socket(socket)
      join_or_kill(acceptor)
      clients.each { |thread| join_or_kill(thread) }
      flush_log
      Diagnostics.log("asset_server_stopped", "status" => "ok")
      true
    end

    def stopped?
      @lock.synchronize { @stopped }
    end

    # Declared assets that are missing or altered on disk. A server with any is refused before use.
    def invalid_assets
      @invalid_assets.keys.sort
    end

    # What the server has served and which of its resources are still held. After `stop`, every
    # resource count is zero.
    def snapshot
      @lock.synchronize do
        {
          "request_count" => @served,
          "request_ledger" => @ledger.map(&:dup),
          "max_pump_ms" => @max_pump_ms.round(3),
          "resources" => {
            "timer" => @pump_timer ? 1 : 0,
            "acceptor" => @acceptor&.alive? ? 1 : 0,
            "clients" => @clients.count(&:alive?),
            "socket" => @socket && !@socket.closed? ? 1 : 0
          }
        }
      end
    end

    private

    def start_acceptor
      @acceptor = Thread.new do
        loop do
          session = @socket.accept
          @lock.synchronize { admit(session) }
        end
      rescue IOError, Errno::EBADF
        note("acceptor stopped") unless stopped?
      rescue StandardError => error
        note("acceptor failed: #{error.class}")
      end
    end

    # Called with the lock held.
    def admit(session)
      @clients.select!(&:alive?)
      if @stopped
        session.close
      elsif @clients.length >= MAX_CLIENTS
        session.close
        @log << "connection refused: client limit"
      else
        @clients << Thread.new(session) { |client| serve(client) }
      end
    end

    def schedule_pump
      return if stopped?

      delay = @lock.synchronize { @busy.positive? ? BUSY_INTERVAL : IDLE_INTERVAL }
      timer = @timer_api.start_timer(delay, false) { pump }
      @lock.synchronize { @pump_timer = timer unless @stopped }
    end

    def pump
      started = LoopbackHttp.monotonic
      busy = @lock.synchronize { @busy }
      sleep(busy.positive? ? BUSY_SLICE : IDLE_SLICE)
      flush_log
      elapsed = (LoopbackHttp.monotonic - started) * 1000.0
      @lock.synchronize do
        @max_pump_ms = elapsed if elapsed > @max_pump_ms
        @pump_timer = nil
      end
      schedule_pump
    end

    def serve(session)
      sequence = @lock.synchronize do
        @served += 1
        @busy += 1
        @served
      end
      request = parse(LoopbackHttp.read_request_line(session, :timeout => @request_timeout,
                                                              :max_header_bytes => MAX_HEADER_BYTES))
      ROUTES.each do |route|
        next unless (outcome = send(route.check, request))

        record(sequence, route.names_asset ? request.relative : "", route.status, outcome)
        return LoopbackHttp.respond(session, route.status, TEXT, route.body, route.header)
      end
      record(sequence, request.relative, 200, "served")
      LoopbackHttp.respond(session, 200, request.entry.fetch("mime"), request.body)
    rescue StandardError => error
      record(sequence || 0, "", 500, "worker_#{error.class.name}")
      begin
        LoopbackHttp.respond(session, 500, TEXT, "server failure")
      rescue StandardError
        nil
      end
    ensure
      @lock.synchronize do
        @busy -= 1
        @clients.delete(Thread.current)
      end
      close_socket(session)
    end

    def parse(line)
      return Request.new unless line

      method, target = line.split(" ", 3)
      path = target.to_s.split("?", 2).first.to_s
      prefix = "/#{@token}/"
      relative = LoopbackHttp.percent_decode(path[prefix.length..-1].to_s) if path.start_with?(prefix)
      Request.new(method, relative, relative && @assets[relative])
    end

    def incomplete(request)
      "timeout" unless request.method
    end

    def not_get(request)
      "unsupported_method" unless request.method == "GET"
    end

    def wrong_token(request)
      "wrong_token" unless request.relative
    end

    def undeclared(request)
      "undeclared_asset" unless request.entry
    end

    # Reads the body into the request when the asset is intact, so serving it reads the file once.
    # The full hash was checked when the server was built; a size change since then still refuses.
    def integrity_failure(request)
      return @invalid_assets.fetch(request.relative) if @invalid_assets.key?(request.relative)

      request.body = File.binread(File.join(@root, request.relative))
      "asset_integrity_failed" unless request.body.bytesize == request.entry.fetch("bytes")
    end

    def record(sequence, asset, status, outcome)
      @lock.synchronize do
        @ledger << { "sequence" => sequence, "asset" => asset, "status" => status, "outcome" => outcome }
        @log << "request #{sequence}: #{status} #{asset.empty? ? outcome : asset}"
      end
    end

    def note(line)
      @lock.synchronize { @log << line }
    end

    def flush_log
      lines = @lock.synchronize { @log.slice!(0, @log.length) }
      Diagnostics.log("asset_server_activity", "status" => lines.join(" | ")) unless lines.empty?
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
