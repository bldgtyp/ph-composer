# frozen_string_literal: true

module PhComposer
  module Assemblies
    module Thermal
      RSI = { "RoofCeiling" => 0.10, "Wall" => 0.13, "Floor" => 0.17 }.freeze
      # Bound exact Cartesian evaluation, not authoring: 30 binary mixed Layers would require
      # over a billion paths on the host thread. Above this budget the record stays editable and
      # the display reports calculation_limit rather than an approximation.
      PATH_BUDGET = 16_384
      HEAT_FLOW = { "RoofCeiling" => "upward", "Floor" => "downward" }.freeze
      # Named reasons for withholding thermal display values.
      PREVIEW_MESSAGES = {
        "membrane_in_mixed_layer" => "A membrane Layer must hold only one Layer-Segment.",
        "missing_material" => "One or more segments do not have a material assignment.",
        "missing_conductivity" => "One or more assigned materials need conductivity before export.",
        "invalid_geometry" => "Layer thickness, segment width, or steel-stud spacing is invalid.",
        "broken_material_reference" => "One or more segments reference a missing project material.",
        "no_thermal_layers" => "Every Layer is a membrane with no thermal resistance, so no U-value is available.",
        "unreadable_material" => "One or more referenced Materials cannot be read.",
        "calculation_limit" => "The exact thermal calculation exceeds its path budget; no value is available."
      }.freeze
      UNCALCULABLE = "Thermal resistance could not be calculated from the assigned segments."

      module_function

      # The Assembly editor's and inventory's thermal block for a projected layered assembly: the effective values when
      # they can be calculated, the ISO 6946 films shown beside them, and the flags that say why a value is missing or
      # incomplete. The panel reads this block; it does not calculate.
      def preview(assembly, materials)
        films = surface_resistances(assembly)
        flags = preview_flags(assembly, materials)
        block = {
          "complete" => flags.empty?, "flags" => flags, "warnings" => flags.map { |flag| PREVIEW_MESSAGES.fetch(flag) },
          "u_effective" => nil, "u_construction" => nil, "r_construction" => nil,
          "rsi" => films.fetch("r_in"), "rse" => films.fetch("r_out"),
          "direction" => HEAT_FLOW.fetch(assembly["type"], "horizontal")
        }
        return block if flags.any?

        values = effective(assembly, materials)
        return block.merge(values) if values

        flags = (flags + ["invalid_geometry"]).uniq.sort
        block.merge("complete" => false, "flags" => flags,
                    "warnings" => flags.map { |flag| PREVIEW_MESSAGES.fetch(flag) } + [UNCALCULABLE])
      end

      def preview_flags(assembly, materials)
        layers = Array(assembly["layers"])
        flags = layers.each_with_object([]) do |layer, result|
          segments = Array(layer["segments"])
          result << "invalid_geometry" unless layer["thickness_mm"].to_f.positive?
          if segments.length > 1 && segments.any? { |entry| materials[entry["material_id"]] &&
              Materials::Schema.membrane?(materials.fetch(entry["material_id"])) }
            result << "membrane_in_mixed_layer"
          end
          segments.each { |segment| result.concat(segment_flags(segment, materials)) }
        end
        flags << "invalid_geometry" if layers.empty?
        flags << "no_thermal_layers" if !layers.empty? && layers.all? { |layer| membrane?(layer, materials) }
        flags << "calculation_limit" if flags.empty? && calculation_limited?(layers, materials)
        flags.uniq.sort
      end
      private_class_method :preview_flags

      def segment_flags(segment, materials)
        spacing = segment["steel_stud_spacing_mm"]
        flags = []
        flags << "invalid_geometry" if !segment["width_mm"].to_f.positive? || (!spacing.nil? && !spacing.to_f.positive?)
        return flags << "missing_material" if segment["material_id"].nil?

        material = materials[segment["material_id"]]
        if material.nil?
          flags << "broken_material_reference"
        elsif !Materials::Schema::KIND.problems(material).empty?
          flags << "unreadable_material"
        elsif !Materials::Schema.membrane?(material) && !material["conductivity_w_mk"].to_f.positive?
          flags << "missing_conductivity"
        end
        flags
      end
      private_class_method :segment_flags

      # Counts possible thermal paths with an early exit; no Cartesian paths are generated here.
      def calculation_limited?(layers, materials)
        count = 1
        layers.each do |layer|
          next if membrane?(layer, materials)

          count *= layer.fetch("segments").length
          return true if count > PATH_BUDGET
        end
        false
      end

      # Mean of parallel-path and isothermal-plane construction resistances; films added afterward.
      def effective(assembly, materials)
        layers = Array(assembly["layers"])
        return nil if layers.empty?
        return nil unless preview_flags(assembly, materials).empty?

        per_layer = layers.reject { |layer| membrane?(layer, materials) }
                          .map { |layer| layer_paths(layer, materials) }.reject(&:empty?)
        return nil if per_layer.empty?

        r_parallel = parallel(per_layer)
        r_isothermal = isothermal(per_layer)
        return nil unless r_parallel.positive? && r_isothermal.positive?

        r_construction = (r_parallel + r_isothermal) / 2.0
        films = surface_resistances(assembly)
        {
          "u_effective" => round6(1.0 / (r_construction + films.fetch("r_in") + films.fetch("r_out"))),
          "u_construction" => round6(1.0 / r_construction),
          "r_construction" => round6(r_construction)
        }
      end

      def surface_resistances(assembly)
        r_in = RSI.fetch(assembly["type"], 0.13)
        r_out = case assembly["exterior_condition"]
                when "Ground" then 0.0
                when "Outdoors", nil then 0.04
                else r_in
                end
        r_out = r_in if assembly["ventilated_cladding"]
        { "r_in" => r_in, "r_out" => r_out }
      end

      # Projected layers carry is_membrane; raw records fall back to the material rule.
      def membrane?(layer, materials)
        layer.key?("is_membrane") ? layer.fetch("is_membrane") : Materials::Schema.membrane_layer?(layer, materials)
      end
      private_class_method :membrane?

      def layer_paths(layer, materials)
        assigned = Array(layer["segments"]).each_with_object([]) do |segment, result|
          material = materials[segment["material_id"]]
          next unless material && material["conductivity_w_mk"].to_f.positive?
          result << [segment, material]
        end
        total = assigned.sum { |segment, _material| segment.fetch("width_mm") }
        return [] unless total.positive?
        assigned.map do |segment, material|
          [(layer.fetch("thickness_mm") / 1000.0) / material.fetch("conductivity_w_mk"),
           segment.fetch("width_mm").to_f / total]
        end
      end
      private_class_method :layer_paths

      def parallel(paths)
        uniform, mixed = paths.partition { |path| path.length == 1 }
        base_resistance = uniform.sum { |path| path.first.first }
        return base_resistance if mixed.empty?

        # Each mixed Layer has at least two paths. The checked budget therefore bounds recursive
        # depth to fourteen, however many uniform Layers were authored.
        total_u = 0.0
        visit = lambda do |index, resistance, fraction|
          if index == mixed.length
            total_u += fraction / resistance if resistance.positive?
            next
          end
          mixed[index].each { |entry| visit.call(index + 1, resistance + entry[0], fraction * entry[1]) }
        end
        visit.call(0, base_resistance, 1.0)
        total_u.positive? ? 1.0 / total_u : 0.0
      end
      private_class_method :parallel

      def isothermal(per_layer)
        per_layer.sum do |paths|
          next paths.first.first if paths.length == 1
          1.0 / paths.sum { |resistance, fraction| fraction / resistance }
        end
      end
      private_class_method :isothermal

      def round6(value)
        value.round(6)
      end
      private_class_method :round6
    end
  end
end
