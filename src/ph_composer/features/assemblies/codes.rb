# frozen_string_literal: true

module PhComposer
  module Assemblies
    # The codes Materials and Assemblies raise under their own nouns, published in
    # docs/API_REFERENCE.md. Validation, the thermal preview's flags and the export preflight share them.
    module Codes
      ALL = {
        "assembly.calculation_limit" => "The exact thermal calculation exceeds its path budget; no value is given.",
        "assembly.geometry_invalid" => "A Layer thickness, Layer-Segment width or steel-stud spacing is not " \
                                       "positive.",
        "assembly.invalid" => "The Assembly record does not satisfy its schema.",
        "assembly.material_dangling" => "A Layer-Segment names a Material that is not in the Model.",
        "assembly.membrane_in_mixed_layer" => "A Layer holding a membrane has more than one Layer-Segment.",
        "assembly.no_thermal_layers" => "Every Layer is a membrane, so no U-value can be calculated.",
        "assembly.segment_unassigned" => "A Layer-Segment has no Material.",
        "assembly.thermal_layer_limit" => "The Assembly has more thermal Layers than a Honeybee OpaqueConstruction " \
                                          "holds.",
        "material.conductivity_missing" => "A non-membrane Material has no conductivity.",
        "material.invalid" => "The Material record does not satisfy its schema.",
        "material.specific_heat_too_low" => "A Material's specific heat is below the Honeybee minimum.",
        "material.thermal_mass_defaulted" => "A Material has no density or specific heat; export uses disclosed " \
                                             "defaults."
      }.freeze

      module_function

      def install(feature)
        ALL.each { |code, description| feature.code(code, :description => description) }
      end
    end
  end
end
