"use strict";
var assert = require("assert");
var test = require("node:test");
var dom = require("./support/dom_stub");
var panelSource = require("./support/panel_source");
var fixtures = require("./support/inventory_fixtures");

function setup() {
  var document = dom.buildDocument("");
  var sections = {}, guards = {}, sent = [], notices = [], state = fixtures.state();
  var roots = { library: dom.element("div"), assemblies: dom.element("div") };
  Object.keys(roots).forEach(function (key) { document.body.appendChild(roots[key]); });
  function send(type, payload) { sent.push({ type: type, payload: payload }); }
  function paint() { Object.keys(sections).forEach(function (key) { sections[key](roots[key], state, send); }); }
  var panel = { section: function (name, render) { sections[name] = render; }, repaint: paint,
    navigationGuard: function (name, guard) { guards[name] = guard; },
    notify: function (message) { notices.push(message); } };
  var context = { document: document, Intl: Intl, innerWidth: 1280, innerHeight: 800,
    setTimeout: setTimeout, clearTimeout: clearTimeout };
  context.window = context;
  dom.attachEvents(context);
  var modules = panelSource.start(context, ["sections/library", "sections/assemblies"], { panel: panel });
  paint();
  return { roots: roots, state: state, sent: sent, notices: notices, modules: modules, paint: paint, guards: guards };
}
function enter(input, value) {
  input.value = value;
  input.listeners.input({});
  input.listeners.keydown({ key: "Enter", preventDefault: function () {}, stopImmediatePropagation: function () {} });
}
function text(node) { return node.textContent + node.children.map(text).join(" "); }

test("library export offers deduped actual grid selection and defaults to all despite the filter", function () {
  var o = setup(), view = o.roots.library._view, grid = view.material.grid;
  grid.select(view.edits.cells["mat_a:name"]);
  grid.select(view.edits.cells["mat_a:conductivity_w_mk"], true);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(view.selection())), {
    record_kind: "ph_composer.assemblies.material", ids: ["mat_a"] });
  view.exportLibrary.listeners.click({});
  assert.strictEqual(o.sent[0].payload.params.scope, "all");
  assert.strictEqual(view.exportForm.selection.length, 1); view.exportForm.hide();
  view.controls.filter.value = "Wood"; view.controls.filter.listeners.input({});
  assert.strictEqual(view.selection().ids.length, 0, "a hidden selected row is withdrawn");
  view.exportLibrary.listeners.click({});
  assert.strictEqual(o.sent[1].payload.params.scope, "all");
  assert.strictEqual(view.exportForm.selection.length, 0, "visible filtered rows are not selected implicitly");
});

test("inventories render transport values, material uses and withheld U-value reasons", function () {
  var o = setup();
  assert.strictEqual(o.roots.library._view.edits.cells["mat_a:name"].input.value, "Mineral wool");
  assert.ok(text(o.roots.library).includes("Definitions stored in this model."));
  var withheld = o.roots.assemblies.querySelector("[data-u-withheld]");
  assert.ok(withheld.getAttribute("aria-label").includes("Choose a Material for every Layer-Segment."));
  assert.strictEqual(o.roots.library.querySelector("[data-material-use-count]").textContent, "1");
  assert.strictEqual(o.sent.length, 0);
});

test("an inline edit sends expected_values once and retains a refused draft", function () {
  var o = setup(), input = o.roots.library._view.edits.cells["mat_a:conductivity_w_mk"].input;
  enter(input, "0.05");
  assert.strictEqual(o.sent.length, 1);
  assert.strictEqual(o.sent[0].payload.name, "ph_composer.assemblies.materials.update");
  assert.strictEqual(o.sent[0].payload.params.expected_values.conductivity_w_mk, 0.04);
  o.state.ui.actionResult = { session: "session", request_id: o.sent[0].payload.request_id,
    outcome: { status: "refused", message: "The Material changed. Nothing was written." } };
  o.paint();
  assert.strictEqual(input.value, "0.05");
  assert.ok(o.guards.library("assemblies"));
});

