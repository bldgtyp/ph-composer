# frozen_string_literal: true

require_relative "test_helper"

class FileExportTest < PhComposerTestCase
  API = PhComposer::API
  NAME = "test.files.save"
  SHAPE = { "type" => "object", "additionalProperties" => false, "required" => ["written"],
            "properties" => { "written" => { "type" => "boolean" } } }.freeze

  def feature(handler = ->(_request) { { "written" => true } },
              params: { "type" => "object", "properties" => {}, "additionalProperties" => false }, result: SHAPE)
    Object.new.tap do |item|
      item.define_singleton_method(:name) { "TestFiles" }
      item.define_singleton_method(:install) do |registry|
        registry.feature("test.files", :contract_version => 1).file_export(NAME,
          :description => "Write a synthetic file without changing the Model.", :params => params,
          :result => result, :examples => [{}], &handler)
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

  def test_cancel_and_invalid_result_are_safe_and_never_open_undo
    handler = ->(_request) { raise PhComposer::Declarations::FileExportCancelled }
    PhComposer::Registry.install([feature(handler)])
    result = API.export_file(:context => context, :name => NAME)
    assert_equal %w[cancelled export.cancelled none], result.values_at("status", "code", "effect")
    assert_nil result["value"]
    assert_empty Sketchup.active_model.operations
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
        :description => "Colliding capability name.", :params => { "type" => "object" },
        :result => { "type" => "object" }) { {} }
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
