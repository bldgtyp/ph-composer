# frozen_string_literal: true

module PhComposer
  module Zones
    module Faces
      module ExportProjection
        SECTION = "ph_composer.zones.faces.export.faces"

        module_function

        def install(feature)
          feature.query("#{PREFIX}.export_preflight", :description => "Face classification and Assembly checks.",
                        :params => Shapes::NONE, :result => Export::PREFLIGHT_RESULT,
                      :examples => [{}]) { |request| preflight(request) }
          feature.export_contributor(SECTION, :section_version => 1,
                                     :preflight => "#{PREFIX}.export_preflight",
                                     :result => { "surface_omissions" => [
                                       Export::Privacy.fields(%w[face_id zone_id code reason area_m2])
                                     ] }, :report => method(:omission_report)) { |reader| records(reader) }
        end

        def omission_report(result, display_units)
          omissions = result.fetch("surface_omissions", [])
          return [] if omissions.empty?

          rows = omissions.map do |row|
            area = Units.to_display(row.fetch("area_m2"), :quantity => "area", :system => display_units)
            [row.fetch("face_id"), row.fetch("zone_id"), format("%.2f", area), row.fetch("reason")]
          end
          heading = "Area (#{Units.label(:quantity => 'area', :system => display_units)})"
          table = Export::ReportHtml.table(["Face", "Zone", heading, "Reason"], rows)
          [Export::ReportHtml.section("Faces omitted", table)]
        end

        def preflight(request)
          index = Zones::Index.new(request.model)
          findings = Zones::Occurrences.zones(request.model, :index => index).flat_map do |zone|
            Zones::Occurrences.faces(zone).flat_map do |occurrence|
              face_findings(request, zone, occurrence, index)
            end
          end
          { "findings" => findings, "repairs" => [] }
        end

        def face_findings(request, zone, occurrence, index)
          record = Zones::Occurrences.face_record(occurrence.entity)
          issues = if record.nil?
                     [["face.unclassified", "Zone #{zone.record.fetch('name')} has an unclassified Face.", true]]
                   elsif !Schema.problems(record).empty?
                     [["face.invalid", "Face assignment is invalid: #{Schema.problems(record).first}.", true]]
                   else
                     assignment_issues(request, occurrence, record, index)
                   end
          issues.map do |code, message, blocking|
            { "code" => code, "section" => SECTION, "object_id" => record && record["id"],
              "message" => message, "blocks_export" => blocking, "locate" => {
                "name" => "#{PREFIX}.locate", "params" => { "faces" => [occurrence.reference] }
              } }
          end
        end

        def assignment_issues(request, occurrence, record, index)
          issues = []
          issues << ["face.type_missing", "Choose a Face type before exporting.", true] unless record["face_type"]
          unless record["boundary_condition"]
            issues << ["face.boundary_unassigned", "Face has no boundary condition and will be omitted.", false]
          end
          state = Zones::Adjacency.state(request.model, occurrence, record, :index => index)
          if state && state != "current"
            issues << ["adjacency.#{state}", "Surface adjacency is #{state}; this Face will be omitted.", false]
          end
          issues.concat(attached_zone_issues(request, record)) if record["boundary_condition"] == "AttachedZone"
          return issues unless record["boundary_condition"] && (!state || state == "current")

          issues << [record["assembly_id"] ? "construction.unavailable" : "construction.missing",
                     "Face #{record.fetch('id')} needs an available authored Assembly. " \
                     "Assembly authoring is scheduled for the next phase.", true]
          issues
        end

        def attached_zone_issues(request, record)
          id = record["attached_zone_id"]
          state = if id.to_s.empty?
                    "absent"
                  else
                    attached_record_state(request, id)
                  end
          return [] if state == "resolved"

          [["attached_zone.#{state}", "The Face's Attached zone reference is #{state}.", true]]
        end

        def attached_record_state(request, id)
          kind = request.engine.kind(AttachedZone::KIND_ID)
          stored = kind.store.read(request.model, id)
          return "dangling" unless stored
          return "invalid" unless stored.is_a?(Hash)
          return "unavailable" unless stored["schema_version"] == kind.schema_version
          return "invalid" unless kind.problems(stored).empty?

          required = stored.fetch("extension_data", {}).select do |_namespace, envelope|
            envelope.is_a?(Hash) && envelope["export_relevance"] != "local_only"
          end
          return "unavailable" unless required.all? do |namespace, envelope|
            Records::Extension.status(envelope, request.registry.catalog.extension(namespace)) == "understood"
          end

          "resolved"
        rescue JSON::ParserError, CodedError
          "invalid"
        end

        def records(reader)
          reader.snapshot.records(FACE_DICTIONARY, :kind => "face").map do |entry, record|
            Schema.validate!(record)
            geometry = entry.geometry
            stamp = entry.record(Zones::STAMP_DICTIONARY)
            owner = Zones::ExportProjection.zone_owner(reader.snapshot, entry)
            unless stamp && stamp["zone_id"].is_a?(String) && owner && owner.fetch(1)["id"] == stamp["zone_id"]
              raise Export::Blocked.new("face.wrong_zone", "Face #{record.fetch('id')} has no owning Zone stamp.")
            end
            exported = reader.entity_record(
              record, :fields => %w[face_type boundary_condition assembly_id adjacency]
            ).merge(
              "zone_id" => stamp.fetch("zone_id"), "geometry" => geometry.to_h
            )
            omission = omission_reason(reader.snapshot, entry, record)
            if omission
              exported["omission"] = { "code" => omission.fetch(0), "reason" => omission.fetch(1),
                                       "area_m2" => geometry.area_m2, "zone_id" => stamp.fetch("zone_id") }
            end
            exported
          end.sort_by { |record| record.fetch("id") }
        end

        def omission_reason(snapshot, entry, record)
          unless record["boundary_condition"]
            return ["face.boundary_unassigned", "Face has no assigned boundary condition."]
          end
          return nil unless record["boundary_condition"] == "Surface"

          endpoint = record.dig("adjacency", "counterpart")
          path = Array(endpoint&.fetch("zone_path", nil)) + Array(endpoint&.fetch("entity_path", nil))
          counterpart = snapshot.entry_at(path, :kind => "face")
          other = counterpart&.record(FACE_DICTIONARY)
          unless counterpart && other
            return ["adjacency.unresolved", "Face has no reciprocal Surface endpoint."]
          end
          return nil if Zones::Adjacency.snapshot_pair_current?(entry, record, counterpart, other)

          ["adjacency.stale", "Face has no current reciprocal Surface endpoint."]
        end
        private_class_method :face_findings, :assignment_issues, :attached_zone_issues, :attached_record_state,
                             :omission_reason
      end
    end
  end
end
