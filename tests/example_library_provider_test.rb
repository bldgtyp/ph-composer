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

  def test_name_free_tags_copy_assign_replace_then_export_and_import_into_a_fresh_model
    assert BldgtypExampleLibrary.activate
    proof = BldgtypExampleLibraryWalkthrough.tags
    assert proof.fetch("assigned"), proof.inspect
    assert_equal "reuse", proof.fetch("outcome")
    assert proof.fetch("source_changed")
    assert_equal proof.fetch("local_id"), proof.fetch("replaced_id")
    assert_equal({ "designation" => "N-1", "height_mm" => 200.0 },
                 proof.dig("tag", "values").slice("designation", "height_mm"))
    assert_equal proof.fetch("local_id"), proof.dig("holder", "values", "tag_id")

    directory = Dir.mktmpdir("example-tags")
    path = File.join(directory, "tags.json")
    session = PhComposer::Sessions.for(Sketchup.active_model)
    context = PhComposer::API.connect(:session_id => session.id, :capabilities => %w[read export])
    # The export as a native client runs it once the user has chosen the file in the save dialog.
    approval = PhComposer::NativeApproval::Granted.new(:path => path, :replace => true)
    exported = PhComposer::Dispatch.new.file_export(context, "ph_composer.library.export_file", { "kinds" => ["tags"] },
                                                    :approval => approval)
    assert_equal "completed", exported["status"], exported.inspect
    row = JSON.parse(File.read(path)).dig("kinds", "tags").first
    assert_equal %w[designation height_mm id], row.keys.sort

    PhComposer::Library::Setup.add_file(:id => "exported.tags", :label => "Exported tags", :path => path)
    Sketchup.active_model = Sketchup::Model.new
    fresh = PhComposer::Sessions.for(Sketchup.active_model)
    context = PhComposer::API.connect(:session_id => fresh.id, :capabilities => %w[read model_write setup])
    loaded = PhComposer::API.setup(:context => context, :name => "ph_composer.library.load",
                                   :params => { "provider_id" => "exported.tags", "kind" => "tags" })
    holder = PhComposer::API.invoke(:context => context, :name => "bldgtyp.example_library.add_holder",
                                    :params => { "position" => "Imported" },
                                    :request => { "sequence" => 1, "expected_revision" => fresh.revision })
    copied = PhComposer::API.invoke(:context => context, :name => "ph_composer.library.copy", :params => {
      "provider_id" => "exported.tags", "kind" => "tags", "generation" => loaded.dig("value", "generation"),
      "library_id" => exported.dig("value", "library_id"), "record_id" => row.fetch("id"), "choice" => "create",
      "assignment" => { "id" => holder.dig("value", "id") }
    }, :request => { "sequence" => 2, "expected_revision" => fresh.revision })
    assert_equal "committed", copied["effect"], copied.inspect
    holders = PhComposer::API.query(:context => context, :name => "ph_composer.records.list",
                                    :params => { "kind" => BldgtypExampleLibrary::HOLDER }).dig("value", "records")
    assert_equal [copied.dig("value", "local_id")], holders.map { |entry| entry.dig("values", "tag_id") }
  ensure
    FileUtils.rm_rf(directory) if directory
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
