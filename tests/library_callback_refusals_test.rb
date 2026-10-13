# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/library_provider_fixtures"
require_relative "../tools/api_reference/api_reference"

class LibraryCallbackRefusalsTest < PhComposerTestCase
  include LibraryProviderFixtures

  API = PhComposer::API
  D = PhComposer::Declarations
  KIND = "probe.widget.record"
  OBJECT = { "type" => "object" }.freeze
  CODES = { :local_read => "widget.read_blocked", :create => "widget.create_blocked",
            :replace => "widget.replace_blocked", :assign => "widget.assign_blocked" }.freeze

  def setup
    super
    PhComposer::Registry.reset
    PhComposer::Registry.install(PhComposer::FOUNDATION_FEATURES)
    @before_description = API.describe(:name => "ph_composer.library.copy")
    @blocked = nil
    @sequence = 0
    @kind = PhComposer::Records::RecordKind.new(
      :id => KIND, :label => "Widget", :schema_version => 1,
      :id_prefix => "wid", :fields => PhComposer::Records::AuthoringFields.common
    )
    @adapter = widget_adapter
    install_widget
    @directory = Dir.mktmpdir("callback-refusals")
    value = envelope([], :kinds => { "widgets" => [{ "id" => "one", "name" => "Synthetic Widget" }] })
    value["kind_schema_versions"] = { "widgets" => 1 }
    path = write_library(File.join(@directory, "synthetic.json"), value)
    PhComposer::Library::Setup.add_file(:id => "synthetic.file", :label => "Synthetic", :path => path)
    @session = PhComposer::Sessions.for(Sketchup.active_model)
    @context = API.connect(:session_id => @session.id, :capabilities => %w[read model_write setup])
    loaded = API.setup(:context => @context, :name => "ph_composer.library.load",
                       :params => { "provider_id" => "synthetic.file", "kind" => "widgets" })
    assert_equal "completed", loaded["status"], loaded.inspect
    @selected = { "provider_id" => "synthetic.file", "kind" => "widgets",
                  "generation" => loaded.dig("value", "generation") }
  end

  def teardown
    FileUtils.rm_rf(@directory) if @directory
    super
  end

  def install_widget
    kind = @kind
    adapter = @adapter
    feature = Module.new
    feature.define_singleton_method(:install) do |registry|
      scope = registry.feature("probe.widget", :contract_version => 1)
      scope.record_kind(kind)
      CODES.each_value { |code| scope.code(code, :description => "Synthetic Widget callback refusal.") }
      scope.library_kind("probe.widget.wire", :contract_version => 1, :record_kind => KIND, :adapter => adapter)
    end
    PhComposer::Registry.install([feature])
  end

  def callback(part, result = OBJECT, &handler)
    D::LibraryCallback.new(:params => OBJECT, :result => result, :refuses => [CODES.fetch(part)], :handler => handler)
  end

  def refuse(part)
    raise PhComposer::CodedError.new(CODES.fetch(part), "Synthetic callback refused.") if @blocked == part
  end

  def widget_adapter
    shape = { "type" => "object", "properties" => { "name" => { "type" => "string" } }, "required" => ["name"] }
    D::LibraryAdapter.new(
      :wire_kind => "widgets", :wire_version => 1, :fingerprint_version => 1,
      :wire_schema => shape.merge("properties" => shape["properties"].merge("id" => { "type" => "string" }),
                                  "required" => %w[id name]),
      :display_label => ->(mapped) { mapped.fetch("name") },
      :mapped_schema => shape, :fingerprint_fields => ["name"], :map => ->(row) { row.slice("name") },
      :reverse => ->(row) { row.slice("id", "name") },
      :fingerprint => ->(row) { PhComposer::CanonicalJson.digest(row.slice("name")) },
      :local_read => callback(:local_read, { "type" => "array", "items" => OBJECT }) do |request, _proposal|
        refuse(:local_read)
        request.engine.ids(KIND).map do |id|
          record = request.engine.find(KIND, id)
          { "id" => id, "mapped" => record.slice("name"), "expected_values" => record.slice("name"),
            "source" => record["source"] }
        end
      end,
      :create => callback(:create) do |request, proposal|
        id = request.engine.propose_create(KIND, proposal, :values => request.params.fetch("values"))
        refuse(:create)
        { "id" => id }
      end,
      :replace => callback(:replace) do |request, proposal|
        id = request.params.fetch("id")
        request.engine.propose_update(KIND, id, proposal, :values => request.params.fetch("values"),
                                                          :expected_values => request.params.fetch("expected_values"))
        refuse(:replace)
        { "id" => id }
      end,
      :assign => callback(:assign) do |_request, _proposal|
        refuse(:assign)
        { "assigned" => true }
      end
    )
  end

  def copy(choice = "create", **extra)
    @sequence += 1
    API.invoke(:context => @context, :name => "ph_composer.library.copy",
               :params => @selected.merge("library_id" => "synthetic.one", "record_id" => "one",
                                          "choice" => choice).merge(extra.transform_keys(&:to_s)),
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end

  def inventory
    API.query(:context => @context, :name => "ph_composer.records.list", :params => { "kind" => KIND })
       .dig("value", "records")
  end

  def test_outside_read_refusal_is_described_and_audited_for_copy_and_in_file_without_windows
    refute PhComposer::Registry.installed?("ph_composer.windows")
    @blocked = :local_read
    in_file = API.query(:context => @context, :name => "ph_composer.library.in_file", :params => @selected)
    [copy, in_file].each do |outcome|
      assert_equal CODES[:local_read], outcome["code"], outcome.inspect
      assert_equal "none", outcome["effect"]
    end
    %w[copy in_file].each do |operation|
      codes = API.describe(:name => "ph_composer.library.#{operation}").fetch("refuses")
      assert_includes codes, { "code" => CODES[:local_read], "owner" => "probe.widget",
                               "description" => "Synthetic Widget callback refusal." }
    end
    assert_empty inventory
  end

  def test_discovery_projects_only_the_installed_callbacks_each_operation_calls
    assert_empty @before_description.fetch("refuses").map { |item| item["code"] } & CODES.values
    %w[geometry.invalid target.wrong_zone].each do |code|
      refute_includes @before_description.fetch("refuses").map { |item| item["code"] }, code
    end
    copy_codes = API.describe(:name => "ph_composer.library.copy").fetch("refuses").map { |item| item["code"] }
    assert_equal CODES.values.sort, (copy_codes & CODES.values).sort
    read_codes = API.describe(:name => "ph_composer.library.in_file").fetch("refuses").map { |item| item["code"] }
    assert_equal [CODES[:local_read]], read_codes & CODES.values
    catalog_codes = API.describe(:name => "ph_composer.library.catalog").fetch("refuses").map { |item| item["code"] }
    assert_empty catalog_codes & CODES.values
  end

  def test_create_and_assignment_refusals_discard_staged_creates_without_revision_or_undo
    %i[create assign].each do |part|
      @blocked = part
      revision = @session.revision
      operations = Sketchup.active_model.operations.dup
      outcome = copy("create", :assignment => {})
      assert_equal CODES[part], outcome["code"], outcome.inspect
      assert_equal "none", outcome["effect"]
      assert_empty inventory
      assert_equal revision, @session.revision
      assert_equal operations, Sketchup.active_model.operations
    end
  end

  def test_generated_refusal_list_uses_its_supplied_composition
    outside_registry = PhComposer::Registry.current
    declaration = outside_registry.actions.fetch("ph_composer.library.copy")
    PhComposer::Registry.reset
    PhComposer::Registry.install(PhComposer::FOUNDATION_FEATURES)
    generated = PhComposerTools::ApiReference.refuses_line(declaration, outside_registry)
    CODES.each_value { |code| assert_includes generated, "`#{code}`" }
    foundation = PhComposerTools::ApiReference.refuses_line(declaration, PhComposer::Registry.current)
    CODES.each_value { |code| refute_includes foundation, "`#{code}`" }
  end

  def test_replace_refusal_discards_staged_update_and_keeps_existing_record
    created = copy
    assert_equal "completed", created["status"], created.inspect
    id = created.dig("value", "local_id")
    before = inventory
    revision = @session.revision
    operations = Sketchup.active_model.operations.dup
    @blocked = :replace
    outcome = copy("use_library", :local_id => id, :expected_values => { "name" => "Synthetic Widget" })
    assert_equal CODES[:replace], outcome["code"], outcome.inspect
    assert_equal "none", outcome["effect"]
    assert_equal before, inventory
    assert_equal revision, @session.revision
    assert_equal operations, Sketchup.active_model.operations
  end
end
