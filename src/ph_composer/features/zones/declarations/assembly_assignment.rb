# frozen_string_literal: true

module PhComposer
  module Zones
    module Faces
      module AssemblyRegistration
        TARGET = Shapes.object({ "reference" => FACE_REFERENCE, "expected_values" => FACE_VALUES }).freeze
        PARAMS = Shapes.object({
          "targets" => Shapes.list(TARGET).merge("minItems" => 1, "description" => "Each Face occurrence to " \
                                                                                  "change, with the values last " \
                                                                                  "read; a change refuses."),
          "assembly_id" => { "type" => %w[string null], "description" => "The Assembly to assign, or null to clear " \
                                                                         "it." }
        }).freeze
        USAGE_ROW = Shapes.object({ "assembly_id" => Shapes::ID, "face_count" => Shapes::COUNT,
                                    "gross_area_m2" => { "type" => "number", "x-unit" => "m2" },
                                    "faces" => Shapes.list(FACE_REFERENCE) }).freeze
        USAGE = Shapes.list(USAGE_ROW).freeze
        FINDINGS = Shapes.list(Shapes.object({ "code" => Shapes::ID, "message" => Shapes::ID,
                                              "assembly_id" => { "type" => %w[string null] } })).freeze
        CHOICE = Shapes.object({ "id" => Shapes::ID, "name" => Shapes::ID,
                                 "type" => { "type" => %w[string null] }, "color" => Shapes::ID }).freeze
        CHOICES = Shapes.object({ "assemblies" => Shapes.list(CHOICE) }).freeze
        module_function

        def install(feature)
          feature.action("#{PREFIX}.assign_assembly",
                         :description => "Set or clear only the Assembly of explicit Faces.",
                         :params => PARAMS, :result => Registration::FACE_IDS_RESULT,
                         :undo_name => "Assign Assembly", :side_effects => "Changes only assembly_id on all targets.",
                         :examples => [{ "targets" => [{ "reference" => Registration::EXAMPLE_FACE,
                                                          "expected_values" => {} }],
                                         "assembly_id" => "asm_Ab12Cd34Ef56" }]) do |request, proposal|
            AssemblyAssignment.assign(request, proposal, :assembly_id => request.params.fetch("assembly_id"),
                                                         :targets => request.params.fetch("targets"))
          end
          kind = AssemblyAssignment::KIND
          feature.reference_retargeter("#{PREFIX}.retarget_assembly", :target_kind => kind) do |request, proposal, from:, to:|
            AssemblyAssignment.retarget(request, proposal, :from => from, :to => to)
          end
          feature.query("#{PREFIX}.assembly_usage", :description => "Face counts and gross areas by Assembly.",
                        :params => Shapes::NONE, :result => Shapes.object({ "assemblies" => USAGE }),
                        :examples => [{}]) { |request| { "assemblies" => Faces.all(request).fetch("assembly_usage") } }
          # Identical snapshot queries are memoized for this build by the shared shell. Usage and the
          # Face table therefore share one walk, without retaining an Index after the read phase.
          feature.snapshot_section("#{PREFIX}.usage", :query => "#{PREFIX}.all")
          feature.query("#{PREFIX}.assembly_choices", :description => "Current Assembly names, hints and colours.",
                        :params => Shapes::NONE, :result => CHOICES, :examples => [{}]) do |request|
            { "assemblies" => AssemblyAssignment.catalog(request).fetch(:records).values.map do |row|
              { "id" => row.fetch("id"), "name" => row.fetch("values").fetch("name"),
                "type" => row.fetch("values")["type"], "color" => row.fetch("display").fetch("color") }
            end }
          end
          feature.snapshot_section("#{PREFIX}.assemblies", :query => "#{PREFIX}.assembly_choices")
        end
      end
    end
  end
end