test("display preferences reformat clean cells and preserve a typing draft", function () {
  var o = setup(), view = o.roots.library._view;
  var input = view.edits.cells["mat_a:conductivity_w_mk"].input;
  input.value = "0.05";
  input.listeners.input({});
  o.modules.unit_preferences.set("unit_system", "IP");
  o.paint();
  assert.strictEqual(input.value, "0.05");
  assert.notStrictEqual(view.edits.cells["mat_b:conductivity_w_mk"].input.value, "0.12");
  assert.strictEqual(o.sent.length, 0);
});

test("an in-use Material delete requires an explicit replacement and names affected Assemblies", function () {
  var o = setup(), view = o.roots.library._view;
  view.replacement.open(o.state.sections["ph_composer.assemblies.materials"].value.records[0],
    o.state.sections["ph_composer.assemblies.materials"].value.records);
  assert.ok(view.replacement.uses.textContent.includes("Wall"));
  view.replacement.submit();
  assert.strictEqual(o.sent.length, 0);
  view.replacement.select.value = "mat_b";
  view.replacement.select.listeners.change({});
  view.replacement.submit();
  assert.strictEqual(o.sent[0].payload.params.replacement_id, "mat_b");
});

test("view controls send nothing and refuse hiding an active draft", function () {
  var o = setup(), view = o.roots.library._view;
  view.controls.filter.value = "Wood";
  view.controls.filter.listeners.input({});
  view.controls.groupBy.value = "category";
  view.controls.groupBy.listeners.change({});
  view.controls.orderBy.value = "conductivity_w_mk";
  view.controls.orderBy.listeners.change({});
  assert.strictEqual(o.sent.length, 0);
  var input = view.edits.cells["mat_b:name"].input;
  input.value = "Draft";
  input.listeners.input({});
  view.controls.filter.value = "Mineral";
  view.controls.filter.listeners.input({});
  assert.strictEqual(view.controls.filter.value, "Wood");
  assert.strictEqual(input.value, "Draft");
});

test("Attached zones use only the existing save and duplicate actions", function () {
  var o = setup(), view = o.roots.library._view;
  view.tabs.select("attached_zones");
  var input = view.attachedEdits.cells["atz_a:name"].input;
  enter(input, "Carport");
  assert.strictEqual(o.sent[0].payload.name, "ph_composer.zones.faces.attached_zone.save");
  assert.strictEqual(o.sent[0].payload.params.expected_values.name, "Garage");
});

test("Assembly Open shows the Builder and exposes no provider controls", function () {
  var o = setup(), view = o.roots.assemblies._view;
  view.open(o.state.sections["ph_composer.assemblies.assemblies"].value.records[0]);
  assert.ok(view.editor);
  assert.ok(view.listRoot.hidden);
  assert.ok(text(view.editor.root).includes("Back to Assemblies"));
  assert.ok(!text(o.roots.assemblies).includes("designPH"));
  assert.ok(!o.roots.assemblies.querySelector("[data-row-action='faces']"));
  assert.strictEqual(o.sent.length, 0);
});

function result(o, index, status, value) {
  var payload = o.sent[index].payload;
  o.state.ui.actionResult = { session: "session", request_id: payload.request_id,
    outcome: { status: status, value: value, message: status === "completed" ? "" : "Changed in the Model." } };
  o.paint();
}

test("new Material converts IP entries and a refused create retains its fields", function () {
  var o = setup(), form = o.roots.library._view.newMaterial;
  o.modules.unit_preferences.set("unit_system", "IP");
  form.open();
  form.fields.name.value = "New insulation";
  form.fields.conductivity_w_mk.value = "0.04 W/(m K)";
  form.fields.conductivity_w_mk.listeners.input({});
  form.submit();
  var params = o.sent[0].payload.params;
  assert.strictEqual(params.values.conductivity_w_mk, 0.04);
  assert.strictEqual(params.values.density_kg_m3, null);
  assert.strictEqual(params.values.category, "");
  result(o, 0, "refused");
  assert.strictEqual(form.root.hidden, false);
  assert.strictEqual(form.fields.name.value, "New insulation");
  assert.strictEqual(form.fields.conductivity_w_mk.value, "0.04 W/(m K)");
  assert.strictEqual(form.cancel.disabled, false);
});

