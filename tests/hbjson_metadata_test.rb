# frozen_string_literal: true

require_relative "test_helper"

# R-D2: the artifact guard parses a copy of the canonical HBJSON. `user_data` may hold only the keys
# export contributors declare; extension envelopes, usernames and paths refuse at any depth; the
# bytes written are the translator's own.
class HbjsonMetadataTest < PhComposerTestCase
  FIXTURE = File.join(TESTS_ROOT, "fixtures", "phase_one", "two_zones.hbjson")
  Privacy = PhComposer::Export::Privacy

  def test_the_review_reproduction_refuses
    hbjson = JSON.generate("type" => "Model", "username" => "private-user", "extension_data" => { "secret" => "x" })

    assert_equal "export.privacy_undeclared", refusal(hbjson)
  end

  def test_the_real_two_zone_translation_passes_and_its_bytes_are_unchanged
    hbjson = File.read(FIXTURE)
    before = hbjson.dup
    document = result(hbjson)

    assert Privacy.validate!(document)
    assert_equal before, document.dig("canonical_model", "hbjson")
  end

  def test_nested_or_undeclared_metadata_refuses_and_declared_metadata_passes
    declared = model("user_data" => { "ph_composer" => { "level" => "L1", "building_segment" => "House" } })
    nested = model("faces" => [{ "properties" => { "extension_data" => { "a" => 1 } } }])
    undeclared = model("user_data" => { "ph_composer" => { "level" => "L1", "secret" => "x" } })
    foreign = model("user_data" => { "firm" => { "note" => "x" } })

    assert Privacy.validate!(result(declared))
    [nested, undeclared, foreign].each { |hbjson| assert_equal "export.privacy_undeclared", refusal(hbjson) }
    assert_match(/ph_composer\.secret/, refusal_message(undeclared))
  end

  def test_a_contributor_that_declares_its_keys_needs_no_guard_change
    feature = Module.new do
      define_singleton_method(:install) do |registry|
        registry.feature("outside.tags", :contract_version => 1)
                .export_contributor("outside.tags.export", :section_version => 1,
                                                           :user_data_keys => ["outside.tag"]) { [] }
      end
    end
    PhComposer::Registry.install([feature])

    assert Privacy.validate!(result(model("user_data" => { "outside" => { "tag" => "north" } })))
  end

  def test_a_malformed_key_declaration_refuses_registration
    feature = Module.new do
      define_singleton_method(:install) do |registry|
        registry.feature("outside.tags", :contract_version => 1)
                .export_contributor("outside.tags.export", :section_version => 1,
                                                           :user_data_keys => ["Not A Key"]) { [] }
      end
    end

    error = assert_raises(PhComposer::RegistrationError) { PhComposer::Registry.install([feature]) }
    assert_equal ["registration.schema_invalid"], error.diagnostics.map(&:code)
  end

  def test_escaped_path_spellings_inside_the_hbjson_are_caught
    [model("display_name" => "C:\\Users\\someone\\model.skp"),
     JSON.generate("type" => "Model", "rooms" => [], "note" => "/Users/someone/model.skp").gsub("/", "\\/")]
      .each { |hbjson| assert_equal "export.privacy_undeclared", refusal(hbjson) }
  end

  private

  def model(room)
    JSON.generate("type" => "Model", "rooms" => [{ "identifier" => "zon_AAAAAAAAAAAA" }.merge(room)])
  end

  def result(hbjson)
    {
      "schema_version" => 1, "run_id" => "run", "state" => "complete",
      "summary" => { "objects" => 1, "unavailable" => 0, "findings" => 0, "publishable" => true },
      "sections" => [], "findings" => [], "failure" => nil,
      "canonical_model" => { "hbjson" => hbjson, "rooms" => 1, "faces" => 0, "surface_pairs" => 0, "omitted" => 0 }
    }
  end

  def refusal(hbjson)
    assert_raises(PhComposer::CodedError) { Privacy.validate!(result(hbjson)) }.code
  end

  def refusal_message(hbjson)
    assert_raises(PhComposer::CodedError) { Privacy.validate!(result(hbjson)) }.message
  end
end
