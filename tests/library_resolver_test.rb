# frozen_string_literal: true

require_relative "test_helper"
require_relative "../src/ph_composer/library/resolver"

class LibraryResolverTest < PhComposerTestCase
  def setup
    super
    @source = { "provider_kind" => "example.file", "library_id" => "one", "record_kind" => "materials",
                "record_id" => "shared" }
    @mapped = { "name" => "Insulation", "conductivity_w_mk" => 0.04 }
  end

  def resolve(locals, source = @source)
    PhComposer::Library::Resolver.resolve(:source => source, :mapped => @mapped, :locals => locals)
  end

  def local(id, mapped = @mapped, source = nil)
    { "id" => id, "mapped" => PhComposer::DeepCopy.call(mapped), "source" => source }
  end

  def test_exact_identity_reuses_renamed_and_edited_record_before_same_name
    attributed = @source.merge("kind" => "library")
    result = resolve([local("a", { "name" => "Renamed", "conductivity_w_mk" => 0.08 }, attributed), local("b")])
    assert_equal "reuse", result["outcome"]
    assert_equal ["a"], result["candidates"].map { |row| row["id"] }
    assert_equal %w[conductivity_w_mk name], result["candidates"][0]["differences"].map { |row| row["field"] }
  end

  def test_duplicate_source_is_ambiguous_even_after_rename
    source = @source.merge("kind" => "library")
    result = resolve([local("b", { "name" => "Other" }, source), local("a", @mapped, source)])
    assert_equal "ambiguous_source", result["outcome"]
    assert_equal %w[a b], result["candidates"].map { |row| row["id"] }
  end

  def test_each_same_name_outcome
    assert_equal "create", resolve([])["outcome"]
    assert_equal "reuse", resolve([local("a")])["outcome"]
    assert_equal "review_required", resolve([local("a", @mapped.merge("conductivity_w_mk" => 0.08))])["outcome"]
    assert_equal "ambiguous_name", resolve([local("a"), local("b")])["outcome"]
  end

  def test_case_and_outer_space_match_the_local_unique_name_rule
    result = resolve([local("a", @mapped.merge("name" => "  insulation  "))])
    assert_equal "review_required", result.fetch("outcome")
    assert_equal ["a"], result.fetch("candidates").map { |row| row.fetch("id") }
  end

  def test_identity_includes_library_and_provider_kind_and_ignores_configuration
    source = @source.merge("kind" => "library", "configuration_id" => "old")
    renamed = local("a", { "name" => "Other" }, source)
    assert_equal "reuse", resolve([renamed], @source.merge("configuration_id" => "new"))["outcome"]
    assert_equal "create", resolve([renamed], @source.merge("library_id" => "two"))["outcome"]
    assert_equal "create", resolve([renamed], @source.merge("provider_kind" => "example.connection"))["outcome"]
  end

  def test_detached_differences_distinguish_missing_from_null
    result = resolve([local("a", @mapped.merge("color" => nil))])
    difference = result["candidates"][0]["differences"][0]
    assert_equal "color", difference["field"]
    assert difference["local_present"]
    refute difference["incoming_present"]
    result["candidates"][0]["name"].replace("Changed")
    assert_equal "Insulation", @mapped["name"]
  end
end
