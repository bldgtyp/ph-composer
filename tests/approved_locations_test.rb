# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"

# A location the user approved once is kept on this machine behind an opaque id; no public read ever
# carries its path or file name, and approving it needs the native dialog.
class ApprovedLocationsTest < PhComposerTestCase
  Locations = PhComposer::ApprovedLocations
  PREFIX = PhComposer::LocationCommands::PREFIX

  def setup
    super
    @directory = Dir.mktmpdir("phc-locations")
    @session = PhComposer::Sessions.for(Sketchup.active_model)
  end

  def teardown
    FileUtils.rm_rf(@directory)
    super
  end

  def context(grants = %w[read setup])
    PhComposer::API.connect(:session_id => @session.id, :capabilities => grants)
  end

  def listed
    PhComposer::API.query(:context => context, :name => "#{PREFIX}.list").fetch("value")
  end

  def test_an_approval_round_trips_and_resolves_only_for_its_kind
    path = File.join(@directory, "export-target.json")
    row = Locations.approve(:kind => "save_file", :path => path)
    assert_equal ["Export destination 1", "reusable", true, nil],
                 row.values_at("label", "use", "available", "last_used_at")
    assert_equal path, Locations.resolve(row.fetch("id"), :kind => "save_file")
    error = assert_raises(PhComposer::CodedError) { Locations.resolve(row.fetch("id"), :kind => "open_folder") }
    assert_equal "location.kind_mismatch", error.code
    assert_equal [row], listed.fetch("locations")
    Locations.mark_used(row.fetch("id"))
    refute_nil Locations.list.first.fetch("last_used_at")
    first = Locations.approve(:kind => "open_folder", :path => @directory)
    second = Locations.approve(:kind => "open_folder", :path => @directory)
    Locations.revoke(first.fetch("id"))
    third = Locations.approve(:kind => "open_folder", :path => @directory)
    assert_equal ["Library folder 1", "Library folder 2", "Library folder 3"],
                 [first, second, third].map { |item| item.fetch("label") }
  end

  # The distinctive fixture name stands in for a client's: neither it nor any part of the path may leave.
  def test_no_public_read_or_refusal_carries_the_path_or_file_name
    path = File.join(@directory, "PRIVATE-CLIENT-NAME.json")
    File.write(path, "{}")
    row = Locations.approve(:kind => "open_file", :path => path, :label => "Project library")
    rename = PhComposer::API.setup(:context => context, :name => "#{PREFIX}.rename",
                                   :params => { "id" => row.fetch("id"), "label" => "Renamed" })
    File.delete(path)
    unavailable = assert_raises(PhComposer::CodedError) { Locations.resolve(row.fetch("id"), :kind => "open_file") }
    assert_equal "location.unavailable", unavailable.code
    public = JSON.generate([listed, rename, unavailable.message, PhComposer::API.discover])
    ["PRIVATE-CLIENT-NAME", @directory].each { |secret| refute_includes public, secret }
    assert_equal ["Renamed", false], listed.fetch("locations").first.values_at("label", "available")
  end

  # Approving needs the user. A scripted call is refused before any dialog; through the native path the
  # answer is stored, and replacing nothing asks nothing even where a replacement question is asked.
  def test_approving_needs_the_native_dialog_and_asks_no_replacement_question
    Sketchup.platform_value = :platform_win
    name = "#{PREFIX}.approve_destination"
    UI.stub(:savepanel, ->(*) { flunk "A scripted approval must not open a dialog." }) do
      outcome = PhComposer::API.setup(:context => context, :name => name, :params => {})
      assert_equal %w[refused access.user_required none], outcome.values_at("status", "code", "effect")
    end
    existing = File.join(@directory, "existing.json")
    File.write(existing, "prior")
    UI.selected_save_path = existing
    outcome = PhComposer::NativeApproval.setup(context, name, { "label" => "Library export" })
    assert_equal "completed", outcome.fetch("status"), outcome.inspect
    assert_equal [[], "Library export"], [UI.messages.to_a, outcome.dig("value", "label")]
    assert_equal "prior", File.read(existing)
    assert_equal [@session.revision, []], [@session.revision, Sketchup.active_model.operations.to_a]
  end

  # The Libraries menu approves through the same native dialog and names what it approved; a dismissed
  # dialog says nothing, and the items stay off the viewport context menu.
  def test_the_libraries_menu_approves_and_names_the_location
    menu = PhComposer::Registry.current.menu_items.fetch("#{PREFIX}.approve_folder_menu")
    notices = []
    @session.stub(:notice, ->(message, tone:) { notices << [message, tone] }) do
      UI.stub(:select_directory, @directory) { menu.handler.call(@session) }
      UI.stub(:select_directory, nil) { menu.handler.call(@session) }
    end
    assert_equal [["Approved Library folder 1. An agent can now use it by id.", :info]], notices
    refute menu.available.call(@session)
    assert_equal "Libraries", menu.menu
  end

  # A revoked id says so rather than reading as unknown, and the tombstones it leaves are bounded.
  def test_revoke_leaves_a_bounded_tombstone
    first = Locations.approve(:kind => "open_folder", :path => @directory).fetch("id")
    revoke = lambda do |id|
      PhComposer::API.setup(:context => context, :name => "#{PREFIX}.revoke", :params => { "id" => id })
    end
    assert_equal [], revoke.call(first).fetch("value")
    assert_equal "location.revoked", revoke.call(first).fetch("code")
    assert_equal "location.unknown", revoke.call("location_AAAAAAAAAAAA").fetch("code")
    Locations::TOMBSTONES.times do
      Locations.revoke(Locations.approve(:kind => "open_folder", :path => @directory).fetch("id"))
    end
    error = assert_raises(PhComposer::CodedError) { Locations.resolve(first, :kind => "open_folder") }
    assert_equal "location.unknown", error.code
  end

  # An unreadable store is reported, never silently replaced: approving refuses until reset clears it.
  def test_an_unreadable_store_refuses_changes_until_reset
    Sketchup.write_default(Locations::SECTION, Locations::KEY, "not base64 json")
    assert_equal({ "state" => "unreadable", "locations" => [] }, listed)
    error = assert_raises(PhComposer::CodedError) { Locations.approve(:kind => "open_folder", :path => @directory) }
    assert_equal "location.setup_unreadable", error.code
    assert_equal "not base64 json", Sketchup.read_default(Locations::SECTION, Locations::KEY)
    reset = PhComposer::API.setup(:context => context, :name => "#{PREFIX}.reset", :params => {})
    assert_equal [[], "readable"], [reset.fetch("value"), listed.fetch("state")]
  end
end
