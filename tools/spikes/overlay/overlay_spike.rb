# frozen_string_literal: true

# B2 spike: overlay fill (planning/archive/phase-zero/phases/phase-01-investigations.md). Development only,
# never shipped. Loaded into SketchUp through the development bridge:
#
#   load "<repo>/tools/spikes/overlay/overlay_spike.rb"
#   OverlaySpike.build                       # three scenes, one operation, then save the Model
#   OverlaySpike.show(1000)                  # one scene visible, overlay cache rebuilt
#   OverlaySpike.measure(paths: 5)           # disabled, outline and fill on the same camera paths
#   OverlaySpike.mode = :fill                # leave a mode on for a native look
#
# The overlay draws only. It never writes to the Model; `fingerprint` checks that.
require "json"
require "digest"

module OverlaySpike
  SIZES = [100, 1000, 10_000].freeze
  CELL = 1000.mm
  MODES = %i[disabled outline fill].freeze

  # Draws the visible scene's faces as triangles or outlines, from a cache built once per scene.
  class Fill < Sketchup::Overlay
    attr_accessor :mode
    attr_reader :draw_ms, :triangles, :segments

    def initialize
      super("phc.spike.overlay_fill", "PH-Composer overlay spike", :description => "B2 fill experiment")
      @mode = :disabled
      @draw_ms = []
      @triangles = []
      @segments = []
    end

    def stamps
      @stamps ||= []
    end

    def rebuild(entities)
      @triangles = []
      @segments = []
      collect(entities, Geom::Transformation.new)
      [@triangles.length / 3, @segments.length / 2]
    end

    def draw(view)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      stamps << started
      return if @mode == :disabled

      if @mode == :fill
        view.drawing_color = Sketchup::Color.new(0, 110, 255, 110)
        view.draw(GL_TRIANGLES, @triangles)
      end
      view.line_width = 2
      view.drawing_color = Sketchup::Color.new(0, 60, 160)
      view.draw(GL_LINES, @segments)
      @draw_ms << (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000.0
    end

    private

    def collect(entities, transformation)
      entities.each do |entity|
        next if entity.hidden? || (entity.layer && !entity.layer.visible?)
        # The occluding box is Model geometry the fill must hide behind, not a filled target.
        next if entity.respond_to?(:name) && entity.name.start_with?("blocker_")

        case entity
        when Sketchup::Face then add_face(entity, transformation)
        when Sketchup::Group, Sketchup::ComponentInstance
          collect(entity.definition.entities, transformation * entity.transformation)
        end
      end
    end

    def add_face(face, transformation)
      mesh = face.mesh(0)
      mesh.polygons.each do |polygon|
        polygon.each { |index| @triangles << mesh.point_at(index.abs).transform(transformation) }
      end
      face.loops.each do |loop|
        loop.edges.each do |edge|
          @segments << edge.start.position.transform(transformation) << edge.end.position.transform(transformation)
        end
      end
    end
  end

  class << self
    def overlay
      @overlay ||= begin
        fill = Fill.new
        Sketchup.active_model.overlays.add(fill)
        fill.enabled = true
        fill
      end
    end

    def mode=(value)
      overlay.mode = value
      Sketchup.active_model.active_view.invalidate
    end

    # Three scene groups, one per size. One operation, so the build is one Undo step.
    def build
      model = Sketchup.active_model
      model.start_operation("Build overlay spike scenes", true)
      definition = cell_component(model)
      SIZES.each_with_index do |size, row|
        scene = model.entities.add_group
        scene.name = "scene_#{size}"
        (size / 20.0).ceil.times { |index| add_cell(scene.entities, definition, index, row) }
        add_blocker(scene.entities, size)
      end
      model.commit_operation
      counts
    end

    def counts
      scenes.to_h { |scene| [scene.name, triangle_count(scene.definition.entities)] }
    end

    def show(size)
      scenes.each { |scene| scene.hidden = scene.name != "scene_#{size}" }
      visible = scenes.find { |scene| !scene.hidden? }
      counted = overlay.rebuild([visible])
      Sketchup.active_model.active_view.zoom(visible)
      { "scene" => visible.name, "overlay_triangles" => counted[0], "overlay_segments" => counted[1] }
    end

    # Each path orbits the visible scene in `frames` steps and forces a redraw per step. Modes are
    # interleaved per path so drift affects all three alike. The first path of each mode is warm-up.
    def measure(paths: 5, frames: 90)
      view = Sketchup.active_model.active_view
      start_camera = view.camera
      results = MODES.to_h { |mode| [mode, []] }
      ruby_ms = MODES.to_h { |mode| [mode, []] }
      (paths + 1).times do |path|
        MODES.each do |mode|
          overlay.mode = mode
          overlay.draw_ms.clear
          times = orbit(view, frames)
          next if path.zero?

          results[mode] << times
          ruby_ms[mode].concat(overlay.draw_ms)
        end
      end
      view.camera = start_camera
      overlay.mode = :disabled
      summarize(results, ruby_ms)
    end

    # The second measure: the host's own frame cadence. A repeating zero-delay timer moves the camera and
    # invalidates the view; the interval between draw calls is what a user sees during an orbit. Call
    # `cadence_start(mode)`, wait, then `cadence_stop`.
    def cadence_start(mode, frames: 360)
      view = Sketchup.active_model.active_view
      overlay.mode = mode
      overlay.stamps.clear
      step = 0
      @cadence_camera = view.camera
      @cadence_timer = UI.start_timer(0, true) do
        step += 1
        UI.stop_timer(@cadence_timer) if step >= frames
        angle = 2 * Math::PI * step / 120
        bounds = scenes.find { |scene| !scene.hidden? }.bounds
        offset = Geom::Vector3d.new(Math.cos(angle), Math.sin(angle), 0.6)
        offset.length = bounds.diagonal
        view.camera = Sketchup::Camera.new(bounds.center.offset(offset), bounds.center, Z_AXIS)
        view.invalidate
      end
      mode
    end

    def cadence_stop
      UI.stop_timer(@cadence_timer) if @cadence_timer
      Sketchup.active_model.active_view.camera = @cadence_camera if @cadence_camera
      gaps = overlay.stamps.each_cons(2).map { |a, b| (b - a) * 1000.0 }.drop(10)
      overlay.mode = :disabled
      { "intervals" => gaps.length, "median_ms" => percentile(gaps, 50), "p95_ms" => percentile(gaps, 95),
        "max_ms" => gaps.max&.round(2) }
    end

    # What must not change: entity counts, materials, attribute dictionaries, modified state.
    def fingerprint
      model = Sketchup.active_model
      dictionaries = model.definitions.flat_map { |d| d.entities.to_a }.map(&:attribute_dictionaries).compact
      {
        "entities" => model.definitions.sum { |d| d.entities.length } + model.entities.length,
        "materials" => model.materials.map(&:name).sort,
        "attribute_dictionaries" => dictionaries.sum(&:count),
        "modified" => model.modified?
      }
    end

    private

    def scenes
      Sketchup.active_model.entities.grep(Sketchup::Group).select { |g| g.name.start_with?("scene_") }
    end

    def triangle_count(entities, count = 0)
      entities.each do |entity|
        case entity
        when Sketchup::Face then count += entity.mesh(0).count_polygons
        when Sketchup::Group, Sketchup::ComponentInstance then count = triangle_count(entity.definition.entities, count)
        end
      end
      count
    end

    def cell_component(model)
      definition = model.definitions.add("spike_cell_component")
      definition.entities.add_face([0, 0, 0], [300.mm, 0, 0], [300.mm, 300.mm, 0], [0, 300.mm, 0])
      definition
    end

    # About twenty triangles: a concave face, a face with a hole, two overlapping faces in separate
    # groups, a reversed face and a nested, rotated and scaled component instance. Alternate cells
    # stand vertical so the scene has depth.
    def add_cell(entities, definition, index, row)
      cell = entities.add_group
      origin = [(index % 25) * CELL * 1.2, (index / 25) * CELL * 1.2 + row * 40 * CELL, 0]
      tilt = index.odd? ? Geom::Transformation.rotation(ORIGIN, X_AXIS, 90.degrees) : Geom::Transformation.new
      cell.transformation = Geom::Transformation.new(origin) * tilt
      add_shapes(cell.entities, definition)
    end

    def add_shapes(entities, definition)
      s = CELL / 10
      concave = [[0, 0, 0], [4 * s, 0, 0], [4 * s, 2 * s, 0], [2 * s, 2 * s, 0], [2 * s, 4 * s, 0], [0, 4 * s, 0]]
      entities.add_face(concave)
      holed = entities.add_face([5 * s, 0, 0], [9 * s, 0, 0], [9 * s, 4 * s, 0], [5 * s, 4 * s, 0])
      hole = entities.add_face([6 * s, s, 0], [8 * s, s, 0], [8 * s, 3 * s, 0], [6 * s, 3 * s, 0])
      hole.erase! if hole && holed.valid?
      [0, s].each do |offset|
        entities.add_group.entities.add_face([offset, 5 * s, 0], [offset + 3 * s, 5 * s, 0],
                                             [offset + 3 * s, 8 * s, 0], [offset, 8 * s, 0])
      end
      entities.add_face([5 * s, 5 * s, 0], [8 * s, 5 * s, 0], [8 * s, 8 * s, 0], [5 * s, 8 * s, 0]).reverse!
      holder = entities.add_group
      turn = Geom::Transformation.rotation(ORIGIN, Z_AXIS, 30.degrees)
      holder.transformation = Geom::Transformation.new([7 * s, 7 * s, s]) * turn
      holder.entities.add_instance(definition, Geom::Transformation.scaling(0.5))
    end

    # An opaque box in front of part of the scene, for the occlusion check.
    def add_blocker(entities, size)
      box = entities.add_group
      box.name = "blocker_#{size}"
      face = box.entities.add_face([0, -2 * CELL, 0], [3 * CELL, -2 * CELL, 0], [3 * CELL, -2 * CELL, 3 * CELL],
                                   [0, -2 * CELL, 3 * CELL])
      face.pushpull(CELL)
    end

    def orbit(view, frames)
      bounds = scenes.find { |scene| !scene.hidden? }.bounds
      target = bounds.center
      radius = bounds.diagonal
      Array.new(frames) do |frame|
        angle = 2 * Math::PI * frame / frames
        eye = target.offset(Geom::Vector3d.new(Math.cos(angle) * radius, Math.sin(angle) * radius, radius * 0.6))
        view.camera = Sketchup::Camera.new(eye, target, Z_AXIS)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        view.refresh
        (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000.0
      end
    end

    def summarize(results, ruby_ms)
      disabled = results[:disabled].flatten
      MODES.to_h do |mode|
        frames = results[mode].flatten
        added = frames.each_with_index.map { |ms, index| ms - disabled[index] }
        [mode.to_s, {
          "frames" => frames.length, "median_ms" => percentile(frames, 50), "p95_ms" => percentile(frames, 95),
          "max_ms" => frames.max.round(2), "added_median_ms" => percentile(added, 50),
          "added_p95_ms" => percentile(added, 95), "ruby_draw_median_ms" => percentile(ruby_ms[mode], 50),
          "ruby_draw_p95_ms" => percentile(ruby_ms[mode], 95)
        }]
      end
    end

    def percentile(values, rank)
      return nil if values.empty?

      sorted = values.sort
      sorted[((rank / 100.0) * (sorted.length - 1)).round].round(2)
    end
  end
end
