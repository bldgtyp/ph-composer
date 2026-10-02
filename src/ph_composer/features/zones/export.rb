# frozen_string_literal: true

module PhComposer
  module Zones
    module ExportProjection
      SECTION = "ph_composer.zones.export.zones"
      # The Assemblies section whose definitions name the constructions this report counts.
      CONSTRUCTIONS = "ph_composer.assemblies.export.constructions"

      module_function

      def install(feature)
        feature.export_contributor(
          SECTION, :section_version => 1,
                   :preflight => "#{FEATURE_ID}.export_preflight",
                   # What the Zone translation writes on each Room (python/ph_composer_translation/model_sections.py).
                   :user_data_keys => %w[ph_composer.level ph_composer.building_segment],
                   :result => {
                     "construction_usage" => [Export::Privacy.fields(%w[assembly_id face_count gross_area_m2])]
                   },
                   :requires => [CONSTRUCTIONS], :report => method(:report)
        ) { |reader| records(reader) }
        feature.query("#{FEATURE_ID}.export_preflight", :description => "All-Zone export checks and adjacency repair.",
                                                        :params => Shapes::NONE, :result => Export::PREFLIGHT_RESULT,
                                                        :examples => [{}]) { |request| preflight(request) }
      end

      def preflight(request)
        index = Index.new(request.model)
        zones = Occurrences.zones(request.model, :index => index)
        findings = []
        if zones.empty?
          findings << { "code" => "zone.none", "section" => SECTION, "object_id" => nil,
                        "message" => "Make at least one Zone before exporting.", "blocks_export" => true }
        end
        zones.each do |zone|
          begin
            Schema.validate!(zone.record)
            Occurrences.resolve_zone(request.model, zone.reference, :mutable => true, :index => index)
          rescue CodedError => error
            findings << { "code" => error.code, "section" => SECTION, "object_id" => zone.record["id"],
                          "message" => error.message, "blocks_export" => true }
          end
        end
        repair = { "id" => "#{FEATURE_ID}.solve_all", "label" => "Solve stale adjacencies before export",
                   "checked" => true, "action" => "#{FEATURE_ID}.solve_adjacency",
                   "params" => { "zones" => zones.map(&:reference) } }
        { "findings" => findings, "repairs" => zones.empty? ? [] : [repair] }
      end

      # Gross area per Assembly over the emitted Faces. Window net areas are the Windows report's.
      def report(result, display_units)
        usage = result.fetch("construction_usage", [])
        return [] if usage.empty?

        names = result.section(CONSTRUCTIONS).fetch("construction_definitions", []).to_h do |row|
          [row.fetch("assembly_id"), row.fetch("name")]
        end
        rows = usage.map do |row|
          area = Units.to_display(row.fetch("gross_area_m2"), :quantity => "area", :system => display_units)
          [names.fetch(row.fetch("assembly_id"), row.fetch("assembly_id")), row.fetch("face_count"),
           format("%.2f", area)]
        end
        heading = "Gross area (#{Units.label(:quantity => 'area', :system => display_units)})"
        table = Export::ReportHtml.table(["Assembly", "Faces", heading], rows)
        [Export::ReportHtml.section("Construction usage", table)]
      end

      # The one Zone occurrence containing a snapshot entry, as [entry, record], or nil. Two means a
      # Zone nested in a Zone, which export refuses.
      def zone_owner(snapshot, entry)
        matches = snapshot.records(ZONE_DICTIONARY, :kind => "group").select do |zone_entry, _record|
          snapshot.contains?(zone_entry, entry)
        end
        raise Export::Blocked.new("face.wrong_zone", "A Face is contained by more than one Zone.") if matches.length > 1

        matches.first
      end

      def records(reader)
        zones = reader.snapshot.records(ZONE_DICTIONARY, :kind => "group")
        zones.map do |entry, record|
          record = Names.project(record, entry.native_name)
          Schema.validate!(record)
          owned = reader.snapshot.descendants(entry, :kind => "face")
          assigned = owned.map { |face| [face, face.record(Faces::FACE_DICTIONARY)] }
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
