# frozen_string_literal: true

module PhComposer
  module Zones
    module Faces
      # What Locate leaves in the viewport: an outline on the Faces it framed, drawn by one
      # `Sketchup::Overlay` while there is something to show. It changes no selection and no Model, and
      # it lasts until the next Locate, the next selection change or an explicit clear, which is what
      # the panel sends on Escape and on its next pointer press.
      #
      # It is this feature's own overlay rather than a Colour-by mode: it shows whether or not Colour by
      # is on, and the Colour-by service names no feature.
      class LocateHighlight
        OVERLAY_ID = "#{EXTENSION_ID}.zones.locate"
        COLOUR = [0, 170, 200].freeze
        LINE_WIDTH = 4

        attr_reader :segments

        def initialize(session)
          @session = session
          @segments = []
          @overlay = nil
        end

        def active?
          !@segments.empty?
        end

        # `found` is the Face occurrences Locate resolved; each carries its parent-to-world transform.
        def show(found)
          @segments = found.flat_map { |face| ColourBy::Tessellation.call(face.entity, face.transform).last }
          active? ? attach_overlay : detach_overlay
          invalidate_view
          self
        end

        def clear
          return self unless active? || @overlay

          @segments = []
          detach_overlay
          invalidate_view
          self
        end

        def detach
          @segments = []
          detach_overlay
        end

        private

        # An overlay added through `OverlaysManager#add` starts disabled and never draws until it is
        # enabled (context/SKETCHUP_HOST_BEHAVIOR.md, "Overlays"). It is enabled once, when it is added,
        # so a user who unticks it in the Overlays panel keeps that choice until the outline goes.
        def attach_overlay
          model = live_model
          return if @overlay || model.nil?

          @overlay = Overlay.new(self)
          model.overlays.add(@overlay)
          @overlay.enabled = true if @overlay.respond_to?(:enabled=)
        end

        def detach_overlay
          overlay = @overlay
          @overlay = nil
          model = live_model
          model.overlays.remove(overlay) if overlay && model
        end

        def live_model
          model = @session.model
          return nil unless model.respond_to?(:overlays)

          model.respond_to?(:valid?) && !model.valid? ? nil : model
        end

        def invalidate_view
          model = live_model
          view = model.respond_to?(:active_view) ? model.active_view : nil if model
          view&.invalidate
        end

        # Draws the cached outline and nothing else; points are lifted toward the eye so the line does
        # not z-fight the Face edges it traces.
        class Overlay < Sketchup::Overlay
          def initialize(highlight)
            super(OVERLAY_ID, "PH-Composer Locate", :description => "Outlines the Faces Locate framed.")
            @highlight = highlight
          end

          def draw(view)
            return unless @highlight.active?

            view.line_width = LINE_WIDTH
            view.line_stipple = "" if view.respond_to?(:line_stipple=)
            view.drawing_color = Sketchup::Color.new(*COLOUR)
            view.draw(GL_LINES, ColourBy::Tessellation.lift(@highlight.segments, view))
          end
        end
      end

      module_function

      def locate_highlight(session)
        session.feature_state(:faces_locate_highlight) { LocateHighlight.new(session) }
      end
    end
  end
end
