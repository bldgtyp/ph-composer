# frozen_string_literal: true

require_relative "plane"

module PhComposer
  module Windows
    module Placement
      # Script offsets locate the chosen anchor from the host's minimum right/up extents. The
      # origin therefore survives harmless loop rotation and agrees with sill/edge measurements.
      module Offsets
        module_function

        def point(host_geometry, x_m:, y_m:)
          unless [x_m, y_m].all? { |value| (value.is_a?(Integer) || value.is_a?(Float)) && value.to_f.finite? }
            raise CodedError.new("params.invalid", "Placement offsets must be finite metre coordinates.")
          end

          plane = Plane.new(host_geometry)
          projected = host_geometry.outer_loop.map { |point| plane.project(point) }
          x = projected.map(&:first).min + x_m
          y = projected.map(&:last).min + y_m
          result = plane.world(x, y)
          plane.assert_on_plane!(result)
          result
        end

        def from_point(host_geometry, point_m)
          plane = Plane.new(host_geometry)
          plane.assert_on_plane!(point_m)
          projected = host_geometry.outer_loop.map { |point| plane.project(point) }
          x, y = plane.project(point_m)
          { "x_m" => x - projected.map(&:first).min, "y_m" => y - projected.map(&:last).min }
        end
      end
    end
  end
end
