# frozen_string_literal: true

module PhComposer
  module ColourBy
    # The one `Sketchup::Overlay` a Model gets while a Colour-by mode is active. It draws what the
    # service already cached and nothing else: no Model read, no record read and no repair, so the
    # cost of a frame is the marshalling B2 measured
    # ([spike](../../../planning/archive/phase-zero/evidence/spike-overlay.md)).
    #
    # Fills are batched per colour, one `View#draw` a legend row rather than one a face, because that
    # marshalling is what dominates past about 10,000 triangles.
    class Overlay < Sketchup::Overlay
      OVERLAY_ID = "#{EXTENSION_ID}.colour_by"
      LINE_WIDTH = 2
      # The HUD sits in the upper left of the viewport (face-assignment PRD "Viewport HUD legend").
      HUD_ORIGIN = [12, 12].freeze
      HUD_ROW_HEIGHT = 18
      HUD_SWATCH = 12

      def initialize(service)
        super(OVERLAY_ID, "PH-Composer Colour by", :description => "Colours the Model by the active mode.")
        @service = service
      end

      def draw(view)
        return unless @service.active?

        @service.fills.each do |colour, points|
          next if points.empty?

          view.drawing_color = fill_colour(colour)
          view.draw(GL_TRIANGLES, Tessellation.lift(points, view))
        end
        draw_outlines(view)
        draw_hud(view)
      end

      private

      def draw_outlines(view)
        view.line_width = LINE_WIDTH
        @service.outlines.each do |colour, points|
          next if points.empty?

          view.drawing_color = outline_colour(colour)
          view.draw(GL_LINES, Tessellation.lift(points, view))
        end
        return if @service.unclassified_outlines.empty?

        # Unclassified entities are not filled: an absent record should not read as a colour choice.
        view.line_stipple = "-" if view.respond_to?(:line_stipple=)
        view.drawing_color = outline_colour(Palette::UNCLASSIFIED)
        view.draw(GL_LINES, Tessellation.lift(@service.unclassified_outlines, view))
        view.line_stipple = "" if view.respond_to?(:line_stipple=)
      end

      # The legend the HUD draws is the panel's legend: one source, so a QA screenshot and the panel
      # never disagree.
      def draw_hud(view)
        left, top = HUD_ORIGIN
        draw_hud_text(view, left, top, @service.mode&.label.to_s)
        @service.rows.each_with_index do |row, index|
          row_top = top + ((index + 1) * HUD_ROW_HEIGHT)
          draw_swatch(view, left, row_top, row.colour)
          draw_hud_text(view, left + HUD_SWATCH + 6, row_top, "#{row.label} (#{row.count})")
        end
      end

      def draw_swatch(view, left, top, colour)
        return unless view.respond_to?(:draw2d)

        view.drawing_color = fill_colour(colour)
        view.draw2d(GL_TRIANGLES, [
                      Geom::Point3d.new(left, top, 0), Geom::Point3d.new(left + HUD_SWATCH, top, 0),
                      Geom::Point3d.new(left + HUD_SWATCH, top + HUD_SWATCH, 0),
                      Geom::Point3d.new(left, top, 0), Geom::Point3d.new(left + HUD_SWATCH, top + HUD_SWATCH, 0),
                      Geom::Point3d.new(left, top + HUD_SWATCH, 0)
                    ])
      end

      def draw_hud_text(view, left, top, text)
        return unless view.respond_to?(:draw_text)

        view.draw_text(Geom::Point3d.new(left, top, 0), text)
      end

      def fill_colour(colour)
        Sketchup::Color.new(colour[0], colour[1], colour[2], Palette::FILL_ALPHA)
      end

      def outline_colour(colour)
        Sketchup::Color.new(colour[0], colour[1], colour[2], Palette::OUTLINE_ALPHA)
      end
    end
  end
end
