# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"

# With the panel closed, a caller holding the operation's grant names a location the user approved
# instead of a path. Dispatch turns it into the same answer a native dialog gives, so the handler is
# unchanged; every way the id can fail refuses before anything is written.
class ApprovedLocationUseTest < PhComposerTestCase
  Locations = PhComposer::ApprovedLocations
  Setup = PhComposer::Library::Setup
  ADD_FOLDER = "ph_composer.library.providers.add_folder"
  ADD_FILE = "ph_composer.library.providers.add_file"

  def setup
    super
    @directory = Dir.mktmpdir("phc-location-use")
    @session = PhComposer::Sessions.for(Sketchup.active_model)
  end

  def teardown
    FileUtils.rm_rf(@directory)
    super
  end

  def add(name, location, grants = %w[read setup])
    context = PhComposer::API.connect(:session_id => @session.id, :capabilities => grants)
    PhComposer::API.setup(:context => context, :name => name, :params => { "location" => location })
  end

  def folder(name)
    File.join(@directory, name).tap { |path| Dir.mkdir(path) }
  end

  def test_a_setup_caller_adds_an_approved_folder_once_with_no_dialog
    id = Locations.approve(:kind => "open_folder", :path => folder("PRIVATE-FOLDER"), :label => "Shared").fetch("id")
    outcome = UI.stub(:select_directory, ->(*) { flunk "A location id must not open a picker." }) do
      add(ADD_FOLDER, { "id" => id })
    end
    assert_equal %w[completed none], outcome.values_at("status", "effect"), outcome.inspect
    assert_equal [["Shared", File.join(@directory, "PRIVATE-FOLDER")]], Setup.load.map { |row|
                                                                          row.values_at("label", "path")
                                                                        }
    refute_includes JSON.generate(outcome), "PRIVATE-FOLDER"
    assert_empty Locations.list
    again = add(ADD_FOLDER, { "id" => id })
    assert_equal %w[refused location.used none], again.values_at("status", "code", "effect")
    assert_equal 1, Setup.load.length
    assert_empty Sketchup.active_model.operations
  end

  def test_every_unusable_location_refuses_before_anything_is_configured
    file = Locations.approve(:kind => "open_file", :path => File.join(@directory, "missing.json")).fetch("id")
    gone = Locations.approve(:kind => "open_folder", :path => File.join(@directory, "gone")).fetch("id")
    revoked = Locations.approve(:kind => "open_folder", :path => folder("revoked")).fetch("id")
    Locations.revoke(revoked)
    usable = Locations.approve(:kind => "open_folder", :path => folder("usable")).fetch("id")
    cases = { "location.kind_mismatch" => [ADD_FOLDER, file], "location.unavailable" => [ADD_FOLDER, gone],
              "location.revoked" => [ADD_FOLDER, revoked], "location.unknown" => [ADD_FILE, "location_AAAAAAAAAAAA"] }
    cases.each do |code, (name, id)|
      assert_equal ["refused", code, "none"], add(name, { "id" => id }).values_at("status", "code", "effect"), code
    end
    assert_equal "request.capability_denied", add(ADD_FOLDER, { "id" => usable }, %w[read]).fetch("code")
    assert_equal "params.invalid", add(ADD_FOLDER, { "id" => usable, "replace" => true }).fetch("code")
    assert_empty Setup.load
    assert_equal [usable], Locations.list.select { |row| row.fetch("available") }.map { |row| row.fetch("id") }
  end

  # An approved location answers only operations that would otherwise ask, and registration adds its
  # param: a feature declaring its own is refused, and an approve command takes none.
  def test_registration_adds_the_location_param_and_refuses_a_feature_that_declares_one
    described = PhComposer::API.describe(:name => ADD_FOLDER)
    assert_equal %w[id], described.dig("params", "properties", "location", "properties").keys
    assert_equal %w[id replace expected_destination],
                 PhComposer::API.describe(:name => "ph_composer.library.export_file")
                                .dig("params", "properties", "location", "properties").keys
    refute PhComposer::API.describe(:name => "ph_composer.locations.approve_folder")
                          .dig("params", "properties").key?("location")
    feature = Object.new
    feature.define_singleton_method(:name) { "TestFiles" }
    feature.define_singleton_method(:install) do |registry|
      approval = PhComposer::Declarations::Approval.new(:kind => "open_folder", :title => "Pick")
      params = { "type" => "object", "additionalProperties" => false,
                 "properties" => { "location" => { "type" => "string", "description" => "A path." } } }
      registry.feature("test.files", :contract_version => 1).setup_command(
        "test.files.pick", :description => "Pick a folder.", :params => params, :refuses => [], :approval => approval,
                           :result => { "type" => "object" }
      ) { |_request| {} }
    end
    error = assert_raises(PhComposer::RegistrationError) { PhComposer::Registry.install([feature]) }
    assert_includes error.message, "params declare location"
  end
end
