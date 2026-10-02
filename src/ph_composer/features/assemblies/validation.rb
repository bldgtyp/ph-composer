# frozen_string_literal: true

module PhComposer
  module Assemblies
    # Conditions only. Assignment and output policy decide severity at the export boundary.
    module Validation
      module_function

      def finding(code, message, identity = {}, parts: nil)
        { "code" => code, "message" => message,
          "message_parts" => parts || [MessageParts.text(message)] }.merge(identity)
      end

      def material(record)
        identity = { "material_id" => record.fetch("id") }
        problems = Materials::Schema::KIND.problems(record)
        return [finding("material.invalid", problems.first, identity)] unless problems.empty?
        return [] if Materials::Schema.membrane?(record)

        found = []
        unless record["conductivity_w_mk"]
          found << finding("material.conductivity_missing", "#{record.fetch('name')} needs conductivity.", identity)
        end
        missing = %w[density_kg_m3 specific_heat_j_kgk].select { |key| record[key].nil? }
        unless missing.empty?
          parts = [MessageParts.text("Missing thermal mass properties use export defaults: "),
                   MessageParts.quantity("density", 600.0), MessageParts.text(" and "),
                   MessageParts.quantity("specific_heat", 1000.0), MessageParts.text(".")]
          found << finding("material.thermal_mass_defaulted", "Thermal mass properties need disclosed export defaults.",
                           identity.merge("missing_fields" => missing), :parts => parts)
        end
        found
      end

      def assembly(record, materials, material_findings: nil)
        identity = { "assembly_id" => record.fetch("id") }
        problems = Assembly::Schema::KIND.problems(record)
        return [finding("assembly.invalid", problems.first, identity)] unless problems.empty?

        found = record.fetch("layers").flat_map { |layer| layer_findings(layer, materials, identity) }
        used = Assembly::Schema::KIND.references.first.ids(record).uniq
        used.each do |id|
          material = materials[id]
          next unless material

          conditions = material_findings ? material_findings.fetch(id) : self.material(material)
          found.concat(conditions.map { |entry| entry.merge(identity) })
        end
        if record.fetch("layers").all? { |layer| Materials::Schema.membrane_layer?(layer, materials) }
          found << finding("assembly.no_thermal_layers", Thermal::PREVIEW_MESSAGES.fetch("assembly.no_thermal_layers"),
                           identity)
        end
        if complete?(found) && Thermal.calculation_limited?(record.fetch("layers"), materials)
          found << finding("assembly.calculation_limit", Thermal::PREVIEW_MESSAGES.fetch("assembly.calculation_limit"),
                           identity)
        end
        found
      end

      def layer_findings(layer, materials, identity)
        found = []
        layer_identity = identity.merge("layer_id" => layer.fetch("id"))
        if layer.fetch("segments").length > 1 && layer.fetch("segments").any? { |segment|
          material = materials[segment["material_id"]]
          material && Materials::Schema.membrane?(material)
        }
          found << finding("assembly.membrane_in_mixed_layer", "A membrane Layer holds one Layer-Segment.", layer_identity)
        end
        layer.fetch("segments").each do |segment|
          segment_identity = layer_identity.merge("segment_id" => segment.fetch("id"))
          material_id = segment["material_id"]
          if material_id.nil?
            found << finding("assembly.segment_unassigned", "A Layer-Segment has no Material.", segment_identity)
          elsif !materials.key?(material_id)
            found << finding("assembly.material_dangling", "The referenced Material cannot be read.",
                             segment_identity.merge("material_id" => material_id))
          end
        end
        found
      end

      # Authored values Honeybee cannot convert. They stay in the Model, and a Face cannot export with them.
      def material_conversion(record)
        heat = record["specific_heat_j_kgk"]
        return [] if Materials::Schema.membrane?(record) || !heat.is_a?(Numeric) || heat >= 100

        [finding("material.specific_heat_too_low",
                 "Honeybee needs specific heat of at least 100 J/kgK; authored value was retained.",
                 { "material_id" => record.fetch("id") })]
      end

      def assembly_conversion(record, materials)
        return [] if record.fetch("layers").count { |layer| !Materials::Schema.membrane_layer?(layer, materials) } <= 10

        [finding("assembly.thermal_layer_limit",
                 "Honeybee OpaqueConstruction supports at most 10 thermal Layers; authored Layers were retained.",
                 { "assembly_id" => record.fetch("id") })]
      end

      # Why a Face cannot export with this Assembly: conversion limits first, then every finding but the
      # disclosed thermal mass default. Empty when it can.
      def export_blockers(record, materials, findings)
        identity = { "assembly_id" => record.fetch("id") }
        used = Assembly::Schema::KIND.references.first.ids(record).uniq.filter_map { |id| materials[id] }
        assembly_conversion(record, materials) +
          used.flat_map { |material| material_conversion(material).map { |entry| entry.merge(identity) } } +
          findings.reject { |entry| entry.fetch("code") == "material.thermal_mass_defaulted" }
      end

      def complete?(findings)
        findings.all? { |entry| entry.fetch("code") == "material.thermal_mass_defaulted" }
      end
    end
  end
end
