# frozen_string_literal: true

require_relative "state"
require_relative "generated_geometry"
require_relative "../placement/host"

module PhComposer
  module Windows
    module Units
      # Public Zones reads and one Window inventory per action/read, with no private Zone
      # dictionaries. Include unglued occurrences when measuring same-plane conflicts.
      class ReadContext
        attr_reader :occurrences

        def initialize(request)
          @request = request
          @occurrences = Occurrences.all(request.model)
          @types = request.engine.ids(TYPE_KIND).to_h { |id| [id, request.engine.find(TYPE_KIND, id)] }
          @faces = request.query("ph_composer.zones.faces.all").fetch("faces")
          @zones = request.query("ph_composer.zones.all").fetch("zones")
          @hosts = {}
        end

        def type(item)
          @types[item.record.fetch("window_type_id")]
        end

        def polygon(item)
          authored = type(item)
          definition = item.entity.definition
          type_id = item.record.fetch("window_type_id")
          plan = authored && DefinitionPlan.build(authored)
          primary_id = DefinitionIndex.read(@request.model)[type_id]
          if plan && primary_id == definition.persistent_id &&
             DefinitionGeometry.matches?(definition, :type_id => type_id, :plan => plan)
            # An all-Empty definition has no pane bounds. Its generation datum still carries
            # a stale native footprint even when the current empty Type has different dimensions.
            stamp = DEFINITION_STORE.read(definition)
            if stamp.key?("generated_size_m")
              generated = GeneratedGeometry.plan(definition, :type_id => type_id)
              plan = generated unless [plan.width_m, plan.height_m] == [generated.width_m, generated.height_m]
            end
          else
            plan = GeneratedGeometry.plan(definition, :type_id => type_id)
          end
          WorldGeometry.map(plan, item.transform.to_a).outer_polygon_m
        end

        # Uncertain native geometry remains readable, but cannot supply a mutation footprint.
        # Malformed persisted records continue to refuse rather than disappearing from reads.
        def read_polygon(item)
          polygon(item)
        rescue CodedError => error
          raise unless error.code == "window.type_geometry_unknown"

          nil
        end

        def other_polygons(except: [])
          occurrences.reject { |item| except.include?(item.path) }.map { |item| polygon(item) }
        end

        def host(item, writable: true)
          return nil unless item.entity.glued_to

          native_path = item.path[0...-1] + [item.entity.glued_to.persistent_id]
          row = @faces.find do |face|
            reference = face.fetch("reference")
            reference.fetch("zone_path") + reference.fetch("entity_path") == native_path
          end
          return nil unless row

          reference = row.fetch("reference")
          @hosts[[native_path, writable]] ||= Placement::Hosts.resolve(@request.model, reference, :writable => writable,
            :zone_rows => @zones, :face_rows => @faces)
        end

        def host_reference(reference)
          Placement::Hosts.resolve(@request.model, reference, :zone_rows => @zones, :face_rows => @faces)
        end
      end
    end
  end
end
