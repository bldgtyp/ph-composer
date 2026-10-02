"use strict";
var PREFIX = "ph_composer.windows.";
function sides(value) { return { top: value, right: value, bottom: value, left: value }; }
function element(id, col, kind) { return { id: id, name: "Element " + (col + 1), kind: kind || "glazed",
  row_span: [0, 0], column_span: [col, col], glazing_id: kind === "empty" ? null : "glz_a",
  frames: sides(kind === "empty" ? null : "frm_a"), installs: sides(null), operation: kind === "empty" ? null :
    { type: "fixed", directions: [] } }; }
function record(id, values) { return { id: id, values: values, user_data: {}, extension_data: {}, findings: [] }; }
function state() {
  var type = record("wnt_a", { name: "Three elements", notes: "", rows_m: [1.5], columns_m: [0.5, 0.5, 0.5],
    elements: [element("wel_a", 0), element("wel_b", 1), element("wel_c", 2, "empty")] });
  type.display = { width_m: 1.5, height_m: 1.5, install_depth_m: 0.1, thermal: { uw_w_m2k: 0.8, u_effective_w_m2k: 0.9,
    complete: true, area_m2: 1.5, empty_area_m2: 0.75, findings: [],
      elements: type.values.elements.map(function (cell) {
      return { id: cell.id, uw_w_m2k: cell.kind === "empty" ? null : 0.8, findings: [],
        edges: ["top", "right", "bottom", "left"].map(function (side) {
        return { side: side, length_m: 0.5, install: { source: (cell.id === "wel_a" && side === "right") ||
          (cell.id === "wel_b" && side === "left") ? "shared" : "default", id: null, psi_w_mk: 0.04 } };
      }) };
    }) } };
  var sections = {};
  sections[PREFIX + "types"] = { status: "completed", value: { records: [type], unreadable: [] } };
  sections[PREFIX + "frames"] = { status: "completed", value: { records: [record("frm_a", { name: "Timber frame",
    manufacturer: "Synthetic", notes: "", color: "#eeeeee", width_m: 0.08, uf_w_m2k: 1.1, psi_g_w_mk: 0.03 })] } };
  sections[PREFIX + "glazings"] = { status: "completed", value: { records: [record("glz_a", { name: "Triple glazing",
    manufacturer: "Synthetic", notes: "", color: "#e8f4fa", ug_w_m2k: 0.6, g_value: 0.5 })] } };
  sections[PREFIX + "psi_install_types"] = { status: "completed", value: { records: [record("psi_a", {
    name: "Insulated junction", notes: "", psi_w_mk: 0.04 })] } };
  sections[PREFIX + "settings"] = { status: "completed", value: { default_psi_install_id: "psi_a",
    default_install_depth_m: 0.1 } };
  return { session: "session", revision: 1, sections: sections, ui: {} };
}
module.exports = { state: state, record: record, element: element, sides: sides };
