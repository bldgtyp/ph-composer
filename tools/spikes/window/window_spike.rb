# frozen_string_literal: true

# B3 spike: a flat cutting window component (planning/archive/phase-00-foundation/phases/phase-01-investigations.md).
# Development only, never shipped. Loaded into SketchUp through the development bridge, one step per eval:
#
#   load "<repo>/tools/spikes/window/window_spike.rb"
#   WindowSpike.setup                        # a Zone-like group, nested in a parent group, and its walls
#   WindowSpike.place_all                    # direct, repeated, nested and mirrored placements
#   WindowSpike.report                       # host face loops and areas, glue, anchors, transformations
#
# Every Model change is one operation, so native Undo takes each back as one step.
module WindowSpike
  TYPE_ID = "b3_window_type"
  W = 1000.mm
  H = 1200.mm

  class << self
    def model
      Sketchup.active_model
    end

    # Two Zone-like boxes of 5 x 4 x 3 m: `zone_a` at the top level and `zone_b` inside a parent group.
    def setup
      operation("B3 setup") do
        @zone_a = box(model.entities, "zone_a", [0, 0, 0])
        parent = model.entities.add_group
        parent.name = "parent"
        parent.transformation = Geom::Transformation.new([8000.mm, 0, 0])
        @zone_b = box(parent.entities, "zone_b", [0, 0, 0])
        @definition = define(2)
      end
      report
    end

    # The type's definition: one face per glazed element in its own XY plane, glue to any face, cut an
    # opening, refuse every scale handle.
    def define(elements)
      definition = model.definitions[TYPE_ID] || model.definitions.add(TYPE_ID)
      definition.entities.clear!
      elements.times do |index|
        x = index * (W + 50.mm)
        definition.entities.add_face([x, 0, 0], [x + W, 0, 0], [x + W, H, 0], [x, H, 0])
      end
      behavior = definition.behavior
      behavior.is2d = true
      behavior.cuts_opening = true
      behavior.snapto = SnapTo_Arbitrary
      behavior.no_scale_mask = 127
      definition.set_attribute("phc_spike", "window_type_id", TYPE_ID)
      definition
    end

    def place_all
      operation("B3 place") do
        place(@zone_a, 500.mm, 900.mm, "direct")
        place(@zone_a, 2700.mm, 900.mm, "repeated")
        place(@zone_b, 500.mm, 900.mm, "nested")
        place(@zone_b, 4700.mm, 900.mm, "mirrored", :mirror => true)
      end
      report
    end

    # Rewrites the definition to three elements: every instance changes, as a type edit would.
    def rewrite
      operation("B3 rewrite definition") { define(3) }
      report
    end

    # Programmatic scaling of one instance despite `no_scale_mask`.
    def scale_one
      operation("B3 scale") do
        unit = units.find { |u| u.name == "repeated" }
        unit.transform!(Geom::Transformation.scaling(unit.transformation.origin, 1.5, 1.0, 1.0))
      end
      report
    end

    # Splits `zone_a`'s south wall with a vertical line between the two units, as an adjacency split would.
    def split_host
      operation("B3 split host face") do
        @zone_a.entities.add_line([2625.mm, 0, 0], [2625.mm, 0, 3000.mm])
      end
      report
    end

    def explode_one
      operation("B3 explode") { units.find { |u| u.name == "direct" }.explode }
      report
    end

    def report
      {
        "units" => units.map { |unit| unit_state(unit) },
        "south_faces" => [@zone_a, @zone_b].compact.to_h { |zone| [zone.name, south_faces(zone)] },
        "definition" => definition_state,
        "undo_modified" => model.modified?
      }
    end

    def units
      [@zone_a, @zone_b].compact.select(&:valid?).flat_map do |zone|
        zone.entities.grep(Sketchup::ComponentInstance).select { |i| i.definition.name == TYPE_ID }
      end
    end

    # Rebinds the zones after Undo, Redo or a reopen, when the held references may be stale.
    def rebind
      @zone_a = model.entities.grep(Sketchup::Group).find { |g| g.name == "zone_a" }
      parent = model.entities.grep(Sketchup::Group).find { |g| g.name == "parent" }
      @zone_b = parent&.entities&.grep(Sketchup::Group)&.find { |g| g.name == "zone_b" }
      @definition = model.definitions[TYPE_ID]
      report
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

    def box(entities, name, origin)
      zone = entities.add_group
      zone.name = name
      zone.transformation = Geom::Transformation.new(origin)
      floor = zone.entities.add_face([0, 0, 0], [0, 4000.mm, 0], [5000.mm, 4000.mm, 0], [5000.mm, 0, 0])
      floor.reverse! if floor.normal.z.positive?
      floor.pushpull(-3000.mm)
      zone
    end

    # Adds an instance in the host face's own context, axes in the face plane, and glues it there.
    def place(zone, x, sill, name, mirror: false)
      face = south_face_at(zone, mirror ? x - W / 2 : x + W / 2)
      axes = Geom::Transformation.axes(Geom::Point3d.new(x, 0, sill), X_AXIS, Z_AXIS, face.normal)
      axes *= Geom::Transformation.scaling(-1, 1, 1) if mirror
      unit = zone.entities.add_instance(@definition, axes)
      unit.name = name
      unit.glued_to = face
      unit
    end

    def south_faces(zone)
      zone.entities.grep(Sketchup::Face).select { |f| f.normal.y < -0.99 }.map do |face|
        { "loops" => face.loops.length, "area_m2" => (face.area * 0.00064516).round(4),
          "outer_area_m2" => outer_area(face).round(4),
          "pid" => face.persistent_id }
      end
    end

    def outer_area(face)
      points = face.outer_loop.vertices.map(&:position)
      normal = face.normal
      sum = Geom::Vector3d.new(0, 0, 0)
      points.each_with_index do |point, index|
        following = points[(index + 1) % points.length]
        sum += Geom::Vector3d.new(point.to_a) * Geom::Vector3d.new(following.to_a)
      end
      (sum % normal).abs / 2 * 0.00064516
    end

    def south_face_at(zone, x)
      zone.entities.grep(Sketchup::Face).find do |face|
        face.normal.y < -0.99 && face.classify_point([x, 0, 1500.mm]) == Sketchup::Face::PointInside
      end
    end

    def unit_state(unit)
      t = unit.transformation
      {
        "name" => unit.name, "glued_to" => unit.glued_to&.persistent_id,
        "origin_mm" => t.origin.to_a.map { |v| v.to_mm.round(1) },
        "x_axis" => t.xaxis.to_a.map { |v| v.round(3) }, "scale_x" => t.xscale.round(3),
        "determinant_sign" => (t.xaxis * t.yaxis) % t.zaxis >= 0 ? 1 : -1,
        "pid" => unit.persistent_id
      }
    end

    def definition_state
      d = model.definitions[TYPE_ID]
      return nil unless d

      b = d.behavior
      { "faces" => d.entities.grep(Sketchup::Face).length, "instances" => d.instances.length,
        "is2d" => b.is2d?, "cuts_opening" => b.cuts_opening?, "no_scale_mask" => b.no_scale_mask? }
    end
  end
end
