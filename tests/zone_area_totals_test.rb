# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/assembly_assignment_fixtures"

# Each Zone occurrence publishes its Face area, whole and unclassified, so the panel never sums Faces
# itself: the same Faces the Face rows list, each through its own occurrence's transform.
class ZoneAreaTotalsTest < PhComposerTestCase
  include AssemblyAssignmentFixtures

  ZONE_PREFIX = "ph_composer.zones"

  def setup
    super
    assignment_setup
  end

  def zones
    assignment_query("#{ZONE_PREFIX}.all").fetch("zones")
  end

  def faces_of(zone)
    assignment_faces.select { |face| face.dig("reference", "zone_path") == zone.dig("reference", "zone_path") }
  end

  # A second placement of a Zone's Group, sharing its Faces, as a native copy is.
  def placed_copy(group, id, transformation)
    dictionaries = {}
    group.attribute_dictionaries.each do |dictionary|
      values = {}
      dictionary.each { |key, value| values[key] = value }
      dictionaries[dictionary.name] = values
    end
    copy = Sketchup::Group.new(id, group.entities, dictionaries, :transformation => transformation)
    @model.entities << copy
    copy
  end

  def test_totals_sum_the_faces_rows_and_split_out_the_unclassified_ones
    assignment_zone(100, 3)
    classified = assignment_faces.first(1)
    assignment_classify(classified, "face_type" => { "mode" => "set", "value" => "Floor" })
    zone = zones.first
    rows = faces_of(zone)
    assert_in_delta rows.sum { |face| face.fetch("area_m2") }, zone.fetch("face_area_m2"), 1e-12
    assert_in_delta rows.select { |face| face.fetch("state") == "unclassified" }.sum { |face| face.fetch("area_m2") },
                    zone.fetch("unclassified_face_area_m2"), 1e-12
    assert_operator zone.fetch("unclassified_face_area_m2"), :<, zone.fetch("face_area_m2")
    assert_equal({ "ground_depth_mm" => "mm", "face_area_m2" => "m2", "unclassified_face_area_m2" => "m2" },
                 assignment_query("#{ZONE_PREFIX}.all").fetch("units"))
  end

  def test_a_zone_with_no_faces_totals_zero
    group, faces = assignment_zone(200, 1)
    faces.each { |face| group.entities.erase_entities(face) }
    zone = zones.first
    assert_equal [0, 0.0, 0.0], zone.values_at("face_count", "face_area_m2", "unclassified_face_area_m2")
  end

  def test_each_placement_of_a_shared_zone_totals_through_its_own_transform
    group, = assignment_zone(300, 2)
    placed_copy(group, 350, Geom::Transformation.scaling(2, 2, 1))
    placed_copy(group, 360, Geom::Transformation.scaling(-1, 1, 1))
    treat_duplicates_as_existing
    totals = zones.to_h { |zone| [zone.dig("reference", "zone_path"), zone.fetch("face_area_m2")] }
    assert_equal 3, totals.length, "three path-qualified occurrences"
    original, scaled, mirrored = totals.values_at([group.persistent_id], [350], [360])
    assert_in_delta 4 * original, scaled, 1e-9
    assert_in_delta original, mirrored, 1e-9
    zones.each do |zone|
      assert_in_delta faces_of(zone).sum { |face| face.fetch("area_m2") }, zone.fetch("face_area_m2"), 1e-9
    end
  end

  def test_an_unreadable_face_or_a_singular_transform_refuses_the_zone_read_with_the_face_reads_codes
    group, faces = assignment_zone(400, 1)
    PhComposer::Zones::Faces::FACE_STORE.write(faces.first, "id" => "fac_Ab12Cd34Ef56", "schema_version" => 1,
                                                            "face_type" => "Doorway")
    result = API.query(:context => @context, :name => "#{ZONE_PREFIX}.all")
    assert_equal "validation.failed", result.fetch("code"), result.inspect
    assert_equal result.fetch("code"), API.query(:context => @context, :name => "#{FACE_PREFIX}.all").fetch("code")

    PhComposer::Zones::Faces::FACE_STORE.delete(faces.first)
    group.transformation = Geom::Transformation.scaling(0, 1, 1)
    result = API.query(:context => @context, :name => "#{ZONE_PREFIX}.all")
    assert_equal "geometry.invalid", result.fetch("code"), result.inspect
  end
end
