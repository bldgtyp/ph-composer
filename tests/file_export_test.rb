# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"

class FileExportTest < PhComposerTestCase
  API = PhComposer::API
  NAME = "test.files.save"
  SHAPE = { "type" => "object", "additionalProperties" => false, "required" => ["written"],
            "properties" => { "written" => { "type" => "boolean" } } }.freeze

  def feature(handler = ->(_request) { { "written" => true } },
              params: { "type" => "object", "properties" => {}, "additionalProperties" => false }, result: SHAPE,
              approval: nil)
    Object.new.tap do |item|
      item.define_singleton_method(:name) { "TestFiles" }
      item.define_singleton_method(:install) do |registry|
        registry.feature("test.files", :contract_version => 1).file_export(
          NAME, :description => "Write a synthetic file without changing the Model.", :params => params,
                :result => result, :examples => [{}], :refuses => [], :approval => approval, &handler
        )
      end
    end
  end

  def context(grants = %w[read export])
    API.connect(:session_id => PhComposer::Sessions.for(Sketchup.active_model).id, :capabilities => grants)
  end

  def test_registration_discovery_and_detached_frozen_schemas
    PhComposer::Registry.install([feature])
    assert_equal NAME, API.discover.fetch("file_exports").last.fetch("name")
    described = API.describe(:name => NAME)
    assert_equal "file_export", described["kind"]
    described.fetch("result").fetch("properties").clear
    assert_equal ["written"], API.describe(:name => NAME).dig("result", "properties").keys
    assert PhComposer::Registry.current.file_exports.fetch(NAME).frozen?
    assert PhComposer::Registry.current.file_exports.fetch(NAME).result.frozen?
    assert_equal "test.files", PhComposer::Registry.current.owner_of(NAME)
  end

  def test_export_grant_validation_and_no_model_operation_or_revision_change
    PhComposer::Registry.install([feature])
    model = Sketchup.active_model
    session = PhComposer::Sessions.for(model)
    before = [model.operations.length, session.revision, model.modified?]
    denied = API.export_file(:context => context(%w[read view model_write]), :name => NAME)
    assert_equal "request.capability_denied", denied["code"]
    result = API.export_file(:context => context, :name => NAME)
    assert_equal %w[completed ok none], result.values_at("status", "code", "effect")
    assert_equal({ "written" => true }, result["value"])
    assert_equal before, [model.operations.length, session.revision, model.modified?]
    assert_equal "request.unknown_operation", API.query(:context => context, :name => NAME)["code"]
  end

  # A declared approval is the shell's to obtain: the public API never carries one, so a scripted call
  # is refused before the handler runs, and the native path hands the handler the user's answer.
  def test_a_declared_approval_reaches_the_handler_only_from_the_native_path
    seen = []
    handler = lambda do |request|
      seen << request.approval.path
      { "written" => true }
    end
    approval = PhComposer::Declarations::Approval.new(:kind => "save_file", :title => "Save synthetic",
                                                      :default_name => "synthetic.json")
    PhComposer::Registry.install([feature(handler, :approval => approval)])
    assert_equal "access.user_required", API.export_file(:context => context, :name => NAME)["code"]
    assert_empty seen
    UI.stub(:savepanel, "/chosen/synthetic.json") do
      result = PhComposer::NativeApproval.file_export(context, NAME, {})
      assert_equal %w[completed ok none], result.values_at("status", "code", "effect")
    end
    assert_equal ["/chosen/synthetic.json"], seen
    UI.stub(:savepanel, nil) do
      assert_equal "cancelled", PhComposer::NativeApproval.file_export(context, NAME, {})["status"]
    end
    assert_equal 1, seen.length
    assert_empty Sketchup.active_model.operations
  end

  # The macOS Save sheet already asked about the file it names, so replacing it asks nothing more.
  def test_replacing_the_chosen_file_asks_nothing_more_on_macos_and_once_elsewhere
    approval = PhComposer::Declarations::Approval.new(:kind => "save_file", :title => "Save synthetic",
                                                      :default_name => "synthetic.json")
    seen = []
    PhComposer::Registry.install([feature(lambda { |request|
      seen << request.approval.replace
      { "written" => true }
    }, :approval => approval)])
    Dir.mktmpdir("phc-replace") do |directory|
      UI.selected_save_path = File.join(directory, "synthetic.json")
      File.write(File.join(directory, "synthetic.json"), "prior")
      assert_equal "completed", PhComposer::NativeApproval.file_export(context, NAME, {})["status"]
      assert_equal [[], [true]], [UI.messages.to_a, seen]
      Sketchup.platform_value = :platform_win
      assert_equal "completed", PhComposer::NativeApproval.file_export(context, NAME, {})["status"]
      assert_equal [["Replace the existing file?"], [true, true]], [UI.messages, seen]
    end
  end

  def test_a_busy_session_or_invalid_params_refuse_before_the_native_dialog_opens
    approval = PhComposer::Declarations::Approval.new(:kind => "save_file", :title => "Save synthetic",
                                                      :default_name => "synthetic.json")
    PhComposer::Registry.install([feature(->(_request) { flunk "The handler must not run." }, :approval => approval)])
    UI.stub(:savepanel, ->(*) { flunk "A refused export must not open the save dialog." }) do
      assert_equal "params.invalid", PhComposer::NativeApproval.file_export(context, NAME, { "extra" => 1 })["code"]
      PhComposer::Sessions.for(Sketchup.active_model).exclusive do
        result = PhComposer::NativeApproval.file_export(context, NAME, {})
        assert_equal %w[busy session.busy], result.values_at("status", "code")
      end
    end
  end

  # A stale library export refuses before the user is asked for a destination, and a direct call with
  # the same params is refused by the same declared precondition.
  def test_a_declared_precondition_refuses_before_the_save_dialog_and_on_direct_dispatch
    session = PhComposer::Sessions.for(Sketchup.active_model)
    name = "ph_composer.library.export_file"
    stale = { "expected_revision" => session.revision + 1 }
    UI.stub(:savepanel, ->(*) { flunk "A stale export must not open the save dialog." }) do
      assert_equal "revision.stale", PhComposer::NativeApproval.file_export(context, name, stale)["code"]
    end
    granted = PhComposer::NativeApproval::Granted.new(:path => "/never/written.json", :replace => false)
    direct = PhComposer::Dispatch.new.file_export(context, name, stale, :approval => granted)
    assert_equal %w[refused revision.stale none], direct.values_at("status", "code", "effect")
  end

  def test_a_precondition_that_cannot_be_called_is_refused_at_registration
    item = feature
    item.define_singleton_method(:install) do |registry|
      closed = { "type" => "object", "properties" => {}, "additionalProperties" => false }
      registry.feature("test.files", :contract_version => 1).file_export(
        NAME, :description => "Write a synthetic file.", :params => closed, :result => SHAPE, :refuses => [],
              :precondition => "stale?"
      ) { |_request| { "written" => true } }
    end
    error = assert_raises(PhComposer::RegistrationError) { PhComposer::Registry.install([item]) }
    assert_includes error.message, "precondition must be callable"
  end

  def test_an_approval_of_an_unknown_kind_is_refused_at_registration
    approval = PhComposer::Declarations::Approval.new(:kind => "print", :title => "Print")
    error = assert_raises(PhComposer::RegistrationError) do
      PhComposer::Registry.install([feature(:approval => approval)])
    end
    assert_includes error.message, "approval must be"
  end

  def test_invalid_params_results_busy_and_closed_session_refuse_without_calling_handler
    called = 0
    handler = lambda do |_request|
      called += 1
      { "written" => "wrong type" }
    end
    PhComposer::Registry.install([feature(handler)])
    connected = context
    assert_equal "params.invalid", API.export_file(:context => connected, :name => NAME,
                                                   :params => { "destination" => "/PRIVATE/path" })["code"]
    assert_equal 0, called
    assert_equal "operation.failed", API.export_file(:context => connected, :name => NAME)["code"]
    assert_equal 1, called
    session = PhComposer::Sessions.for(Sketchup.active_model)
    session.exclusive do
      assert_equal "session.busy", API.export_file(:context => connected, :name => NAME)["code"]
    end
    assert_equal 1, called
    Sketchup.active_model.close
    assert_equal "session.unknown", API.export_file(:context => connected, :name => NAME)["code"]
    assert_equal 1, called
  end

  def test_open_result_schema_and_cross_capability_name_collision_refuse_the_entire_batch
    open_result = { "type" => "object", "properties" => { "written" => { "type" => "boolean" } } }
    assert_raises(PhComposer::RegistrationError) { PhComposer::Registry.install([feature(:result => open_result)]) }
    refute PhComposer::Registry.current.file_exports.key?(NAME)
    collision = feature
    original_install = collision.method(:install)
    collision.define_singleton_method(:install) do |registry|
      original_install.call(registry)
      registry.feature("test.other", :contract_version => 1).query(NAME,
                                                                   :description => "Colliding capability name.",
                                                                   :params => { "type" => "object" },
                                                                   :result => { "type" => "object" },
                                                                   :refuses => []) { {} }
    end
    error = assert_raises(PhComposer::RegistrationError) { PhComposer::Registry.install([collision]) }
    assert_includes error.diagnostics.map(&:code), "registration.duplicate_id"
    refute PhComposer::Registry.current.file_exports.key?(NAME)
    refute PhComposer::Registry.current.queries.key?(NAME)
  end

  def test_bad_batch_is_atomic_and_duplicate_names_share_existing_namespace
    bad = feature(->(_request) { {} }, :params => { "type" => "string" })
    error = assert_raises(PhComposer::RegistrationError) { PhComposer::Registry.install([bad]) }
    assert_includes error.diagnostics.map(&:code), "registration.schema_invalid"
    refute PhComposer::Registry.current.file_exports.key?(NAME)
    assert_raises(PhComposer::RegistrationError) { PhComposer::Registry.install([feature, feature]) }
    refute PhComposer::Registry.current.file_exports.key?(NAME)
  end
end
