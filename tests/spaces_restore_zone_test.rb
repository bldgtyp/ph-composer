# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/space_fixtures"

# Restore Zone recovers a Space Group, which Zones stamped as one of its nested containers, along with
# the Zone's stamped Faces (context/CONTRACTS.md, "Nested containers").
class SpacesRestoreZoneTest < PhComposerTestCase
  include SpaceFixtures

  API = PhComposer::API

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @space = space_group(110, space_record("S", :number => "1"),
                         [volume_group(111, volume_record("A"), [floor_face(112, rectangle(0, 0, 2, 2),
                                                                            segment_record("A"))])])
    @zone = zone_group(100, "Z", [@space])
    @model.entities << @zone
    ZONES::STAMP_STORE.write(@space, ZONES::Schema.stamp(ZONES::ZONE_STORE.read(@zone)))
  end

  def test_a_zone_exploded_with_a_space_inside_is_restored_around_it
    @zone.explode
    offer = API.query(:context => @context, :name => "ph_composer.zones.all").dig("value", "restorable", 0)
    assert_equal({ "zone_id" => "zon_ZZZZZZZZZZZZ", "entity_ids" => [110], "refusal" => nil },
                 offer.slice("zone_id", "entity_ids", "refusal"))
    result = API.invoke(:context => @context, :name => "ph_composer.zones.restore",
                        :params => { "parent_path" => [], "zone_id" => "zon_ZZZZZZZZZZZZ" },
                        :request => { "sequence" => 1, "expected_revision" => @session.revision })
    assert_equal "completed", result["status"], result.inspect
    row = API.query(:context => @context, :name => "ph_composer.spaces.all").dig("value", "spaces", 0)
    assert_equal "zon_ZZZZZZZZZZZZ", row.dig("zone", "zone_id")
    assert_equal "spc_SSSSSSSSSSSS", row["id"]
    refute_includes row.fetch("findings").map { |finding| finding["code"] }, "space.outside_zone"
  end
end
