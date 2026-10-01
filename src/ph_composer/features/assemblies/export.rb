# frozen_string_literal: true

module PhComposer
  module Assemblies
    # The conversion allowlist is narrower than authored values. Each Assembly is a self-contained
    # translation record; the Section contract can therefore refuse it without shared mutable state.
    module ExportProjection
      SECTION = "ph_composer.assemblies.export.constructions"
      MATERIAL_FIELDS = %w[id name category conductivity_w_mk density_kg_m3 specific_heat_j_kgk emissivity color].freeze
      SEGMENT_FIELDS = %w[id width_mm material_id steel_stud_spacing_mm].freeze

      module_function

      def install(feature)
        feature.query("#{FEATURE_ID}.export_preflight", :description => "Material and Assembly export conditions.",
                      :params => { "type" => "object", "properties" => {}, "additionalProperties" => false },
                      :result => Export::PREFLIGHT_RESULT, :examples => [{}]) { |request| preflight(request) }
        feature.export_contributor(SECTION, :section_version => 1, :preflight => "#{FEATURE_ID}.export_preflight",
                                   :user_data_keys => %w[ph_composer.assembly_id ph_composer.membrane_layers],
                                   :result => { "construction_definitions" => [Export::Privacy.fields(
                                     %w[assembly_id name thermal_layer_count membrane_names defaulted_material_ids]
                                   )] }, :report => method(:report)) { |reader| records(reader) }
      end

      def records(reader)
        materials = reader.records(MATERIAL_KIND).to_h { |row| [row.fetch("id"), row.slice(*MATERIAL_FIELDS)] }
        reader.records(ASSEMBLY_KIND).map do |row|
          layers = row.fetch("layers").map do |layer|
            layer.slice("id", "thickness_mm").merge(
              "segments" => layer.fetch("segments").map { |segment| segment.slice(*SEGMENT_FIELDS) }
            )
          end
          used = layers.flat_map { |layer| layer.fetch("segments").map { |segment| segment["material_id"] } }.uniq
          row.slice("id", "name", "orientation").merge(
            "layers" => layers, "materials" => used.compact.sort.filter_map { |id| materials[id] }
          )
        end
      end

      def preflight(request)
        materials, bad_materials = Snapshot.read_records(request.engine, MATERIAL_KIND,
                                                         request.engine.ids(MATERIAL_KIND))
        assemblies, bad_assemblies = Snapshot.read_records(request.engine, ASSEMBLY_KIND,
                                                           request.engine.ids(ASSEMBLY_KIND))
        by_id = materials.to_h { |row| [row.fetch("id"), row] }
        findings = materials.flat_map { |row| Validation.material(row) }
        findings.concat(assemblies.flat_map { |row| Validation.assembly(row, by_id) })
        findings = findings.map do |finding|
          message = finding.fetch("message")
          if finding.fetch("code") == "material_thermal_mass_default"
            message = "Missing thermal mass properties use 600 kg/m3 density and 1000 J/kgK specific heat."
          end
          preflight_row(finding.fetch("code"), finding["assembly_id"] || finding["material_id"], message, false)
        end
        materials.each do |row|
          heat = row["specific_heat_j_kgk"]
          next if Materials::Schema.membrane?(row) || heat.nil? || heat >= 100

          findings << preflight_row("material_specific_heat_unavailable", row.fetch("id"),
                                    "Honeybee needs specific heat of at least 100 J/kgK; " \
                                    "authored value was retained.", false)
        end
        assemblies.each do |row|
          count = row.fetch("layers").count { |layer| !Materials::Schema.membrane_layer?(layer, by_id) }
          next if count <= 10

          findings << preflight_row("construction_thermal_layer_limit", row.fetch("id"),
                                    "Honeybee OpaqueConstruction supports at most 10 thermal Layers; " \
                                    "authored Layers were retained.", false)
        end
        findings.concat((bad_materials + bad_assemblies).map do |row|
          preflight_row(row.fetch("code"), row.fetch("id"), row.fetch("message"), true)
        end)
        { "findings" => findings, "repairs" => [] }
      end

      def preflight_row(code, id, message, blocking)
        { "code" => code, "section" => SECTION, "object_id" => id,
          "message" => message, "blocks_export" => blocking }
      end

      def report(result, display_units)
        definitions = result.fetch("construction_definitions", [])
        return [] if definitions.empty?

        usage = result.fetch("construction_usage", []).to_h { |row| [row.fetch("assembly_id"), row] }
        rows = definitions.filter_map do |definition|
          used = usage[definition.fetch("assembly_id")]
          next unless used

          area = Units.to_display(used.fetch("gross_area_m2"), :quantity => "area", :system => display_units)
          disclosures = []
          unless definition.fetch("membrane_names").empty?
            disclosures << "Membranes: #{definition.fetch('membrane_names').join(', ')}."
          end
          unless definition.fetch("defaulted_material_ids").empty?
            disclosures << "Missing thermal mass properties use 600 kg/m3 and 1000 J/kgK."
          end
          [definition.fetch("name"), used.fetch("face_count"), format("%.2f", area), disclosures.join(" ")]
        end
        heading = "Gross area (#{Units.label(:quantity => 'area', :system => display_units)})"
        body = Export::ReportHtml.table(["Assembly", "Faces", heading, "Disclosures"], rows)
        if definitions.any? { |row| usage.key?(row.fetch("assembly_id")) && !row.fetch("membrane_names").empty? }
          body += Export::ReportHtml.paragraph(
            "Membranes carried in HBJSON; ignored by the current PHX/METr conversion."
          )
        end
        body += Export::ReportHtml.paragraph(
          "Honeybee defaults: roughness MediumRough; thermal absorptance 0.9 when emissivity is absent; " \
          "solar and visible absorptance 0.7. Authored emissivity supplies thermal absorptance when present."
        )
        body += Export::ReportHtml.paragraph(
          "Air barrier, photos, ventilated cladding, hints and local notes remain in the Model."
        )
        [Export::ReportHtml.section("Authored constructions", body)]
      end
      private_class_method :preflight_row
    end
  end
end
