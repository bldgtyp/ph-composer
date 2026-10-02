# frozen_string_literal: true

require_relative "test_helper"

# The Ground suggestion, boundary by boundary. honeybee's own rule
# (`honeybee.boundarycondition.get_bc_from_position`) is that a Face is Ground only when every
# vertex is at or below the ground depth, and Outdoors as soon as one is above it. A wall standing
# on grade starts exactly at the depth, so asking about its lowest vertex called it Ground.
class FaceSuggestionTest < PhComposerTestCase
  API = PhComposer::API

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
    @next_group = 100
  end

  def test_a_wall_standing_on_grade_is_outdoors_not_ground
    assert_equal "Outdoors", suggestion_for(wall(0.0, 3.0)).fetch("boundary_condition")
  end

  def test_a_slab_lying_on_grade_is_ground
    assert_equal "Ground", suggestion_for(slab(0.0)).fetch("boundary_condition")
  end

  def test_a_wall_wholly_below_grade_is_ground
    assert_equal "Ground", suggestion_for(wall(-3.0, -0.001)).fetch("boundary_condition")
  end

  # The boundary itself: at the depth is Ground, a millimetre above it is not.
  def test_a_face_exactly_at_the_ground_depth_is_ground_and_one_above_is_outdoors
    assert_equal "Ground", suggestion_for(slab(0.0)).fetch("boundary_condition")
    assert_equal "Outdoors", suggestion_for(slab(0.001)).fetch("boundary_condition")
  end

  def test_a_basement_wall_is_ground_under_a_zone_whose_ground_depth_is_raised
    zone = zone_with(wall(0.0, 2.5))

    assert_equal "Outdoors", faces.first.dig("suggested", "boundary_condition")

    raise_ground_depth(zone, 2_500.0)

    assert_equal "Ground", faces.first.dig("suggested", "boundary_condition")
  end

  # One box, the shape a user actually draws: only the floor is Ground.
  def test_a_plain_box_on_grade_suggests_ground_for_its_floor_alone
    zone_with(*box_faces)

    conditions = faces.map { |face| face.dig("suggested", "boundary_condition") }

    assert_equal 1, conditions.count("Ground")
    assert_equal 5, conditions.count("Outdoors")
  end

  private

  def invoke(name, params)
    @sequence += 1
    API.invoke(:context => @context, :name => name, :params => params,
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end

  def faces
    API.query(:context => @context, :name => "ph_composer.zones.faces.list").dig("value", "faces")
  end

  # Each call builds its own Zone, so several suggestions can be read in one test.
  def suggestion_for(face)
    zone = zone_with(face)
    faces.find { |row| row.dig("reference", "zone_id") == zone.fetch("id") }.fetch("suggested")
  end

  def zone_with(*entities)
    id = (@next_group += 10)
    @model.entities << Sketchup::Group.new(id, Sketchup::Entities.new(entities))
    invoke("ph_composer.zones.make", { "parent_path" => [], "entity_ids" => [id] })
    API.query(:context => @context, :name => "ph_composer.zones.list")
       .dig("value", "zones").find { |zone| zone.dig("reference", "zone_path") == [id] }
  end

  def raise_ground_depth(zone, depth_mm)
    invoke("ph_composer.zones.update", {
      "reference" => zone.fetch("reference"),
      "values" => zone.fetch("values").merge("ground_depth_mm" => depth_mm),
      "expected_values" => zone.fetch("values")
    })
  end

  # A vertical Face spanning two heights, so its lowest and highest vertices differ.
  def wall(bottom, top, persistent_id = nil)
    persistent_id ||= (@next_face = (@next_face || 1_000) + 1)
    Sketchup::Face.new(persistent_id, {},
                       :points => [metres(0, 0, bottom), metres(0, 4, bottom),
                                   metres(0, 4, top), metres(0, 0, top)],
                       :normal => Geom::Vector3d.new(1, 0, 0))
  end

  # A horizontal Face, every vertex at one height.
  def slab(height, persistent_id = nil, normal: [0, 0, -1])
    persistent_id ||= (@next_face = (@next_face || 1_000) + 1)
    Sketchup::Face.new(persistent_id, {},
                       :points => [metres(0, 0, height), metres(4, 0, height),
                                   metres(4, 4, height), metres(0, 4, height)],
                       :normal => Geom::Vector3d.new(*normal))
  end

  def box_faces
    [slab(0.0), slab(3.0, nil, :normal => [0, 0, 1]),
     wall(0.0, 3.0), wall(0.0, 3.0), wall(0.0, 3.0), wall(0.0, 3.0)]
  end

  def metres(x, y, z)
    Geom::Point3d.new(x / 0.0254, y / 0.0254, z / 0.0254)
  end
end
