"use strict";
var assert = require("assert");
var test = require("node:test");
var dom = require("./support/dom_stub");
var source = require("./support/panel_source");
var fixtures = require("./support/inventory_fixtures");
var PREFIX = "ph_composer.zones.faces";
function setup() {
  var document = dom.buildDocument(source.markup("index.html"));
  var sent = [], context = { document: document, Intl: Intl, innerWidth: 1280, innerHeight: 900,
    setTimeout: setTimeout, clearTimeout: clearTimeout,
    sketchup: { ph_composer_message: function (message) { sent.push(JSON.parse(message)); } } };
  context.window = context;
  dom.attachEvents(context);
  var modules = source.start(context, ["features/zones/overview", "features/zones/classify",
    "features/assemblies/section"]);
  var state = fixtures.state("session-a");
  state.product = "PH-Composer";
  state.preferences = { unit_system: "SI", dimension_formats: {},
    number_format: { decimal: ".", locale: "en-US" } };
  var face = { reference: { zone_id: "zon_a", zone_path: [100], entity_path: [101], entity_id: "fac_a" },
    values: { face_type: "Wall", boundary_condition: "Surface", assembly_id: "asm_missing",
      boundary_face_id: "fac_b" }, area_m2: 12, state: "classified", assembly_state: "dangling", findings: [] };
  state.sections["ph_composer.zones.overview"] = { status: "completed", value: {
    zones: [{ id: "zon_a", reference: { zone_id: "zon_a", zone_path: [100] }, state: "found",
      values: { name: "Zone 1", ground_depth_mm: 0, level: null }, face_count: 1 }], make_zone: null } };
  state.sections[PREFIX + ".faces"] = { status: "completed", value: { faces: [face] } };
  state.sections[PREFIX + ".palette"] = { status: "completed", value: { active: false,
    palette: {}, face_types: ["Wall", "RoofCeiling", "Floor"],
    boundary_conditions: ["Outdoors", "Ground", "Surface"] } };
  state.sections[PREFIX + ".selected"] = { status: "completed", value: {
    faces: [face.reference],
    targets: [{ reference: face.reference, expected_values: face.values }] } };
  state.sections[PREFIX + ".assemblies"] = { status: "completed", value: { assemblies: [
    { id: "asm_b", name: "A Roof", type: "RoofCeiling", color: "#bbdefb" },
    { id: "asm_a", name: "Wall", type: "Wall", color: "#c5e1a5" }] } };
  state.sections[PREFIX + ".usage"] = { status: "completed", value: {
    faces: [Object.assign({ zone_name: "Zone 1" }, face)], assembly_usage: [
    { assembly_id: "asm_a", face_count: 1, gross_area_m2: 12, faces: [face.reference] }] } };
  function paint() { modules.panel.receive({ type: "panel.snapshot", payload: state }); }
  paint();
  return { document: document, modules: modules, panel: modules.panel, state: state, face: face,
    sent: sent, paint: paint, query: function (selector) { return document.querySelector(selector); } };
}
function byLabel(root, label) {
  return root.querySelectorAll("input, select, button").filter(function (node) {
    return node.getAttribute("aria-label") === label;
  })[0];
}
function click(node) { node.listeners.click({ preventDefault: function () {} }); }
function text(node) { return node.textContent + node.children.map(text).join(" "); }
test("selection Assembly choices prioritize matching hints; a choice assigns at once to its targets", function () {
  var o = setup(), picker = byLabel(o.document.body, "Assembly for selected Faces");
  assert.deepStrictEqual(picker.children.map(function (entry) { return entry.textContent; }),
    ["Choose Assembly", "Clear Assembly", "Wall", "A Roof"]);
  assert.strictEqual(byLabel(o.document.body, "Apply Assembly to selected Faces"), undefined, "no Apply step");
  picker.value = "asm_a";
  picker.listeners.change({});
  assert.strictEqual(o.sent.length, 1);
  assert.strictEqual(o.sent[0].payload.name, PREFIX + ".assign_assembly");
  assert.deepStrictEqual(o.sent[0].payload.params, { targets: [{ reference: o.face.reference,
    expected_values: o.face.values }], assembly_id: "asm_a" });
  assert.ok(text(o.document.body).includes("1 Face selected"));
});
test("table Assembly chip names dangling references and clears only the guarded Assembly", function () {
  var o = setup(), chip = byLabel(o.document.body, "Wall 1 Assembly");
  assert.ok(chip.children.some(function (entry) { return entry.textContent.includes("Missing Assembly"); }));
  chip.value = "";
  chip.listeners.change({});
  assert.strictEqual(o.sent.length, 1);
  assert.deepStrictEqual(o.sent[0].payload.params, { targets: [{ reference: o.face.reference,
    expected_values: o.face.values }], assembly_id: null });
});
test("the table Assembly chip takes its Assembly's colour and follows it; None stays neutral", function () {
  var o = setup(), chip = byLabel(o.document.body, "Wall 1 Assembly");
  assert.strictEqual(chip.style["--category-fill"], undefined, "a missing Assembly keeps the neutral pill");
  o.face.values.assembly_id = "asm_a";
  o.paint();
  assert.strictEqual(chip.style["--category-fill"], "#c5e1a5");
  assert.strictEqual(chip.style["--category-ink"], undefined);
  o.state.sections[PREFIX + ".assemblies"].value.assemblies[1].color = "#263238";
  o.paint();
  assert.deepStrictEqual([chip.style["--category-fill"], chip.style["--category-ink"]], ["#263238", "#fff"]);
  o.face.values.assembly_id = null;
  o.paint();
  assert.deepStrictEqual([chip.style["--category-fill"], chip.style["--category-ink"]], [undefined, undefined]);
});
test("the Classify palette offers no Assembly choice and names the one being painted", function () {
  var o = setup(), palette = o.query("[data-section='ph_composer.classify']");
  assert.strictEqual(byLabel(o.document.body, "Classify Assembly"), undefined);
  assert.ok(!text(palette).includes("Assembly"), "nothing about Assemblies until one is being painted");
  o.state.sections[PREFIX + ".palette"].value.palette.assembly_id = "asm_a";
  o.paint();
  assert.ok(text(palette).includes("Wall"), "the Assembly being painted is named");
});
test("Zones contributes gross usage and view actions through the generic Assembly inventory seam", function () {
  var o = setup(), inventory = o.query("[data-section='assemblies']")._view.inventory;
  o.panel.showTab("assemblies");
  assert.ok(inventory.tableOptions.columns.some(function (column) { return column[0] === "face_usage"; }));
  var cell = inventory.scroll._table.rows.asm_a.cells.face_usage;
  assert.ok(text(cell).includes("12 m²"));
  var action = inventory.tableOptions.actions({ record: inventory.records[0] }).filter(function (item) {
    return item.id === "select_assembly_faces";
  })[0];
  inventory.tableOptions.action({ record: inventory.records[0] }, action);
  assert.strictEqual(o.sent[0].type, "view.invoke");
  assert.deepStrictEqual(o.sent[0].payload.params, { faces: [o.face.reference] });
  delete o.state.sections[PREFIX + ".usage"];
  o.paint();
  assert.ok(!inventory.tableOptions.columns.some(function (column) { return column[0] === "face_usage"; }));
});
test("an assignment refusal says why and leaves the control ready; a Model switch forbids it", function () {
  var o = setup(), picker = byLabel(o.document.body, "Assembly for selected Faces");
  picker.value = "asm_a";
  picker.listeners.change({});
  o.panel.receive({ type: "action.result", payload: { session: "session-a",
    request_id: o.sent[0].payload.request_id, outcome: { status: "refused", message: "Changed in the Model." } } });
  assert.strictEqual(picker.value, "", "nothing is left looking chosen");
  assert.strictEqual(picker.disabled, false);
  assert.ok(text(o.document.body).includes("Changed in the Model."));
  var chip = byLabel(o.document.body, "Wall 1 Assembly");
  o.state.session = "session-b";
  o.paint();
  picker.value = "asm_b";
  picker.listeners.change({});
  chip.value = "asm_b";
  chip.listeners.change({});
  assert.strictEqual(o.sent.length, 1);
});
test("Assembly replacement UI requires an explicit replacement or Clear before one delete action", function () {
  var o = setup(), view = o.query("[data-section='assemblies']")._view, inventory = view.inventory;
  var row = { record: inventory.records[0] };
  var action = inventory.tableOptions.actions(row).filter(function (item) {
    return item.id === "replace_assembly";
  })[0];
  inventory.tableOptions.action(row, action);
  var dialog = o.document.querySelectorAll("dialog").filter(function (node) { return !node.hidden; })[0];
  assert.ok(text(dialog).includes("1 Face"));
  var select = byLabel(dialog, "Replacement assembly");
  var submit = dialog.querySelectorAll("button").filter(function (button) { return button.type === "submit"; })[0];
  assert.ok(submit.disabled);
  select.value = "__clear__";
  select.listeners.change({});
  dialog.querySelector("form").listeners.submit({ preventDefault: function () {} });
  assert.strictEqual(o.sent.length, 1);
  assert.strictEqual(o.sent[0].payload.name, "ph_composer.assemblies.assemblies.delete");
  assert.strictEqual(o.sent[0].payload.params.replacement_id, null);
});
test("selection Clear is explicit and inventory Paint resets other fields", function () {
  var o = setup(), picker = byLabel(o.document.body, "Assembly for selected Faces");
  picker.value = "__clear__";
  picker.listeners.change({});
  assert.strictEqual(o.sent[0].payload.params.assembly_id, null);
  o = setup();
  var inventory = o.query("[data-section='assemblies']")._view.inventory, row = { record: inventory.records[0] };
  var paint = inventory.tableOptions.actions(row).filter(function (action) {
    return action.id === "paint_assembly";
  })[0];
  inventory.tableOptions.action(row, paint);
  assert.strictEqual(o.sent.length, 1);
  assert.deepStrictEqual(o.sent[0].payload.params, { field: "assembly_id", value: "asm_a", reset: true });
});
test("withdrawal forgets a pending selection request and restores navigation without a late result", function () {
  var o = setup(), picker = byLabel(o.document.body, "Assembly for selected Faces");
  picker.value = "asm_a"; picker.listeners.change({});
  o.panel.showTab("assemblies");
  assert.strictEqual(o.panel.state.ui.activeTab, "overview", "a request in flight holds the tab");
  delete o.state.sections[PREFIX + ".selected"]; o.paint();
  o.panel.showTab("assemblies");
  assert.strictEqual(o.panel.state.ui.activeTab, "assemblies");
  assert.ok(picker.disabled);
  picker.value = "asm_b"; picker.listeners.change({});
  assert.strictEqual(o.sent.length, 1);
});
test("contributed actions respect inventory drafts and withdrawn replacement controls cannot write", function () {
  var o = setup(), inventory = o.query("[data-section='assemblies']")._view.inventory;
  var cell = inventory.edits.cells["asm_a:name"], input = cell.input;
  input.value = "Draft name"; input.listeners.input({});
  var row = { record: inventory.records[0] };
  var replace = inventory.tableOptions.actions(row).filter(function (action) {
    return action.id === "replace_assembly";
  })[0];
  inventory.tableOptions.action(row, replace);
  assert.ok(!o.document.querySelectorAll("dialog").some(function (node) { return !node.hidden; }));
  inventory.edits.cancel(cell); o.paint();
  inventory.tableOptions.action(row, replace);
  var dialog = o.document.querySelectorAll("dialog").filter(function (node) { return !node.hidden; })[0];
  var select = byLabel(dialog, "Replacement assembly");
  select.value = "asm_b"; select.listeners.change({});
  delete o.state.sections[PREFIX + ".usage"]; o.paint();
  dialog.querySelector("form").listeners.submit({ preventDefault: function () {} });
  assert.strictEqual(o.sent.length, 0);
  o.panel.showTab("library");
  assert.strictEqual(o.panel.state.ui.activeTab, "library");
});