test("new Assembly leaves unset hints absent and creation never authors Layers", function () {
  var o = setup(), form = o.roots.assemblies._view.newAssembly;
  form.open();
  form.fields.name.value = "New wall";
  form.submit();
  var values = o.sent[0].payload.params.values;
  assert.strictEqual(o.sent[0].payload.name, "ph_composer.assemblies.assemblies.create");
  assert.strictEqual(Object.prototype.hasOwnProperty.call(values, "type"), false);
  assert.strictEqual(Object.prototype.hasOwnProperty.call(values, "exterior_condition"), false);
  assert.strictEqual(Object.prototype.hasOwnProperty.call(values, "layers"), false);
  assert.strictEqual(Object.prototype.hasOwnProperty.call(values, "kind"), false);
});

test("duplicate Material copies datasheet links only through the explicit checkbox", function () {
  var o = setup(), form = o.roots.library._view.duplicate;
  form.open(o.state.sections["ph_composer.assemblies.materials"].value.records[0]);
  assert.strictEqual(form.copyDatasheets.checked, false);
  form.submit();
  assert.strictEqual(o.sent[0].payload.params.copy_datasheets, false);
  result(o, 0, "refused");
  form.copyDatasheets.checked = true;
  form.submit();
  assert.strictEqual(o.sent[1].payload.params.copy_datasheets, true);
});

test("Assembly hint selects store honeybee words and clear with a null patch", function () {
  var o = setup(), cell = o.roots.assemblies._view.edits.cells["asm_a:type"];
  cell.input.value = "RoofCeiling";
  cell.input.listeners.change({});
  assert.strictEqual(o.sent[0].payload.params.values.type, "RoofCeiling");
  o.state.sections["ph_composer.assemblies.assemblies"].value.records[0].values.type = "RoofCeiling";
  result(o, 0, "completed");
  cell.input.value = "";
  cell.input.listeners.change({});
  assert.strictEqual(o.sent[1].payload.params.values.type, null);
  assert.strictEqual(o.sent[1].payload.params.expected_values.type, "RoofCeiling");
});

test("range writes stay canonical, serialize individual actions and stop at a refusal", function () {
  var o = setup(), inventory = o.roots.library._view.material;
  inventory.ranges.submit([
    { id: "mat_a", values: { conductivity_w_mk: 0.06 }, expected_values: { conductivity_w_mk: 0.04 } },
    { id: "mat_b", values: { conductivity_w_mk: 0.06 }, expected_values: { conductivity_w_mk: 0.12 } }
  ]);
  assert.strictEqual(o.sent.length, 1);
  assert.strictEqual(o.sent[0].payload.params.values.conductivity_w_mk, 0.06);
  assert.ok(o.guards.library("assemblies"));
  result(o, 0, "refused");
  assert.strictEqual(o.sent.length, 1);
  assert.strictEqual(inventory.ranges.busy(), false);
  assert.ok(o.notices.includes("Changed in the Model."));
});

test("a host category change cannot collapse or filter away a refused draft", function () {
  var o = setup(), inventory = o.roots.library._view.material;
  inventory.controls.groupBy.value = "category";
  inventory.controls.groupBy.listeners.change({});
  var input = inventory.edits.cells["mat_b:name"].input;
  input.value = "Draft wood";
  input.listeners.input({});
  inventory.controls.collapsed[JSON.stringify(["category", "insulation"])] = true;
  o.state.sections["ph_composer.assemblies.materials"].value.records[1].values.category = "insulation";
  o.paint();
  assert.strictEqual(inventory.scroll._table.rows.mat_b.node.hidden, false);
  assert.strictEqual(input.value, "Draft wood");
});

