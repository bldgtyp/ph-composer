# frozen_string_literal: true

require_relative "read_context"

module PhComposer
  module Windows
    module Units
      # A writable host Face as `units.place` measures it, in the frame its offsets use (right and up from the
      # Face's lowest, leftmost extent as seen from outside): its outline and that outline's bounding width and
      # height, and the bounding rectangles a placement must stay clear of there, the Face's holes and every
      # Unit outline on its plane, as Placement::Fit checks them. A Face that is not a rectangle is narrower
      # than its bounding box in places, so the outline is what an opening must stay inside. Writes nothing;
      # refuses what locating the host for a placement refuses.
      module HostExtent
        module_function

        def read(request, host_reference)
          reads = ReadContext.new(request)
          host = reads.host_reference(host_reference)
          plane = Placement::Plane.new(host.geometry)
          outer = host.geometry.outer_loop.map { |point| plane.project(point) }
          origin = [outer.map(&:first).min, outer.map(&:last).min]
          { "width_m" => outer.map(&:first).max - origin[0], "height_m" => outer.map(&:last).max - origin[1],
            "outline_m" => outer.map { |x, y| [x - origin[0], y - origin[1]] },
            "holes" => host.geometry.holes.map { |loop| rectangle(loop.map { |point| plane.project(point) }, origin) },
            "units" => units(reads, plane, origin) }
        end

        # Each Unit whose outline lies on the host's plane, glued or not and on this Face or another in the same
        # plane; one with unknown native geometry has no footprint to report.
        def units(reads, plane, origin)
          reads.occurrences.sort_by(&:path).filter_map do |item|
            polygon = reads.read_polygon(item)
            next unless polygon&.all? { |point| plane.signed_distance_m(point).abs <= FaceGeometry::QUANTUM_M }

            { "reference" => item.reference }.merge(rectangle(polygon.map { |point| plane.project(point) }, origin))
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
