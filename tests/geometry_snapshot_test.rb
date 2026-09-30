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

  # R-D1 and SNAP: Zone and Face storage is private to the zones feature. Shared code, export
  # included, reads it only through public operations or a feature's own projection.
  def test_no_code_outside_the_zones_feature_names_its_private_stores
    root = File.expand_path("../src/ph_composer", __dir__)
    private_names = /\b(ZONE_STORE|STAMP_STORE|FACE_STORE|ZONE_DICTIONARY|STAMP_DICTIONARY|FACE_DICTIONARY)\b/
    offenders = Dir[File.join(root, "**", "*.rb")].reject { |path| path.include?("/features/zones/") }
                                                  .select { |path| File.read(path).match?(private_names) }

    assert_empty offenders.map { |path| path.delete_prefix("#{root}/") }
  end
end