test("changing Model sessions disposes every old draft and form", function () {
  var o = setup(), old = o.roots.library._view, cell = old.edits.cells["mat_a:name"];
  cell.input.value = "Old draft";
  cell.input.listeners.input({});
  o.state.session = "different-session";
  o.paint();
  old.edits.commit(cell);
  old.newMaterial.fields.name.value = "Old form";
  old.newMaterial.submit();
  assert.strictEqual(o.sent.length, 0);
  old.color.open(o.state.sections["ph_composer.assemblies.materials"].value.records[0],
    old.material.scroll._table.rows.mat_a.cells.color._color);
  old.color.submit();
  assert.strictEqual(o.sent.length, 0);
  assert.strictEqual(old.color.enabled, false);
  assert.strictEqual(old.edits.disposed, true);
  assert.strictEqual(o.roots.library._view.edits.cells["mat_a:name"].input.value, "Mineral wool");
});

test("the graphical color picker compares stored color even when the display color was computed", function () {
  var o = setup(), view = o.roots.assemblies._view;
  var record = o.state.sections["ph_composer.assemblies.assemblies"].value.records[0];
  delete record.values.color;
  record.display.color = "#64a4d8";
  view.color.open(record, view.inventory.scroll._table.rows.asm_a.cells.color._color);
  assert.strictEqual(view.color.hex.value, "#64a4d8");
  view.color.square.listeners.keydown({ key: "ArrowRight", preventDefault: function () {} });
  assert.notStrictEqual(view.color.hex.value, "#64a4d8");
  view.color.submit();
  assert.strictEqual(o.sent[0].payload.params.expected_values.color, null);
  view.color.hide();
  assert.strictEqual(view.color.root.hidden, false, "pending color edits cannot dismiss");
  result(o, 0, "refused");
  assert.strictEqual(view.color.root.hidden, false);
  view.color.hide();
  assert.strictEqual(view.color.root.hidden, true);
});

test("feature absence closes inventory forms and unreadable records have a visible explanation", function () {
  var o = setup(), view = o.roots.library._view;
  o.state.sections["ph_composer.assemblies.materials"].value.unreadable = [
    { id: "mat_broken", message: "Unsupported record version." }
  ];
  o.paint();
  assert.ok(view.material.unreadable.textContent.includes("mat_broken: Unsupported record version."));
  view.newMaterial.open();
  delete o.state.sections["ph_composer.assemblies.materials"];
  o.paint();
  assert.strictEqual(view.newMaterial.root.hidden, true);
  assert.strictEqual(view.createMaterial.disabled, true);
  view.newMaterial.fields.name.value = "Cannot create";
  view.newMaterial.submit();
  assert.strictEqual(o.sent.length, 0);
});

test("a modified color draft survives an outside navigation click", function () {
  var o = setup(), view = o.roots.library._view;
  var record = o.state.sections["ph_composer.assemblies.materials"].value.records[0];
  view.color.open(record, view.material.scroll._table.rows.mat_a.cells.color._color);
  view.color.hex.value = "#123456";
  var prevented = false;
  view.color.dismissOutside({ target: o.roots.assemblies, preventDefault: function () { prevented = true; } });
  assert.strictEqual(view.color.root.hidden, false);
  assert.strictEqual(prevented, true);
  assert.ok(o.guards.library("assemblies"));
  assert.strictEqual(o.sent.length, 0);
});

test("withdrawn create requests can reopen with an enabled Cancel after their feature returns", function () {
  var cases = [["library", "newMaterial", "ph_composer.assemblies.materials"],
    ["assemblies", "newAssembly", "ph_composer.assemblies.assemblies"]];
  cases.forEach(function (entry) {
    var o = setup(), form = o.roots[entry[0]]._view[entry[1]], section = o.state.sections[entry[2]];
    form.open();
    form.fields.name.value = "Pending new record";
    form.submit();
    assert.strictEqual(form.cancel.disabled, true);
    delete o.state.sections[entry[2]];
    o.paint();
    assert.strictEqual(form.busy(), false);
    assert.strictEqual(form.root.hidden, true);
    o.state.sections[entry[2]] = section;
    o.paint();
    form.open();
    assert.strictEqual(form.cancel.disabled, false);
    form.cancel.listeners.click({});
    assert.strictEqual(form.root.hidden, true);
    assert.strictEqual(o.sent.length, 1);
  });
});

