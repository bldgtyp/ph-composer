# frozen_string_literal: true

require_relative "test_helper"

# The shared export snapshot is neutral: a contributor finds its own records and what they contain
# through generic reads, and no feature's policy lives in export. Nothing here uses a building feature.
class GeometrySnapshotTest < PhComposerTestCase
  MARKER = "ph_composer.test_snapshot.marker"

  def test_an_outside_contributor_finds_its_containers_through_the_neutral_interface
    model = Sketchup.active_model
    inner = Sketchup::Face.new(11)
    outer = Sketchup::Group.new(10, Sketchup::Entities.new([inner]))
    loose = Sketchup::Face.new(20)
    model.entities << outer << loose
    PhComposer::Records::EntityStore.new(MARKER).write(outer, "id" => "mkr_1")

    snapshot = PhComposer::Export::GeometrySnapshot.capture(model, :revision => 1)
    containers = snapshot.records(MARKER, :kind => "group")
    faces = snapshot.entries.select { |entry| entry.kind == "face" }

    assert_equal [[10]], containers.map { |entry, _record| entry.path }
    assert_equal [[10, 11]], snapshot.descendants(containers.first.first, :kind => "face").map(&:path)
    owners = faces.to_h do |face|
      [face.path, containers.select { |entry, _record| snapshot.contains?(entry, face) }.map { |_e, r| r["id"] }]
    end
    assert_equal({ [10, 11] => ["mkr_1"], [20] => [] }, owners)
  end

  def edge(id, from, to, dictionaries = {})
    Sketchup::Edge.new(id, Geom::Point3d.new(*from), Geom::Point3d.new(*to), dictionaries)
  end

  def edges(snapshot)
    snapshot.entries.select { |entry| entry.kind == "edge" }
  end

  def test_a_root_edge_is_captured_with_si_endpoints_its_ids_and_its_data
    model = Sketchup.active_model
    line = edge(30, [0, 0, 0], [100, 0, 0], MARKER => { "record" => '{"id":"tb_1"}' })
    face = Sketchup::Face.new(31)
    line.attach_face(face)
    model.entities << line << face

    captured = edges(PhComposer::Export::GeometrySnapshot.capture(model, :revision => 1)).first

    assert_equal [30], captured.path
    assert_equal({ "id" => "tb_1" }, captured.record(MARKER))
    assert_equal [[0.0, 0.0, 0.0], [2.54, 0.0, 0.0]], captured.geometry.points_m
    assert_equal [line.start.persistent_id, line.end.persistent_id], captured.geometry.vertex_ids
    assert_equal [31], captured.geometry.face_ids
  end

  def test_nested_scaled_and_reflected_edges_transform_once_and_keep_distinct_paths
    model = Sketchup.active_model
    inner = Sketchup::Group.new(41, Sketchup::Entities.new([edge(42, [0, 0, 0], [1, 0, 0])]),
                                :transformation => Geom::Transformation.scaling(-2, 1, 1))
    outer = Sketchup::Group.new(40, Sketchup::Entities.new([inner]),
                                :transformation => Geom::Transformation.translation([0, 10, 0]))
    model.entities << outer << edge(43, [0, 0, 0], [1, 0, 0])

    captured = edges(PhComposer::Export::GeometrySnapshot.capture(model, :revision => 1))

    assert_equal [[40, 41, 42], [43]], captured.map(&:path)
    nested = captured.first.geometry.points_m
    assert_in_delta(-2 * 0.0254, nested.last[0], 1e-12)
    assert_in_delta 10 * 0.0254, nested.last[1], 1e-12
  end

  def test_coincident_edges_in_separate_containers_share_no_vertex
    model = Sketchup.active_model
    left = Sketchup::Group.new(50, Sketchup::Entities.new([edge(51, [0, 0, 0], [1, 0, 0])]))
    right = Sketchup::Group.new(52, Sketchup::Entities.new([edge(53, [0, 0, 0], [1, 0, 0])]))
    model.entities << left << right

    first, second = edges(PhComposer::Export::GeometrySnapshot.capture(model, :revision => 1))

    assert_equal first.geometry.points_m, second.geometry.points_m
    assert_empty first.geometry.vertex_ids & second.geometry.vertex_ids
  end

  def test_edges_meeting_at_a_vertex_share_it_within_each_occurrence_of_a_repeated_definition
    corner = Sketchup::Vertex.new(Geom::Point3d.new(1, 0, 0))
    first = Sketchup::Edge.new(91, Geom::Point3d.new(0, 0, 0), corner)
    second = Sketchup::Edge.new(92, corner, Geom::Point3d.new(1, 1, 0))
    face = Sketchup::Face.new(93)
    first.attach_face(face)
    definition = Sketchup::ComponentDefinition.new(Sketchup::Entities.new([first, second, face]))
    model = Sketchup.active_model
    model.entities << Sketchup::ComponentInstance.new(90, definition)
    model.entities << Sketchup::ComponentInstance.new(94, definition,
                                                      :transformation => Geom::Transformation.translation([10, 0, 0]))

    captured = edges(PhComposer::Export::GeometrySnapshot.capture(model, :revision => 1))

    assert_equal [[90, 91], [90, 92], [94, 91], [94, 92]], captured.map(&:path)
    captured.each_slice(2) do |left, right|
      assert_equal left.geometry.vertex_ids.last, right.geometry.vertex_ids.first, "the corner is shared"
      assert_equal [93], left.geometry.face_ids
    end
    assert_in_delta 11 * 0.0254, captured[2].geometry.points_m.last[0], 1e-12
    assert_equal captured[0].geometry.vertex_ids, captured[2].geometry.vertex_ids,
                 "vertex ids are definition-local; the occurrence path tells copies apart"
  end

  def test_edges_inside_a_cutting_component_are_not_captured
    model = Sketchup.active_model
    definition = Sketchup::ComponentDefinition.new(Sketchup::Entities.new([edge(61, [0, 0, 0], [1, 0, 0])]))
    definition.behavior.cuts_opening = true
    model.entities << Sketchup::ComponentInstance.new(60, definition)

    assert_empty edges(PhComposer::Export::GeometrySnapshot.capture(model, :revision => 1))
  end

  def test_the_resumable_cursor_and_the_direct_capture_give_equal_edge_entries
    model = Sketchup.active_model
    model.entities << Sketchup::Group.new(70, Sketchup::Entities.new(3.times.map { |i|
      edge(71 + i, [i, 0, 0], [i, 1, 0])
    }))
    cursor = PhComposer::Export::GeometrySnapshot::Cursor.new(model)
    cursor.advance(:limit => 1) until cursor.done?

    direct = edges(PhComposer::Export::GeometrySnapshot.capture(model, :revision => 1))

    assert_equal direct.map(&:to_h), cursor.entries.select { |entry| entry.kind == "edge" }.map(&:to_h)
  end

  def test_an_edge_under_a_singular_transform_is_invalid_geometry
    model = Sketchup.active_model
    model.entities << Sketchup::Group.new(80, Sketchup::Entities.new([edge(81, [0, 0, 0], [1, 0, 0])]),
                                          :transformation => Geom::Transformation.scaling(0, 1, 1))

    error = assert_raises(PhComposer::CodedError) {
      PhComposer::Export::GeometrySnapshot.capture(model, :revision => 1)
    }
    assert_equal "geometry.invalid", error.code
  end

  # Zone and Face storage is private to the zones feature. Shared code, export included, reads it only
  # through public operations or a feature's own projection.
  def test_no_code_outside_the_zones_feature_names_its_private_stores
    root = File.expand_path("../src/ph_composer", __dir__)
    private_names = /\b(ZONE_STORE|STAMP_STORE|FACE_STORE|ZONE_DICTIONARY|STAMP_DICTIONARY|FACE_DICTIONARY)\b/
    offenders = Dir[File.join(root, "**", "*.rb")].reject { |path| path.include?("/features/zones/") }
                                                  .select { |path| File.read(path).match?(private_names) }

    assert_empty offenders.map { |path| path.delete_prefix("#{root}/") }
  end
end
