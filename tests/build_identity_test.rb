# frozen_string_literal: true

require_relative "test_helper"

# Which package is running: the RBZ's recorded build, or a development build from a source checkout.
class BuildIdentityTest < PhComposerTestCase
  BuildIdentity = PhComposer::BuildIdentity
  def setup
    super
    @directory = Dir.mktmpdir("phc-build-")
    BuildIdentity.record_path = File.join(@directory, "build.json")
  end

  def teardown
    FileUtils.remove_entry(@directory)
    super
  end

  def test_a_source_checkout_is_a_development_build
    assert_equal ["development", nil], [BuildIdentity.build, BuildIdentity.commit]
    assert BuildIdentity.development?
    assert_match(/\A[0-9a-f]{12}\z/, BuildIdentity.manifest)
  end

  def test_a_package_reports_its_recorded_build_and_commit
    File.write(File.join(@directory, "build.json"),
               JSON.generate("build" => "0123456789ab", "commit" => "a1b2c3d4e5f6-dirty"))

    assert_equal %w[0123456789ab a1b2c3d4e5f6-dirty], [BuildIdentity.build, BuildIdentity.commit]
  end

  def test_a_record_it_cannot_trust_is_unavailable_rather_than_development
    File.write(File.join(@directory, "build.json"),
               JSON.generate("build" => "/Users/example", "commit" => "not a commit"))

    assert_equal ["unavailable", nil], [BuildIdentity.build, BuildIdentity.commit]
  end
end
