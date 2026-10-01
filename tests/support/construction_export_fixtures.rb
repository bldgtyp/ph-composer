# frozen_string_literal: true

# Authored synthetic data shared with the Python construction contract examples.
module ConstructionExportFixtures
  def seed_export_construction
    fixture = JSON.parse(File.read(File.join(TESTS_ROOT, "fixtures", "assemblies", "authoring.json")))
    material = fixture.fetch("materials").find { |row| row["id"] == "mat_Wool00000001" }
    assembly = fixture.fetch("assemblies").find { |row| row["id"] == "asm_Single000001" }
    [material, assembly].each { |row| row["user_data"] = {} }
    PhComposer::Assemblies::Materials::Schema::KIND.store.write(@model, material)
    PhComposer::Assemblies::Assembly::Schema::KIND.store.write(@model, assembly)
    assembly.fetch("id")
  end
end
