# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/library_provider_fixtures"

class FileLibraryProviderTest < PhComposerTestCase
  include LibraryProviderFixtures
  include LibraryProviderContract

  def setup
    super
    @directory = Dir.mktmpdir("phc-synthetic-library-")
  end

  def teardown
    FileUtils.remove_entry(@directory)
    super
  end

  def path(name)
    File.join(@directory, name)
  end

  def test_file_and_immediate_folder_pass_reusable_provider_contract
    file = write_library(path("one.json"))
    assert_equal 1, assert_library_provider(file_provider(file), "materials").rows.length
    write_library(path("second.JSON"), envelope(:library_id => "synthetic.two"))
    File.write(path("ignore.txt"), "invalid JSON")
    Dir.mkdir(path("nested"))
    write_library(File.join(path("nested"), "nested.json"))
    batch = assert_library_provider(file_provider(@directory), "materials")
    assert_equal %w[synthetic.one synthetic.two], batch.rows.map { |row| row.fetch("library_id") }
    assert_empty Sketchup.active_model.operations
  end

  def test_duplicate_folder_ids_refuse_affected_library_kind_and_preserve_other_kind_and_library
    write_library(path("one.json"), 
envelope(:kinds => { "materials" => [library_row], "synthetic_parts" => [library_row] }))
    write_library(path("two.json"), envelope)
    write_library(path("three.json"), envelope(:library_id => "synthetic.other"))
    provider = file_provider(@directory)
    batch = provider.list("materials")
    assert_equal ["synthetic.other"], batch.rows.map { |row| row.fetch("library_id") }
    assert_equal ["library.duplicate_record_id"], batch.unavailable.map { |row| row.fetch("code") }
    assert_equal 1, provider.list("synthetic_parts").rows.length
  end

  def test_conflicting_library_names_are_unavailable_instead_of_arbitrarily_merged
    write_library(path("one.json"))
    other = envelope([library_row("other")])
    other.fetch("library")["name"] = "Conflicting library"
    write_library(path("two.json"), other)
    batch = file_provider(@directory).list("materials")
    assert_empty batch.rows
    assert_equal ["library.identity_conflict"], batch.unavailable.map { |row| row.fetch("code") }
  end

  def test_malformed_candidate_warns_and_no_path_or_os_message_leaves_provider
    File.write(path("broken.json"), "invalid")
    write_library(path("valid.json"))
    provider = file_provider(@directory)
    batch = provider.list("materials")
    assert_equal 1, batch.rows.length
    assert_equal ["library.file_malformed"], batch.warnings.map { |row| row.fetch("code") }
    [JSON.generate(batch.to_h), provider.inspect].each { |text| refute_includes text, @directory }
    error = assert_raises(PhComposer::Library::Error) { file_provider(path("missing.json")).list("materials") }
    refute_includes error.full_message, @directory
  end

  def test_unknown_kind_is_visible_without_hiding_supported_rows
    write_library(path("one.json"), envelope(:kinds => { "materials" => [library_row], "foreign" => [library_row] }))
    batch = file_provider(@directory).list("materials")
    assert_equal 1, batch.rows.length
    assert_equal [{ "code" => "library.kind_unavailable", "kind" => "foreign", "library_id" => "synthetic.one" }],
                 batch.unavailable
  end

  def test_one_malformed_folder_candidate_is_an_empty_result_with_warning
    File.write(path("one.json"), "invalid")
    batch = file_provider(@directory).list("materials")
    assert_empty batch.rows
    assert_equal ["library.file_malformed"], batch.warnings.map { |row| row.fetch("code") }
  end

  def test_empty_folder_is_a_success_and_unsupported_kind_refuses
    batch = file_provider(@directory).list("materials")
    assert_empty batch.rows
    assert_empty batch.warnings
    assert_empty batch.unavailable
    assert batch.freshness.fetch("loaded_at")
    error = assert_raises(PhComposer::Library::Error) { file_provider(@directory).list("foreign") }
    assert_equal "library.kind_unavailable", error.code
  end

  def test_per_file_limit_exactly_and_one_byte_above_without_truncation
    file = write_library(path("limit.json"), envelope, :bytes => PhComposer::Library::LibraryFile::MAX_BYTES)
    assert_equal 1, file_provider(file).list("materials").rows.length
    File.open(file, "ab") { |stream| stream.write(" ") }
    error = assert_raises(PhComposer::Library::Error) { file_provider(file).list("materials") }
    assert_equal "library.file_too_large", error.code
  end

  def test_aggregate_bytes_exactly_and_one_byte_above_without_truncation
    limit = PhComposer::Library::LibraryFile::MAX_BYTES
    write_library(path("one.json"), envelope, :bytes => limit)
    write_library(path("two.json"), envelope(:library_id => "synthetic.two"), :bytes => limit)
    assert_equal 2, file_provider(@directory).list("materials").rows.length
    File.write(path("three.json"), " ")
    error = assert_raises(PhComposer::Library::Error) { file_provider(@directory).list("materials") }
    assert_equal "library.catalog_too_large", error.code
  end

  def test_aggregate_rows_exactly_and_one_above_includes_unavailable_kinds
    rows = 10_000.times.map { |index| library_row("record-#{index}") }
    write_library(path("one.json"), envelope(rows))
    write_library(path("two.json"), envelope(rows, :library_id => "synthetic.two"))
    assert_equal 20_000, file_provider(@directory).list("materials").rows.length
    write_library(path("three.json"), 
envelope(:library_id => "synthetic.three", :kinds => { "foreign" => [library_row] }))
    error = assert_raises(PhComposer::Library::Error) { file_provider(@directory).list("materials") }
    assert_equal "library.catalog_too_many_rows", error.code
  end
end
