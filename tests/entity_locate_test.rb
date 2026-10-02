# frozen_string_literal: true

require_relative "test_helper"
require_relative "../src/ph_composer/features/windows/install"

# A reference target's `locate:` reached through `request.locate`, with the owner's refusals
# (context/EXTENSIBILITY.md, "Entity-owned reference targets"), and the Zones host read hosting
# features use beside it.
class EntityLocateTest < PhComposerTestCase
  W = PhComposer::Windows
  FACE_KIND = PhComposer::Zones::Faces::REFERENCE_KIND
  ZONE_STORE = PhComposer::Zones::ZONE_STORE

  def setup
    super
    PhComposer::Registry.install([W]) unless PhComposer::Registry.installed?(W::FEATURE_ID)
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
  end

  def request(owner = W::FEATURE_ID)
    PhComposer::HandlerRequest.for(@session, :owner => owner, :name => "test.locate")
  end

  def zone(id, base, children)
    group = Sketchup::Group.new(base, Sketchup::Entities.new(children))
    @model.entities << group
    ZONE_STORE.write(group, "id" => id, "schema_version" => 1, "name" => "Zone #{base}",
                            "building_segment" => "Building", "level" => nil, "ground_depth_mm" => 0.0, "user_data" => {},
                            "extension_data" => {})
    group
  end

  def reference(zone_id, path)
    { "zone_id" => zone_id, "zone_path" => path.take(1), "entity_path" => path.drop(1), "entity_id" => nil }
  end

  def refusal(zone_id, path)
    assert_raises(PhComposer::CodedError) { request.locate(FACE_KIND, reference(zone_id, path)) }.code
  end

  def test_locates_the_live_face_its_collection_transform_and_parent_path
    face = Sketchup::Face.new(102)
    wrapper = Sketchup::Group.new(101, Sketchup::Entities.new([face]))
    wrapper.transformation = Geom::Transformation.translation([1, 2, 3])
    zone("zon_AAAAAAAAAAAA", 100, [wrapper])

    located = request.locate(FACE_KIND, reference("zon_AAAAAAAAAAAA", [100, 101, 102]))

    assert_same face, located.entity
    assert_same wrapper.entities, located.entities
    assert_equal [100, 101], located.parent_path
    assert_equal wrapper.transformation.to_a, located.transform.to_a
  end

  def test_missing_ambiguous_and_locked_targets_refuse_with_the_owners_codes
    group = zone("zon_AAAAAAAAAAAA", 100, [Sketchup::Face.new(101)])
    assert_equal "target.not_found", refusal("zon_AAAAAAAAAAAA", [100, 999])
    group.locked = true
    assert_equal "target.locked", refusal("zon_AAAAAAAAAAAA", [100, 101])
    group.locked = false
    zone("zon_AAAAAAAAAAAA", 200, [Sketchup::Face.new(201)])
    assert_equal "target.ambiguous", refusal("zon_AAAAAAAAAAAA", [100, 101])
  end

  def test_a_locked_group_above_the_zone_refuses_a_write_but_not_a_read
    group = Sketchup::Group.new(100, Sketchup::Entities.new([Sketchup::Face.new(102)]))
    outer = Sketchup::Group.new(99, Sketchup::Entities.new([group]))
    @model.entities << outer
    ZONE_STORE.write(group, "id" => "zon_AAAAAAAAAAAA", "schema_version" => 1, "name" => "Zone",
                            "building_segment" => "Building", "level" => nil, "ground_depth_mm" => 0.0, "user_data" => {},
                            "extension_data" => {})
    outer.locked = true
    reference = { "zone_id" => "zon_AAAAAAAAAAAA", "zone_path" => [99, 100], "entity_path" => [102],
                  "entity_id" => nil }

    error = assert_raises(PhComposer::CodedError) { request.locate(FACE_KIND, reference) }
    assert_equal "target.locked", error.code
    assert_equal [99, 100], request.locate(FACE_KIND, reference, :mutable => false).parent_path
  end

  def test_shared_storage_cutting_component_and_cross_zone_paths_refuse
    wrapper = Sketchup::Group.new(101, Sketchup::Entities.new([Sketchup::Face.new(102)]))
    definition = Sketchup::ComponentDefinition.new(Sketchup::Entities.new([Sketchup::Face.new(104)]))
    definition.behavior.cuts_opening = true
    inner = Sketchup::Group.new(105, Sketchup::Entities.new([Sketchup::Face.new(106)]))
    group = zone("zon_AAAAAAAAAAAA", 100, [wrapper, Sketchup::ComponentInstance.new(103, definition), inner])
    ZONE_STORE.write(inner, ZONE_STORE.read(group).merge("id" => "zon_BBBBBBBBBBBB"))
    group.entities << Sketchup::Group.new(107, wrapper.entities)

    assert_equal "target.shared_definition", refusal("zon_AAAAAAAAAAAA", [100, 101, 102])
    assert_equal "target.wrong_kind", refusal("zon_AAAAAAAAAAAA", [100, 103, 104])
    assert_equal "target.wrong_hierarchy", refusal("zon_AAAAAAAAAAAA", [100, 105, 106])
  end

  def test_a_face_that_gained_a_record_after_the_read_refuses
    face = Sketchup::Face.new(101)
    zone("zon_AAAAAAAAAAAA", 100, [face])
    PhComposer::Zones::Faces::FACE_STORE.write(face, "id" => "fac_AAAAAAAAAAAA")
    assert_equal "target.changed", refusal("zon_AAAAAAAAAAAA", [100, 101])
  end

  def test_locator_requires_the_owner_a_registered_kind_and_a_declared_locate
    zone("zon_AAAAAAAAAAAA", 100, [Sketchup::Face.new(101)])
    codes = [[request("ph_composer.assemblies"), FACE_KIND], [request, "outside.missing"],
             [request, PhComposer::Zones::REFERENCE_KIND]].map do |read, kind|
      assert_raises(PhComposer::CodedError) { read.locator(kind) }.code
    end
    assert_equal %w[operation.dependency_missing reference.invalid operation.locate_missing], codes
  end

  def test_hosts_read_more_paths_than_one_host_context_page
    faces = Array.new(PhComposer::Pages::MAXIMUM_LIMIT + 1) { |index| Sketchup::Face.new(1000 + index) }
    zone("zon_AAAAAAAAAAAA", 100, faces)

    rows = W::Placement::Hosts.context(request, faces.map { |face| [100, face.persistent_id] })

    assert_equal faces.length, rows.length
  end

  def test_host_context_answers_zone_faces_by_path_and_omits_the_rest
    zone("zon_AAAAAAAAAAAA", 100, [Sketchup::Face.new(101)])
    zone("zon_AAAAAAAAAAAA", 200, [Sketchup::Face.new(201)])
    @model.entities << Sketchup::Face.new(301)

    rows = request.query("ph_composer.zones.faces.host_context", "paths" => [[100, 101], [301], [100, 999]])

    assert_equal [[100, 101]], rows.fetch("faces").map { |row| row.fetch("path") }
    row = rows.fetch("faces").first
    assert_equal reference("zon_AAAAAAAAAAAA", [100, 101]), row.fetch("reference")
    assert_equal({}, row.fetch("values"))
    refute row.key?("zone_state")
  end

  def test_a_read_phase_index_walks_the_zones_once_for_a_batch_of_locates
    faces = Array.new(3) { |index| Sketchup::Face.new(101 + index) }
    zone("zon_AAAAAAAAAAAA", 100, faces)
    read = request
    walks = 0
    scan = PhComposer::Zones::Occurrences.method(:scan_zones)
    counted = lambda do |model|
      walks += 1
      scan.call(model)
    end
    PhComposer::Zones::Occurrences.stub(:scan_zones, counted) do
      index = read.locate_index(FACE_KIND)
      located = faces.map do |face|
        read.locate(FACE_KIND, reference("zon_AAAAAAAAAAAA", [100, face.persistent_id]), :index => index)
      end
      assert_equal faces, located.map(&:entity)
    end
    assert_equal 1, walks
  end

  def test_host_context_carries_the_write_refusal_its_path_shows
    group = zone("zon_AAAAAAAAAAAA", 100, [Sketchup::Face.new(101)])
    row = -> { request.query("ph_composer.zones.faces.host_context", "paths" => [[100, 101]]).fetch("faces").first }
    assert_nil row.call.fetch("write_refusal")
    group.locked = true
    assert_equal "target.locked", row.call.fetch("write_refusal").fetch("code")
    group.locked = false
    face = Sketchup::Face.new(202)
    wrapper = Sketchup::Group.new(201, Sketchup::Entities.new([face]))
    group.entities << wrapper
    group.entities << Sketchup::Group.new(203, wrapper.entities)
    path = [100, 201, 202]
    rows = request.query("ph_composer.zones.faces.host_context", "paths" => [path]).fetch("faces")
    assert_equal refusal("zon_AAAAAAAAAAAA", path), rows.first.fetch("write_refusal").fetch("code")
  end
end
