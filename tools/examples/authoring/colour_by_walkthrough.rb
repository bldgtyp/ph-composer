# frozen_string_literal: true

# P1-D D5's fresh-host walkthrough: what the shared Colour-by service does on a real SketchUp.
#
# B2 measured that a filled overlay is affordable and behaves correctly (occlusion, alpha, picking).
# This measures the feature built on it, which B2 did not have: the cache, its invalidation and the
# HUD. Questions it has to answer, because the implementation assumes all of them:
#
#   1. Does `Face#mesh` triangulate a concave and a holed Face the way the fill needs? The offline
#      stub fans the outer loop, which is right only for a convex outline.
#   2. Does `Sketchup::LayersObserver#onLayerChanged` fire when a tag's visibility is toggled?
#      Measured on SketchUp 2026; repeat when proving another host.
#   3. Does activating a scene invalidate the drawing? Scene tag visibility reaches the layer observer
#      on SketchUp 2026. Record other scene state separately.
#   4. Does the Model come through unchanged: materials, attribute dictionaries and Undo stack?
#   5. What does a rebuild plus a frame cost on a Model of real size?
#   6. Does the HUD legend draw legibly, and does the overlay leave with its Model?
#   7. What does SketchUp's own Overlays panel do to a mode the user unticks there?
module ColourByWalkthrough
  API = PhComposer::API
  PREFIX = "p1d_colour_"
  MODE = "ph_composer.zones.faces.by_face_type"

  module_function

  # Two boxes, one Zone each, auto-classified so the legend has more than one row, including
  # one Face with a hole for question 1. A concave fixture is a separate gate setup.
  def setup
    model = Sketchup.active_model
    model.start_operation("P1-D Colour-by walkthrough geometry", true)
    model.entities.erase_entities(zone_groups) unless zone_groups.empty?
    box(model.entities, "#{PREFIX}west", [0, 0, 0], 5000.mm, 4000.mm)
    east = box(model.entities, "#{PREFIX}east", [6000.mm, 0, 0], 4000.mm, 4000.mm)
    punch(east)
    raise "SketchUp refused the walkthrough geometry." unless model.commit_operation

    author
  end

  def author
    client = Client.new
    zone_groups.each do |group|
      target = { "parent_path" => [], "entity_ids" => [group.persistent_id],
                 "name" => group.name.sub(PREFIX, "") }
      preview = client.preview("ph_composer.zones.make", target)
      client.invoke("ph_composer.zones.make", target, preview.fetch("proposal_digest"))
    end
    client.query("ph_composer.zones.all").dig("value", "zones").each do |zone|
      client.invoke("ph_composer.zones.faces.auto_classify", { "zone" => zone.fetch("reference") })
    end
    fingerprint
  end

  # Everything the Model must come back with unchanged (question 4).
  def fingerprint
    model = Sketchup.active_model
    @fingerprint = {
      "entities" => model.entities.to_a.length,
      "materials" => model.materials.map(&:name).sort,
      "dictionaries" => model.entities.grep(Sketchup::Group).sum do |group|
        group.entities.to_a.sum { |entity| Array(entity.attribute_dictionaries).length }
      end,
      "modified" => model.modified?
    }
  end

  def on(mode = MODE)
    service.activate(mode)
    report
  end

  def off
    service.deactivate
    report
  end

  # The legend, the batching and what the Model looks like now. Compare `fingerprint_now` with the
  # one taken before: the whole of it must be equal.
  def report
    {
      "mode" => service.mode_name,
      "rows" => service.rows.map { |row| [row.label, row.count, row.state.to_s, row.colour] },
      "fill_batches" => service.fills.map { |colour, points| [colour, points.length / 3] },
      "unclassified_segments" => service.unclassified_outlines.length / 2,
      "overlays" => Sketchup.active_model.overlays.map(&:overlay_id),
      "fingerprint_before" => @fingerprint,
      "fingerprint_now" => fingerprint_now
    }
  end

  def fingerprint_now
    model = Sketchup.active_model
    {
      "entities" => model.entities.to_a.length,
      "materials" => model.materials.map(&:name).sort,
      "dictionaries" => model.entities.grep(Sketchup::Group).sum do |group|
        group.entities.to_a.sum { |entity| Array(entity.attribute_dictionaries).length }
      end,
      "modified" => model.modified?
    }
  end

  # Question 1: what the host makes of the holed Face and of a concave one. `triangles` is what the
  # fill would marshal; `loops` says whether the hole is still a hole.
  def meshes
    zone_groups.flat_map do |group|
      group.entities.grep(Sketchup::Face).map do |face|
        mesh = face.mesh(0)
        { "persistent_id" => face.persistent_id, "loops" => face.loops.length,
          "triangles" => mesh.count_polygons,
          # The fill flattens every polygon into one GL_TRIANGLES stream, so a polygon with any
          # other arity would draw the wrong shape.
          "triangles_only" => mesh.polygons.all? { |polygon| polygon.length == 3 },
          "area_m2" => (face.area * 0.0254 * 0.0254).round(4) }
      end
    end
  end

  # Question 2. Hide a tag in the viewport, or call this, then read `rows` and `fill_batches`: the
  # hidden Faces must leave the drawing without any other change.
  def hide_tag(name = "#{PREFIX}tag")
    model = Sketchup.active_model
    layer = model.layers[name] || model.layers.add(name)
    faces = zone_groups.first.entities.grep(Sketchup::Face).first(2)
    model.start_operation("Tag walkthrough Faces", true)
    faces.each { |face| face.layer = layer }
    model.commit_operation
    before_revision = PhComposer::Sessions.current.revision
    layer.visible = false
    report.merge("tagged" => faces.map(&:persistent_id), "rebuilds" => service.rebuilds,
                 "revision_before" => before_revision,
                 "revision_after" => PhComposer::Sessions.current.revision)
  end

  # Question 3. Create two scenes with different tag visibility in the viewport first, then call
  # this with each page name and compare the drawing.
  def activate_scene(name)
    page = Sketchup.active_model.pages[name]
    raise "There is no scene named #{name}." unless page

    Sketchup.active_model.pages.selected_page = page
    report
  end

  # Question 5, on the Model as it stands. Ruby time only: the GPU cost is B2's measurement.
  def cost(samples = 20)
    view = Sketchup.active_model.active_view
    rebuilds = samples.times.map { timed { service.invalidate!(:force => true) } }
    overlay = Sketchup.active_model.overlays.find { |item| item.overlay_id.end_with?("colour_by") }
    draws = samples.times.map { timed { overlay.draw(view) } }
    {
      "triangles" => service.fills.values.sum(&:length) / 3,
      "rebuild_ms" => summary(rebuilds), "draw_ms" => summary(draws)
    }
  end

  def summary(values)
    sorted = values.sort
    { "median" => sorted[sorted.length / 2].round(3), "max" => sorted.last.round(3) }
  end

  def timed
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000.0
  end

  # Native Undo goes through the menu action; SketchUp has no Model#undo. Read the result in a
  # later call, never in this one.
  def undo
    Sketchup.send_action("editUndo:")
    report
  end

  def redo_last
    Sketchup.send_action("editRedo:")
    report
  end

  def service
    PhComposer::ColourBy.for(PhComposer::Sessions.current)
  end

  def zone_groups
    Sketchup.active_model.entities.grep(Sketchup::Group)
            .select { |group| group.name.start_with?(PREFIX) || %w[west east].include?(group.name) }
  end

  def box(entities, name, origin, width, depth, height = 3000.mm)
    group = entities.add_group
    group.name = name
    group.transformation = Geom::Transformation.new(origin)
    floor = group.entities.add_face([0, 0, 0], [0, depth, 0], [width, depth, 0], [width, 0, 0])
    floor.reverse! if floor.normal.z.positive?
    floor.pushpull(-height)
    group
  end

  # A hole in one wall, so the fill meets the shape Phase 2 windows will make.
  def punch(group)
    wall = group.entities.grep(Sketchup::Face).find { |face| face.normal.x.abs > 0.9 }
    return unless wall

    x = wall.vertices.first.position.x
    opening = group.entities.add_face([x, 1000.mm, 1000.mm], [x, 2000.mm, 1000.mm],
                                      [x, 2000.mm, 2000.mm], [x, 1000.mm, 2000.mm])
    opening.erase!
  end

  class Client
    def initialize
      session = API.discover.fetch("sessions").find { |row| row.fetch("active") }.fetch("id")
      @context = API.connect(:session_id => session)
      @sequence = 0
    end

    def query(name)
      API.query(:context => @context, :name => name)
    end

    def preview(name, params)
      API.preview(:context => @context, :name => name, :params => params)
    end

    def invoke(name, params, proposal_digest = nil)
      @sequence += 1
      revision = query("ph_composer.zones.all").fetch("revision")
      request = { "sequence" => @sequence, "expected_revision" => revision }
      request["proposal_digest"] = proposal_digest if proposal_digest
      API.invoke(:context => @context, :name => name, :params => params, :request => request)
    end
  end
end
