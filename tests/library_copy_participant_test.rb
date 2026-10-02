# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/library_provider_fixtures"

class LibraryCopyParticipantTest < PhComposerTestCase
  include LibraryProviderFixtures
  LIBRARY = PhComposer::Library
  API = PhComposer::API
  ACTION = "probe.library_copy.apply"

  def setup
    super
    @directory = Dir.mktmpdir("library-participant")
    path = write_library(File.join(@directory, "synthetic.json"))
    LIBRARY::Setup.add_file(:id => "synthetic.file", :label => "Synthetic", :path => path)
    @session = PhComposer::Sessions.for(Sketchup.active_model)
    @context = API.connect(:session_id => @session.id, :capabilities => %w[read view model_write setup])
    generation = API.setup(:context => @context, :name => "ph_composer.library.load",
                           :params => { "provider_id" => "synthetic.file", "kind" => "materials" })
                    .dig("value", "generation")
    @copy = { "provider_id" => "synthetic.file", "kind" => "materials", "generation" => generation,
              "library_id" => "synthetic.one", "record_id" => "public-1", "choice" => "create" }
    @sequence = 0
  end

  def teardown
    FileUtils.rm_rf(@directory)
    super
  end

  def install_probe(dependency: true)
    probe = Module.new
    probe.define_singleton_method(:install) do |registry|
      feature = registry.feature("probe.library_copy", :contract_version => 1,
                                                       :requires => dependency ? ["ph_composer.library"] : [])
      feature.action(ACTION,
                     :description => "Synthetic composite copy.",
                     :params => { "type" => "object" }, :result => LIBRARY::Schemas.copy_result,
                     :undo_name => "Composite Copy", :side_effects => "Copies in the shared proposal.",
                     :examples => [{}]) do |r, p|
        result = r.participant("ph_composer.library.copy_into_proposal").call(r, p, r.params.fetch("copy"))
        if r.params["refuse_after_copy"] || r.params["wrong_proposal"]
          begin
            invalid = r.params.fetch("copy").merge("secret" => "rejected")
            supplied = case r.params["wrong_proposal"]
                       when "nil" then nil
                       when "other" then PhComposer::Records::ChangeSet.new
                       else p
                       end
            r.participant("ph_composer.library.copy_into_proposal").call(r, supplied, invalid)
          rescue PhComposer::CodedError
            # A participant failure still poisons the enclosing proposal when a caller catches it.
          end
        end
        result
      end
    end
    PhComposer::Registry.install([probe])
  end

  def invoke(params)
    @sequence += 1
    API.invoke(:context => @context, :name => ACTION, :params => params,
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end

  def inventory
    API.query(:context => @context, :name => "ph_composer.assemblies.materials.all").dig("value", "records")
  end

  def test_preview_is_detached_and_composite_copy_commits_once_with_trusted_attribution
    install_probe
    revision = @session.revision
    preview = API.preview(:context => @context, :name => ACTION, :params => { "copy" => @copy })
    assert_equal "completed", preview["status"], preview.inspect
    assert_empty inventory
    assert_equal revision, @session.revision
    result = invoke("copy" => @copy)
    assert_equal "committed", result["effect"], result.inspect
    assert_equal revision + 1, @session.revision
    assert_equal 1, inventory.length
    assert_equal result.dig("value", "local_id"), inventory.first["id"]
    assert_equal "public-1", inventory.first.dig("values", "source", "record_id")
    refute_includes JSON.generate(result), @directory
  end

  def test_caught_late_schema_failure_rolls_back_the_earlier_copy
    install_probe
    revision = @session.revision
    result = invoke("copy" => @copy, "refuse_after_copy" => true)
    assert_equal "params.invalid", result["code"], result.inspect
    assert_empty inventory
    assert_equal revision, @session.revision
  end

  def test_caught_missing_or_mismatched_proposal_poison_the_actual_caller_proposal
    install_probe
    revision = @session.revision
    %w[nil other].each do |wrong|
      result = invoke("copy" => @copy, "wrong_proposal" => wrong)
      assert_equal "operation.proposal_required", result["code"], result.inspect
      assert_empty inventory
      assert_equal revision, @session.revision
    end
  end

  def test_undeclared_dependency_cannot_use_the_participant
    install_probe(:dependency => false)
    result = invoke("copy" => @copy)
    assert_equal "operation.dependency_missing", result["code"], result.inspect
    assert_empty inventory
  end

  def test_stale_catalog_generation_is_refused_inside_the_composite_action
    install_probe
    LIBRARY::State.for(@session).remove("synthetic.file")
    result = invoke("copy" => @copy)
    refute_equal "completed", result["status"], result.inspect
    assert_equal "none", result["effect"]
    assert_empty inventory
  end
end
