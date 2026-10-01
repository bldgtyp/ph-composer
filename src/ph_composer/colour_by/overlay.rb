# frozen_string_literal: true

module PhComposer
  module ColourBy
    # The one `Sketchup::Overlay` a Model gets while a Colour-by mode is active. It draws what the
    # service already cached and nothing else: no Model read, no record read and no repair, so the
    # cost of a frame is Ruby marshalling (context/SKETCHUP_HOST_BEHAVIOR.md, "Overlays").
    #
    # Fills are batched per colour, one `View#draw` a legend row rather than one a face, because that
    # marshalling is what dominates past about 10,000 triangles.
    class Overlay < Sketchup::Overlay
      OVERLAY_ID = "#{EXTENSION_ID}.colour_by"
      LINE_WIDTH = 2
      # The HUD sits in the upper left of the viewport.
      HUD_ORIGIN = [12, 12].freeze
      HUD_ROW_HEIGHT = 18
      HUD_SWATCH = 12

      def initialize(service)
        super(OVERLAY_ID, "PH-Composer Colour by", :description => "Colours the Model by the active mode.")
        @service = service
      end

      def draw(view)
        return unless @service.active?

        draw_wash(view)
        @service.fills.each do |colour, points|
          next if points.empty?

          view.drawing_color = fill_colour(colour)
          view.draw(GL_TRIANGLES, Tessellation.lift(points, view))
        end
        draw_outlines(view)
        draw_hud(view)
      end

      private

      def draw_wash(view)
        return if @service.wash_triangles.empty?

        colour = Palette::ISOLATION_WASH
        view.drawing_color = Sketchup::Color.new(*colour, Palette::ISOLATION_WASH_ALPHA)
        view.draw(GL_TRIANGLES, Tessellation.lift(@service.wash_triangles, view))
      end

      def draw_outlines(view)
        view.line_width = LINE_WIDTH
        # Classified Faces carry fills only. Their native edges remain available to SketchUp's
        # selection, hover and inference highlights, including Outdoors' similar blue.
        return if @service.unclassified_outlines.empty? && @service.unclassified_hatch.empty?

        # A solid boundary remains legible on tiny Faces where no six-inch stripe crosses the mesh.
        # Hatch points were clipped and cached at rebuild time; draw only lifts them toward the eye.
        view.line_stipple = "" if view.respond_to?(:line_stipple=)
        view.drawing_color = outline_colour(Palette::UNCLASSIFIED)
        unless @service.unclassified_outlines.empty?
          view.draw(GL_LINES, Tessellation.lift(@service.unclassified_outlines, view))
        end
        return if @service.unclassified_hatch.empty?

        view.line_width = 1
        view.draw(GL_LINES, Tessellation.lift(@service.unclassified_hatch, view))
      end

      # The legend the HUD draws is the panel's legend: one source, so a QA screenshot and the panel
      # never disagree.
      def draw_hud(view)
        left, top = HUD_ORIGIN
        draw_hud_text(view, left, top, @service.mode&.label.to_s)
        if @service.isolated
          row = @service.rows.find { |item| [item.value, item.state] == @service.isolated }
          top += HUD_ROW_HEIGHT
          draw_hud_text(view, left, top, "Showing only: #{row.label}") if row
        end
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
