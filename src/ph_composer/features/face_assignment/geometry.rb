# frozen_string_literal: true

module PhComposer
  module FaceAssignment
    module Geometry
      module_function

      def area_m2(occurrence)
        occurrence.entity.area(occurrence.transform).to_f * SQUARE_INCH_TO_M2
      end

      def suggested_values(occurrence)
        normal = world_normal(occurrence.entity.normal, occurrence.transform)
        angle = Math.acos([[normal[2], -1.0].max, 1.0].min) * 180.0 / Math::PI
        face_type = if angle <= 60.0
                      "RoofCeiling"
                    elsif angle >= 130.0
                      "Floor"
                    else
                      "Wall"
                    end
        lowest_mm = occurrence.entity.loops.flat_map(&:vertices).map do |vertex|
          vertex.position.transform(occurrence.transform).z.to_f * 25.4
        end.min
        boundary = lowest_mm <= occurrence.zone.record.fetch("ground_depth_mm") ? "Ground" : "Outdoors"
        { "face_type" => face_type, "boundary_condition" => boundary }
      end

      def world_normal(normal, transformation)
        values = transformation.to_a
        a, b, c = values[0], values[4], values[8]
        d, e, f = values[1], values[5], values[9]
        g, h, i = values[2], values[6], values[10]
        determinant = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
        raise CodedError.new("geometry.invalid", "The Face transform is singular.") if determinant.abs < 1.0e-12

        x = ((e * i - f * h) * normal.x + (f * g - d * i) * normal.y + (d * h - e * g) * normal.z) / determinant
        y = ((c * h - b * i) * normal.x + (a * i - c * g) * normal.y + (b * g - a * h) * normal.z) / determinant
        z = ((b * f - c * e) * normal.x + (c * d - a * f) * normal.y + (a * e - b * d) * normal.z) / determinant
        length = Math.sqrt(x * x + y * y + z * z)
        raise CodedError.new("geometry.invalid", "The Face normal has no direction.") if length.zero?

        [x / length, y / length, z / length]
      end
      private_class_method :world_normal
    end
  end
end
