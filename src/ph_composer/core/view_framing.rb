# frozen_string_literal: true

module PhComposer
  # Brings geometry into view by its world bounds, keeping the camera's direction. `View#zoom` given
  # entities inside a closed Group frames their bounds in that Group's own coordinates, which leaves
  # geometry placed away from the origin off screen (context/SKETCHUP_HOST_BEHAVIOR.md). A caller that
  # knows where its geometry is in the world passes those points; a view with no camera (the offline
  # stub) or no points falls back to `View#zoom` on the entities. Changes the camera and nothing else.
  module ViewFraming
    MARGIN = 1.2

    module_function

    # `points` are world-space points of what to frame; `entities` are what `View#zoom` gets instead.
    def call(view, points, entities)
      return unless view

      camera = view.respond_to?(:camera) ? view.camera : nil
      if points.empty? || !camera.respond_to?(:set)
        view.zoom(entities) if view.respond_to?(:zoom) && !entities.empty?
        return
      end

      box = Geom::BoundingBox.new
      points.each { |point| box.add(point) }
      frame(view, camera, box)
    end

    def frame(view, camera, box)
      center = box.center
      radius = [box.diagonal.to_f / 2.0, 1.0].max * MARGIN
      direction = camera.direction
      aspect = view.vpwidth.to_f / [view.vpheight.to_f, 1.0].max
      if camera.perspective?
        eye = center.offset(direction.reverse, radius / Math.sin(narrowest_angle(camera, aspect) / 2.0))
        camera.set(eye, center, camera.up)
      else
        camera.set(center.offset(direction.reverse, radius * 4.0), center, camera.up)
        camera.height = radius * 2.0 / [aspect, 1.0].min
      end
      view.invalidate
    end

    # The smaller of the view's two angles. `fov` is the vertical angle unless the camera says it is the
    # horizontal one (`fov_is_height?` false), a per-camera setting.
    def narrowest_angle(camera, aspect)
      angle = camera.fov.to_f * Math::PI / 180.0
      height = !camera.respond_to?(:fov_is_height?) || camera.fov_is_height?
      half = Math.tan(angle / 2.0)
      other = 2.0 * Math.atan(height ? half * aspect : half / aspect)
      [angle, other].min
    end

    private_class_method :frame, :narrowest_angle
  end
end
