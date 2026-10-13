# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/library_provider_fixtures"

# A library kind whose authored vocabulary has no `name`: its adapter declares the label instead.
class LibraryLabelTest < PhComposerTestCase
  include LibraryProviderFixtures

  API = PhComposer::API
  D = PhComposer::Declarations
  KIND = "probe.tag.record"
  OBJECT = { "type" => "object" }.freeze
  DESIGNATION = { "type" => %w[string null] }.freeze

  def setup
    super
    PhComposer::Registry.reset
    PhComposer::Registry.install(PhComposer::FOUNDATION_FEATURES)
    @directory = Dir.mktmpdir("library-label")
    @sequence = 0
  end

  def teardown
    FileUtils.rm_rf(@directory) if @directory
    super
  end

  def callback(result = OBJECT, &handler)
    D::LibraryCallback.new(:params => OBJECT, :result => result, :refuses => [], :handler => handler)
  end

  def tag_adapter(label: ->(mapped) { mapped["designation"] })
    mapped = { "type" => "object", "properties" => { "designation" => DESIGNATION } }
    wire = { "type" => "object", "required" => ["id"],
             "properties" => { "id" => { "type" => "string" }, "designation" => DESIGNATION } }
    D::LibraryAdapter.new(
      :wire_kind => "tags", :wire_version => 1, :fingerprint_version => 1, :wire_schema => wire,
      :display_label => label, :mapped_schema => mapped, :fingerprint_fields => ["designation"],
      :map => ->(row) { row.slice("designation") }, :reverse => ->(row) { row.slice("id", "designation") },
      :fingerprint => ->(row) { PhComposer::CanonicalJson.digest(row.slice("designation")) },
      :local_read => callback({ "type" => "array", "items" => OBJECT }) do |request, _proposal|
        request.engine.ids(KIND).map do |id|
          record = request.engine.find(KIND, id)
          { "id" => id, "mapped" => record.slice("designation"), "expected_values" => record.slice("designation"),
            "source" => record["source"] }
        end
      end,
      :create => callback do |request, proposal|
        { "id" => request.engine.propose_create(KIND, proposal, :values => request.params.fetch("values")) }
      end,
      :replace => callback do |request, proposal|
        id = request.params.fetch("id")
        request.engine.propose_update(KIND, id, proposal, :values => request.params.fetch("values"),
                                                          :expected_values => request.params.fetch("expected_values"))
        { "id" => id }
      end
    )
  end

  def tag_feature(adapter = tag_adapter)
    kind = PhComposer::Records::RecordKind.new(
      :id => KIND, :label => "Tag", :schema_version => 1, :id_prefix => "tag",
      :fields => [PhComposer::Records::AuthoringFields.field("designation", DESIGNATION),
                  PhComposer::Records::AuthoringFields.field("source",
                                                             PhComposer::Records::AuthoringFields.source_schema)]
    )
    Module.new do
      define_singleton_method(:name) { "TagProbe" }
      define_singleton_method(:install) do |registry|
        scope = registry.feature("probe.tag", :contract_version => 1)
        scope.record_kind(kind)
        scope.library_kind("probe.tag.wire", :contract_version => 1, :record_kind => KIND, :adapter => adapter)
      end
    end
  end

  def tag_row(id, designation = :absent)
    designation == :absent ? { "id" => id } : { "id" => id, "designation" => designation }
  end

  def admit(adapter, rows)
    batch = PhComposer::Library::Provider::Batch.new(
      :rows => rows.map do |snapshot|
        { "library_id" => "synthetic.one", "library_name" => "Synthetic", "record_id" => snapshot.fetch("id"),
          "wire_schema_version" => 1, "snapshot" => snapshot }
      end, :warnings => [], :unavailable => [], :freshness => {}
    )
    PhComposer::Library::Admission.call(batch, :kind => "tags", :adapter => adapter)
  end

  def load_tags(rows, file: "tags.json")
    value = envelope([], :kinds => { "tags" => rows })
    value["kind_schema_versions"] = { "tags" => 1 }
    path = write_library(File.join(@directory, file), value)
    PhComposer::Library::Setup.add_file(:id => "synthetic.file", :label => "Synthetic", :path => path)
    @session = PhComposer::Sessions.for(Sketchup.active_model)
    @context = API.connect(:session_id => @session.id, :capabilities => %w[read model_write setup])
    loaded = API.setup(:context => @context, :name => "ph_composer.library.load",
                       :params => { "provider_id" => "synthetic.file", "kind" => "tags" })
    assert_equal "completed", loaded["status"], loaded.inspect
    @selected = { "provider_id" => "synthetic.file", "kind" => "tags",
                  "generation" => loaded.dig("value", "generation") }
  end

  def in_file
    API.query(:context => @context, :name => "ph_composer.library.in_file", :params => @selected)
  end

  def copy(record_id, choice = "create", **extra)
    @sequence += 1
    API.invoke(:context => @context, :name => "ph_composer.library.copy",
               :params => @selected.merge("library_id" => "synthetic.one", "record_id" => record_id,
                                          "choice" => choice).merge(extra.transform_keys(&:to_s)),
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end

  def test_name_free_kind_registers_and_built_in_kinds_are_unaffected
    PhComposer::Registry.install([tag_feature])
    assert PhComposer::Registry.installed?("probe.tag")
    assert_equal "tags", PhComposer::Registry.current.library_kinds.fetch("probe.tag.wire").adapter.wire_kind
  end

  def test_missing_label_or_wire_id_refuses_naming_the_adapter
    without_label = tag_adapter.tap { |adapter| adapter.display_label = nil }
    without_id = tag_adapter.tap do |adapter|
      adapter.wire_schema = adapter.wire_schema.merge("required" => [])
    end
    [without_label, without_id].each do |adapter|
      error = assert_raises(PhComposer::RegistrationError) { PhComposer::Registry.install([tag_feature(adapter)]) }
      diagnostic = error.diagnostics.find { |item| item.code == "registration.schema_invalid" }
      refute_nil diagnostic, error.diagnostics.inspect
      assert_includes diagnostic.message, "probe.tag.wire"
      refute PhComposer::Registry.installed?("probe.tag")
    end
  end

  def test_unusable_projections_omit_only_their_row_with_the_label_code
    projections = { "nil" => nil, "number" => 3, "object" => { "a" => 1 }, "blank" => "  " }
    label = lambda do |mapped|
      raise "projection failed" if mapped["designation"] == "raise"

      projections.fetch(mapped["designation"], mapped["designation"])
    end
    result = admit(tag_adapter(:label => label),
                   [*projections.keys, "raise", "Kept"].map { |value| tag_row("r-#{value}", value) })
    assert_equal ["r-Kept"], result.rows.map { |row| row.fetch("record_id") }
    assert_equal "Kept", result.rows.first.fetch("display_label")
    codes = result.warnings.map { |row| [row.fetch("code"), row.fetch("record_id")] }
    assert_equal(%w[nil number object blank raise].map { |value| ["library.row_label_invalid", "r-#{value}"] }, codes)
  end

  def test_absent_and_null_designations_are_omitted_and_labels_are_trimmed
    result = admit(tag_adapter, [tag_row("a"), tag_row("b", nil), tag_row("c", "  Wall tag  ")])
    assert_equal [%w[c Wall\ tag]], result.rows.map { |row| [row["record_id"], row["display_label"]] }
    labels = result.warnings.select { |row| row.fetch("code") == "library.row_label_invalid" }
    assert_equal %w[a b], labels.map { |row| row.fetch("record_id") }
  end

  def test_rows_sort_by_label_then_case_then_record_id_and_equal_labels_all_remain
    rows = [tag_row("z", "beta"), tag_row("b", "Alpha"), tag_row("a", "Alpha"), tag_row("c", "alpha")]
    first = admit(tag_adapter, rows).rows.map { |row| row.fetch("record_id") }
    assert_equal %w[a b c z], first
    assert_equal first, admit(tag_adapter, rows.reverse).rows.map { |row| row.fetch("record_id") }
  end

  def test_file_rows_get_the_admitted_label_in_order_across_a_folder_merge_and_reload
    adapter = tag_adapter
    adapters = { "tags" => adapter }
    second = envelope([], :library_id => "synthetic.two", :kinds => { "tags" => [tag_row("x", "Alpha")] })
    first = envelope([], :kinds => { "tags" => [tag_row("q", "beta"), tag_row("p", "Alpha")] })
    [first, second].each { |value| value["kind_schema_versions"] = { "tags" => 1 } }
    write_library(File.join(@directory, "b.json"), second)
    write_library(File.join(@directory, "a.json"), first)
    provider = PhComposer::Library::FileProvider.new(:id => "provider.folder", :label => "Folder", :path => @directory,
                                                     :kinds => ["tags"], :adapters => adapters.method(:[]))
    labelled = lambda do
      PhComposer::Library::Admission.call(provider.list("tags"), :kind => "tags", :adapter => adapter)
                                    .rows.map { |row| [row["library_id"], row["record_id"], row["display_label"]] }
    end
    expected = [%w[synthetic.one p Alpha], %w[synthetic.one q beta], %w[synthetic.two x Alpha]]
    assert_equal expected, labelled.call
    assert_equal expected, labelled.call
    direct = admit(adapter, [tag_row("q", "beta"), tag_row("p", "Alpha")]).rows
    assert_equal(%w[Alpha beta], direct.map { |row| row["display_label"] })
  end

  def test_name_free_kind_lists_copies_and_then_reuses_by_source
    PhComposer::Registry.install([tag_feature])
    load_tags([tag_row("one", "Wall tag"), tag_row("two", "wall TAG")])
    rows = in_file.dig("value", "rows")
    assert_equal ["Wall tag", "wall TAG"], rows.map { |row| row["display_label"] }
    assert_equal %w[create create], rows.map { |row| row.dig("resolution", "outcome") }
    created = copy("one")
    assert_equal "committed", created["effect"], created.inspect
    id = created.dig("value", "local_id")
    resolved = in_file.dig("value", "rows").to_h { |row| [row["record_id"], row["resolution"]] }
    assert_equal "reuse", resolved.dig("one", "outcome")
    assert_equal [id], resolved.dig("one", "candidates").map { |row| row["id"] }
    assert_equal "review_required", resolved.dig("two", "outcome")
    assert_equal "Wall tag", resolved.dig("two", "candidates", 0, "display_label")
  end
end
