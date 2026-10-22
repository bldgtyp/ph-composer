# frozen_string_literal: true

require_relative "test_helper"
require_relative "../src/ph_composer/features/zones/install"

# What an edge-owned record can rely on before any feature stores one (context/CONTRACTS.md,
# "Geometry records and occurrence references"): the entity store needs no Edge-specific code and its
# dictionary reaches the export snapshot, and Zones' host read answers an Edge's Faces by their own
# paths while saying nothing for the Edge's path itself.
class EdgeRecordContractTest < PhComposerTestCase
  Z = PhComposer::Zones
  DICTIONARY = "ph_composer.test_edge_record"
  ZONE_STORE = Z::ZONE_STORE

  def setup
    super
    PhComposer::Registry.install([Z]) unless PhComposer::Registry.installed?(Z::FEATURE_ID)
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
  end

  def edge(id, from, to)
    Sketchup::Edge.new(id, Geom::Point3d.new(*from), Geom::Point3d.new(*to))
  end

  def zone(id, base, children)
    group = Sketchup::Group.new(base, Sketchup::Entities.new(children))
    @model.entities << group
    ZONE_STORE.write(group,
                     "id" => id, "schema_version" => 1, "name" => "Zone #{base}",
                     "building_segment" => "Building", "level" => nil, "ground_depth_mm" => 0.0, "user_data" => {},
                     "extension_data" => {})
    group
  end

  def host_context(paths)
    request = PhComposer::HandlerRequest.for(@session, :owner => Z::FEATURE_ID, :name => "test.edge_record")
    request.query("ph_composer.zones.faces.host_context", "paths" => paths).fetch("faces")
  end

  def test_an_entity_store_round_trips_a_record_on_an_edge_and_the_snapshot_reads_it
    line = edge(30, [0, 0, 0], [100, 0, 0])
    wall = Sketchup::Face.new(31, :edges => [line])
    @model.entities << Sketchup::Group.new(10, Sketchup::Entities.new([line, wall]))
    store = PhComposer::Records::EntityStore.new(DICTIONARY)

    store.write(line, "id" => "edg_1", "schema_version" => 1, "quantity" => 2)

    assert_includes PhComposer::Dictionaries.names, DICTIONARY
    assert_equal({ "id" => "edg_1", "schema_version" => 1, "quantity" => 2 }, store.read(line))
    snapshot = PhComposer::Export::GeometrySnapshot.capture(@model, :revision => 1)
    captured = snapshot.entries.find { |entry| entry.kind == "edge" && entry.path == [10, 30] }
    assert_equal({ "id" => "edg_1", "schema_version" => 1, "quantity" => 2 }, captured.record(DICTIONARY))
    assert_equal [31], captured.geometry.face_ids
    assert_equal 2, captured.geometry.vertex_ids.uniq.length

    store.delete(line)

    assert_nil store.read(line)
    assert_nil line.attribute_dictionary(DICTIONARY)
  end

  def test_host_context_answers_an_edges_faces_by_their_paths_and_nothing_for_the_edge_itself
    line = edge(102, [0, 0, 0], [100, 0, 0])
    wall = Sketchup::Face.new(101, :edges => [line])
    floor = Sketchup::Face.new(103, :edges => [line])
    zone("zon_AAAAAAAAAAAA", 100, [wall, line, floor])
    edge_path = [100, line.persistent_id]
    face_paths = line.faces.map { |face| edge_path[0...-1] + [face.persistent_id] }

    assert_empty host_context([edge_path])
    rows = host_context(face_paths)

    assert_equal [[100, 101], [100, 103]], rows.map { |row| row.fetch("path") }
    assert_equal %w[zon_AAAAAAAAAAAA zon_AAAAAAAAAAAA], rows.map { |row| row.fetch("reference").fetch("zone_id") }
    assert_equal [nil, nil], rows.map { |row| row.fetch("write_refusal") }
  end
end
