# frozen_string_literal: true

require_relative "test_helper"

# The display preference store: what it reads back, what it refuses, and how it survives values it did
# not write. The panel's message handling is in panel_test.rb.
class PreferencesTest < PhComposerTestCase
  Preferences = PhComposer::Preferences
  SECTION = Preferences::SECTION

  def test_first_use_is_si_with_no_remembered_scope
    snapshot = Preferences.snapshot

    assert_equal "SI", snapshot.fetch("unit_system")
    assert_equal({}, snapshot.fetch("dimension_formats"))
    assert_equal({ "decimal" => ".", "locale" => "en-US" }, snapshot.fetch("number_format"))
  end

  def test_each_scope_remembers_its_si_and_ip_formats_separately
    Preferences.set("dimension_format", "cm", :scope => "example.editor", :system => "SI")
    Preferences.set("dimension_format", "ft-in", :scope => "example.editor", :system => "IP")
    Preferences.set("dimension_format", "m", :scope => "example.builder", :system => "SI")

    assert_equal({ "example.editor" => { "SI" => "cm", "IP" => "ft-in" },
                   "example.builder" => { "SI" => "m", "IP" => "in" } }, Preferences.dimension_formats)
  end

  # SketchUp 26.1 reads back nil for a stored string holding a double quote; the stub does the same.
  def test_the_remembered_formats_survive_the_hosts_quote_handling
    Preferences.set("dimension_format", "in-frac", :scope => "example.editor", :system => "IP")

    stored = Sketchup.read_default(SECTION, "dimension_formats")
    refute_nil stored
    refute_includes stored, '"'
  end

  def test_values_the_store_did_not_write_read_as_defaults
    Sketchup.write_default(SECTION, "unit_system", "metric")
    formats = { "example.editor" => { "SI" => "in", "IP" => "yards" }, "Not A Scope" => { "SI" => "cm" } }
    Sketchup.write_default(SECTION, "dimension_formats", [JSON.generate(formats)].pack("m0"))

    assert_equal "SI", Preferences.unit_system
    assert_equal({ "example.editor" => { "SI" => "mm", "IP" => "in" } }, Preferences.dimension_formats)
    Sketchup.write_default(SECTION, "dimension_formats", "not base64 json")
    assert_equal({}, Preferences.dimension_formats)
  end

  def test_a_bad_scope_or_too_many_scopes_are_refused_without_writing
    error = assert_raises(PhComposer::UserError) do
      Preferences.set("dimension_format", "mm", :scope => "Editor", :system => "SI")
    end
    assert_equal "The dimension scope name is not valid.", error.message

    Preferences::MAX_SCOPES.times do |index|
      Preferences.set("dimension_format", "cm", :scope => "example.scope_#{index}", :system => "SI")
    end
    Sketchup.clear_default_writes
    assert_raises(PhComposer::UserError) do
      Preferences.set("dimension_format", "cm", :scope => "example.one_more", :system => "SI")
    end
    assert_empty Sketchup.instance_variable_get(:@default_writes)
    Preferences.set("dimension_format", "m", :scope => "example.scope_0", :system => "SI")
    assert_equal "m", Preferences.dimension_formats.dig("example.scope_0", "SI"), "a known scope still changes"
  end

  def test_the_regional_format_takes_the_macos_region_and_the_sketchup_decimal
    Sketchup::RegionalSettings.decimal_separator = ","
    Preferences.apple_locale_reader = proc { "de_DE" }
    assert_equal({ "decimal" => ",", "locale" => "de-DE" }, Preferences.snapshot.fetch("number_format"))

    PhComposer::Preferences.reset_for_test
    Preferences.apple_locale_reader = proc { "en_US@rg=chzzzz" }
    assert_equal "en-CH", Preferences.snapshot.dig("number_format", "locale"), "a chosen region replaces the language's"
  end

  def test_the_regional_format_falls_back_to_sketchups_locale_and_is_read_once
    reads = 0
    Sketchup.locale_value = "fr-FR"
    Preferences.apple_locale_reader = proc {
      reads += 1
      raise IOError, "defaults unavailable"
    }

    assert_equal "fr-FR", Preferences.snapshot.dig("number_format", "locale")
    assert_equal "fr-FR", Preferences.snapshot.dig("number_format", "locale")
    assert_equal 1, reads
  end
end
