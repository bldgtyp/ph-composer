# frozen_string_literal: true

module PhComposer
  module Zones
    module ExportProjection
      SECTION = "ph_composer.zones.export.zones"

      module_function

      def records(reader)
        zones = reader.snapshot.records(ZONE_DICTIONARY, :kind => "group")
        zones.map do |entry, record|
          Schema.validate!(record)
          owned = reader.snapshot.descendants(entry, :kind => "face")
          assigned = owned.map { |face| [face, face.record(FaceAssignment::FACE_DICTIONARY)] }
          missing = assigned.select { |_face, assignment| assignment.nil? }
          unless missing.empty?
            raise Export::Blocked.new("face.unclassified",
                                      "Zone #{record.fetch('id')} has #{missing.length} unclassified Faces.")
          end
          ids = assigned.map { |_face, assignment| assignment.fetch("id") }.sort
          reader.entity_record(record, :fields => %w[name building_segment level]).merge("face_ids" => ids)
        end.sort_by { |record| record.fetch("id") }
      end
    end
  end
end
