# frozen_string_literal: true

module PhComposer
  module Windows
    module Placement
      Host = Struct.new(:entity, :entities, :parent_path, :transform, :reference, :values, :geometry,
                        :zone_state, keyword_init: true)

      # Face semantics come from the caller's Zones reads, passed in as rows. The SDK path walk resolves
      # only native geometry/storage, never another feature's dictionaries or private resolver.
      module Hosts
        module_function

        def resolve(model, reference, zone_rows:, face_rows:, writable: true)
          zone_reference = reference.slice("zone_id", "zone_path")
          zone = zone_rows.find { |row| row.fetch("reference") == zone_reference }
          unless zone && (!writable || zone.fetch("state") == "found")
            raise CodedError.new("target.not_found", "Choose a Face in one writable, unambiguous Zone.")
          end
          row = face_rows.find { |item| item.fetch("reference") == reference }
          raise CodedError.new("target.changed", "The host Face reference no longer matches the Zone read.") unless row

          if writable && row.fetch("values")["boundary_condition"] == "Surface"
            raise CodedError.new("window.surface_host", "A paired Surface Face cannot host a Window unit.")
          end
          native(model, reference, row.fetch("values"), writable).tap do |host|
            host.zone_state = zone.fetch("state")
          end
        end

        def native(model, reference, values, writable)
          path = reference.fetch("zone_path") + reference.fetch("entity_path")
          entities = model.entities
          transform = Geom::Transformation.new
          path[0...-1].each do |persistent_id|
            container = unique(entities, persistent_id)
            unless container.is_a?(Sketchup::Group) && (!writable || container.definition.instances.length == 1)
              raise CodedError.new("target.shared_definition",
                "Make the host's parent storage unique before placement.")
            end
            if writable && container.locked?
              raise CodedError.new("target.locked", "The host's parent Group is locked.")
            end

            transform *= container.transformation
            entities = container.entities
          end
          face = unique(entities, path.last)
          unless face.is_a?(Sketchup::Face)
            raise CodedError.new("target.wrong_kind", "The host path must end at a Face.")
          end

          Host.new(:entity => face, :entities => entities, :parent_path => path[0...-1], :transform => transform,
            :reference => DeepCopy.call(reference), :values => DeepCopy.call(values),
            :geometry => FaceGeometry.capture(face, transform))
        end

        def unique(entities, persistent_id)
          found = entities.to_a.select { |entity| entity.persistent_id == persistent_id }
          unless found.length == 1
            raise CodedError.new("target.not_found", "The host occurrence path no longer resolves uniquely.")
          end
          found.first
        end
        private_class_method :native, :unique
      end
    end
  end
end
