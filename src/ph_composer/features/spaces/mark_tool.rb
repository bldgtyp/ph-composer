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
    class MarkTool
      MARK = "#{FEATURE_ID}.floors.mark"
      ADD_VOLUME = "#{FEATURE_ID}.volumes.create"
      HOVER_COLOUR = [184, 59, 59].freeze
      COLLECTED_COLOUR = [47, 143, 131].freeze
      FILL_ALPHA = 90
      OUTLINE_ALPHA = 230
      OUTSIDE_ZONE = "That Face is in no Zone. Make it a Zone first, then mark floors in its Spaces."
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

      # Sets the factor and starts the tool, turning on Colour by weighting factor and leaving it on.
      def start(weighting_factor)
        @weighting_factor = Float(weighting_factor)
        ColourBy.for(@session).activate(ColourModes::BY_WEIGHTING_FACTOR) if ColourBy.registered?(
          ColourModes::BY_WEIGHTING_FACTOR
        )
        model = @session.model
        model.select_tool(self) if model.respond_to?(:select_tool)
        show_instructions
        @session.request_refresh
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

      def onMouseMove(_flags, x, y, view)
        path = Pick.face_path(view, x, y)
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
        @scan = Occurrences.scan(@session.model)
        @collected = DragSet.new(:limit => Spaces.floor_gesture_limit)
        collect(Pick.face_path(view, x, y))
        view.invalidate if view.respond_to?(:invalidate)
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

      # What one picked Face means, as `[place, target]`: `:mark` with its Volume, `:volume` with its
      # Space, `:offer`, or a refusal message.
      def place(entities)
        ids = entities.map(&:persistent_id)
        parent = ids[0...-1]
        volume = @scan.volumes.find { |candidate| candidate.path == parent }
        return [:mark, volume] if volume

        space = @scan.spaces.find { |candidate| candidate.path == parent }
        return [:volume, space] if space

        zone_face = Zones::Occurrences.occurrence_for_path(entities)
        return [:refuse, OUTSIDE_ZONE] unless zone_face

        # Whether it is one of the Zone's classified Faces is asked of the Faces read when the gesture ends.
        [:offer, zone_face]
      end

      # A Face directly in a Zone that the Faces feature has a record for is the Zone's own, classified in the
      # Faces view; asked through its public list, one Zone at a time.
      def classified?(zone_face)
        reference = zone_face.reference(nil)
        cursor = nil
        loop do
          params = { "zone_paths" => [reference.fetch("zone_path")], "fields" => ["face_type"], "limit" => 500 }
          params["cursor"] = cursor if cursor
          page = API.query(:context => context, :name => "ph_composer.zones.faces.list", :params => params)
          return false unless page.fetch("status") == "completed"

          value = page.fetch("value")
          row = value.fetch("faces").find do |face|
            face.dig("reference", "entity_path") == reference.fetch("entity_path")
          end
          return !row.dig("reference", "entity_id").nil? if row

          cursor = value["next_cursor"]
          return false unless cursor
        end
      end

      # A refusal ends the whole pending gesture; pointing at nothing does not.
      def collect(entities)
        return if @collected.nil? || entities.nil?

        kind, target = place(entities)
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
        kinds = items.map { |item| [item[:kind], item[:kind] == :volume ? item[:target].path : nil] }.uniq
        return announce(MIXED, :warning) unless kinds.length == 1

        paths = items.map { |item| item[:entities].map(&:persistent_id) }
        if kinds.first.first == :offer && items.any? { |item| classified?(item[:target]) }
          return announce(ZONE_FACE, :warning)
        end

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
        outcome = invoke(ADD_VOLUME, { "space" => space.reference, "faces" => paths, "weighting_factor" => factor },
                         revision)
        report(outcome, "Added a Volume to the Space with #{paths.length} " \
                        "#{paths.length == 1 ? 'Floor Segment' : 'Floor Segments'}.")
      end

      # Nothing is written: the Faces are remembered for the Create Space route, which shows what it would
      # make before it makes it.
      def offer(paths)
        @offered = paths
        announce(OFFER)
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
        @scan = nil
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

        @scan = Occurrences.scan(@session.model)
        kind, target = place(entities)
        @scan = nil
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
