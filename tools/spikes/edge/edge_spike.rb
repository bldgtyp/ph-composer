# frozen_string_literal: true

# B4 spike: edge identity (planning/archive/phase-zero/phases/phase-01-investigations.md). Development only,
# never shipped. Loaded into SketchUp through the development bridge after the B3 spike file:
#
#   load "<repo>/tools/spikes/window/window_spike.rb"
#   load "<repo>/tools/spikes/edge/edge_spike.rb"
#   EdgeSpike.setup                 # tagged edges in five situations, plus a Model-level registry
#   EdgeSpike.run(:split)           # one operation, then an observer-free scan against the registry
#   EdgeSpike.scan                  # classify every assignment: kept, replaced, split, duplicated, lost
#
# Tags are synthetic: a type id, an assignment id and a namespaced JSON payload on each edge. The registry
# is what a feature record would hold: assignment id to the edge persistent ids it was made on.
require "json"

module EdgeSpike
  DICT = "phc_edge"
  REGISTRY = "phc_edge_registry"

  class << self
    def model
      Sketchup.active_model
    end

    def setup
      operation("B4 setup") do
        zone = box
        tag(zone.entities.grep(Sketchup::Edge).find { |e| south_bottom?(e) }, "asg_wall_base", "b4_type_base")
        runs = group("runs", [0, 6000.mm, 0])
        chain = [[0, 0, 0], [1000.mm, 0, 0], [2000.mm, 500.mm, 0], [3000.mm, 500.mm, 0]]
        chain.each_cons(2) { |a, b| tag(runs.entities.add_line(a, b), "asg_run", "b4_type_run") }
        loose = group("loose", [0, 9000.mm, 0])
        tag(loose.entities.add_line([0, 0, 0], [1500.mm, 0, 0]), "asg_loose_1", "b4_type_loose")
        tag(loose.entities.add_line([0, 500.mm, 0], [1500.mm, 500.mm, 0]), "asg_loose_2", "b4_type_loose")
        components
      end
      register
      scan
    end

    OPERATIONS = {
      :split => ->(s) { s.edge("asg_wall_base").split(0.5) },
      :weld => ->(s) { s.container("runs").entities.weld(s.edges("asg_run")) },
      :move => lambda { |s|
        lift = Geom::Transformation.new([0, 0, 300.mm])
        s.container("loose").entities.transform_entities(lift, s.edge("asg_loose_1"))
      },
      :pushpull => ->(s) { s.south_wall.pushpull(-200.mm) },
      :window_cut => ->(s) { s.place_window },
      :window_explode => ->(s) { s.window_unit.explode }
    }.freeze

    def run(name)
      operation("B4 #{name}") { OPERATIONS.fetch(name).call(self) }
      scan
    end

    # Every tagged edge where it is now: persistent id, container path, world endpoints, length, tags.
    def snapshot
      found = []
      walk(model.entities, [], Geom::Transformation.new, found)
      found.sort_by { |e| [e["assignment_id"], e["path"], e["pid"]] }
    end

    # Classifies each registered assignment from a scan alone, with no observer.
    def scan
      now = snapshot
      registry = JSON.parse(model.get_attribute(REGISTRY, "assignments", "{}"))
      registry.to_h do |id, pids|
        found = now.select { |e| e["assignment_id"] == id }
        edges = found.map { |e| e.slice("pid", "path", "length_mm", "start", "end") }
        targets = pids.map { |pid| target(pid, id) }
        [id, classify(pids, found).merge("edges" => edges, "registry_targets" => targets)]
      end
    end

    def edges(id, entities = nil)
      (entities || all_entities).grep(Sketchup::Edge).select { |e| e.get_attribute(DICT, "assignment_id") == id }
    end

    def edge(id)
      edges(id).first
    end

    def container(name)
      model.entities.grep(Sketchup::Group).find { |g| g.name == name }
    end

    def south_wall
      container("zone").entities.grep(Sketchup::Face).find { |f| f.normal.y < -0.99 }
    end

    # A B3 unit whose sill sits on the tagged base edge.
    def place_window
      zone = container("zone")
      definition = WindowSpike.define(1)
      wall = south_wall.vertices.first.position.y
      axes = Geom::Transformation.axes(Geom::Point3d.new(1000.mm, wall, 0), X_AXIS, Z_AXIS, Y_AXIS.reverse)
      unit = zone.entities.add_instance(definition, axes)
      unit.name = "b4_window"
      unit.glued_to = south_wall
    end

    def window_unit
      container("zone").entities.grep(Sketchup::ComponentInstance).find { |i| i.name == "b4_window" }
    end

    private

    def operation(name)
      model.start_operation(name, true)
      yield
      model.commit_operation
    rescue StandardError
      model.abort_operation
      raise
    end

    def tag(edge, assignment_id, type_id)
      edge.set_attribute(DICT, "type_id", type_id)
      edge.set_attribute(DICT, "assignment_id", assignment_id)
      edge.set_attribute(DICT, "payload", JSON.generate("example.ns" => { "note" => assignment_id, "rank" => 1 }))
      edge
    end

    def box
      zone = group("zone", [0, 0, 0])
      floor = zone.entities.add_face([0, 0, 0], [0, 4000.mm, 0], [5000.mm, 4000.mm, 0], [5000.mm, 0, 0])
      floor.reverse! if floor.normal.z.positive?
      floor.pushpull(-3000.mm)
      zone
    end

    def south_bottom?(edge)
      edge.start.position.y.abs < 0.001 && edge.end.position.y.abs < 0.001 &&
        edge.start.position.z.abs < 0.001 && edge.end.position.z.abs < 0.001
    end

    def group(name, origin)
      created = model.entities.add_group
      created.name = name
      created.transformation = Geom::Transformation.new(origin)
      created
    end

    # A two-edge run in one definition, placed twice inside a `systems` group: nested and repeated.
    def components
      definition = model.definitions.add("b4_pipe")
      a = definition.entities.add_line([0, 0, 0], [800.mm, 0, 0])
      b = definition.entities.add_line([800.mm, 0, 0], [800.mm, 600.mm, 0])
      tag(a, "asg_pipe", "b4_type_pipe")
      tag(b, "asg_pipe", "b4_type_pipe")
      systems = group("systems", [7000.mm, 6000.mm, 0])
      systems.entities.add_instance(definition, Geom::Transformation.new([0, 0, 0]))
      systems.entities.add_instance(definition, Geom::Transformation.new([0, 2000.mm, 0]))
    end

    def register
      grouped = snapshot.group_by { |e| e["assignment_id"] }
      assignments = grouped.transform_values { |list| list.map { |e| e["pid"] }.uniq }
      operation("B4 register") { model.set_attribute(REGISTRY, "assignments", JSON.generate(assignments)) }
    end

    def all_entities(entities = model.entities, found = [])
      entities.each do |entity|
        found << entity
        nested = entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
        all_entities(entity.definition.entities, found) if nested
      end
      found.uniq
    end

    def walk(entities, path, transformation, found)
      entities.each do |entity|
        case entity
        when Sketchup::Edge then record(entity, path, transformation, found)
        when Sketchup::Group, Sketchup::ComponentInstance
          walk(entity.definition.entities, path + [entity.persistent_id], transformation * entity.transformation, found)
        end
      end
    end

    def record(edge, path, transformation, found)
      id = edge.get_attribute(DICT, "assignment_id")
      return unless id

      found << {
        "assignment_id" => id, "pid" => edge.persistent_id, "path" => path,
        "start" => edge.start.position.transform(transformation).to_a.map { |v| v.to_mm.round(1) },
        "end" => edge.end.position.transform(transformation).to_a.map { |v| v.to_mm.round(1) },
        "length_mm" => edge.length.to_mm.round(1), "attributes" => edge.attribute_dictionary(DICT).to_h
      }
    end

    def classify(registered, found)
      pids = found.map { |e| e["pid"] }.uniq
      occurrences = found.map { |e| [e["pid"], e["path"]] }.uniq.length
      state =
        if found.empty? then "lost"
        elsif pids.sort == registered.sort
          occurrences > pids.length ? "kept, shared by #{occurrences} occurrences" : "kept"
        elsif (pids & registered).empty? then "replaced"
        else "split or extended"
        end
      { "state" => state, "registered" => registered.length, "edges_now" => pids.length,
        "total_length_mm" => found.uniq { |e| e["pid"] }.sum { |e| e["length_mm"] }.round(1),
        "attributes_intact" => found.all? { |e| e["attributes"]["assignment_id"] && e["attributes"]["payload"] } }
    end

    def target(pid, id)
      entity = model.find_entity_by_persistent_id(pid)
      return "missing" unless entity
      return "wrong kind #{entity.class}" unless entity.is_a?(Sketchup::Edge)

      entity.get_attribute(DICT, "assignment_id") == id ? "resolves" : "resolves to an edge without this assignment"
    end
  end
end
