# frozen_string_literal: true

module PhComposer
  module Spaces
    # Pure: a Volume's preview prism, one prism per Floor Segment. Each segment's outer loop is projected
    # onto the horizontal plane at the loop's mean height, the projection the metrics use, and extruded up
    # by the Volume's average clear ceiling height: a base, a top and one side per edge. Points are world
    # coordinates in metres, so the Colour-by modes draw it and the export writes it from the same value.
    # A Volume with no height has no prism. A hole in a segment is subtracted from its area by the metrics
    # but not cut from its prism, since a drawn polygon has one loop.
    module Prism
      # Projected points closer than this (metres) are one point.
      COINCIDENT_M = 1e-9

      module_function

      # `loops_m` holds each segment's world outer loop in metres; answers one list of polygons per segment.
      def call(loops_m, height_m)
        return [] if height_m.nil? || height_m <= 0

        loops_m.filter_map { |loop| segment(loop, height_m) }
      end

      def segment(loop, height_m)
        base_z = loop.sum { |point| point[2].to_f } / loop.length
        base = distinct(loop.map { |x, y, _z| [x, y, base_z] })
        return nil if base.length < 3

        top = base.map { |x, y, z| [x, y, z + height_m] }
        sides = base.each_index.map do |index|
          following = (index + 1) % base.length
          [base[index], base[following], top[following], top[index]]
        end
        [base, top, *sides]
      end

      # Drops a point that repeats the one before it in plan, as a vertical edge of a sloped loop would.
      def distinct(points)
        points.each_with_object([]) do |point, kept|
          kept << point unless kept.last && same?(kept.last, point)
        end.then { |kept| kept.length > 1 && same?(kept.first, kept.last) ? kept[0...-1] : kept }
      end

      def same?(first, second)
        (first[0] - second[0]).abs < COINCIDENT_M && (first[1] - second[1]).abs < COINCIDENT_M
      end

      # The prisms' enclosed volume in m3: each base's plan area times the height.
      def volume_m3(prisms, height_m)
        prisms.sum { |polygons| Metrics.plan_area(polygons.first, polygons.first.first) * height_m }
      end
    end
  end
end