test("the selection inspector sets Type and Boundary on every selected Face, one attribute at a time", function () {
  var o = setup(), type = byLabel(o.document.body, "Type for selected Faces");
  var boundary = byLabel(o.document.body, "Boundary for selected Faces");
  assert.strictEqual(type.value, o.face.values.face_type, "what the selection shares is shown");
  assert.ok(!boundary.children.some(function (entry) { return entry.value === "AttachedZone"; }),
    "an Attached zone needs a record, so it is not offered here");
  boundary.value = "Ground";
  boundary.listeners.change({});
  assert.strictEqual(o.sent[0].payload.name, PREFIX + ".classify");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(o.sent[0].payload.params)), { faces: [o.face.reference],
    intent: { face_type: { mode: "keep" }, boundary_condition: { mode: "set", value: "Ground" } },
    expected_values: o.face.values });
  var section = o.query("[data-section='ph_composer.zones.selection']");
  assert.strictEqual(section.hidden, false);
  assert.strictEqual(section.parentNode.getAttribute("data-phc-region"), "inspector");
  o.state.sections[PREFIX + ".selected"].value.targets = []; o.paint();
  assert.strictEqual(section.hidden, true, "no selection, no selection inspector");
});

test("the selection's Assembly rests on what the Faces share, and reads Mixed when they differ", function () {
  var o = setup(), targets = o.state.sections[PREFIX + ".selected"].value.targets;
  var picker = byLabel(o.document.body, "Assembly for selected Faces");
  targets[0].expected_values.assembly_id = "asm_a";
  o.paint();
  assert.deepStrictEqual([picker.value, picker.children[0].textContent], ["asm_a", "Choose Assembly"]);
  picker.listeners.change({});
  assert.strictEqual(o.sent.length, 0, "choosing what is already assigned sends nothing");
  picker.value = ""; picker.listeners.change({});
  assert.deepStrictEqual([picker.value, o.sent.length], ["asm_a", 0], "the label is not a choice");
  var second = JSON.parse(JSON.stringify(targets[0]));
  second.reference.entity_path = [999];
  second.expected_values.assembly_id = null;
  targets.push(second);
  o.paint();
  assert.deepStrictEqual([picker.value, picker.children[0].textContent], ["", "Mixed"]);
});

