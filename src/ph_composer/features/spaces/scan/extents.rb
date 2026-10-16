# frozen_string_literal: true

module PhComposer
  module Spaces
    # Pure: whether a Space is drawn off to the side of its Zone, which export allows and the report
    # names in one line. A Space is outside when any point of its Floor Segments' outer loops falls outside the
    # plan rectangle around its Zone's own Faces, by more than the tolerance. Points are world metres.
    module Extents
      TOLERANCE_M = 0.01

      module_function

      def outside?(space_points, zone_points)
        return false if space_points.empty? || zone_points.empty?

        xs = zone_points.map { |point| point[0] }
        ys = zone_points.map { |point| point[1] }
        space_points.any? do |x, y, _z|
          x < xs.min - TOLERANCE_M || x > xs.max + TOLERANCE_M || y < ys.min - TOLERANCE_M || y > ys.max + TOLERANCE_M
        end
      end
    end
  end
end
