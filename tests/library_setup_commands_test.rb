# frozen_string_literal: true

require "minitest/mock"
require_relative "test_helper"
require_relative "support/library_provider_fixtures"
require_relative "../src/ph_composer/library/setup_commands"

class LibrarySetupCommandsTest < PhComposerTestCase
  include LibraryProviderFixtures
  Commands = PhComposer::Library::SetupCommands
  Setup = PhComposer::Library::Setup

  def test_public_native_picker_cancel_is_readonly_and_setup_menus_are_extensions_only
    session = PhComposer::Sessions.for(Sketchup.active_model)
    context = PhComposer::API.connect(:session_id => session.id)
    revision = session.revision
    UI.stub(:openpanel, nil) do
      outcome = PhComposer::API.view(:context => context,
                                    :name => "ph_composer.library.providers.add_file", :params => {})
      assert_equal "completed", outcome.fetch("status")
      assert_empty outcome.fetch("value")
    end
    assert_equal revision, session.revision
    assert_empty Sketchup.active_model.operations
    menus = PhComposer::Registry.current.menu_items.values.select { |item| item.name.start_with?(Commands::PREFIX) }
    assert_equal 2, menus.length
    assert menus.all? { |item| !item.available.call(session) }
    refute_empty PhComposer::Commands.install_feature_menus(UI.menu("Extensions"))
    refute PhComposer::Commands.install_feature_menus(UI.menu("Context"), :contextual => true).key?("Libraries")
  end

  def test_add_file_uses_envelope_label_and_keeps_path_out_of_public_result
    Dir.mktmpdir do |folder|
      path = write_library(File.join(folder, "private-address.json"))
      value = Commands.add_path(path, :adapters => adapters.method(:[]), :kinds => adapters.keys)
      assert_equal "Synthetic library", value.first.fetch("label")
      assert_equal path, Setup.load.first.fetch("path")
      refute_includes JSON.generate(value), path
      assert_empty Sketchup.active_model.operations
    end
  end

  def test_folder_accepts_unrelated_malformed_file_and_uses_folder_label_for_many_candidates
    Dir.mktmpdir do |folder|
      write_library(File.join(folder, "one.json"))
      File.write(File.join(folder, "unrelated.json"), "not a library")
      result = Commands.add_path(folder, :adapters => adapters.method(:[]), :kinds => adapters.keys)
      assert_equal File.basename(folder), result.first.fetch("label")
      assert_empty Sketchup.active_model.operations
    end
  end

  def test_cancel_and_invalid_file_leave_configuration_unchanged_without_private_error
    assert_empty Commands.add_path(nil, :adapters => adapters.method(:[]), :kinds => adapters.keys)
    Dir.mktmpdir do |folder|
      path = File.join(folder, "private-name.json")
      File.write(path, "not a library")
      error = assert_raises(PhComposer::Library::Error) do
        Commands.add_path(path, :adapters => adapters.method(:[]), :kinds => adapters.keys)
      end
      refute_includes error.full_message, path
      assert_empty Setup.load
    end
  end
end
