# frozen_string_literal: true

module PhComposer
  module FaceAssignment
    module Geometry
      module_function

      def area_m2(occurrence)
        FaceGeometry.capture(occurrence.entity, occurrence.transform).area_m2
      end

      def suggested_values(occurrence)
        normal = FaceGeometry.capture(occurrence.entity, occurrence.transform).normal
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

    end
  end
end
