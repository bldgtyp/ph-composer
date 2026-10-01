# frozen_string_literal: true

require_relative "state"
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
          unless authored
            raise CodedError.new("window.unknown_type",
              "A Window unit has no known Type; its outline cannot be checked.")
          end
          WorldGeometry.map(DefinitionPlan.build(authored), item.transform.to_a).outer_polygon_m
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
          @hosts[[native_path, writable]] ||= Placement::Hosts.resolve(@request, reference, :writable => writable,
            :zone_rows => @zones, :face_rows => @faces)
        end

        def host_reference(reference)
          Placement::Hosts.resolve(@request, reference, :zone_rows => @zones, :face_rows => @faces)
        end
      end
    end
  end
end
