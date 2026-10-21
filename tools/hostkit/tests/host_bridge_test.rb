# frozen_string_literal: true

require "json"
require "socket"
require "test_helper"

class HostBridgeTest < PhComposerTestCase
  Bridge = PhComposerHostBridge

  def setup
    super
    @directory = Dir.mktmpdir("ph-composer-bridge")
    @server = Bridge::Server.new(:state_path => File.join(@directory, "state.json")).start
  end

  def teardown
    @server.stop
    FileUtils.rm_rf(@directory)
    super
  end

  def test_evaluates_on_the_main_thread_and_captures_stdout
    state = JSON.parse(File.read(@server.state_path))
    assert_equal @server.port, state.fetch("port")

    reply = exchange("token" => state.fetch("token"), "code" => "puts 'hello'; [1, 2].sum")
    assert reply.fetch("ok")
    assert_equal 3, reply.fetch("value")
    assert_equal "hello\n", reply.fetch("stdout")
  end

  def test_rejects_a_wrong_token_and_reports_ruby_errors
    forbidden = exchange("token" => "nope", "code" => "1")
    refute forbidden.fetch("ok")
    assert_equal "forbidden", forbidden.fetch("error")

    failed = exchange("token" => @server.token, "code" => "raise ArgumentError, 'boom'")
    refute failed.fetch("ok")
    assert_equal "ArgumentError: boom", failed.fetch("error")
  end

  def test_the_state_file_is_readable_by_its_owner_only
    skip "file modes are POSIX" if Gem.win_platform?

    assert_equal 0o600, File.stat(@server.state_path).mode & 0o777
  end

  def test_stop_removes_the_state_file
    @server.stop
    refute File.exist?(@server.state_path)
  end

  private

  def exchange(payload)
    socket = TCPSocket.new("127.0.0.1", @server.port)
    socket.write(JSON.generate(payload) + "\n")
    deadline = Time.now + 5
    until IO.select([socket], nil, nil, 0.05)
      UI.run_next_timer
      raise "no reply" if Time.now > deadline
    end
    JSON.parse(socket.gets)
  ensure
    socket&.close
  end
end
