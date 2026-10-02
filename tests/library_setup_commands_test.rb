# frozen_string_literal: true

require "minitest/mock"
require_relative "test_helper"
require_relative "support/library_provider_fixtures"
require_relative "../src/ph_composer/library/setup_commands"

class LibrarySetupCommandsTest < PhComposerTestCase
  include LibraryProviderFixtures
  Commands = PhComposer::Library::SetupCommands
  Setup = PhComposer::Library::Setup

  # Adding a library needs the user to pick it, so a scripted caller is refused at once and no picker
  # opens; through the native path a dismissed picker changes nothing.
  def test_scripted_add_is_refused_native_cancel_is_readonly_and_setup_menus_are_extensions_only
    session = PhComposer::Sessions.for(Sketchup.active_model)
    context = PhComposer::API.connect(:session_id => session.id, :capabilities => %w[read setup])
    revision = session.revision
    %w[add_file add_folder].each do |verb|
      name = "#{Commands::PREFIX}.#{verb}"
      UI.stub(:openpanel, ->(*) { flunk "A scripted add must not open a picker." }) do
        UI.stub(:select_directory, ->(*) { flunk "A scripted add must not open a picker." }) do
          outcome = PhComposer::API.setup(:context => context, :name => name, :params => {})
          assert_equal %w[refused access.user_required none], outcome.values_at("status", "code", "effect")
        end
      end
      UI.stub(:openpanel, nil) do
        UI.stub(:select_directory, nil) do
          assert_equal "cancelled", PhComposer::NativeApproval.setup(context, name, {}).fetch("status")
        end
      end
    end
    assert_empty Setup.load
    assert_equal revision, session.revision
    assert_empty Sketchup.active_model.operations
    menus = PhComposer::Registry.current.menu_items.values.select { |item| item.name.start_with?(Commands::PREFIX) }
    assert_equal 2, menus.length
    assert(menus.none? do |item|
      item.available.call(PhComposer::HandlerRequest.for(session, :owner => item.owner, :name => item.name))
    end)
    refute_empty PhComposer::Commands.install_feature_menus(UI.menu("Extensions"))
    refute PhComposer::Commands.install_feature_menus(UI.menu("Context"), :contextual => true).key?("Libraries")
  end

  # Removing a library changes this machine's configuration, which neither the viewport-state `view`
  # grant nor the default grant covers; only an explicit `setup` grant does.
  def test_only_a_setup_grant_changes_library_configuration
    Setup.add_file(:id => "synthetic", :label => "Synthetic library", :path => "/nowhere/library.json")
    session = PhComposer::Sessions.for(Sketchup.active_model)
    remove = lambda do |capabilities|
      context = capabilities ? PhComposer::API.connect(:session_id => session.id, :capabilities => capabilities)
                             : PhComposer::API.connect(:session_id => session.id)
      PhComposer::API.setup(:context => context, :name => "#{Commands::PREFIX}.remove",
                            :params => { "provider_id" => "synthetic" })
    end
    [["view"], nil].each do |capabilities|
      assert_equal "request.capability_denied", remove.call(capabilities).fetch("code")
      assert_equal ["synthetic"], Setup.load.map { |provider| provider.fetch("id") }
    end
    assert_equal "setup_command", PhComposer::API.describe(:name => "#{Commands::PREFIX}.remove").fetch("kind")
    assert_equal "completed", remove.call(%w[setup]).fetch("status")
    assert_empty Setup.load
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

  def test_invalid_file_leaves_configuration_unchanged_without_private_error
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
