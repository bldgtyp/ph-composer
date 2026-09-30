# frozen_string_literal: true

# P1-A native geometry investigation. Development only, never shipped.
#
# Load in a fresh synthetic Model through tools/hostkit/host_bridge.py, one action per eval:
#
#   load "<repo>/tools/spikes/geometry/geometry_spike.rb"
#   GeometrySpike.setup
#   GeometrySpike.split_face
#   GeometrySpike.explode_zone
#   GeometrySpike.restore_zone
#   GeometrySpike.report
#
# Each mutation is one native operation so the caller can inspect Undo/Redo between steps.
require "json"

module GeometrySpike
  DICT = "phc_p1a"
  REGISTRY = "phc_p1a_registry"
  ZONE_ID = "zon_p1a_restore"
  FACE_ID = "fac_p1a_split"

  class << self
    def model
      Sketchup.active_model
    end

    def setup
      operation("P1-A geometry setup") do
        clear_named_fixtures
        registry = {}
        registry["make_zone"] = make_zone_fixture
        registry["split"] = split_fixture
        registry["restore"] = restore_fixture
        registry["transforms"] = transform_fixture
        registry["closure"] = closure_fixture
        registry["tolerances"] = tolerance_fixtures
        model.set_attribute(REGISTRY, "setup", JSON.generate(registry))
      end
      report
    end

    def split_face
      group = named_group("p1a_split")
      before = split_faces(group).map(&:persistent_id)
      operation("P1-A split face") do
        group.entities.add_line([2000.mm, 0, 0], [2000.mm, 3000.mm, 0])
      end
      { "before_pids" => before, "after" => split_state }
    end

    def explode_zone
      group = named_group("p1a_restore")
      before = restore_state
      operation("P1-A explode Zone") { group.explode }
      { "before" => before, "after" => restore_state }
    end

    def restore_zone
      faces = stamped_restore_faces
      raise "No unambiguous stamped faces are available." if faces.empty?

      zone_ids = faces.map { |face| face.get_attribute(DICT, "zone_id") }.uniq
      raise "Conflicting Zone stamps: #{zone_ids.inspect}" unless zone_ids == [ZONE_ID]

      parents = faces.map(&:parent).uniq
      raise "Stamped faces do not share one parent context." unless parents.length == 1

      members = faces.flat_map { |face| [face] + face.edges }.uniq
      operation("P1-A restore Zone") do
        restored = model.entities.add_group(members)
        restored.name = "p1a_restore"
        restored.set_attribute(DICT, "zone_id", ZONE_ID)
        restored.set_attribute(DICT, "restored", true)
      end
      restore_state
    end

    def report
      {
        "host" => host_state,
        "make_zone" => make_zone_state,
        "split" => split_state,
        "restore" => restore_state,
        "transforms" => transform_state,
        "closure" => closure_state,
        "tolerances" => tolerance_state
      }
    end

    private

    def operation(name)
      model.start_operation(name, true)
      result = yield
      raise "SketchUp refused to commit #{name}." unless model.commit_operation

      result
    rescue StandardError
      model.abort_operation
      raise
    end

    def clear_named_fixtures
      fixtures = model.entities.grep(Sketchup::Group).select { |group| group.name.start_with?("p1a_") }
      model.entities.erase_entities(fixtures) unless fixtures.empty?
      dictionary = model.attribute_dictionary(REGISTRY)
      dictionary.delete_key("setup") if dictionary
    end

    def make_zone_fixture
      before = model.entities.to_a
      floor = model.entities.add_face([0, 0, 0], [0, 4000.mm, 0], [5000.mm, 4000.mm, 0], [5000.mm, 0, 0])
      floor.reverse! if floor.normal.z.positive?
      floor.pushpull(-3000.mm)
      created = model.entities.to_a - before
      faces = created.grep(Sketchup::Face)
      faces.each_with_index do |face, index|
        face.set_attribute(DICT, "zone_id", "zon_p1a_make")
        face.set_attribute(DICT, "face_index", index)
      end
      pids = created.map(&:persistent_id)
      group = model.entities.add_group(created)
      group.name = "p1a_make_zone"
      group.set_attribute(DICT, "zone_id", "zon_p1a_make")
      { "member_pids_before_group" => pids, "group_pid" => group.persistent_id }
    end

    def split_fixture
      group = model.entities.add_group
      group.name = "p1a_split"
      face = group.entities.add_face([0, 0, 0], [4000.mm, 0, 0], [4000.mm, 3000.mm, 0], [0, 3000.mm, 0])
      face.set_attribute(DICT, "face_id", FACE_ID)
      face.set_attribute(DICT, "payload", JSON.generate("example.ns" => { "note" => "preserve" }))

      inner = group.entities.add_face(
        [500.mm, 800.mm, 0], [1200.mm, 800.mm, 0], [1200.mm, 1800.mm, 0], [500.mm, 1800.mm, 0]
      )
      group.entities.erase_entities(inner)
      { "face_pid" => face.persistent_id, "loops" => face.loops.length }
    end

    def restore_fixture
      group = box(model.entities, "p1a_restore", [7000.mm, 0, 0])
      group.set_attribute(DICT, "zone_id", ZONE_ID)
      group.set_attribute(DICT, "zone_name", "Lost with group")
      group.entities.grep(Sketchup::Face).each_with_index do |face, index|
        face.set_attribute(DICT, "zone_id", ZONE_ID)
        face.set_attribute(DICT, "face_id", "fac_restore_#{index}")
        face.set_attribute(DICT, "payload", JSON.generate("example.ns" => { "rank" => index }))
      end
      { "group_pid" => group.persistent_id, "face_pids" => group.entities.grep(Sketchup::Face).map(&:persistent_id) }
    end

    def transform_fixture
      parent = model.entities.add_group
      parent.name = "p1a_transform_parent"
      transform = Geom::Transformation.new([14_000.mm, 0, 0]) *
                  Geom::Transformation.rotation(ORIGIN, Z_AXIS, 30.degrees) *
                  Geom::Transformation.scaling(-1.0, 1.5, 0.75)
      parent.transformation = transform
      zone = box(parent.entities, "p1a_transform_zone", [0, 0, 0])
      face = zone.entities.grep(Sketchup::Face).find { |candidate| candidate.normal.z.abs > 0.99 }
      {
        "parent_pid" => parent.persistent_id,
        "zone_pid" => zone.persistent_id,
        "face_pid" => face.persistent_id
      }
    end

    def closure_fixture
      closed = box(model.entities, "p1a_closed", [0, 7000.mm, 0])
      open = box(model.entities, "p1a_open", [7000.mm, 7000.mm, 0])
      roof = open.entities.grep(Sketchup::Face).find { |face| face.normal.z.positive? }
      open.entities.erase_entities(roof)
      { "closed_pid" => closed.persistent_id, "open_pid" => open.persistent_id }
    end

    def tolerance_fixtures
      deltas_mm = [0.0001, 0.001, 0.005, 0.01, 0.02, 0.025, 0.0254, 0.0255, 0.026, 0.05, 0.1, 1.0]
      deltas_mm.to_h do |delta_mm|
        group = model.entities.add_group
        group.name = "p1a_tolerance_#{delta_mm}"
        first = group.entities.add_line([0, 0, 0], [1000.mm, 0, 0])
        second = group.entities.add_line([(1000.0 + delta_mm).mm, 0, 0], [2000.mm, 0, 0])
        [delta_mm.to_s, { "first_pid" => first.persistent_id, "second_pid" => second.persistent_id }]
      end
    end

    def box(entities, name, origin)
      group = entities.add_group
      group.name = name
      group.transformation = Geom::Transformation.new(origin)
      floor = group.entities.add_face([0, 0, 0], [0, 4000.mm, 0], [5000.mm, 4000.mm, 0], [5000.mm, 0, 0])
      floor.reverse! if floor.normal.z.positive?
      floor.pushpull(-3000.mm)
      group
    end

    def named_group(name)
      model.entities.grep(Sketchup::Group).find { |group| group.name == name }
    end

    def make_zone_state
      group = named_group("p1a_make_zone")
      return { "state" => "missing" } unless group

      setup = setup_registry.fetch("make_zone", {})
      member_pids = group.entities.to_a.map(&:persistent_id)
      {
        "state" => "grouped",
        "group_pid" => group.persistent_id,
        "manifold" => group.manifold?,
        "member_pids_preserved" => setup.fetch("member_pids_before_group", []).sort == member_pids.sort,
        "tagged_faces" => group.entities.grep(Sketchup::Face).count do |face|
          face.get_attribute(DICT, "zone_id") == "zon_p1a_make"
        end
      }
    end

    def split_faces(group)
      group.entities.grep(Sketchup::Face).select do |face|
        face.normal.z.abs > 0.99 && face.bounds.center.z.abs < 0.001
      end
    end

    def split_state
      group = named_group("p1a_split")
      return { "state" => "missing" } unless group

      original_pid = setup_registry.dig("split", "face_pid")
      faces = split_faces(group)
      {
        "face_count" => faces.length,
        "faces" => faces.sort_by(&:persistent_id).map do |face|
          {
            "pid" => face.persistent_id,
            "original_pid" => face.persistent_id == original_pid,
            "area_m2" => (face.area.to_f / 1.m.to_f**2).round(6),
            "loops" => face.loops.length,
            "face_id" => face.get_attribute(DICT, "face_id"),
            "payload" => face.get_attribute(DICT, "payload")
          }
        end,
        "original_target_class" => target_class(original_pid)
      }
    end

    def stamped_restore_faces
      all_root_faces.select { |face| face.get_attribute(DICT, "zone_id") == ZONE_ID }
    end

    def all_root_faces
      model.entities.grep(Sketchup::Face)
    end

    def restore_state
      group = named_group("p1a_restore")
      if group
        faces = group.entities.grep(Sketchup::Face)
        return {
          "state" => group.get_attribute(DICT, "restored") ? "restored" : "grouped",
          "group_pid" => group.persistent_id,
          "manifold" => group.manifold?,
          "zone_id" => group.get_attribute(DICT, "zone_id"),
          "zone_name" => group.get_attribute(DICT, "zone_name"),
          "faces" => restore_face_state(faces)
        }
      end

      faces = stamped_restore_faces
      {
        "state" => faces.empty? ? "missing" : "exploded",
        "one_parent" => faces.map(&:parent).uniq.length == 1,
        "faces" => restore_face_state(faces),
        "old_group_target_class" => target_class(setup_registry.dig("restore", "group_pid"))
      }
    end

    def restore_face_state(faces)
      faces.sort_by(&:persistent_id).map do |face|
        {
          "pid" => face.persistent_id,
          "zone_id" => face.get_attribute(DICT, "zone_id"),
          "face_id" => face.get_attribute(DICT, "face_id"),
          "payload" => face.get_attribute(DICT, "payload")
        }
      end
    end

    def transform_state
      parent = named_group("p1a_transform_parent")
      return { "state" => "missing" } unless parent

      zone = parent.entities.grep(Sketchup::Group).find { |group| group.name == "p1a_transform_zone" }
      face = zone.entities.grep(Sketchup::Face).find do |candidate|
        candidate.persistent_id == setup_registry.dig("transforms", "face_pid")
      end
      world = parent.transformation * zone.transformation
      points = face.outer_loop.vertices.map { |vertex| vertex.position.transform(world) }
      {
        "path" => [parent.persistent_id, zone.persistent_id, face.persistent_id],
        "world_points_mm" => points.map { |point| point.to_a.map { |value| value.to_mm.round(6) } },
        "mirrored" => world.xaxis.cross(world.yaxis).dot(world.zaxis).negative?,
        "scale" => [world.xscale, world.yscale, world.zscale].map { |value| value.round(6) },
        "manifold" => zone.manifold?
      }
    end

    def tolerance_state
      setup_registry.fetch("tolerances", {}).to_h do |delta_mm, pids|
        first = model.find_entity_by_persistent_id(pids.fetch("first_pid"))
        second = model.find_entity_by_persistent_id(pids.fetch("second_pid"))
        distance = first && second ? first.end.position.distance(second.start.position).to_mm : nil
        same_vertex = first && second ? first.end.equal?(second.start) : nil
        [delta_mm, { "same_vertex" => same_vertex, "distance_mm" => distance&.round(9) }]
      end
    end

    def closure_state
      %w[p1a_closed p1a_open].to_h do |name|
        group = named_group(name)
        state = { "manifold" => group&.manifold?, "faces" => group&.entities&.grep(Sketchup::Face)&.length }
        [name.delete_prefix("p1a_"), state]
      end
    end

    def target_class(pid)
      return "none" unless pid

      entity = model.find_entity_by_persistent_id(pid)
      entity ? entity.class.name : "missing"
    end

    def setup_registry
      JSON.parse(model.get_attribute(REGISTRY, "setup", "{}"))
    end

    def host_state
      {
        "sketchup" => Sketchup.version,
        "ruby" => RUBY_VERSION,
        "platform" => Sketchup.platform.to_s,
        "model_path" => File.basename(model.path.to_s),
        "modified" => model.modified?
      }
    end
  end
end