test("withdrawing an inventory forgets its queued range and ignores the late outcome", function () {
  var o = setup(), inventory = o.roots.library._view.material;
  var section = o.state.sections["ph_composer.assemblies.materials"];
  inventory.ranges.submit([
    { id: "mat_a", values: { notes: "First" }, expected_values: { notes: "" } },
    { id: "mat_b", values: { notes: "Second" }, expected_values: { notes: "" } }
  ]);
  delete o.state.sections["ph_composer.assemblies.materials"];
  o.paint();
  assert.strictEqual(inventory.ranges.busy(), false);
  assert.strictEqual(o.guards.library("assemblies"), null);
  result(o, 0, "completed");
  o.state.sections["ph_composer.assemblies.materials"] = section;
  o.paint();
  assert.strictEqual(o.sent.length, 1, "a late result must not start the abandoned next range write");
  assert.strictEqual(inventory.ranges.busy(), false);
});

test("withdrawing an inventory resets its pending row action", function () {
  var o = setup(), inventory = o.roots.assemblies._view.inventory;
  var section = o.state.sections["ph_composer.assemblies.assemblies"];
  inventory.requests.run("ph_composer.assemblies.assemblies.duplicate", { id: "asm_a" });
  delete o.state.sections["ph_composer.assemblies.assemblies"];
  o.paint();
  assert.strictEqual(inventory.requests.busy(), false);
  assert.strictEqual(o.guards.assemblies("library"), null);
  o.state.sections["ph_composer.assemblies.assemblies"] = section;
  o.paint();
  inventory.requests.run("ph_composer.assemblies.assemblies.duplicate", { id: "asm_b" });
  assert.strictEqual(o.sent.length, 2);
});

test("retained Assembly and Attached-zone Duplicate listeners cannot write after a Model switch", function () {
  var o = setup(), library = o.roots.library._view, assemblies = o.roots.assemblies._view;
  var assemblyDuplicate = assemblies.inventory.scroll._table.rows.asm_a.controls.duplicate.node;
  library.tabs.select("attached_zones");
  var attachedDuplicate = library.attached.scroll._table.rows.atz_a.controls.duplicate.node;
  o.state.session = "new-model-session";
  o.paint();
  assemblyDuplicate.listeners.click({});
  attachedDuplicate.listeners.click({});
  assert.strictEqual(o.sent.length, 0);
  assert.strictEqual(assemblies.inventory.disposed, true);
  assert.strictEqual(library.attached.disposed, true);
});


test("Assembly numeric inventory cells follow the displayed SI and IP units", function () {
  var o = setup(), units = o.modules.units, fields = o.modules.fields;
  var rows = o.state.sections["ph_composer.assemblies.assemblies"].value.records;
  rows[0].display.total_thickness_mm = 165;
  rows[0].display.thermal.u_effective_w_m2k = 0.2;
  o.paint();
  assert.ok(text(o.roots.assemblies).includes(units.format(165, fields.LENGTH_MM,
    units.profile(fields.LENGTH_MM, { unit_system: "SI" }))));
  o.modules.unit_preferences.set("unit_system", "IP");
  o.paint();
  var displayed = text(o.roots.assemblies);
  assert.ok(displayed.includes(units.format(165, fields.LENGTH_MM,
    units.profile(fields.LENGTH_MM, o.modules.unit_preferences.current()))));
  assert.ok(displayed.includes(units.format(0.2, fields.U_VALUE,
    units.profile(fields.U_VALUE, o.modules.unit_preferences.current()))));
  assert.strictEqual(o.sent.length, 0);
});
