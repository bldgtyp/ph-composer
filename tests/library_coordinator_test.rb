# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/library_provider_fixtures"
require_relative "support/assembly_record_fixtures"

class LibraryCoordinatorTest < PhComposerTestCase
  include LibraryProviderFixtures
  include AssemblyRecordFixtures

  API = PhComposer::API
  PREFIX = "ph_composer.library"
  MATERIALS = "ph_composer.assemblies.materials"

  def setup
    super
    @directory = Dir.mktmpdir("library-coordinator")
    @path = write_library(File.join(@directory, "synthetic.json"))
    PhComposer::Library::Setup.add_file(:id => "synthetic.file", :label => "Synthetic", :path => @path)
    @session = PhComposer::Sessions.for(Sketchup.active_model)
    @context = API.connect(:session_id => @session.id, :capabilities => %w[read view model_write setup])
    @sequence = 0
    @generation = load_catalog.fetch("value").fetch("generation")
  end

  def teardown
    FileUtils.rm_rf(@directory)
    super
  end

  def load_catalog
    API.setup(:context => @context, :name => "#{PREFIX}.load",
              :params => { "provider_id" => "synthetic.file", "kind" => "materials" })
  end

  def params(choice = "create")
    { "provider_id" => "synthetic.file", "kind" => "materials", "generation" => @generation,
      "library_id" => "synthetic.one", "record_id" => "public-1", "choice" => choice }
  end

  def invoke(name, values)
    @sequence += 1
    API.invoke(:context => @context, :name => name, :params => values,
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end

  def materials
    API.query(:context => @context, :name => "#{MATERIALS}.all").dig("value", "records")
  end

  def test_load_and_catalog_are_session_only_and_transport_private
    revision = @session.revision
    result = API.query(:context => @context, :name => "#{PREFIX}.catalog",
                       :params => params.slice("provider_id", "kind", "generation").merge("limit" => 1))
    assert_equal "completed", result["status"]
    assert_equal 1, result.dig("value", "total")
    assert_nil result.dig("value", "next_cursor")
    refute_includes JSON.generate(result), @directory
    refute_includes JSON.generate(API.query(:context => @context, :name => "#{PREFIX}.providers")), @directory
    assert_equal revision, @session.revision
    assert_empty materials
  end

  # Library reads page as every other list does, with the cursor bound to the catalog generation it
  # was read from: a reload publishes a new generation and the old cursor is refused.
  def test_catalog_pages_by_cursor_bound_to_its_generation
    write_library(@path, envelope(%w[public-1 public-2 public-3].map { |id| library_row(id) }))
    load_catalog
    selected = { "provider_id" => "synthetic.file", "kind" => "materials" }
    first = API.query(:context => @context, :name => "#{PREFIX}.catalog", :params => selected.merge("limit" => 2))
    assert_equal [2, 3], [first.dig("value", "rows").length, first.dig("value", "total")]
    cursor = first.dig("value", "next_cursor")
    second = API.query(:context => @context, :name => "#{PREFIX}.catalog",
                       :params => selected.merge("limit" => 2, "cursor" => cursor))
    seen = (first.dig("value", "rows") + second.dig("value", "rows")).map { |row| row.fetch("record_id") }
    assert_equal %w[public-1 public-2 public-3], seen.sort
    assert_nil second.dig("value", "next_cursor")
    load_catalog
    expired = API.query(:context => @context, :name => "#{PREFIX}.catalog",
                        :params => selected.merge("limit" => 2, "cursor" => cursor))
    assert_equal "query.cursor_expired", expired["code"]
  end

  def test_preview_and_apply_share_digest_and_retry_cannot_copy_twice
    input = params("create")
    preview = API.preview(:context => @context, :name => "#{PREFIX}.copy", :params => input)
    assert_equal "completed", preview["status"], preview.inspect
    assert_empty materials
    @sequence += 1
    request = { "sequence" => @sequence, "expected_revision" => @session.revision,
                "proposal_digest" => preview.fetch("proposal_digest") }
    result = API.invoke(:context => @context, :name => "#{PREFIX}.copy", :params => input, :request => request)
    assert_equal "committed", result["effect"], result.inspect
    assert_equal result,
                 API.invoke(:context => @context, :name => "#{PREFIX}.copy", :params => input, :request => request)
    assert_equal 1, materials.length
    source = materials.first.dig("values", "source")
    assert_equal "ph_composer.library.file", source["provider_kind"]
    assert_equal "public-1", source["record_id"]
    refute source.fetch("snapshot").key?("id")
    refute_includes JSON.generate(materials), @directory
  end

  def test_exact_source_reuses_renamed_edited_local_copy_without_overwriting
    created = invoke("#{PREFIX}.copy", params("create"))
    id = created.dig("value", "local_id")
    invoke("#{MATERIALS}.update", "id" => id, "values" => { "name" => "Edited", "conductivity_w_mk" => 0.08 },
                                  "expected_values" => { "name" => "Synthetic insulation" })
    assert_equal "reuse", in_file.fetch("rows").first.dig("resolution", "outcome")
    reused = invoke("#{PREFIX}.copy", params("keep_local"))
    assert_equal id, reused.dig("value", "local_id")
    assert_equal "none", reused["effect"]
    assert_equal 0.08, materials.first.dig("values", "conductivity_w_mk")
  end

  def in_file
    result = API.query(:context => @context, :name => "#{PREFIX}.in_file",
                       :params => params.slice("provider_id", "kind", "generation"))
    assert_equal "completed", result["status"], result.inspect
    result.fetch("value")
  end

  def test_public_copy_and_assignment_commit_together_and_preserve_other_segment_fields
    assembly = fixture_assembly([[100.0, [[600.0, nil]]]])
    Assemblies::Assembly::Schema::KIND.store.write(Sketchup.active_model, assembly)
    layer = assembly.fetch("layers").first
    target = { "id" => assembly.fetch("id"), "layer_id" => layer.fetch("id"),
               "segment_id" => layer.fetch("segments").first.fetch("id"),
               "expected_values" => { "layers" => assembly.fetch("layers") } }
    revision = @session.revision
    result = invoke("#{PREFIX}.copy", params("create").merge("assignment" => target))
    assert_equal "committed", result["effect"], result.inspect
    assert_equal true, result.dig("value", "assigned")
    assert_equal revision + 1, @session.revision
    current = Assemblies::Assembly::Schema::KIND.store.read(Sketchup.active_model, assembly.fetch("id"))
    id = result.dig("value", "local_id")
    expected = PhComposer::DeepCopy.call(assembly)
    expected.fetch("layers").first.fetch("segments").first["material_id"] = id
    assert_equal expected, current
    assert_equal id, materials.first.fetch("id")
  end

  def test_reviewed_replacement_requires_all_local_values_and_preserves_metadata
    record = fixture_materials.fetch(material_id("wool"))
    record["name"] = "Synthetic insulation"
    record["conductivity_w_mk"] = 0.09
    record["user_data"] = { "firm.note" => ["retain"] }
    record["extension_data"] = { "outside.vendor" => { "schema_version" => 8, "payload" => { "retain" => true } } }
    Assemblies::Materials::Schema::KIND.store.write(Sketchup.active_model, record)
    candidate = in_file.fetch("rows").first.fetch("resolution").fetch("candidates").first
    assert_equal false, candidate.fetch("comparison_available")
    assert_nil candidate.fetch("source_changed")
    input = params("use_library").merge("expected_values" => { "name" => record["name"] })
    incomplete = invoke("#{PREFIX}.copy", input)
    assert_equal "params.invalid", incomplete["code"]
    assert_equal 0.09, materials.first.dig("values", "conductivity_w_mk")
    replaced = invoke("#{PREFIX}.copy", params("use_library").merge("expected_values" => candidate["expected_values"]))
    assert_equal "committed", replaced["effect"], replaced.inspect
    assert_equal record.fetch("id"), replaced.dig("value", "local_id")
    current = Assemblies::Materials::Schema::KIND.store.read(Sketchup.active_model, record.fetch("id"))
    assert_equal 0.04, current.fetch("conductivity_w_mk")
    assert_equal record.fetch("user_data"), current.fetch("user_data")
    assert_equal record.fetch("extension_data"), current.fetch("extension_data")
  end

  def test_source_change_comparison_ignores_local_edits_and_reports_incompatible_versions
    id = invoke("#{PREFIX}.copy", params("create")).dig("value", "local_id")
    invoke("#{MATERIALS}.update", "id" => id, "values" => { "conductivity_w_mk" => 0.08 },
                                  "expected_values" => { "conductivity_w_mk" => 0.04 })
    candidate = in_file.fetch("rows").first.fetch("resolution").fetch("candidates").first
    assert_equal true, candidate.fetch("comparison_available")
    assert_equal false, candidate.fetch("source_changed")
    changed = library_row.merge("conductivity_w_mk" => 0.06)
    write_library(@path, envelope([changed]))
    @generation = load_catalog.dig("value", "generation")
    candidate = in_file.fetch("rows").first.fetch("resolution").fetch("candidates").first
    assert_equal true, candidate.fetch("source_changed")
    declaration = PhComposer::Library::State.kind("materials", PhComposer::Registry.current)
    adapter = declaration.adapter.dup
    adapter.fingerprint_version = 2
    record = Assemblies::Materials::Schema::KIND.store.read(Sketchup.active_model, id)
    local = { "id" => id, "mapped" => adapter.map.call(record), "source" => record.fetch("source") }
    source = record.fetch("source").slice(*PhComposer::Library::Resolver::IDENTITY_FIELDS)
    candidate = PhComposer::Library::Coordinator.resolve(adapter, source, adapter.map.call(changed), [local])
                                                .fetch("candidates").first
    assert_equal false, candidate.fetch("comparison_available")
    assert_nil candidate.fetch("source_changed")
  end

  def test_invalid_material_color_never_offers_a_public_copy
    write_library(@path, envelope([library_row.merge("color" => "not-hex")]))
    loaded = load_catalog
    @generation = loaded.dig("value", "generation")
    assert_equal "empty", loaded.dig("value", "state"), loaded.inspect
    assert_equal "library.row_semantic_invalid", loaded.dig("value", "warnings", -1, "code")
    assert_empty in_file.fetch("rows")
    result = invoke("#{PREFIX}.copy", params("create"))
    assert_equal "library.row_unavailable", result["code"]
    assert_empty materials
  end

  def test_unknown_wire_kind_is_unavailable_without_withholding_known_materials
    write_library(@path, envelope(:kinds => { "materials" => [library_row], "future_parts" => [library_row] }))
    loaded = load_catalog
    @generation = loaded.dig("value", "generation")
    assert_equal "loaded", loaded.dig("value", "state"), loaded.inspect
    assert_equal 1, in_file.fetch("total")
    assert_equal "future_parts", loaded.dig("value", "unavailable", 0, "kind")
  end

  def test_failed_assignment_refuses_the_staged_copy_without_any_model_write
    result = invoke("#{PREFIX}.copy", params("create").merge("assignment" => {}))
    assert_equal "refused", result["status"], result.inspect
    assert_empty materials
    assert_equal 1, @session.revision
  end

  def test_replacing_private_provider_configuration_invalidates_loaded_rows
    replacement = write_library(File.join(@directory, "replacement.json"), envelope([library_row("new-id")]))
    PhComposer::Library::Setup.add_file(:id => "synthetic.file", :label => "Replacement", :path => replacement)
    result = invoke("#{PREFIX}.copy", params("create"))
    assert_equal "library.catalog_stale", result["code"], result.inspect
    assert_empty materials
    assert_equal "unloaded", API.query(:context => @context, :name => "#{PREFIX}.providers")
                                .dig("value", 0, "catalogs", 0, "state")
  end

  def test_refresh_publishes_a_new_generation_and_old_copy_is_refused
    previous = @generation
    @generation = load_catalog.dig("value", "generation")
    assert_operator @generation, :>, previous
    result = invoke("#{PREFIX}.copy", params("create").merge("generation" => previous))
    assert_equal "library.catalog_stale", result["code"]
    assert_empty materials
  end

  def test_failed_refresh_keeps_the_valid_catalog_and_failure_age_visible
    File.write(@path, "not JSON")
    result = load_catalog
    assert_equal "failed", result.dig("value", "state"), result.inspect
    assert_equal @generation, result.dig("value", "generation")
    page = API.query(:context => @context, :name => "#{PREFIX}.catalog", :params => params.slice("provider_id", "kind"))
    assert_equal 1, page.dig("value", "total")
    assert_operator page.dig("value", "age_seconds"), :>=, 0
  end
end
