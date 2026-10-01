# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/library_provider_fixtures"

class LibraryFileTest < PhComposerTestCase
  include LibraryProviderFixtures

  def test_many_kinds_are_detached_immutable_allowlisted_rows_with_separate_provenance
    value = envelope(:kinds => { "materials" => [library_row], "synthetic_parts" => [library_row] })
    result = parse_library(value)
    assert_equal %w[materials synthetic_parts], result.fetch("rows").keys.sort
    row = result.fetch("rows").fetch("materials").first
    assert_equal "synthetic.one", row.fetch("library_id")
    assert_equal library_row, row.fetch("snapshot")
    value.fetch("kinds").fetch("materials").first["name"] = "changed"
    assert_equal "Synthetic insulation", row.dig("snapshot", "name")
    assert_raises(FrozenError) { row["library_name"] = "changed" }
  end

  def test_envelope_problems_refuse_before_row_normalization_with_sanitized_distinct_codes
    [{ "schema_version" => 2 }, { "format" => "other" }, { "library" => nil }, { "exported_at" => "bad" }]
      .zip(%w[library.schema_unsupported library.format_invalid library.file_malformed 
library.file_malformed]) do |change, code|
      error = assert_raises(PhComposer::Library::Error) { parse_library(envelope.merge(change)) }
      assert_equal code, error.code
      refute_includes error.message, "bad"
    end
  end

  def test_unknown_and_unsupported_kind_are_unavailable_without_blocking_other_kind
    value = envelope(:kinds => { "materials" => [library_row], "synthetic_parts" => [library_row], "foreign" => [] })
    value.fetch("kind_schema_versions")["synthetic_parts"] = 9
    result = parse_library(value)
    assert_equal 1, result.fetch("rows").fetch("materials").length
    assert_equal %w[library.kind_schema_unsupported library.kind_unavailable],
                 result.fetch("unavailable").map { |row| row.fetch("code") }.sort
  end

  def test_bad_required_and_optional_values_are_skipped_without_nulling_and_absence_warns
    rows = [library_row("numeric-string").merge("conductivity_w_mk" => "0.04"),
            library_row("optional-bad").merge("notes" => 12),
            library_row("optional-absent").reject { |key, _| key == "notes" }]
    result = parse_library(envelope(rows))
    assert_equal ["optional-absent"], result.fetch("rows").fetch("materials").map { |row| row.fetch("record_id") }
    assert_equal %w[library.row_optional_absent library.row_optional_invalid library.row_required_invalid],
                 result.fetch("warnings").map { |row| row.fetch("code") }.sort
    refute result.fetch("rows").fetch("materials").first.fetch("snapshot").key?("notes")
  end

  def test_units_are_not_guessed_and_unknown_transport_fields_never_escape
    row = library_row.merge("path" => "/Users/private/catalog.json", "address" => "https://private.test",
                            "token" => "secret-test-token")
    ip = library_row("ip").reject { |key, _| key == "conductivity_w_mk" }.merge("conductivity_btu_hftf" => 0.03)
    unitless = library_row("unitless").reject { |key, _| key == "conductivity_w_mk" }.merge("conductivity" => 0.04)
    result = parse_library(envelope([row, ip, unitless]))
    assert_equal 1, result.fetch("rows").fetch("materials").length
    assert_equal 2, result.fetch("warnings").count { |entry| entry["code"] == "library.unit_invalid" }
    text = JSON.generate(result)
    %w[private secret-test-token conductivity_btu_hftf].each { |value| refute_includes text, value }
  end

  def test_missing_version_and_nonlist_kind_have_distinct_unavailable_conditions
    missing = envelope
    missing.fetch("kind_schema_versions").delete("materials")
    assert_equal "library.kind_schema_missing", parse_library(missing).fetch("unavailable").first.fetch("code")
    invalid = envelope(:kinds => { "materials" => {} })
    assert_equal "library.kind_malformed", parse_library(invalid).fetch("unavailable").first.fetch("code")
  end

  def test_shared_row_normalization_is_public_pure_and_does_not_alias_authored_values
    row = library_row
    snapshot, warnings = PhComposer::Library::LibraryFile.normalize_row(row, adapters.fetch("materials").wire_schema)
    assert_empty warnings
    snapshot["name"].replace("changed")
    assert_equal "Synthetic insulation", row.fetch("name")
  end

  def test_duplicate_id_refuses_only_affected_library_kind
    value = envelope(:kinds => { "materials" => [library_row, library_row], "synthetic_parts" => [library_row] })
    result = parse_library(value)
    assert_empty result.fetch("rows").fetch("materials")
    assert_equal 1, result.fetch("rows").fetch("synthetic_parts").length
    assert_equal ["library.duplicate_record_id"], result.fetch("unavailable").map { |row| row.fetch("code") }
  end
end
