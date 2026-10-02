# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/library_provider_fixtures"

class MaterialSourceReportTest < PhComposerTestCase
  include LibraryProviderFixtures

  def test_unused_copied_material_has_one_allowlisted_report_row_without_setup_or_snapshot
    directory = Dir.mktmpdir("source-report")
    path = write_library(File.join(directory, "fixture.json"))
    PhComposer::Library::Setup.add_file(:id => "synthetic", :label => "Synthetic", :path => path)
    session = PhComposer::Sessions.for(Sketchup.active_model)
    context = PhComposer::API.connect(:session_id => session.id, :capabilities => %w[read view model_write setup])
    loaded = PhComposer::API.setup(:context => context, :name => "ph_composer.library.load",
                                 :params => { "provider_id" => "synthetic", "kind" => "materials" })
    params = { "provider_id" => "synthetic", "kind" => "materials", "generation" => loaded.dig("value", "generation"),
               "library_id" => "synthetic.one", "record_id" => "public-1", "choice" => "create" }
    copied = PhComposer::API.invoke(:context => context, :name => "ph_composer.library.copy", :params => params,
                                   :request => { "sequence" => 1, "expected_revision" => session.revision })
    assert_equal "committed", copied["effect"], copied.inspect
    section = PhComposer::Assemblies::SourceReport::SECTION
    extracted = PhComposer::Export::Collection.build(Sketchup.active_model, :run_id => "sources",
                                                    :contributors => [section])
    rows = extracted.document.fetch("sections").fetch(section).fetch("records")
    assert_equal 1, rows.length
    assert_equal PhComposer::Assemblies::SourceReport::FIELDS.sort, rows.first.keys.sort
    assert_equal copied.dig("value", "local_id"), rows.first.fetch("id")
    assert_equal "public-1", rows.first.fetch("record_id")
    wire = JSON.generate(extracted.document)
    refute_includes wire, directory
    refute_includes wire, "Synthetic public fixture"
    refute_includes wire, "fingerprint"
    html = PhComposer::Assemblies::SourceReport.report({ "material_sources" => rows }, "SI").join
    assert_includes html, "ph_composer.library.file"
    assert_includes html, "public-1"
    refute_includes html, directory
    assert_empty PhComposer::Assemblies::SourceReport.report({}, "SI")
  ensure
    FileUtils.rm_rf(directory) if directory
  end
end
