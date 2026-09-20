# frozen_string_literal: true

module PhComposer
  module FaceAssignment
    module ExportProjection
      SECTION = "ph_composer.face_assignment.export.faces"

      module_function

      def records(reader)
        reader.snapshot.records(FACE_DICTIONARY, :kind => "face").map do |entry, record|
          Schema.validate!(record)
          geometry = entry.geometry
          if record["boundary_condition"] == "Surface" &&
             record.dig("adjacency", "self_geometry", "digest") != geometry.digest
            raise Export::Blocked.new("adjacency.stale",
                                      "Face #{record.fetch('id')} moved after adjacency was solved.")
          end
          stamp = entry.record(Zones::STAMP_DICTIONARY)
          owner = reader.snapshot.zone_owner(entry)
          unless stamp && stamp["zone_id"].is_a?(String) && owner && owner.fetch(1)["id"] == stamp["zone_id"]
            raise Export::Blocked.new("face.wrong_zone", "Face #{record.fetch('id')} has no owning Zone stamp.")
          end
          validate_surface!(reader.snapshot, entry, record) if record["boundary_condition"] == "Surface"
          reader.entity_record(
            record, :fields => %w[face_type boundary_condition assembly_id adjacency]
          ).merge(
            "zone_id" => stamp.fetch("zone_id"), "geometry" => geometry.to_h
          )
        end.sort_by { |record| record.fetch("id") }
      end

      def validate_surface!(snapshot, entry, record)
        endpoint = record.dig("adjacency", "counterpart")
        path = Array(endpoint&.fetch("zone_path", nil)) + Array(endpoint&.fetch("entity_path", nil))
        counterpart = snapshot.entry_at(path, :kind => "face")
        other = counterpart&.record(FACE_DICTIONARY)
        unless counterpart && other
          raise Export::Blocked.new("adjacency.unresolved",
                                    "Face #{record.fetch('id')} has no reciprocal Surface endpoint.")
        end
        return if Zones::Adjacency.snapshot_pair_current?(entry, record, counterpart, other)

        raise Export::Blocked.new("adjacency.stale",
                                  "Face #{record.fetch('id')} has no current reciprocal Surface endpoint.")
      end
      private_class_method :validate_surface!
    end
  end
end
