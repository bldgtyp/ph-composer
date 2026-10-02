# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/assembly_record_fixtures"
require_relative "../src/ph_composer/library/file_provider"

class StarterLibraryTest < PhComposerTestCase
  include AssemblyRecordFixtures

  def test_public_starter_is_complete_warning_free_and_semantically_mappable
    adapter = PhComposer::Registry.current.library_kinds.fetch(PhComposer::Assemblies::MaterialsLibrary::NAME).adapter
    provider = PhComposer::Library::FileProvider.new(
      :id => "test.starter", :label => "Starter",
      :path => File.expand_path("../starter-library/materials.json", __dir__),
      :kinds => ["materials"], :adapters => ->(kind) { adapter if kind == "materials" }
    )
    batch = provider.list("materials")
    assert_equal 12, batch.rows.length
    assert_empty batch.warnings
    assert_empty batch.unavailable
    assert_equal 12, batch.rows.map { |row| row.fetch("record_id") }.uniq.length
    batch.rows.each do |row|
      values = adapter.map.call(row.fetch("snapshot"))
      assert_empty PhComposer::JsonSchema.validate(values, adapter.mapped_schema)
      assert_operator values.fetch("conductivity_w_mk"), :>, 0
      assert_match(%r{https://(?:www\.energy\.gov|tsapps\.nist\.gov)/}, values.fetch("notes"))
      assert_nil values.fetch("emissivity")
      refute values.key?("source")
    end
    assert_empty Sketchup.active_model.operations
  end
end