test("selected Faces that disagree read Mixed; a value the tree keeps read only is read only here", function () {
  var o = setup(), targets = o.state.sections[PREFIX + ".selected"].value.targets;
  var second = JSON.parse(JSON.stringify(targets[0]));
  second.reference.entity_path = [999];
  second.expected_values = { face_type: "Floor", boundary_condition: "Surface" };
  targets.push(second);
  o.paint();
  var type = byLabel(o.document.body, "Type for selected Faces");
  var boundary = byLabel(o.document.body, "Boundary for selected Faces");
  assert.deepStrictEqual([type.value, type.children[0].textContent, type.children[0].disabled], ["", "Mixed", true]);
  assert.strictEqual(boundary.disabled, true, "one of them is a paired Surface");
  type.value = "Wall";
  type.listeners.change({});
  var params = JSON.parse(JSON.stringify(o.sent[0].payload.params));
  assert.strictEqual(params.faces.length, 2);
  assert.strictEqual(params.expected_values, undefined, "several Faces share no one set of values to guard by");
});

test("the palette can drop the Assembly it is painting", function () {
  var o = setup();
  o.state.sections[PREFIX + ".palette"].value.palette.assembly_id = "asm_a";
  o.paint();
  click(o.query("[data-section='ph_composer.classify']").querySelectorAll("button").filter(function (node) {
    return node.textContent === "Stop painting it";
  })[0]);
  assert.deepStrictEqual(o.sent[0].payload.params, { field: "assembly_id", value: null });
});
