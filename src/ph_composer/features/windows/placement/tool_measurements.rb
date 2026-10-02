# frozen_string_literal: true

require_relative "offsets"

module PhComposer
  module Windows
    module Placement
      # Native VCB parsing uses the Model's length display rules; internal placement stays SI.
      class ToolMeasurements
        def initialize
          @values = {}
        end

        def clear
          @values.clear
        end

        def set(text)
          match = /\A\s*(sill|offset)\s*=\s*(.+)\z/i.match(text.to_s)
          invalid! unless match
          length = Sketchup.parse_length(match[2])
          metres = length && length.to_f * INCH_TO_M
          invalid! unless metres && metres.finite? && metres >= 0

          @values[match[1].downcase] = metres
        rescue ArgumentError
          invalid!
        end

        def point(geometry, point_m, plan, anchor)
          plane = Plane.new(geometry)
          position = plane.project(point_m).dup
          boundary = geometry.outer_loop.map { |point| plane.project(point) }
          if @values.key?("offset")
            position = inset(position, boundary, @values.fetch("offset"))
          end
          if @values.key?("sill")
            vertical = 1 - Units::Anchors::FRACTIONS.fetch(anchor).last
            position[1] = boundary.map(&:last).min + @values.fetch("sill") + plan.height_m * vertical
          end
          3.times.map do |axis|
            plane.origin_m[axis] + plane.x_axis[axis] * position[0] + plane.y_axis[axis] * position[1]
          end
        end

        private

        def inset(point, boundary, distance)
          nearest = boundary.each_with_index.map do |a, index|
            b = boundary[(index + 1) % boundary.length]
            delta = [b[0] - a[0], b[1] - a[1]]
            square = delta.sum { |value| value * value }
            next unless square.positive?
            fraction = [[point.zip(a).zip(delta).sum { |(p, origin), d| (p - origin) * d } / square, 0].max, 1].min
            foot = a.zip(delta).map { |origin, d| origin + d * fraction }
            [point.zip(foot).sum { |p, f| (p - f)**2 }, foot, delta, Math.sqrt(square)]
          end.compact.min_by(&:first)
          invalid! unless nearest
          _square, foot, delta, size = nearest
          area = boundary.each_with_index.sum do |point, index|
            following = boundary[(index + 1) % boundary.length]
            point[0] * following[1] - following[0] * point[1]
          end
          sign = area.negative? ? -1 : 1
          normal = [-delta[1] / size * sign, delta[0] / size * sign]
          foot.zip(normal).map { |value, direction| value + direction * distance }
        end

        def invalid!
          raise CodedError.new("params.invalid", "Type sill=<length> or offset=<length>, with a nonnegative length.")
        end
      end
    end
  end
end
