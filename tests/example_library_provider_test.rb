# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/library_provider_fixtures"
require "open3"
require "rbconfig"
require_relative "../tools/examples/library_provider/bldgtyp_example_library/install"
require_relative "../tools/examples/library_provider/walkthrough"

class ExampleLibraryProviderTest < PhComposerTestCase
  include LibraryProviderContract

  def test_loaded_before_core_reports_diagnostic_and_creates_no_core_namespace
    path = File.expand_path("../tools/examples/library_provider/bldgtyp_example_library/install.rb", __dir__)
    out, err, status = Open3.capture3(RbConfig.ruby, "-e", "load ARGV.fetch(0); puts defined?(PhComposer).inspect", 
path)
    assert status.success?, err
    assert_equal "nil\n", out
    assert_includes err, "after PH-Composer has finished loading"
  end

  def test_separate_batch_provider_contract_and_panel_closed_copy_readback
    assert BldgtypExampleLibrary.activate
    provider = BldgtypExampleLibrary::Provider.new
    batch = assert_library_provider(provider, "materials")
    assert_equal 2, batch.rows.length
    before = File.binread(File.join(SOURCE_ROOT, "ph_composer", "extension.rb"))
    proof = BldgtypExampleLibraryWalkthrough.run
    assert proof.fetch("passed"), proof.inspect
    assert_equal "committed", proof.fetch("effect")
    assert_equal before, File.binread(File.join(SOURCE_ROOT, "ph_composer", "extension.rb"))
    second = BldgtypExampleLibraryWalkthrough.run
    assert second.fetch("passed"), second.inspect
    assert_equal proof.fetch("local_id"), second.fetch("local_id")
    assert_equal "none", second.fetch("effect")
  end

  def test_duplicate_registration_and_unavailable_kind_fail_explicitly
    assert BldgtypExampleLibrary.activate
    assert_raises(PhComposer::RegistrationError) { PhComposer::Registry.install([BldgtypExampleLibrary]) }
    error = assert_raises(PhComposer::Library::Error) { BldgtypExampleLibrary::Provider.new.list("frames") }
    assert_equal "library.kind_unavailable", error.code
  end

  def test_unavailable_registered_kind_and_incompatible_major_publish_nothing
    [[1, ["unavailable_parts"]], [2, ["materials"]]].each_with_index do |(version, kinds), index|
      id = "example.invalid#{index}"
      feature = Module.new do
        define_singleton_method(:install) do |registry|
          scope = registry.feature(id, :contract_version => 1)
          scope.library_provider("#{id}.provider", :contract_version => version, :kinds => kinds) { [] }
        end
      end
      assert_raises(PhComposer::RegistrationError) { PhComposer::Registry.install([feature]) }
      refute PhComposer::Registry.installed?(id)
    end
  end
end
