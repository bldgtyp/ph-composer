# frozen_string_literal: true

module PhComposer
  module Zones
    module Faces
      module Geometry
        module_function

        def area_m2(occurrence)
          FaceGeometry.capture(occurrence.entity, occurrence.transform).area_m2
        end

        def suggested_values(occurrence, settings: Settings::DEFAULTS)
          normal = FaceGeometry.capture(occurrence.entity, occurrence.transform).normal
          angle = Math.acos([[normal[2], -1.0].max, 1.0].min) * 180.0 / Math::PI
          face_type = if angle <= settings.fetch("roof_angle_deg")
                        "RoofCeiling"
                      elsif angle >= settings.fetch("floor_angle_deg")
                        "Floor"
                      else
                        "Wall"
                      end
          # Ground only when the whole Face is at or below the Zone's ground depth, which is
          # honeybee's own rule: `get_bc_from_position` returns Outdoors as soon as one vertex is
          # above it. Asking whether the lowest vertex is at or below instead made every wall
          # standing on grade read as Ground, since such a wall starts exactly at the depth.
          highest_mm = occurrence.entity.loops.flat_map(&:vertices).map do |vertex|
            vertex.position.transform(occurrence.transform).z.to_f * 25.4
          end.max
          boundary = highest_mm <= occurrence.zone.record.fetch("ground_depth_mm") ? "Ground" : "Outdoors"
          { "face_type" => face_type, "boundary_condition" => boundary }
        end

      end
    end
  end
end
