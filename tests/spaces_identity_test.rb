# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/space_fixtures"

# Copies of Spaces, Volumes and Floor Segments: the duplicate_identity finding and Make independent
# (context/CONTRACTS.md, "Geometry records and occurrence references"). A native copy is modelled as the
# host makes it: a new Group over the same entities, carrying the original's instance dictionaries.
class SpacesIdentityTest < PhComposerTestCase
  include SpaceFixtures

  API = PhComposer::API

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
    @volume = volume_group(111, volume_record("A"), [floor_face(112, rectangle(0, 0, 2, 2), segment_record("A"))])
    @space = space_group(110, space_record("S", :number => "1").merge("user_data" => { "note" => "kept" }), [@volume])
    @zone = zone_group(100, "Z", [@space])
    @model.entities << @zone
  end

  def native_copy(group, persistent_id, parent)
    copy = Sketchup::Group.new(persistent_id, group.entities, {}, :transformation => group.transformation,
                                                                  :locked => group.locked?)
    Array(group.attribute_dictionaries).each do |dictionary|
      dictionary.each { |key, value| copy.set_attribute(dictionary.name, key, value) }
    end
    parent.entities << copy
    copy
  end

  def spaces
    API.query(:context => @context, :name => "ph_composer.spaces.all").fetch("value").fetch("spaces")
  end

  def codes(row)
    row.fetch("findings").map { |finding| finding["code"] }
  end

  def invoke(name, params)
    @sequence += 1
    API.invoke(:context => @context, :name => name, :params => params,
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end

  def make_independent(reference)
    invoke("ph_composer.spaces.make_independent", "reference" => reference)
  end

  def test_a_copied_space_raises_the_blocking_finding_on_every_record_of_both_occurrences
    native_copy(@space, 120, @zone)
    rows = spaces
    assert_equal [[100, 110], [100, 120]], rows.map { |row| row.dig("reference", "entity_path") }
    rows.each do |row|
      finding = row.fetch("findings").find { |item| item["code"] == "space.duplicate_identity" }
      assert finding["blocks_export"]
      assert_includes finding["message"], "Make independent"
      assert_includes codes(row.dig("volumes", 0)), "space.duplicate_identity"
      assert_includes codes(row.dig("volumes", 0, "floor_segments", 0)), "space.duplicate_identity"
    end
  end

  def test_a_copied_volume_and_a_copied_floor_segment_raise_the_finding_on_both
    native_copy(@volume, 113, @space)
    @volume.entities << floor_face(114, rectangle(2, 0, 1, 1), segment_record("A"))
    volumes = spaces.first.fetch("volumes")
    assert_equal(2, volumes.count { |volume| codes(volume).include?("space.duplicate_identity") })
    segments = volumes.first.fetch("floor_segments")
    assert_equal [true, true], segments.map { |segment| codes(segment).include?("space.duplicate_identity") }
  end

  def test_make_independent_rewrites_the_named_copy_in_one_step_and_leaves_the_original
    copy = native_copy(@space, 120, @zone)
    before = @model.operations.length
    result = make_independent("space_id" => "spc_SSSSSSSSSSSS", "entity_path" => [100, 120])
    assert_equal "completed", result["status"], result.inspect
    assert_equal before + 1, @model.operations.length
    original, independent = spaces
    assert_equal %w[spc_SSSSSSSSSSSS vol_AAAAAAAAAAAA fsg_AAAAAAAAAAAA], ids(original)
    assert_equal "1", original.dig("values", "number")
    refute_equal ids(original), ids(independent)
    assert_equal ids(independent).uniq, ids(independent)
    assert_equal "2", independent.dig("values", "number")
    refute_equal "flr_AAAAAAAAAAAA", independent.dig("volumes", 0, "values", "floor_id")
    assert_equal({ "note" => "kept" }, independent["user_data"])
    refute PhComposer::Spaces::Occurrences.shared_storage?(copy), "the copy has storage of its own"
    [original, independent].each do |row|
      refute_includes codes(row), "space.duplicate_identity"
      refute_includes codes(row.dig("volumes", 0, "floor_segments", 0)), "space.duplicate_identity"
    end
  end

  def test_naming_the_original_rewrites_the_original
    native_copy(@space, 120, @zone)
    result = make_independent("space_id" => "spc_SSSSSSSSSSSS", "entity_path" => [100, 110])
    assert_equal "completed", result["status"], result.inspect
    original, copy = spaces
    refute_equal "spc_SSSSSSSSSSSS", original["id"]
    assert_equal "spc_SSSSSSSSSSSS", copy["id"]
  end

  def test_make_independent_on_a_copied_volume_and_a_copied_floor_segment
    native_copy(@volume, 113, @space)
    result = make_independent("volume_id" => "vol_AAAAAAAAAAAA", "entity_path" => [100, 110, 113])
    assert_equal "completed", result["status"], result.inspect
    volumes = spaces.first.fetch("volumes")
    assert_equal 2, volumes.map { |volume| volume["id"] }.uniq.length
    assert_equal 2, volumes.map { |volume| volume.dig("floor_segments", 0, "id") }.uniq.length
    @volume.entities << floor_face(114, rectangle(2, 0, 1, 1), segment_record("A"))
    result = make_independent("floor_segment_id" => "fsg_AAAAAAAAAAAA", "entity_path" => [100, 110, 111, 114])
    assert_equal "completed", result["status"], result.inspect
    segments = spaces.first.fetch("volumes").find { |volume| volume.dig("reference", "entity_path").last == 111 }
                     .fetch("floor_segments")
    assert_equal 2, segments.map { |segment| segment["id"] }.uniq.length
  end

  # A Space inside a Group copied with it shares storage above the Space: the finding says so, and Make
  # independent refuses rather than making the parent unique.
  def test_a_space_repeated_through_shared_storage_has_no_repair
    wrapper = Sketchup::Group.new(130, Sketchup::Entities.new([@space]))
    @zone.entities.delete(@space)
    @zone.entities << wrapper
    native_copy(wrapper, 131, @zone)
    finding = spaces.first.fetch("findings").find { |item| item["code"] == "space.duplicate_identity" }
    assert_includes finding["message"], "Draw the Space directly"
    before = @model.operations.length
    result = make_independent("space_id" => "spc_SSSSSSSSSSSS", "entity_path" => [100, 131, 110])
    assert_equal %w[refused target.shared_definition], result.values_at("status", "code")
    assert_equal before, @model.operations.length
  end

  def test_an_occurrence_with_its_own_identity_refuses
    result = make_independent("space_id" => "spc_SSSSSSSSSSSS", "entity_path" => [100, 110])
    assert_equal %w[refused space.identity_unique], result.values_at("status", "code")
  end

  private

  def ids(row)
    [row["id"], row.dig("volumes", 0, "id"), row.dig("volumes", 0, "floor_segments", 0, "id")]
  end
end
