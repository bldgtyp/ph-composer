# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/library_provider_fixtures"

class LibraryCatalogTest < PhComposerTestCase
  include LibraryProviderFixtures
  Provider = PhComposer::Library::Provider

  class SyntheticProvider
    attr_accessor :batch, :failure

    def id
      "provider.synthetic"
    end

    def list(_kind)
      raise failure if failure

      batch
    end
  end

  def setup
    super
    @time = Time.utc(2026, 10, 1)
    @catalog = PhComposer::Library::Catalog.new(:clock => -> { @time })
    @provider = SyntheticProvider.new
    @provider.batch = batch([library_row])
  end

  def batch(rows)
    catalog_rows = rows.map do |row|
      { "library_id" => "synthetic.one", "library_name" => "Synthetic library", "record_id" => row.fetch("id"),
        "wire_schema_version" => 1, "snapshot" => row }
    end
    Provider::Batch.new(:rows => catalog_rows, :warnings => [], :unavailable => [],
                        :freshness => { "exported_at" => "2026-10-01T00:00:00Z" })
  end

  def test_failed_refresh_retains_identical_generation_rows_and_visible_age
    first = @catalog.refresh(@provider, :kind => "materials")
    @time += 120
    @provider.failure = IOError.new("private path /Users/private/library.json")
    failed = @catalog.refresh(@provider, :kind => "materials")
    assert_equal "failed", failed.fetch("state")
    assert_equal first.fetch("generation"), failed.fetch("generation")
    assert_equal first.fetch("rows"), failed.fetch("rows")
    assert_equal 120.0, failed.fetch("age_seconds")
    assert_equal "library.provider_failed", failed.dig("failure", "code")
    refute_includes JSON.generate(failed), "/Users/private"
    assert_equal first.fetch("rows"),
                 @catalog.fetch(@provider.id, "materials", :generation => first.fetch("generation")).fetch("rows")
  end

  def test_empty_success_differs_from_unloaded_and_failure_and_advances_generation
    assert_equal "unloaded", @catalog.fetch(@provider.id, "materials").fetch("state")
    first = @catalog.refresh(@provider, :kind => "materials")
    @provider.batch = batch([])
    empty = @catalog.refresh(@provider, :kind => "materials")
    assert_equal "empty", empty.fetch("state")
    assert_nil empty.fetch("failure")
    assert_empty empty.fetch("rows")
    assert_operator empty.fetch("generation"), :>, first.fetch("generation")
    error = assert_raises(PhComposer::Library::Error) do
      @catalog.fetch(@provider.id, "materials", :generation => first.fetch("generation"))
    end
    assert_equal "library.catalog_stale", error.code
  end

  def test_provider_batch_refuses_malformed_base_contract_and_detaches_input
    error = assert_raises(PhComposer::Library::Error) do
      Provider::Batch.new(:rows => [{ "name" => "missing id" }], :warnings => [], :unavailable => [], :freshness => {})
    end
    assert_equal "library.provider_invalid", error.code
    original = library_row
    immutable = batch([original])
    original["name"] = "changed"
    assert_equal "Synthetic insulation", immutable.rows.first.dig("snapshot", "name")
    assert immutable.to_h.frozen?
  end

  def test_shared_admission_runs_before_publication_and_failure_retains_valid_generation
    first = @catalog.refresh(@provider, :kind => "materials")
    @provider.batch = batch([library_row("incoming")])
    failed = @catalog.refresh(@provider, :kind => "materials") do |_incoming|
      raise PhComposer::Library::Error.new("library.row_required_invalid", "unsafe provider text /private/secret")
    end
    assert_equal first.fetch("generation"), failed.fetch("generation")
    assert_equal first.fetch("rows"), failed.fetch("rows")
    refute_includes JSON.generate(failed), "secret"
    published = @catalog.refresh(@provider, :kind => "materials") { |_incoming| batch([]) }
    assert_equal "empty", published.fetch("state")
    assert_operator published.fetch("generation"), :>, first.fetch("generation")
  end

  def test_non_json_values_and_cycles_refuse_before_freezing_or_copying
    cyclic = []
    cyclic << cyclic
    [Object.new, Float::INFINITY, cyclic, "\xff".b, { "\xff".b => "invalid key" }].each do |value|
      assert_raises(PhComposer::Library::Error) do
        Provider::Batch.new(:rows => [], :warnings => [], :unavailable => [], :freshness => { "unsafe" => value })
      end
    end
  end

  def test_invalid_provider_response_cannot_publish_half_generation_and_remove_discards_old_catalog
    first = @catalog.refresh(@provider, :kind => "materials")
    @provider.batch = { "rows" => [library_row("unvalidated")] }
    failed = @catalog.refresh(@provider, :kind => "materials")
    assert_equal first.fetch("generation"), failed.fetch("generation")
    assert_equal "library.provider_invalid", failed.dig("failure", "code")
    assert_raises(FrozenError) { failed.fetch("rows").first.fetch("snapshot")["name"] = "changed" }
    @catalog.remove(@provider.id)
    assert_equal "unloaded", @catalog.fetch(@provider.id, "materials").fetch("state")
  end
end
