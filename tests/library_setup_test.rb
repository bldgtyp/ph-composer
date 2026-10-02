# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/library_provider_fixtures"

class LibrarySetupTest < PhComposerTestCase
  include LibraryProviderFixtures
  Setup = PhComposer::Library::Setup

  def test_setup_persists_one_base64_json_machine_value_and_public_projections_have_no_path
    private_path = '/private/synthetic/"catalog".json'
    result = Setup.add_file(:id => "provider.one", :label => "Synthetic provider", :path => private_path)
    stored = Sketchup.read_default(Setup::SECTION, Setup::KEY)
    refute_includes stored, '"'
    assert_equal private_path, JSON.parse(stored.unpack1("m0")).first.fetch("path")
    assert_equal private_path, Setup.load.first.fetch("path")
    refute_includes JSON.generate(result), private_path
    provider = Setup.provider("provider.one", :kinds => adapters.keys, :adapters => adapters.method(:[]))
    refute_includes provider.inspect, private_path
    assert_equal "provider.one", provider.id
    all = Setup.file_providers(:kinds => adapters.keys, :adapters => adapters.method(:[]))
    assert_equal ["provider.one"], all.map(&:id)
    refute_includes all.inspect, private_path
    assert_empty Setup.remove("provider.one")
    assert_empty Sketchup.active_model.operations
  end

  def test_default_store_failures_are_sanitized_and_failed_write_preserves_old_configuration
    Setup.add_file(:id => "provider.one", :label => "Synthetic", :path => "/private/old.json")
    before = Setup.load
    Sketchup.stub(:write_default, ->(*) { raise IOError, "private /Users/secret/defaults" }) do
      error = assert_raises(PhComposer::Library::Error) do
        Setup.add_file(:id => "provider.two", :label => "Other", :path => "/private/new.json")
      end
      assert_equal "library.setup_unavailable", error.code
      refute_includes error.full_message, "/Users/secret"
    end
    assert_equal before, Setup.load
    Sketchup.stub(:read_default, ->(*) { raise IOError, "private /Users/secret/defaults" }) do
      error = assert_raises(PhComposer::Library::Error) { Setup.providers }
      assert_equal "library.setup_unavailable", error.code
      refute_includes error.full_message, "/Users/secret"
    end
  end

  def test_an_unreadable_setup_reads_as_empty_refuses_changes_until_reset_and_is_kept
    stored = "not base64 json"
    Sketchup.write_default(Setup::SECTION, Setup::KEY, stored)
    assert_equal [[], "unreadable"], [Setup.load, Setup.state]
    [-> { Setup.add_file(:id => "provider.one", :label => "Synthetic", :path => "/private/file.json") },
     -> { Setup.remove("provider.one") }].each do |change|
      error = assert_raises(PhComposer::Library::Error) { change.call }
      assert_equal "library.setup_unreadable", error.code
      assert_equal stored, Sketchup.read_default(Setup::SECTION, Setup::KEY)
    end
    assert_empty Setup.reset
    assert_equal "readable", Setup.state
    Setup.add_file(:id => "provider.one", :label => "Synthetic", :path => "/private/file.json")
    assert_equal ["provider.one"], Setup.load.map { |row| row.fetch("id") }
  end

  def test_invalid_or_duplicate_configurations_are_refused
    row = { "id" => "provider.one", "label" => "Synthetic", "path" => "/private/file.json" }
    [nil, [row, row], [row.merge("token" => "must not persist")]].each do |value|
      error = assert_raises(PhComposer::Library::Error) { Setup.save(value) }
      assert_equal "library.setup_invalid", error.code
      refute_includes error.message, "must not persist"
    end
    error = assert_raises(PhComposer::Library::Error) do
      Setup.provider("missing", :kinds => adapters.keys, :adapters => adapters.method(:[]))
    end
    assert_equal "library.provider_unavailable", error.code
  end
end
