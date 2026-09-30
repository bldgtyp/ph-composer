# frozen_string_literal: true

module PhComposer
  module Zones
    module Faces
      # The Classify tool: the viewport half of the Classify gesture (face-assignment PRD "The
      # Classify tool"). The operation is D1's `ph_composer.face_assignment.classify`, and this tool
      # calls it through the public interface like any other client (CONTRACTS.md C2), with its own
      # caller handle and its own sequence numbers.
      #
      # What the tool owns is the gesture, not the change: which Faces the pointer collected, the
      # palette intent frozen when the button went down, and the refusals that belong to the pointer
      # rather than to the Model. Nothing here opens a Model operation, so an abandoned gesture writes
      # nothing and leaves no Undo entry, and one completed gesture is one invoke and therefore one
      # Undo step however many Faces the pointer crossed.
      #
      # The palette is this Model's, not this gesture's: it survives the tool ending, so turning the
      # tool on again paints what it painted last. A gesture freezes a copy at button-down, so a
      # palette changed mid-drag cannot change what the drag in progress will write.
      #
      # Until the panel palette lands with the Overview UI (D7), the palette is set from the native
      # Classify menu, which offers one item per assignable face type and boundary condition.
      class ClassifyTool
        CLASSIFY = "#{FEATURE_ID}.classify"
        # Transient pointer state is red and collected state is teal, the same two highlight roles the
        # panel uses (.agents/skills/ph-composer-ui-polish/SKILL.md "Graphics and interaction").
        HOVER_COLOUR = [184, 59, 59].freeze
        COLLECTED_COLOUR = [47, 143, 131].freeze
        FILL_ALPHA = 90
        OUTLINE_ALPHA = 230
        OUTSIDE_ZONE = "That Face is in no Zone. Make it a Zone first, then classify its Faces."
        NOTHING_CHOSEN = "Choose a face type or a boundary condition before painting."
        CANCELLED = "The Classify gesture was cancelled. Nothing was written."

        attr_reader :palette, :collected

        def initialize(session)
          @session = session
          @palette = {}
          @sequence = 0
          @collected = nil
          @intent = nil
          @hover = nil
          @pressed = false
          @forced_colour_by = nil
        end

        # Sets one palette field and starts the tool, which is what a native Classify menu item does.
        # `nil` clears the field back to keeping whatever the Face has (PRD Q10, Q21).
        #
        # Choosing an Attached zone carries its boundary condition with it, and dropping it takes that
        # boundary condition back: an AttachedZone boundary naming no record is an incomplete Face, so
        # the two are one choice however the palette is reached.
        def choose(field, value)
          set(field, value)
          set("boundary_condition", "AttachedZone") if field == "attached_zone_id" && value
          if field == "attached_zone_id" && value.nil? && chosen("boundary_condition") == "AttachedZone"
            set("boundary_condition", nil)
          end
          set("attached_zone_id", nil) if field == "boundary_condition" && value != "AttachedZone"
          start
          show_instructions
          @session.request_refresh
          self
        end

        def chosen(field)
          @palette.dig(field, "value")
        end

        def set(field, value)
          @palette = @palette.merge(field => { "mode" => "set", "value" => value })
          @palette.delete(field) if value.nil?
        end

        def start
          model = @session.model
          return self unless model.respond_to?(:select_tool)

          model.select_tool(self)
          self
        end

        def stop
          model = @session.model
          model.select_tool(nil) if model.respond_to?(:select_tool)
          self
        end

        def active?
          @active == true
        end

        # Sketchup::Tool. The host calls these; nothing else does.

        def activate
          @active = true
          @pressed = false
          @collected = nil
          @intent = nil
          @hover = nil
          force_colour_by
          show_instructions
          @session.request_refresh
        end

        def deactivate(view)
          @active = false
          cancel_gesture
          @hover = nil
          release_colour_by
          view.invalidate if view.respond_to?(:invalidate)
          @session.request_refresh
        end

        # Escape, a tool change or an Undo. Escape ends the tool, cancelling its pending gesture with
        # it, which is the one-layer-at-a-time rule the UI polish skill sets; anything else cancels
        # only the gesture, because the host is already taking the tool away or putting it back.
        def onCancel(reason, _view)
          cancel_gesture
          stop if reason.to_i.zero?
        end

        # The edit context changed under a pending gesture, so the paths it collected no longer mean
        # what they meant when the pointer crossed them.
        def suspend(view)
          cancel_gesture
          view.invalidate if view.respond_to?(:invalidate)
        end

        def resume(view)
          view.invalidate if view.respond_to?(:invalidate)
        end

        def onMouseMove(flags, x, y, view)
          path = Pick.face_path(view, x, y)
          if collecting?
            collect(path, flags)
          else
            @hover = path && Zones::Occurrences.occurrence_for_path(path)
            view.tooltip = tooltip(path) if view.respond_to?(:tooltip=)
          end
          view.invalidate if view.respond_to?(:invalidate)
        rescue StandardError => error
          report_exception(error, view)
        end

        def onLButtonDown(flags, x, y, view)
          @pressed = true
          @gesture_edit_path = edit_path
          @intent = DeepCopy.call(@palette).freeze
          # The revision is frozen with the palette. An external client committing a change mid-drag
          # fires no cancel this tool hears, so the gesture is applied against the revision it began
          # at and refuses as `revision.stale` rather than painting paths that no longer describe the
          # Model.
          @revision = @session.revision
          @collected = DragSet.new(:limit => Faces.gesture_face_limit)
          collect(Pick.face_path(view, x, y), flags)
          view.invalidate if view.respond_to?(:invalidate)
        rescue StandardError => error
          report_exception(error, view)
        end

        # One completion boundary for every route: a click, a drag and a Shift-click all end here.
        def onLButtonUp(_flags, _x, _y, view)
          # SketchUp may deliver the old tool's mouse-up after Cmd-N activates another Model,
          # without first suspending it. That release must never commit the old gesture.
          unless Sketchup.active_model.equal?(@session.model) && @gesture_edit_path == edit_path
            cancel_gesture
            view.invalidate if view.respond_to?(:invalidate)
            return
          end
          complete
          view.invalidate if view.respond_to?(:invalidate)
        rescue StandardError => error
          report_exception(error, view)
        end

        def draw(view)
          draw_occurrences(view, @collected ? @collected.values : [], COLLECTED_COLOUR)
          draw_occurrences(view, @hover ? [@hover] : [], HOVER_COLOUR) unless collecting?
        end

        # SketchUp hands a right-click to the active tool rather than selecting what is under it, so
        # the context-menu handler in `shell/` cannot fire while this tool runs, and its
        # selection-based test for "is a Face under the cursor" would answer no in any case. This is
        # the same menu built by the same code, with the coordinates that route never had.
        def getMenu(menu, _flags = 0, x_value = nil, y_value = nil, view = nil)
          return unless view && Zones::Occurrences.occurrence_for_path(Pick.face_path(view, x_value, y_value) || [])

          Commands.install_feature_menus(menu)
        end

        def getInstructorContentDirectory
          nil
        end

        # A Model closing, or the extension reloading, takes its feature state with it. The tool goes
        # with it rather than being left selected against a session that no longer exists, and it
        # gives up the Colour-by mode it forced before it does.
        def detach
          @collected = nil
          @intent = nil
          @pressed = false
          @hover = nil
          return unless @active

          @active = false
          model = @session.model
          @forced_colour_by = nil unless model.respond_to?(:valid?) && model.valid?
          model.select_tool(nil) if model.respond_to?(:select_tool)
        end

        private

        def edit_path
          Array(@session.model.active_path).map(&:persistent_id)
        end

        # Collecting means the button is down. Without the flag, a press whose release the host never
        # delivered would leave every later hover collecting, and the next release would write a
        # gesture the user did not drag.
        def collecting?
          @pressed && !@collected.nil?
        end

        # A target outside any Zone refuses the whole pending gesture rather than painting the rest of
        # it, which is the PRD's rule; Make Zone is its own explicit action and the user then retries.
        #
        # Pointing at nothing is not that. A drag across a window opening, a re-entrant corner or the
        # sky past a gable crosses empty space between Faces the user means, and the PRD's rule is
        # that a drag paints every Face the cursor crosses.
        def collect(path, flags)
          return if @collected.nil?
          return if path.nil?

          occurrence = Zones::Occurrences.occurrence_for_path(path)
          unless occurrence
            @collected = nil
            @intent = nil
            @pressed = false
            announce(OUTSIDE_ZONE, :warning)
            return
          end

          targets = shift?(flags) ? coplanar_neighbours(occurrence) : [occurrence]
          targets.each { |target| @collected.add(Zones::Occurrences.key(target.reference), target) }
        end

        # Shift-click takes every connected coplanar Face in the same container, which is the Zone's
        # own geometry: a wall drawn as several pieces paints as one. Coplanarity uses the adjacency
        # solver's measured plane tolerance rather than a second number of this tool's own.
        # It stops one past the ceiling, for the same reason the drag set does: a flood over a wall of
        # thousands of pieces must refuse, not capture the lot and then refuse, and capturing costs a
        # `FaceGeometry.capture` a Face. A rejected neighbour is remembered too, or every coplanar
        # Face touching it would capture it again.
        def coplanar_neighbours(occurrence)
          limit = Faces.gesture_face_limit
          origin = FaceGeometry.capture(occurrence.entity, occurrence.transform)
          found = { occurrence.entity.persistent_id => occurrence }
          seen = {}
          queue = [occurrence.entity]
          until queue.empty? || found.length > limit
            Array(queue.shift.edges).each do |edge|
              Array(edge.faces).each do |face|
                next if found.key?(face.persistent_id) || seen.key?(face.persistent_id)

                capture = FaceGeometry.capture(face, occurrence.transform)
                unless FaceGeometry.coplanar?(origin, capture, Zones::Adjacency::PLANE_TOLERANCE_M)
                  seen[face.persistent_id] = true
                  next
                end

                found[face.persistent_id] = sibling(occurrence, face)
                queue << face
              end
            end
          end
          found.values
        end

        # A Face reached through a shared Edge is a sibling of the picked Face: same container, so the
        # same Zone and the same transform, and the path differs only in its last persistent id.
        def sibling(occurrence, face)
          Zones::FaceOccurrence.new(:entity => face, :zone => occurrence.zone,
                                    :path => occurrence.path[0...-1] + [face.persistent_id],
                                    :transform => occurrence.transform)
        end

        def shift?(flags)
          (flags.to_i & CONSTRAIN_MODIFIER_MASK) != 0
        end

        def complete
          collected = @collected
          intent = @intent
          revision = @revision
          @collected = nil
          @intent = nil
          @pressed = false
          return if collected.nil? || collected.empty?

          if intent.empty?
            announce(NOTHING_CHOSEN, :warning)
            return
          end

          apply(collected.values.map { |occurrence| reference_for(occurrence) }, intent, revision)
        end

        # The reference the operation resolves. The picked path gives the Face's identity only through
        # its record, so a Face with none is sent with a null `entity_id` and the operation creates it.
        def reference_for(occurrence)
          occurrence.reference(FACE_STORE.read(occurrence.entity)&.fetch("id", nil))
        end

        def apply(references, intent, revision)
          outcome = API.invoke(:context => context, :name => CLASSIFY,
                               :params => { "faces" => references, "intent" => intent, "expected_values" => {} },
                               :request => { "sequence" => next_sequence, "expected_revision" => revision })
          report(outcome, references.length)
        end

        def report(outcome, count)
          if outcome.fetch("status") == "completed"
            announce("Classified #{count} #{count == 1 ? 'Face' : 'Faces'}.")
          else
            announce(outcome.fetch("message"), outcome.fetch("status") == "refused" ? :warning : :error)
          end
        end

        def context
          @context ||= API.connect(:session_id => @session.id)
        end

        def next_sequence
          @sequence += 1
        end

        def cancel_gesture
          pending = !@collected.nil?
          @collected = nil
          @intent = nil
          @pressed = false
          announce(CANCELLED, :warning) if pending
        end

        # PRD Q12: Colour-by is forced on while the tool is active, so the user sees what they are
        # painting. What the tool forced is not what the user chose, so it is turned on without being
        # remembered and turned off again when the tool ends. A mode the user already had on is left
        # exactly as it was.
        def force_colour_by
          service = ColourBy.for(@session)
          return if service.active?

          mode = ColourBy.remembered_mode || ColourModes::BY_FACE_TYPE
          return unless Registry.current.colour_modes.key?(mode)

          service.activate(mode, :remember => false)
          @forced_colour_by = mode
        end

        # Only the mode this tool turned on, and only while it is still the active one. A user who
        # picked a different mode from the Colour by menu while the tool was running chose it, and
        # the tool has no business turning their choice off.
        def release_colour_by
          forced = @forced_colour_by
          @forced_colour_by = nil
          return unless forced

          service = ColourBy.for(@session)
          service.deactivate if service.mode_name == forced
        end

        # A viewport tool is used with the panel closed, and the panel is the only thing that shows a
        # session notice, so a refusal delivered that way alone is silent exactly when it matters: at
        # the pointer, with nothing else on screen. The status bar is SketchUp's own place for a modal
        # tool's guidance and needs no panel. Results and refusals also reach the open panel;
        # activation instructions use the status bar alone.
        def announce(message, tone = :info)
          @session.notice(message, :tone => tone)
          Sketchup.status_text = message if Sketchup.respond_to?(:status_text=)
        end

        def instructions
          chosen = @palette.map { |field, operation| "#{field.tr('_', ' ')} #{operation.fetch('value')}" }
          return NOTHING_CHOSEN if chosen.empty?

          "Classify: #{chosen.join(', ')}. Click or drag over Faces; Shift-click takes a whole plane."
        end

        # Routine guidance stays beside the viewport, including when the host keeps the same tool
        # active after a palette change. A floating copy covers panel controls (D7 host evidence, F8).
        def show_instructions
          Sketchup.status_text = instructions if Sketchup.respond_to?(:status_text=)
        end

        def tooltip(path)
          return "" if path.nil?
          return OUTSIDE_ZONE unless @hover

          suggested = Geometry.suggested_values(@hover)
          "#{@hover.zone.record.fetch('name')}: #{suggested.fetch('face_type')}, " \
            "#{suggested.fetch('boundary_condition')} suggested"
        end

        def draw_occurrences(view, occurrences, colour)
          return if occurrences.empty?
          return unless view.respond_to?(:draw)

          triangles = []
          segments = []
          occurrences.each do |occurrence|
            faces, outlines = ColourBy::Tessellation.call(occurrence.entity, occurrence.transform)
            triangles.concat(faces)
            segments.concat(outlines)
          end
          return if triangles.empty? && segments.empty?

          # Lifted toward the camera, or it z-fights with the Face it is tinting and the host blinks
          # between the two (colour_by/tessellation.rb). The tool's tint sits one pixel in front of
          # Colour-by's fill, so what the pointer is over reads over what the mode painted.
          view.drawing_color = Sketchup::Color.new(*colour, FILL_ALPHA) if view.respond_to?(:drawing_color=)
          view.draw(GL_TRIANGLES, ColourBy::Tessellation.lift(triangles, view, 3.0)) unless triangles.empty?
          view.drawing_color = Sketchup::Color.new(*colour, OUTLINE_ALPHA) if view.respond_to?(:drawing_color=)
          view.draw(GL_LINES, ColourBy::Tessellation.lift(segments, view, 3.0)) unless segments.empty?
        end

        # A tool callback that raises reaches the host, which has nowhere to put it. Every failure is
        # logged, but only one that abandoned a gesture is worth a notice: a hover that fails fails
        # again on the next pointer move, and a notice per move buries the viewport.
        def report_exception(error, view)
          pending = !@collected.nil?
          @collected = nil
          @intent = nil
          @pressed = false
          @hover = nil
          Diagnostics.exception("classify_tool", error)
          announce("The Classify tool could not complete that. #{Outcome::NOTHING_WRITTEN}", :error) if pending
          view.tooltip = "" if view.respond_to?(:tooltip=)
          view.invalidate if view.respond_to?(:invalidate)
        end
      end

      module_function

      # This Model's Classify tool, created on first reach and held as generic session feature state,
      # so its palette survives the tool ending and a Model closing takes it with it.
      def classify_tool(session)
        session.feature_state(:classify_tool) { ClassifyTool.new(session) }
      end
    end
  end
end
