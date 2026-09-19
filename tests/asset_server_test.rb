# frozen_string_literal: true

require "digest"
require "net/http"
require_relative "test_helper"

class AssetServerTest < PhComposerTestCase
  AssetServer = PhComposer::AssetServer
  TOKEN = "a" * 32

  def setup
    super
    @root = Dir.mktmpdir("phc-asset-server")
    write_asset("html/runtime.html", "<h1>runtime</h1>")
    write_manifest
    @server = AssetServer.new(@root, :token => TOKEN).start
  end

  def teardown
    @server.stop
    FileUtils.rm_rf(@root)
    super
  end

  def test_serves_only_a_declared_asset_with_the_isolation_headers
    response = get(@server.url("html/runtime.html"))

    assert_equal "200", response.code
    assert_equal "<h1>runtime</h1>", response.body
    assert_equal "text/html; charset=utf-8", response["content-type"]
    assert_equal "same-origin", response["cross-origin-opener-policy"]
    assert_equal "require-corp", response["cross-origin-embedder-policy"]
    assert_equal "same-origin", response["cross-origin-resource-policy"]
    assert_equal "nosniff", response["x-content-type-options"]
    assert_equal "no-store", response["cache-control"]
  end

  def test_the_manifest_itself_is_served_as_json
    response = get(@server.url("vendor/manifest.json"))

    assert_equal "200", response.code
    assert_equal "application/json", response["content-type"]
  end

  def test_refuses_a_wrong_token_an_unlisted_path_traversal_and_other_methods
    assert_equal "403", get(@server.url("html/runtime.html").sub("/#{TOKEN}/", "/#{'b' * 32}/")).code
    assert_equal "404", get("#{base_url}/html/missing.js").code
    write_asset("secret.txt", "not declared")
    assert_equal "404", get("#{base_url}/%2e%2e/secret.txt").code
    assert_equal "404", get("#{base_url}/secret.txt").code

    uri = URI(@server.url("html/runtime.html"))
    assert_equal "405", Net::HTTP.start(uri.host, uri.port) { |http| http.request(Net::HTTP::Post.new(uri)).code }
    outcomes = @server.snapshot.fetch("request_ledger").map { |row| row.fetch("outcome") }
    assert_equal %w[wrong_token undeclared_asset undeclared_asset undeclared_asset unsupported_method], outcomes
  end

  def test_an_asset_changed_after_start_is_refused
    write_asset("html/runtime.html", "changed")

    response = get(@server.url("html/runtime.html"))

    assert_equal "500", response.code
    assert_equal "asset integrity failed", response.body
    assert_equal "asset_integrity_failed", @server.snapshot.fetch("request_ledger").last.fetch("outcome")
  end

  def test_a_same_size_tampered_asset_is_found_before_anything_is_served
    @server.stop
    write_asset("html/runtime.html", "<h1>runtimf</h1>")
    @server = AssetServer.new(@root, :token => TOKEN).start

    assert_equal ["html/runtime.html"], @server.invalid_assets
    assert_equal "500", get(@server.url("html/runtime.html")).code
  end

  def test_a_missing_asset_is_listed_as_invalid
    @server.stop
    File.delete(File.join(@root, "html", "runtime.html"))
    @server = AssetServer.new(@root, :token => TOKEN).start

    assert_equal ["html/runtime.html"], @server.invalid_assets
  end

  def test_url_names_only_declared_assets_on_a_running_server
    assert_raises(ArgumentError) { @server.url("html/other.html") }
    assert_match(%r{\Ahttp://127\.0\.0\.1:\d+/#{TOKEN}/html/runtime\.html\?session=s1\z},
                 @server.url("html/runtime.html", "session" => "s1"))
    @server.stop
    assert_raises(IOError) { @server.url("html/runtime.html") }
  end

  def test_the_pump_runs_on_a_ui_timer_and_stop_cancels_it
    assert_equal 1, @server.snapshot.dig("resources", "timer")
    UI.run_timer(UI.timer_intervals.keys.last)
    assert_equal 1, @server.snapshot.dig("resources", "timer"), "each tick schedules the next"

    assert @server.stop
    refute @server.stop, "a second stop does nothing"
    assert_equal({ "timer" => 0, "acceptor" => 0, "clients" => 0, "socket" => 0 }, @server.snapshot.fetch("resources"))
    assert_equal 0, UI.timer_count
  end

  def test_a_partial_request_times_out_and_releases_its_worker
    @server.stop
    @server = AssetServer.new(@root, :token => TOKEN, :request_timeout => 0.05).start
    socket = TCPSocket.new("127.0.0.1", @server.port)
    socket.write("GET /#{TOKEN}/html/runtime.html HTTP/1.1\r\n")

    assert_includes socket.read, "400 Bad Request"
    assert wait_for { @server.snapshot.dig("resources", "clients").zero? }
  ensure
    socket.close if socket && !socket.closed?
  end

  def test_an_oversized_request_header_is_refused_before_it_is_parsed
    socket = TCPSocket.new("127.0.0.1", @server.port)
    padding = "p" * (AssetServer::MAX_HEADER_BYTES + 1)
    socket.write("GET /#{TOKEN}/html/runtime.html HTTP/1.1\r\nX-Pad: #{padding}\r\n\r\n")

    assert_includes socket.read, "400 Bad Request"
  ensure
    socket.close if socket && !socket.closed?
  end

  def test_the_client_limit_closes_the_next_connection_without_serving_it
    sockets = Array.new(AssetServer::MAX_CLIENTS) do
      socket = TCPSocket.new("127.0.0.1", @server.port)
      socket.write("GET /#{TOKEN}/html/runtime.html HTTP/1.1\r\n")
      socket
    end
    assert wait_for { @server.snapshot.dig("resources", "clients") >= AssetServer::MAX_CLIENTS }, "the slots fill up"

    refused = TCPSocket.new("127.0.0.1", @server.port)

    assert_equal "", refused.read.to_s, "the connection over the limit is closed, never served"
    assert_operator @server.snapshot.dig("resources", "clients"), :<=, AssetServer::MAX_CLIENTS
  ensure
    Array(sockets).each { |socket| socket.close unless socket.closed? }
    refused.close if refused && !refused.closed?
  end

  private

  def wait_for(timeout = 2.0)
    deadline = Time.now + timeout
    sleep(0.01) until yield || Time.now > deadline
    yield
  end

  def base_url
    @server.url("html/runtime.html").sub(%r{/html/runtime\.html\z}, "")
  end

  def get(url)
    Net::HTTP.get_response(URI(url))
  end

  def write_asset(relative, contents)
    path = File.join(@root, relative)
    FileUtils.mkdir_p(File.dirname(path))
    File.binwrite(path, contents)
  end

  def write_manifest
    body = File.binread(File.join(@root, "html", "runtime.html"))
    entry = { "bytes" => body.bytesize, "sha256" => Digest::SHA256.hexdigest(body),
              "mime" => "text/html; charset=utf-8" }
    manifest = { "schema_version" => 1, "manifest_asset" => "vendor/manifest.json",
                 "assets" => { "html/runtime.html" => entry } }
    write_asset("vendor/manifest.json", JSON.generate(manifest))
  end
end
