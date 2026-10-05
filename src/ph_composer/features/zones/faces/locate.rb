# frozen_string_literal: true

module PhComposer
  module Zones
    module Faces
      # Locate and Select, the two ways a caller reaches an explicit set of Face references in the
      # viewport. Other features use both.
      #
      # Locate brings the Faces into view and outlines them (LocateHighlight). It leaves SketchUp's
      # selection alone, so a set the panel has checked, or a selection the user made, survives it.
      # Select replaces the selection with the Faces and brings them into view, for a caller that wants
      # the native selection itself (an agent handing the user a set to act on).
      #
      # Neither writes a record, opens a Model operation or leaves an Undo entry, which is why they are
      # view commands (Declarations::ViewCommand), `ph_composer.zones.faces.locate` and `.select`,
      # rather than registered actions: an action would manufacture an Undo entry for a read.
      module Locate
        module_function

        # Answers the occurrences it could resolve. A reference that no longer resolves is skipped
        # rather than refusing the rest: Locate is a way of finding things, and the caller's list may
        # be as old as the last read it came from.
        def call(session, references)
          found = resolve(session.model, references)
          zoom(session.model, found)
          Faces.locate_highlight(session).show(found)
          found
        end

        # Whether SketchUp shows a selection made outside the active edit context is not measured, and
        # the host gate asks it (tools/examples/authoring/classify_tool_walkthrough.rb). Select does
        # not open the context itself: changing `active_path` advances the session revision
        # (context/CONTRACTS.md, "Revisions, transactions and host execution") and would cancel a
        # pending gesture, which is too much for a read.
        def select(session, references)
          found = resolve(session.model, references)
          selection = session.model.selection
          selection.clear
          selection.add(found.map(&:entity)) unless found.empty?
          zoom(session.model, found)
          found
        end

        def resolve(model, references)
          index = Zones::Index.new(model)
          Array(references).filter_map do |reference|
            Zones::Occurrences.resolve_face(model, reference, :allow_unassigned => true, :index => index)
          rescue CodedError
            nil
          end
        end

        # Frames the Faces by their world bounds, keeping the camera's direction. `View#zoom` with a Face
        # inside a closed Group frames the Face's bounds in its own Group's coordinates, which leaves a Zone
        # placed away from the origin off screen (context/SKETCHUP_HOST_BEHAVIOR.md); a view without a
        # camera (the offline stub) still gets `zoom`.
        def zoom(model, found)
          return if found.empty?

          view = model.respond_to?(:active_view) ? model.active_view : nil
          return unless view

          camera = view.respond_to?(:camera) ? view.camera : nil
          return view.zoom(found.map(&:entity)) if !camera.respond_to?(:set) && view.respond_to?(:zoom)

          frame(view, camera, world_bounds(found))
        end

        def world_bounds(found)
          found.each_with_object(Geom::BoundingBox.new) do |face, box|
            face.entity.vertices.each { |vertex| box.add(vertex.position.transform(face.transform)) }
          end
        end

        FRAME_MARGIN = 1.2

        def frame(view, camera, box)
          center = box.center
          radius = [box.diagonal.to_f / 2.0, 1.0].max * FRAME_MARGIN
          direction = camera.direction
          if camera.perspective?
            vertical = camera.fov.to_f.degrees
            aspect = view.vpwidth.to_f / [view.vpheight.to_f, 1.0].max
            narrowest = [vertical, 2.0 * Math.atan(Math.tan(vertical / 2.0) * aspect)].min
            eye = center.offset(direction.reverse, radius / Math.sin(narrowest / 2.0))
            camera.set(eye, center, camera.up)
          else
            camera.set(center.offset(direction.reverse, radius * 4.0), center, camera.up)
            camera.height = radius * 2.0
          end
          view.invalidate
        end

        private_class_method :resolve, :zoom, :world_bounds, :frame
      end
    end
  end
end
