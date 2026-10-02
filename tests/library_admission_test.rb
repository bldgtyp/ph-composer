# frozen_string_literal: true

require_relative "test_helper"

class LibraryAdmissionTest < PhComposerTestCase
  def setup
    super
    @adapter = PhComposer::Registry.current.library_kinds.values.first.adapter
  end

  def row(id = "one", library = "first", version = 1, properties = {})
    { "library_id" => library, "library_name" => "Synthetic", "record_id" => id,
      "wire_schema_version" => version, "snapshot" => { "id" => id, "name" => "Insulation" }.merge(properties) }
  end

  def admit(rows, warnings = [], freshness = {})
    batch = PhComposer::Library::Provider::Batch.new(:rows => rows, :warnings => warnings,
                                                    :unavailable => [], :freshness => freshness)
    PhComposer::Library::Admission.call(batch, :kind => "materials", :adapter => @adapter)
  end

  def test_all_providers_drop_unknown_values_and_arbitrary_diagnostic_text
    marker = "credential-value-that-must-not-cross"
    result = admit([row("one", "first", 1, "path" => marker, "token" => marker, "address" => marker)],
                   [{ "code" => "library.row_fields_omitted", "message" => marker, "detail" => marker }],
                   "loaded_at" => "2026-10-01T00:00:00Z", "path" => marker, "exported_at" => marker)
    refute_includes JSON.generate(result.to_h), marker
    assert_equal %w[id name], result.rows.first.fetch("snapshot").keys.sort
    assert_equal({ "loaded_at" => "2026-10-01T00:00:00Z" }, result.freshness)
    assert result.rows.frozen?
  end

  def test_semantically_invalid_color_is_skipped_before_a_catalog_row_is_published
    result = admit([row("invalid", "first", 1, "color" => "not-hex"),
                    row("valid", "first", 1, "color" => "#ABCDEF")])
    assert_equal ["valid"], result.rows.map { |entry| entry.fetch("record_id") }
    warning = result.warnings.find { |row| row["code"] == "library.row_semantic_invalid" }
    refute_nil warning
    assert_equal "invalid", warning.fetch("record_id")
  end

  def test_duplicate_source_identity_withholds_only_its_library
    result = admit([row, row, row("one", "second")])
    assert_equal ["second"], result.rows.map { |entry| entry["library_id"] }
    assert_includes result.unavailable.map { |entry| entry["code"] }, "library.duplicate_record_id"
  end

  def test_unsupported_kind_version_withholds_every_row_claiming_that_library
    result = admit([row("old", "first", 2), row("current"), row("other", "second")])
    assert_equal ["second"], result.rows.map { |entry| entry["library_id"] }
    assert_equal "library.kind_schema_unsupported", result.unavailable.first["code"]
  end

  def test_ip_or_unitless_declared_numeric_values_cannot_become_usable_records
    result = admit([row("one", "first", 1, "conductivity_w_mk" => "0.04")])
    assert_empty result.rows
    assert_equal "library.row_optional_invalid", result.warnings.first["code"]
  end
end
