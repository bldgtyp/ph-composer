# frozen_string_literal: true

require_relative "world_geometry"
require_relative "definition_geometry"
require_relative "../placement/fit"
require_relative "../placement/host"

module PhComposer
  module Windows
    module Units
      # Findings are computed from the current occurrence and explicit public host geometry.
      # A read never re-glues, rewrites geometry or normalizes copied identities.
      module State
        # The action that repairs each condition. A host Zone that is not unique has no Windows repair: the
        # Zone's identity is repaired first, and rehost refuses such a Face.
        REPAIRS = { "window.unhosted" => "rehost", "window.off_host" => "rehost", "window.overhang" => "rehost",
                    "window.overlap" => "rehost", "window.surface_host" => "rehost",
                    "window.scaled" => "reset_to_type", "window.sheared" => "reset_to_type",
                    "window.geometry_differs" => "reset_to_type", "window.definition_detached" => "reset_to_type",
                    "window.mirrored" => "new_flipped_type", "window.unknown_type" => "swap_type",
                    "window.copy_id_pending" => "repair_copied_identities" }.freeze
        # These actions name one occurrence; the others take a list.
        SINGLE_UNIT_REPAIRS = %w[rehost new_flipped_type].freeze
        # Reset to Type refuses a mirrored Window and one glued to a Surface Face or a Face outside one
        # unique Zone, so it is not offered beside those conditions.
        RESET_REFUSED = %w[window.mirrored window.surface_host window.host_zone_unresolved].freeze

        module_function

        def findings(occurrence, type:, canonical_definition:, host_geometry: nil,
                     existing_polygons_m: [], shared_id: false, host_values: {}, host_state: "found")
          codes = []
          codes << "window.copy_id_pending" if shared_id
          # A host read is a Face in a Zone, so its Zone state is reported below rather than as unclassified.
          codes.concat(Placement::Hosts.conditions(host_values, :zoned => true)) if host_geometry
          codes << "window.host_zone_unresolved" if host_geometry && host_state != "found"
          transform = WorldGeometry.transform_state(occurrence.transform.to_a)
          codes << "window.scaled" if transform.scaled
          codes << "window.sheared" if transform.sheared
          codes << "window.mirrored" if transform.mirrored
          codes << "window.unknown_type" unless type
          if type
            plan = DefinitionPlan.build(type)
            definition = occurrence.entity.definition
            codes << "window.definition_detached" unless canonical_definition &&
                                                         definition.persistent_id == canonical_definition.persistent_id
            codes << "window.geometry_differs" unless DefinitionGeometry.matches?(definition,
                                                                                  :type_id => type.fetch("id"),
                                                                                  :plan => plan)
            hosted(codes, occurrence, plan, host_geometry, existing_polygons_m)
          elsif !occurrence.entity.glued_to || !host_geometry
            codes << "window.unhosted"
          end
          codes.uniq!
          codes.map { |code| { "code" => code, "repair" => repair(code, occurrence.reference, codes) } }
        end

        # The operation that repairs a condition, as `{ name, params }`, or nil. A rehost still needs its
        # `host` and a swap its `type_id`; the caller adds them.
        def repair(code, reference, codes)
          action = REPAIRS[code]
          return nil unless action
          # Every action but swap needs the Window's Type.
          return nil if codes.include?("window.unknown_type") && action != "swap_type"
          return nil if action == "reset_to_type" && (codes & RESET_REFUSED).any?

          unit = DeepCopy.call(reference)
          { "name" => "#{FEATURE_ID}.units.#{action}",
            "params" => SINGLE_UNIT_REPAIRS.include?(action) ? { "unit" => unit } : { "units" => [unit] } }
        end

        def hosted(codes, occurrence, plan, host_geometry, existing_polygons_m)
          unless occurrence.entity.glued_to && host_geometry
            codes << "window.unhosted"
            return
          end
          polygon = WorldGeometry.map(plan, occurrence.transform.to_a).outer_polygon_m
          plane = Placement::Plane.new(host_geometry)
          if polygon.any? { |point| plane.signed_distance_m(point).abs > FaceGeometry::QUANTUM_M }
            codes << "window.off_host"
            return
          end
          Placement::Fit.check!(host_geometry, polygon, :existing_polygons_m => existing_polygons_m)
        rescue CodedError => error
          raise unless %w[window.overhang window.overlap].include?(error.code)

          codes << error.code
        end

        private_class_method :hosted
      end
    end
  end
end
