# frozen_string_literal: true

# Development host bridge. Not shipped with the extension.
#
# `make bridge-install` copies this file into the SketchUp Plugins folder, where SketchUp loads it
# at startup. It listens on loopback with a random token and evaluates Ruby sent by
# `tools/hostkit/host_bridge.py` on the main thread, so an agent can drive the real host
# (open a Model, run actions, save, read state) without a person at the Ruby Console.
#
# It also tees everything written to the Ruby Console ($stdout and $stderr) into a log file next
# to the state file, so `host_bridge.py console` shows what the console showed.
#
# Security: loopback only, token required, one request at a time, removed by `make bridge-uninstall`.

require "json"
require "securerandom"
require "socket"
require "stringio"
require "time"

module PhComposerHostBridge
  PUMP_INTERVAL = 0.05
  MAX_REQUEST_BYTES = 4_000_000
  INSPECT_LIMIT = 200_000

  # Forwards console writes to the original stream and appends them to a log file.
  class ConsoleTee
    def initialize(target, path, label)
      @target = target
      @path = path
      @label = label
    end

    def write(*args)
      text = args.map(&:to_s).join
      @target.write(text) if @target.respond_to?(:write)
      append(text)
      text.bytesize
    end

    def puts(*args)
      lines = args.flatten.map { |arg| arg.to_s.end_with?("\n") ? arg.to_s : arg.to_s + "\n" }
      text = args.empty? ? "\n" : lines.join
      write(text)
      nil
    end

    def print(*args)
      write(args.map(&:to_s).join)
      nil
    end

    def <<(text)
      write(text)
      self
    end

    def flush
      @target.flush if @target.respond_to?(:flush)
      self
    end

    def target
      @target
    end

    def respond_to_missing?(name, include_private = false)
      @target.respond_to?(name, include_private) || super
    end

    def method_missing(name, *args, &block)
      @target.respond_to?(name) ? @target.public_send(name, *args, &block) : super
    end

    private

    def append(text)
      File.open(@path, "a") { |file| file.write(text) }
    rescue StandardError
      nil
    end
  end

  class Server
    attr_reader :port, :token, :state_path, :console_path

    def initialize(state_path:, timer_api: UI, token: nil, tee_console: false)
      @state_path = state_path
      @console_path = state_path.sub(/\.json\z/, ".console.log")
      @timer_api = timer_api
      @token = token || SecureRandom.hex(16)
      @tee_console = tee_console
      @queue = Queue.new
      @binding = TOPLEVEL_BINDING
      @stopped = true
    end

    def start
      @socket = TCPServer.new("127.0.0.1", 0)
      @port = @socket.addr[1]
      @stopped = false
      install_console_tee if @tee_console
      write_state
      @acceptor = Thread.new { accept_loop }
      schedule_pump
      self
    end

    def stop
      return false if @stopped

      @stopped = true
      @timer_api.stop_timer(@pump_timer) if @pump_timer
      @pump_timer = nil
      @socket&.close
      @acceptor&.kill
      remove_console_tee
      File.delete(@state_path) if File.file?(@state_path)
      true
    end

    def stopped?
      @stopped
    end

    # Runs on the main thread. Returns the number of requests served.
    def pump
      served = 0
      until @queue.empty?
        session, request = @queue.pop
        reply(session, handle(request))
        served += 1
      end
      served
    end

    private

    def install_console_tee
      banner = "--- bridge started #{Time.now.utc.iso8601} pid #{Process.pid}\n"
      File.open(@console_path, "a") { |file| file.write(banner) }
      @original_stdout = $stdout
      @original_stderr = $stderr
      $stdout = ConsoleTee.new(@original_stdout, @console_path, "out")
      $stderr = ConsoleTee.new(@original_stderr, @console_path, "err")
    end

    def remove_console_tee
      $stdout = @original_stdout if @original_stdout
      $stderr = @original_stderr if @original_stderr
    end

    def write_state
      File.write(@state_path, JSON.generate(
        "port" => @port, "token" => @token, "pid" => Process.pid,
        "started_at" => Time.now.utc.iso8601, "console_log" => @console_path
      ))
    end

    def accept_loop
      loop do
        session = @socket.accept
        line = session.gets("\n", MAX_REQUEST_BYTES)
        request = line ? JSON.parse(line) : nil
        @queue << [session, request]
      rescue JSON::ParserError
        reply(session, "ok" => false, "error" => "bad request")
      end
    rescue IOError, Errno::EBADF
      nil
    end

    def schedule_pump
      return if @stopped

      @pump_timer = @timer_api.start_timer(PUMP_INTERVAL, false) do
        @pump_timer = nil
        begin
          pump
        ensure
          schedule_pump
        end
      end
    end

    def handle(request)
      return { "ok" => false, "error" => "bad request" } unless request.is_a?(Hash)
      return { "ok" => false, "error" => "forbidden" } unless request["token"] == @token
      return { "ok" => true, "result" => "pong", "stdout" => "" } if request["ping"]

      evaluate(request["code"].to_s)
    end

    def evaluate(code)
      captured = StringIO.new
      original = $stdout
      $stdout = captured
      result = eval(code, @binding, "(host_bridge)") # rubocop:disable Security/Eval
      {
        "ok" => true, "result" => truncate(result.inspect), "value" => json_value(result),
        "stdout" => captured.string
      }
    rescue Exception => error # rubocop:disable Lint/RescueException
      raise if error.is_a?(SystemExit)

      {
        "ok" => false, "error" => "#{error.class}: #{error.message}",
        "backtrace" => Array(error.backtrace).first(12), "stdout" => captured.string
      }
    ensure
      $stdout = original
      log_eval_output(captured.string)
    end

    def log_eval_output(text)
      return if text.empty? || !@tee_console

      File.open(@console_path, "a") { |file| file.write(text.end_with?("\n") ? text : text + "\n") }
    rescue StandardError
      nil
    end

    def json_value(result)
      JSON.parse(JSON.generate(result))
    rescue StandardError
      nil
    end

    def truncate(text)
      text.length > INSPECT_LIMIT ? text[0, INSPECT_LIMIT] + "...(truncated)" : text
    end

    def reply(session, payload)
      session.write(JSON.generate(payload) + "\n")
    rescue StandardError
      nil
    ensure
      session.close rescue nil
    end
  end

  def self.state_path
    File.expand_path("../ph_composer_host_bridge.json", __dir__)
  end

  def self.start
    @server ||= Server.new(:state_path => state_path, :tee_console => true).start
  end

  def self.server
    @server
  end
end

if defined?(Sketchup) && Sketchup.respond_to?(:version) && !ENV.key?("PHC_HOST_BRIDGE_NO_AUTOSTART")
  PhComposerHostBridge.start
end
