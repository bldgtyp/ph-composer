# frozen_string_literal: true

require_relative "offsets"

module PhComposer
  module Windows
    module Placement
      # Native VCB parsing uses the Model's length display rules; internal placement stays SI.
      class ToolMeasurements
        # The closest point on one boundary edge, with that edge's direction and length, in plane metres.
        EdgeFoot = Struct.new(:foot, :direction, :length, keyword_init: true)

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
          plane.world(position[0], position[1])
        end

        private

        # The point `distance` inside the boundary from the edge nearest `point`, along that edge's inward
        # normal. The boundary's winding, from its signed area, says which side is inward.
        def inset(point, boundary, distance)
          nearest = nearest_edge(point, boundary)
          invalid! unless nearest
          area = boundary.each_with_index.sum do |corner, index|
            following = boundary[(index + 1) % boundary.length]
            corner[0] * following[1] - following[0] * corner[1]
          end
          sign = area.negative? ? -1 : 1
          delta = nearest.direction
          size = nearest.length
          normal = [-delta[1] / size * sign, delta[0] / size * sign]
          nearest.foot.zip(normal).map { |value, direction| value + direction * distance }
        end

        # The EdgeFoot on the boundary edge closest to `point`; nil when every edge has no length.
        def nearest_edge(point, boundary)
          feet = boundary.each_with_index.filter_map do |a, index|
            b = boundary[(index + 1) % boundary.length]
            delta = [b[0] - a[0], b[1] - a[1]]
            square = delta.sum { |value| value * value }
            next unless square.positive?

            fraction = [[point.zip(a).zip(delta).sum { |(p, origin), d| (p - origin) * d } / square, 0].max, 1].min
            foot = a.zip(delta).map { |origin, d| origin + d * fraction }
            [point.zip(foot).sum { |p, f| (p - f)**2 }, EdgeFoot.new(:foot => foot, :direction => delta,
                                                                     :length => Math.sqrt(square))]
          end
          feet.min_by(&:first)&.last
        end

        def invalid!
          raise CodedError.new("params.invalid", "Type sill=<length> or offset=<length>, with a nonnegative length.")
        end
      end
    end
  end
end
