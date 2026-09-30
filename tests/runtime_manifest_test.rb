# frozen_string_literal: true

require "digest"
require_relative "test_helper"

class RuntimeManifestTest < PhComposerTestCase
  Manifest = PhComposer::RuntimeManifest
  Gate = PhComposer::RuntimeGate
  ENTRY = { "bytes" => 1, "sha256" => "0" * 64, "mime" => "text/plain" }.freeze

  def setup
    super
    @root = Dir.mktmpdir("phc-manifest")
  end

  def teardown
    FileUtils.rm_rf(@root)
    super
  end

  # The one test that reads the real payload: what ships is exactly what the manifest pins.
  def test_the_shipped_payload_matches_its_manifest
    manifest = Manifest.read(PhComposer::ROOT)

    assert_empty Manifest.invalid_assets(PhComposer::ROOT, manifest.fetch("assets"))
    assert_equal "0.24.1", manifest.dig("pyodide", "version")
    roots = %w[html/ python/ vendor/pyodide/ vendor/wheels/]
    assert manifest.fetch("assets").keys.all? { |name| roots.any? { |root| name.start_with?(root) } }
    assert_equal 8, manifest.fetch("wheel_order").length
  end

  def test_a_malformed_manifest_is_a_packaging_fault
    {
      "[]" => "not an object",
      JSON.generate("schema_version" => 2) => "schema is not supported",
      JSON.generate("schema_version" => 1, "manifest_asset" => "other.json") => "control path",
      JSON.generate(base.merge("assets" => {})) => "assets are missing",
      JSON.generate(base.merge("assets" => { "../outside.js" => ENTRY })) => "unsafe asset",
      JSON.generate(base.merge("assets" => { "html/a.js" => ENTRY.merge("sha256" => "zz") })) => "invalid asset entry",
      JSON.generate(base.merge("assets" => { "html/a.js" => ENTRY.merge("mime" => "") })) => "invalid asset entry",
      "{" => "could not be read"
    }.each do |text, message|
      write("vendor/manifest.json", text)
      error = assert_raises(Manifest::Invalid) { Manifest.read(@root) }
      assert_includes error.message, message
    end
  end

  def test_a_missing_manifest_is_a_packaging_fault
    assert_raises(Manifest::Invalid) { Manifest.read(@root) }
  end

  def test_gates_merge_the_platform_overrides
    assert_equal 6_000, Gate.fetch("cold_boot_ceiling_ms", :platform_osx)
    assert_equal 12_000, Gate.fetch("cold_boot_ceiling_ms", :platform_win)
    refute Gate.selected(:platform_osx).keys.any? { |key| key.start_with?("platform_") }
    assert_equal Gate.selected(Sketchup.platform), Gate.selected
  end

  def test_a_missing_or_malformed_gate_is_a_packaging_fault
    error = assert_raises(Manifest::Invalid) { Gate.fetch("no_such_gate_ms") }
    assert_includes error.message, "no_such_gate_ms"

    Manifest.stub(:read, ->(_root) { { "gates" => [] } }) do
      Gate.reset_for_test
      assert_raises(Manifest::Invalid) { Gate.gates }
    end
  end

  private

  def base
    { "schema_version" => 1, "manifest_asset" => "vendor/manifest.json" }
  end

  def write(relative, text)
    path = File.join(@root, relative)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, text)
  end
end
