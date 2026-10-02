"use strict";
function record(id, name, values) {
  return { id: id, kind: id.indexOf("mat") === 0 ?
    "ph_composer.assemblies.material" : "ph_composer.assemblies.assembly",
    schema_version: 1, user_data: {}, extension_data: {}, values: Object.assign({ name: name, notes: "" }, values),
    findings: [] };
}
function state(session) {
  var materials = [record("mat_a", "Mineral wool", { category: "insulation", color: "#fff2cc",
    conductivity_w_mk: 0.04, density_kg_m3: 30, specific_heat_j_kgk: 1000, emissivity: 0.9 }),
  record("mat_b", "Wood", { category: "woods", color: "#c69c6d", conductivity_w_mk: 0.12,
    density_kg_m3: 500, specific_heat_j_kgk: 1500, emissivity: null })];
  materials[0].uses = [{ assembly_id: "asm_a", name: "Wall" }];
  materials[0].use_count = 1;
  materials[1].uses = [];
  materials[1].use_count = 0;
  var assemblies = [record("asm_a", "Wall", { color: "#c5e1a5", type: "Wall", exterior_condition: "Outdoors" }),
    record("asm_b", "Incomplete roof", { color: "#bbdefb", type: "RoofCeiling", exterior_condition: "Outdoors" })];
  assemblies[0].display = { total_thickness_mm: 200, thermal: { complete: true, u_effective: 0.2, warnings: [] } };
  assemblies[1].display = { total_thickness_mm: 100, thermal: { complete: false, u_effective: null,
    warnings: ["Choose a Material for every Layer-Segment."] } };
  return { session: session || "session", revision: 1, ui: {}, sections: {
    "ph_composer.assemblies.materials": { status: "completed", value: { records: materials, unreadable: [],
      categories: [{ id: "insulation", label: "Insulation", tone: "warm" }, { id: "woods", label: "Woods",
        tone: "wood" }] } },
    "ph_composer.assemblies.assemblies": { status: "completed", value: { records: assemblies, unreadable: [] } },
    "ph_composer.zones.faces.attached_zone.list": { status: "completed", value: { records: [
      { id: "atz_a", values: { name: "Garage", kind: "garage", temperature_reduction_factor: 0.95 } }
    ] } }
  } };
}
module.exports = { state: state };
