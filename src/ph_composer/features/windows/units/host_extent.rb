# frozen_string_literal: true

require_relative "read_context"

module PhComposer
  module Windows
    module Units
      # A writable host Face as `units.place` measures it, in the frame its offsets use (right and up from the
      # Face's lowest, leftmost extent as seen from outside): its outline and that outline's bounding width and
      # height, and the bounding rectangles a placement must stay clear of there, the Face's holes and the
      # Unit outlines on its plane that meet it, as Placement::Fit checks them. A Face that is not a rectangle
      # is narrower than its bounding box in places, so the outline is what an opening must stay inside.
      # Writes nothing; refuses what locating the host for a placement refuses.
      # The Unit rows come in bounded pages (Pages.bounded), so a facade carrying hundreds of Windows still
      # answers within an agent's reply budget; the Face's own extent comes on every page.
      module HostExtent
        QUERY = "#{FEATURE_ID}.units.host_extent"

        module_function

        def read(request, host_reference)
          reads = ReadContext.new(request)
          host = reads.host_reference(host_reference)
          plane = Placement::Plane.new(host.geometry)
          outer = host.geometry.outer_loop.map { |point| plane.project(point) }
          origin = [outer.map(&:first).min, outer.map(&:last).min]
          width = outer.map(&:first).max - origin[0]
          height = outer.map(&:last).max - origin[1]
          rows = units(reads, plane, origin, width, height)
          key = ->(row) { row.dig("reference", "entity_path") }
          page, next_cursor = Pages.bounded(request, QUERY, rows, :key => key)
          { "width_m" => width, "height_m" => height,
            "outline_m" => outer.map { |x, y| [x - origin[0], y - origin[1]] },
            "holes" => host.geometry.holes.map { |loop| rectangle(loop.map { |point| plane.project(point) }, origin) },
            "units" => page, "next_cursor" => next_cursor, "total" => rows.length }
        end

        # Each Unit outline on the host's plane, glued or not, that meets the Face's bounding box: one anywhere
        # else on the plane cannot conflict with an opening inside the Face. One with unknown native geometry
        # has no footprint to report.
        def units(reads, plane, origin, width, height)
          reads.occurrences.sort_by(&:path).filter_map do |item|
            polygon = reads.read_polygon(item)
            next unless polygon&.all? { |point| plane.signed_distance_m(point).abs <= FaceGeometry::QUANTUM_M }

            box = rectangle(polygon.map { |point| plane.project(point) }, origin)
            next unless box["x_m"] <= width && box["x_m"] + box["width_m"] >= 0 &&
                        box["y_m"] <= height && box["y_m"] + box["height_m"] >= 0

            { "reference" => item.reference }.merge(box)
          end
        end

        def rectangle(points, origin)
          xs = points.map(&:first)
          ys = points.map(&:last)
          { "x_m" => xs.min - origin[0], "y_m" => ys.min - origin[1], "width_m" => xs.max - xs.min,
            "height_m" => ys.max - ys.min }
        end
        private_class_method :units, :rectangle
      end
    end
  end
end
