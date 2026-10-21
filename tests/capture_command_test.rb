# frozen_string_literal: true

require_relative "test_helper"

# The capture command (context/AGENT_INTERFACE.md, "Focused reads and visual context"): an image of the
# current view under its own grant, with its hash and provenance, kept briefly in a session folder.
class CaptureCommandTest < PhComposerTestCase
  API = PhComposer::API
  CAPTURE = PhComposer::CaptureCommand::CAPTURE

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @capturer = API.connect(:session_id => @session.id, :capabilities => %w[read capture])
  end

  def capture(params = {}, context = @capturer)
    API.view(:context => context, :name => CAPTURE, :params => params)
  end

  def test_capture_needs_its_own_grant_and_view_alone_is_refused
    viewer = API.connect(:session_id => @session.id, :capabilities => %w[read view])

    assert_equal "request.capability_denied", capture({}, viewer)["code"]
    assert_equal "capture", API.describe(:name => CAPTURE).fetch("capability")
  end

  def eye
    point = @model.active_view.camera.eye
    [point.x, point.y, point.z]
  end

  def test_a_capture_answers_its_file_hash_and_provenance_and_moves_nothing
    before = [eye, @model.selection.to_a, @model.active_path, @session.revision]
    value = capture("width" => 800, "height" => 500).fetch("value")
    bytes = File.binread(value.fetch("path"))

    assert_equal [Digest::SHA256.hexdigest(bytes), bytes.bytesize], value.values_at("sha256", "bytes")
    assert_equal [800, 500, "not_included"], value.values_at("width", "height", "overlays")
    refute value.key?("window_state"), "every window state measured gives the current view (#239)"
    assert_equal @session.view_generation, value.dig("provenance", "view_generation")
    assert value.dig("provenance", "camera", "eye_m")
    assert_equal before, [eye, @model.selection.to_a, @model.active_path,
                          @session.revision]
    assert_equal [1600, 1000], capture.dig("value").values_at("width", "height")
  end

  def test_a_failed_write_a_moved_view_and_an_oversized_image_refuse_and_leave_no_file
    view = @model.active_view
    outcomes = [
      lambda do |options|
        File.binwrite(options.fetch(:filename), "partial")
        false
      end,
      lambda do |options|
        File.binwrite(options.fetch(:filename), "partial")
        raise "the renderer failed"
      end,
      lambda do |options|
        File.binwrite(options.fetch(:filename), "png")
        @session.host_event(:camera_changed)
        true
      end,
      lambda do |options|
        File.binwrite(options.fetch(:filename), "x" * (PhComposer::CaptureCommand::MAX_BYTES + 1))
        true
      end
    ].map do |hook|
      view.write_image_hook = hook
      capture.fetch("code")
    end

    assert_equal %w[capture.failed capture.failed capture.view_changed capture.too_large], outcomes
    folder = File.dirname(view.images.last.fetch(:filename))
    assert_empty Dir.glob(File.join(folder, "cap_*.png"))
  end

  def test_one_side_alone_and_a_busy_session_refuse
    assert_equal "params.invalid", capture("width" => 800)["code"]
    @session.feature_state(:probe_deferred) { Struct.new(:pending?).new(true) }
    assert_equal "session.busy", capture["code"]
  end

  def test_a_fifth_capture_removes_the_oldest_and_old_files_go_on_the_next_call
    paths = Array.new(5) do |index|
      capture.dig("value", "path").tap { |path| File.utime(Time.now, Time.now - (10 - index), path) }
    end
    folder = File.dirname(paths.first)
    stranger = File.join(folder, "notes.txt")
    File.write(stranger, "not a capture")

    refute File.exist?(paths.first)
    assert_equal 4, Dir.glob(File.join(folder, "cap_*.png")).length
    paths[1..].each { |path| File.utime(Time.now, Time.now - 3600, path) if File.exist?(path) }
    latest = capture.dig("value", "path")
    assert_equal [latest], Dir.glob(File.join(folder, "cap_*.png"))
    assert File.exist?(stranger), "nothing but captures is touched"
  end
end
