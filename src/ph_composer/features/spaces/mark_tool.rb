# frozen_string_literal: true

module PhComposer
  module Spaces
    # The Mark floor tool: the viewport half of marking Floor Segments (context/EXTENSIBILITY.md, "Viewport
    # tools"). It calls `floors.mark` and `volumes.create` through the public interface like any other client,
    # with its own caller handle and sequence numbers, and opens no operation of its own: an abandoned
    # gesture writes nothing, and one completed gesture is one invoke and one Undo step.
    #
    # What a pick means: a Face directly inside a Volume is marked with the weighting factor; a Face at a
    # Space's root becomes that Space's next Volume; a Face directly in a Zone and in no Space is offered
    # Create Space, and nothing is written on the click; a classified Zone Face, or a Face in no Zone,
    # refuses with the reason. One gesture works in one place, so a drag mixing those refuses whole.
    #
    # The weighting factor is this Model's choice, set when the tool starts; a gesture freezes it, and the
    # revision, at button-down, so a factor chosen mid-drag cannot change what the drag writes.
    #
    # A pick is placed from its own path, never a Model walk: the Spaces records on the path's containers,
    # the Zone paths read once per revision, and Zones' narrow `host_context` row for a Face directly in a
    # Zone. A read that fails refuses the gesture with its reason rather than reading as an answer.
    class MarkTool
      MARK = "#{FEATURE_ID}.floors.mark"
      ADD_VOLUME = "#{FEATURE_ID}.volumes.create"
      ZONES = "ph_composer.zones.all"
      HOST_CONTEXT = "ph_composer.zones.faces.host_context"
      HOVER_COLOUR = [184, 59, 59].freeze
      COLLECTED_COLOUR = [47, 143, 131].freeze
      FILL_ALPHA = 90
      OUTLINE_ALPHA = 230
      OUTSIDE_ZONE = "That Face is in no Zone. Make it a Zone first, then mark floors in its Spaces."
      OUTSIDE_SPACE = "That Face's Volume is in no Space. Move it into a Space, then mark its floors."
      ZONE_FACE = "That Face is one of its Zone's own Faces, classified in the Faces view. Mark floor takes " \
                  "Faces inside a Space."
      MIXED = "One gesture marks Faces in one place: inside Volumes, or at one Space's root. Nothing was written."
      CANCELLED = "The Mark floor gesture was cancelled. Nothing was written."
      OFFER = "That Face is in a Zone and in no Space. Right-click it and choose Create Space to make one from it."

      attr_reader :weighting_factor, :offered

      def initialize(session)
        @session = session
        @weighting_factor = 1.0
        @sequence = 0
        @collected = nil
        @pressed = false
        @offered = []
      end

      # Sets the factor and starts the tool, turning on Colour by weighting factor and leaving it on. The
      # mode follows the tool change, so a tool giving up a mode it forced cannot take this one with it.
      def start(weighting_factor)
        @weighting_factor = Float(weighting_factor)
        model = @session.model
        model.select_tool(self) if model.respond_to?(:select_tool)
        ColourBy.for(@session).activate(ColourModes::BY_WEIGHTING_FACTOR) if ColourBy.registered?(
          ColourModes::BY_WEIGHTING_FACTOR
        )
        show_instructions
        @session.request_refresh
        self
      end

      # Only this tool: a stop arriving after another tool replaced it leaves that tool running.
      def stop
        return self unless active?

        model = @session.model
        model.select_tool(nil) if model.respond_to?(:select_tool)
        self
      end

      def active?
        @active == true
      end

      def state
        { "active" => active?, "weighting_factor" => @weighting_factor }
      end

      # Sketchup::Tool. The host calls these; nothing else does.

      def activate
        @active = true
        reset_gesture
        @hover = nil
        show_instructions
        @session.request_refresh
      end

      def deactivate(view)
        @active = false
        cancel_gesture
        @hover = nil
        view.invalidate if view.respond_to?(:invalidate)
        @session.request_refresh
      end

      # Escape ends the tool with its pending gesture; any other cancel takes only the gesture.
      def onCancel(reason, _view)
        cancel_gesture
        stop if reason.to_i.zero?
      end

      def suspend(view)
        cancel_gesture
        view.invalidate if view.respond_to?(:invalidate)
      end

      def resume(view)
        view.invalidate if view.respond_to?(:invalidate)
      end

      def onMouseMove(flags, x, y, view)
        path = Pick.face_path(view, x, y)
        # A move without the button down after a press means the host lost the release.
        cancel_gesture if collecting? && (flags.to_i & MK_LBUTTON).zero?
        if collecting?
          collect(path)
        else
          @hover = path
          view.tooltip = tooltip(path) if view.respond_to?(:tooltip=)
        end
        view.invalidate if view.respond_to?(:invalidate)
      rescue StandardError => error
        report_exception(error, view)
      end

      def onLButtonDown(_flags, x, y, view)
        @pressed = true
        @gesture_edit_path = edit_path
        @factor = @weighting_factor
        @revision = @session.revision
        refresh_reads
        @collected = DragSet.new(:limit => Spaces.floor_gesture_limit)
        collect(Pick.face_path(view, x, y))
        view.invalidate if view.respond_to?(:invalidate)
      rescue CodedError => error
        reset_gesture
        announce(error.message, :warning)
      rescue StandardError => error
        report_exception(error, view)
      end

      def onLButtonUp(_flags, _x, _y, view)
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
        draw_paths(view, @collected ? @collected.values.map { |item| item[:entities] } : [], COLLECTED_COLOUR)
        draw_paths(view, @hover ? [@hover] : [], HOVER_COLOUR) unless collecting?
      rescue StandardError => error
        report_exception(error, view)
      end

      def getMenu(menu, _flags = 0, _x_value = nil, _y_value = nil, _view = nil)
        Commands.install_feature_menus(menu, :contextual => true)
      end

      def getInstructorContentDirectory
        nil
      end

      def detach
        reset_gesture
        @hover = nil
        return unless @active

        @active = false
        model = @session.model
        model.select_tool(nil) if model.respond_to?(:select_tool)
      end

      private

      def edit_path
        Array(@session.model.active_path).map(&:persistent_id)
      end

      def collecting?
        @pressed && !@collected.nil?
      end

      # What one picked Face means, as `[place, target]`: `:mark`; `:volume` with its Space's reference;
      # `:offer`; or `:refuse` with the reason. Every route needs a Zone above the Face.
      def place(entities)
        ids = entities.map(&:persistent_id)
        parent = entities[-2]
        if parent && Occurrences.read(VOLUME_STORE, VOLUME, parent)
          space_index = entities[0...-2].rindex { |entity| Occurrences.read(SPACE_STORE, SPACE, entity) }
          return [:refuse, OUTSIDE_SPACE] unless space_index
          return [:refuse, OUTSIDE_ZONE] unless in_zone?(ids[0..space_index])

          return [:mark, nil]
        end
        if parent && (space = Occurrences.read(SPACE_STORE, SPACE, parent))
          return [:refuse, OUTSIDE_ZONE] unless in_zone?(ids[0...-1])

          return [:volume, { "space_id" => space.fetch("id"), "entity_path" => ids[0...-1] }]
        end
        zone_face(ids)
      end

      # A Face directly in a Zone is offered Create Space unless the Faces feature records it, which makes
      # it one of the Zone's own Faces, or a write to it would refuse from its path, as shared storage does.
      def zone_face(ids)
        row = host_row(ids)
        return [:refuse, OUTSIDE_ZONE] unless row
        return [:refuse, ZONE_FACE] unless row.dig("reference", "entity_id").nil?
        return [:refuse, row.dig("write_refusal", "message")] if row["write_refusal"]

        [:offer, nil]
      end

      def in_zone?(space_path)
        !Occurrences.zone_path(space_path, @zone_paths).nil?
      end

      def host_row(ids)
        return @rows[ids] if @rows.key?(ids)

        @rows[ids] = query(HOST_CONTEXT, "paths" => [ids]).fetch("faces").first
      end

      # The Zone paths, and the host rows read since, hold until the revision or the edit context changes.
      def refresh_reads
        @zone_paths = query(ZONES).fetch("zones").map { |zone| zone.dig("reference", "zone_path") }
        @rows = {}
        @read_at = [@session.revision, edit_path]
      end

      def current_reads
        refresh_reads unless @read_at == [@session.revision, edit_path]
      end

      def query(name, params = {})
        result = API.query(:context => context, :name => name, :params => params)
        raise CodedError.new(result.fetch("code"), result.fetch("message")) unless result.fetch("status") == "completed"

        result.fetch("value")
      end

      # A refusal ends the whole pending gesture; pointing at nothing does not.
      def collect(entities)
        return if @collected.nil? || entities.nil?

        kind, target = begin
          place(entities)
        rescue CodedError => error
          [:refuse, error.message]
        end
        if kind == :refuse
          reset_gesture
          announce(target, :warning)
          return
        end
        @collected.add(entities.map(&:persistent_id), { :kind => kind, :target => target, :entities => entities })
      end

      def complete
        collected = @collected
        factor = @factor
        revision = @revision
        reset_gesture
        return if collected.nil? || collected.empty?

        items = collected.values
        kinds = items.map { |item| [item[:kind], item[:target]] }.uniq
        return announce(MIXED, :warning) unless kinds.length == 1
        # Marking's operation owns the limit and refuses; adding a Volume and offering Create Space take
        # no gesture, so the gesture refuses here rather than writing the first part of what it crossed.
        return announce(too_large, :warning) if collected.full? && kinds.first.first != :mark

        paths = items.map { |item| item[:entities].map(&:persistent_id) }
        case kinds.first.first
        when :mark then mark(paths, factor, revision)
        when :volume then add_volume(items.first[:target], paths, factor, revision)
        else offer(paths)
        end
      end

      def mark(paths, factor, revision)
        outcome = invoke(MARK, { "faces" => paths, "weighting_factor" => factor }, revision)
        report(outcome, "Marked #{paths.length} #{paths.length == 1 ? 'Floor Segment' : 'Floor Segments'} at " \
                        "#{ColourModes.band(factor)}.")
      end

      def add_volume(space, paths, factor, revision)
        outcome = invoke(ADD_VOLUME, { "space" => space, "faces" => paths, "weighting_factor" => factor }, revision)
        report(outcome, "Added a Volume to the Space with #{paths.length} " \
                        "#{paths.length == 1 ? 'Floor Segment' : 'Floor Segments'}.")
      end

      # Nothing is written: the Faces are remembered for the Create Space route, which shows what it would
      # make before it makes it.
      def offer(paths)
        @offered = paths
        announce(OFFER)
      end

      def too_large
        "One Mark floor gesture takes at most #{Spaces.floor_gesture_limit} Faces. #{Outcome::NOTHING_WRITTEN}"
      end

      def invoke(name, params, revision)
        API.invoke(:context => context, :name => name, :params => params,
                   :request => { "sequence" => next_sequence, "expected_revision" => revision })
      end

      def report(outcome, done)
        if outcome.fetch("status") == "completed"
          announce(done)
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

      def reset_gesture
        @collected = nil
        @pressed = false
      end

      def cancel_gesture
        pending = !@collected.nil?
        reset_gesture
        announce(CANCELLED, :warning) if pending
      end

      # Results and refusals reach the status bar, which a viewport tool always has, and the panel's notice.
      def announce(message, tone = :info)
        @session.notice(message, :tone => tone)
        Sketchup.status_text = message if Sketchup.respond_to?(:status_text=)
      end

      def show_instructions
        return unless Sketchup.respond_to?(:status_text=)

        Sketchup.status_text = "Mark floor at weighting factor #{ColourModes.band(@weighting_factor)}: click or " \
                               "drag over Faces inside a Volume, or click a Face at a Space's root to add a Volume."
      end

      def tooltip(entities)
        return "" if entities.nil?

        kind, target = begin
          current_reads
          place(entities)
        rescue CodedError => error
          [:refuse, error.message]
        end
        { :mark => "Mark as a Floor Segment at #{ColourModes.band(@weighting_factor)}",
          :volume => "Add a Volume to this Space from this Face", :offer => "Create Space from this Face" }
          .fetch(kind, kind == :refuse ? target : "")
      end

      def draw_paths(view, paths, colour)
        return if paths.empty? || !view.respond_to?(:draw)

        triangles = []
        segments = []
        paths.each do |entities|
          transform = entities[0...-1].reduce(Geom::Transformation.new) { |sum, entity| sum * entity.transformation }
          faces, outlines = ColourBy::Tessellation.call(entities.last, transform)
          triangles.concat(faces)
          segments.concat(outlines)
        end
        view.drawing_color = Sketchup::Color.new(*colour, FILL_ALPHA) if view.respond_to?(:drawing_color=)
        view.draw(GL_TRIANGLES, ColourBy::Tessellation.lift(triangles, view, 3.0)) unless triangles.empty?
        view.drawing_color = Sketchup::Color.new(*colour, OUTLINE_ALPHA) if view.respond_to?(:drawing_color=)
        view.draw(GL_LINES, ColourBy::Tessellation.lift(segments, view, 3.0)) unless segments.empty?
      end

      def report_exception(error, view)
        pending = !@collected.nil?
        reset_gesture
        @hover = nil
        Diagnostics.exception("mark_tool", error)
        announce("The Mark floor tool could not complete that. #{Outcome::NOTHING_WRITTEN}", :error) if pending
        view.tooltip = "" if view.respond_to?(:tooltip=)
        view.invalidate if view.respond_to?(:invalidate)
      end
    end

    module_function

    # This Model's Mark floor tool, created on first reach and held as session feature state, so its factor
    # survives the tool ending and a Model closing takes it with it.
    def mark_tool(session)
      session.feature_state(:spaces_mark_tool) { MarkTool.new(session) }
    end
  end
end
