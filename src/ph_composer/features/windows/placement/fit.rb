# frozen_string_literal: true

require_relative "plane"
require_relative "polygons"

module PhComposer
  module Windows
    module Placement
      # Host glue alone proves neither containment nor availability. This pure check uses detached
      # world polygons, including actual host holes and other unit outlines on the same plane.
      module Fit
        module_function

        def check!(host, outer_polygon_m, existing_polygons_m: [])
          unless outer_polygon_m.is_a?(Array) && outer_polygon_m.length == 4
            raise CodedError.new("geometry.invalid", "A four-corner Window outline is required.")
          end

          plane = Plane.new(host)
          candidate = outer_polygon_m.map do |point|
            plane.assert_on_plane!(point)
            plane.project(point)
          end
          boundary = host.outer_loop.map { |point| plane.project(point) }
          holes = host.holes.map do |loop|
            loop.map do |point|
              plane.assert_on_plane!(point)
              plane.project(point)
            end
          end
          unless Polygons.contained?(candidate, boundary) && holes.none? { |hole| Polygons.overlap?(candidate, hole) }
            raise CodedError.new("window.overhang", "The Window outline leaves its host Face or crosses a hole.")
          end
          if existing_polygons_m.any? { |polygon| conflict?(plane, candidate, polygon) }
            raise CodedError.new("window.overlap", "The Window outline overlaps another unit on this host plane.")
          end

          true
        end

        def conflict?(plane, candidate, polygon)
          return false unless polygon.all? { |point| plane.signed_distance_m(point).abs <= FaceGeometry::QUANTUM_M }

          Polygons.overlap?(candidate, polygon.map { |point| plane.project(point) })
        end
        private_class_method :conflict?
      end
    end
  end
end
