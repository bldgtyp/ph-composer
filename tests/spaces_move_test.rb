# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/space_fixtures"

# Move Space to Zone: the Space Group is placed again in the target Zone where it stands, and the
# original erased, in one Undo step (context/SKETCHUP_HOST_BEHAVIOR.md, "Re-placing a Group's definition").
class SpacesMoveTest < PhComposerTestCase
  include SpaceFixtures

  API = PhComposer::API
  # Zone B sits under a wrapper turned a quarter turn and shifted; Zone A under none.
  WRAPPER = Geom::Transformation.new([0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 200, 50, 0, 1])

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
    @volume = volume_group(111, volume_record("A"), [floor_face(112, rectangle(1, 1, 2, 3), segment_record("A"))])
    @space = space_group(110, space_record("S", :number => "7", :name => "Hall"), [@volume],
                         :transformation => Geom::Transformation.translation([10, 20, 0]))
    @space.name = "7 Hall"
    @zone_a = zone_group(100, "A", [@space])
    @zone_b = zone_group(200, "B", [space_group(210, space_record("T", :number => "7"), [])],
                         :transformation => Geom::Transformation.translation([5, 0, 0]))
    @wrapper = Sketchup::Group.new(190, Sketchup::Entities.new([@zone_b]), :transformation => WRAPPER)
    @model.entities << @zone_a << @wrapper
    [@zone_a].each { |zone| ZONES::STAMP_STORE.write(@space, ZONES::Schema.stamp(ZONES::ZONE_STORE.read(zone))) }
  end

  def move(space_path = [100, 110], zone_path = [190, 200])
    @sequence += 1
    API.invoke(:context => @context, :name => "ph_composer.spaces.move_to_zone",
               :params => { "space" => { "space_id" => "spc_SSSSSSSSSSSS", "entity_path" => space_path },
                            "zone" => { "zone_id" => ZONES::ZONE_STORE.read(zone_at(zone_path))["id"],
                                        "zone_path" => zone_path } },
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end

  def zone_at(path)
    SPACES::Occurrences.entity_at(@model, path)
  end

  def hall
    SPACES::Occurrences.scan(@model).spaces.find { |space| space.record["id"] == "spc_SSSSSSSSSSSS" }
  end

  def world_loop
    segment = hall.volumes.first.segments.first
    segment.entity.outer_loop.vertices.map do |vertex|
      point = vertex.position.transform(segment.transform)
      [point.x, point.y, point.z]
    end
  end

  def spaces
    API.query(:context => @context, :name => "ph_composer.spaces.all").fetch("value").fetch("spaces")
  end

  def test_move_under_a_rotated_wrapper_keeps_world_geometry_ids_and_values_in_one_step
    loop_before = world_loop
    records = [hall.record, hall.volumes.first.record, hall.volumes.first.segments.first.record]
    before = @model.operations.length
    result = move
    assert_equal "completed", result["status"], result.inspect
    assert_equal before + 1, @model.operations.length
    moved = hall
    assert_equal [190, 200], moved.path[0, 2]
    loop_before.zip(world_loop).each do |expected, actual|
      expected.zip(actual).each { |e, a| assert_in_delta e, a, 1e-9 }
    end
    assert_equal records, [moved.record, moved.volumes.first.record, moved.volumes.first.segments.first.record]
    assert_equal ZONES::Schema.stamp(ZONES::ZONE_STORE.read(@zone_b)), ZONES::STAMP_STORE.read(moved.entity)
    assert_equal "7 Hall", moved.entity.name
    assert moved.volumes.first.entity.locked?
    row = spaces.find { |space| space["id"] == "spc_SSSSSSSSSSSS" }
    refute row.dig("volumes", 0, "moved"), "home_transform still holds: the Volume did not move in its Space"
    assert_empty @zone_a.entities.to_a
  end

  def test_a_moved_space_keeps_its_number_and_flags_the_collision
    move
    hall_row = spaces.find { |space| space["id"] == "spc_SSSSSSSSSSSS" }
    assert_equal "7", hall_row.dig("values", "number")
    assert_includes hall_row.fetch("findings").map { |finding| finding["code"] }, "space.number_duplicate"
  end

  def test_one_undo_restores_the_original_and_redo_moves_it_again
    move
    @model.undo
    assert_equal [100, 110], hall.path
    @model.redo
    assert_equal [190, 200], hall.path[0, 2]
  end

  def test_move_refuses_with_an_edit_context_open_and_writes_nothing
    @model.active_path = [@zone_a, @space]
    before = @model.operations.length
    assert_equal %w[refused space.context_open], move.values_at("status", "code")
    assert_equal before, @model.operations.length
    assert_equal [100, 110], hall.path
  end

  def test_move_refuses_the_current_zone_and_a_locked_target
    assert_equal %w[refused space.same_zone], move([100, 110], [100]).values_at("status", "code")
    @zone_b.locked = true
    assert_equal %w[refused target.locked], move.values_at("status", "code")
  end

  def test_a_failure_at_the_erase_leaves_the_original_and_no_new_group
    parent = @zone_a.entities
    result = parent.stub(:erase_entities, ->(*) { raise "injected" }) { move }
    assert_equal %w[failed rolled_back], result.values_at("status", "effect")
    assert_equal [100, 110], hall.path
    assert_equal [210], SPACES::Occurrences.entity_at(@model, [190, 200]).entities.to_a.map(&:persistent_id)
  end
end
