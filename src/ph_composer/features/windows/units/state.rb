# frozen_string_literal: true

require_relative "world_geometry"
require_relative "definition_geometry"
require_relative "../placement/fit"

module PhComposer
  module Windows
    module Units
      # Findings are computed from the current occurrence and explicit public host geometry.
      # A read never re-glues, rewrites geometry or normalizes copied identities.
      module State
        REPAIRS = { "unhosted" => "rehost", "off_host" => "rehost", "overlapping" => "rehost",
          "scaled" => "reset_to_type", "sheared" => "reset_to_type", "mirrored" => "new_flipped_type",
          "geometry_differs" => "reset_to_type", "detached_definition" => "reset_to_type",
          "unknown_type" => "swap_type", "copy_id_pending" => "repair_copied_identities",
          "invalid_host" => "rehost" }.freeze
        module_function

        def findings(occurrence, type:, canonical_definition:, host_geometry: nil,
                     existing_polygons_m: [], shared_id: false, host_values: {}, host_state: "found")
          codes = []
          codes << "copy_id_pending" if shared_id
          codes << "invalid_host" if host_values["boundary_condition"] == "Surface"
          codes << "invalid_host" if host_geometry && host_state != "found"
          transform = WorldGeometry.transform_state(occurrence.transform.to_a)
          codes << "scaled" if transform.scaled
          codes << "sheared" if transform.sheared
          codes << "mirrored" if transform.mirrored
          codes << "unknown_type" unless type
          if type
            plan = DefinitionPlan.build(type)
            definition = occurrence.entity.definition
            codes << "detached_definition" unless canonical_definition &&
              definition.persistent_id == canonical_definition.persistent_id
            codes << "geometry_differs" unless DefinitionGeometry.matches?(definition,
              :type_id => type.fetch("id"), :plan => plan)
            hosted(codes, occurrence, plan, host_geometry, existing_polygons_m)
          elsif !occurrence.entity.glued_to || !host_geometry
            codes << "unhosted"
          end
          codes.uniq.map { |code| { "code" => code, "repair" => REPAIRS.fetch(code) } }
        end

        def hosted(codes, occurrence, plan, host_geometry, existing_polygons_m)
          unless occurrence.entity.glued_to && host_geometry
            codes << "unhosted"
            return
          end
          polygon = WorldGeometry.map(plan, occurrence.transform.to_a).outer_polygon_m
          plane = Placement::Plane.new(host_geometry)
          if polygon.any? { |point| plane.signed_distance_m(point).abs > FaceGeometry::QUANTUM_M }
            codes << "off_host"
            return
          end
          Placement::Fit.check!(host_geometry, polygon, :existing_polygons_m => existing_polygons_m)
        rescue CodedError => error
          raise unless %w[window.overhang window.overlap].include?(error.code)

          codes << (error.code == "window.overlap" ? "overlapping" : "off_host")
        end

        private_class_method :hosted
      end
    end
  end
end
