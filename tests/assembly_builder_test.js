"use strict";
var assert = require("assert");
var test = require("node:test");
var dom = require("./support/dom_stub");
var source = require("./support/panel_source");
var fixtures = require("./support/inventory_fixtures");
var ASSEMBLIES = "ph_composer.assemblies.assemblies";
var MATERIALS = "ph_composer.assemblies.materials";
function setup() {
  var document = dom.buildDocument("");
  var context = { document: document, Intl: Intl, innerWidth: 1280, setTimeout: setTimeout,
    clearTimeout: clearTimeout };
  context.window = context;
  dom.attachEvents(context);
  var modules = source.start(context, ["features/assemblies/editor"]), sent = [], notices = [];
  var state = fixtures.state();
  var record = state.sections[ASSEMBLIES].value.records[0];
  record.values.orientation = "first_layer_outside";
  record.values.ventilated_cladding = false;
  record.values.layers = [
    { id: "layer_board", thickness_mm: 12, segments: [{ id: "seg_board", width_mm: 600, material_id: "mat_b" }] },
    { id: "layer_studs", thickness_mm: 140, segments: [
      { id: "seg_wool", width_mm: 560, material_id: "mat_a", is_continuous_insulation: false },
      { id: "seg_steel", width_mm: 40, material_id: null, steel_stud_spacing_mm: 600 }] }
  ];
  record.display = { total_thickness_mm: 152, color: "#c5e1a5", thermal: { complete: true,
    u_effective_w_m2k: 0.21, u_construction_w_m2k: 0.22, rsi_m2k_w: 0.13, rse_m2k_w: 0.04, direction: "horizontal",
    warnings: [], message_parts: [] } };
  var editor = new modules["features/assemblies/editor"].Editor("session", function (type, payload) {
    sent.push({ type: type, payload: payload });
  }, function (message) { notices.push(message); }, function () {});
  document.body.appendChild(editor.root);
  editor.refresh(state, record.id);
  return { editor: editor, modules: modules, state: state, record: record, sent: sent, notices: notices,
    document: document };
}
function click(node) { node.listeners.click({ preventDefault: function () {} }); }
function typed(field, text) { field.input.value = text; field.input.listeners.input({}); }
function text(node) { return node.textContent + node.children.map(text).join(" "); }
function result(o, status) {
  o.state.ui.actionResult = { session: "session", request_id: o.sent[o.sent.length - 1].payload.request_id,
    outcome: { status: status || "completed", message: "Changed in the Model." } };
  o.editor.refresh(o.state, o.record.id);
}
test("Canvas reference retains mixed widths, steel metadata and keyed selection without thermal math", function () {
  var o = setup(), shared = o.modules["features/assemblies/editor_shared"];
  var materials = shared.lookup(o.state.sections[MATERIALS].value.records);
  var canvas = o.modules["features/assemblies/canvas"], layout = canvas.geometry(o.record.values, materials);
  assert.strictEqual(layout.widthMm, 600);
  assert.strictEqual(layout.heightMm, 152);
  assert.strictEqual(layout.segments[2].xMm, 560);
  assert.strictEqual(layout.segments[2].segment.steel_stud_spacing_mm, 600);
  var svg = dom.element("svg");
  canvas.render(svg, layout, materials, { selectedLayerId: "layer_studs", selectedSegmentId: "seg_steel" });
  var shape = svg.querySelector("[data-segment-id='seg_steel']");
  assert.ok(shape.className.includes("is-selected"));
  assert.ok(shape.className.includes("is-null-material"));
  canvas.render(svg, layout, materials, {});
  assert.strictEqual(svg.querySelector("[data-segment-id='seg_steel']"), shape);
  assert.strictEqual(o.sent.length, 0);
});
test("toolbar gestures carry explicit nested IDs and snapshot expected_values in one action", function () {
  var o = setup();
  o.editor.select({ layerId: "layer_studs", segmentId: "seg_steel" });
  click(o.editor.root.querySelector("[data-builder-action='segments.add']"));
  assert.strictEqual(o.sent.length, 1);
  assert.strictEqual(o.sent[0].type, "action.invoke");
  assert.strictEqual(o.sent[0].payload.name, ASSEMBLIES + ".segments.add");
  assert.strictEqual(o.sent[0].payload.params.layer_id, "layer_studs");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(o.sent[0].payload.params.expected_values.layers)),
    o.record.values.layers);
  click(o.editor.root.querySelector("[data-builder-action='layers.flip']"));
  assert.strictEqual(o.sent.length, 1, "a second gesture waits for the first");
});
test("both canonical U-values and films are shown, withheld values show reasons instead of zero", function () {
  var o = setup();
  assert.ok(text(o.editor.root).includes("U-value with films"));
  assert.ok(text(o.editor.root).includes("U-value construction only"));
  assert.ok(text(o.editor.root).includes("0.21"));
  assert.ok(text(o.editor.root).includes("0.22"));
  o.record.display.thermal = { complete: false, u_effective_w_m2k: null, u_construction_w_m2k: null,
    rsi_m2k_w: 0.13, rse_m2k_w: null, warnings: ["Choose a Material for Layer 2 · Layer-Segment 2."] };
  o.editor.refresh(o.state, o.record.id);
  assert.strictEqual(o.editor.root.querySelectorAll("[data-u-withheld]").length, 2);
  assert.ok(text(o.editor.root).includes("Choose a Material for Layer 2"));
  assert.strictEqual(o.sent.length, 0);
});
test("sidebar reads details and search without writes; Use and valid drops assign one explicit segment", function () {
  var o = setup(), sidebar = o.editor.sidebar;
  sidebar.openDetails(sidebar.entries.mat_a);
  assert.ok(text(sidebar.detail.bubble.content).includes("Conductivity"));
  assert.strictEqual(o.sent.length, 0);
  assert.strictEqual(sidebar.use(sidebar.entries.mat_a.row, { layerId: "bad", segmentId: "bad" }), false);
  assert.strictEqual(o.sent.length, 0);
  o.editor.select({ layerId: "layer_studs", segmentId: "seg_steel" });
  sidebar.openDetails(sidebar.entries.mat_a);
  click(sidebar.detail.use);
  assert.strictEqual(o.sent.length, 1);
  assert.strictEqual(o.sent[0].payload.name, ASSEMBLIES + ".segments.set_material");
  assert.strictEqual(o.sent[0].payload.params.segment_id, "seg_steel");
  assert.strictEqual(o.sent[0].payload.params.material_id, "mat_a");
});
test("dimension UnitField freezes SI/IP drafts across repaint, guards Back and retains refusal", function () {
  var o = setup(), field = o.editor.dimensions["thickness:layer_studs"].field;
  typed(field, "160");
  o.modules.unit_preferences.set("unit_system", "IP");
  o.editor.refresh(o.state, o.record.id);
  assert.strictEqual(field.input.value, "160");
  assert.strictEqual(field.unit.textContent, "mm");
  assert.ok(o.editor.guard());
  o.editor.commitDimension("thickness:layer_studs");
  assert.strictEqual(o.sent[0].payload.params.thickness_mm, 160);
  result(o, "refused");
  assert.strictEqual(field.input.value, "160");
  assert.ok(field.editing);
  assert.ok(field.error.textContent.includes("Changed in the Model"));
  field.cancel();
  assert.strictEqual(o.editor.guard(), null);
  assert.notStrictEqual(field.input.value, "140");
});
test("external dimension changes require cancel and a disposed Builder forbids retained callbacks", function () {
  var o = setup(), field = o.editor.dimensions["thickness:layer_studs"].field;
  typed(field, "160");
  o.record.values.layers[1].thickness_mm = 145;
  o.editor.refresh(o.state, o.record.id);
  o.editor.commitDimension("thickness:layer_studs");
  assert.strictEqual(o.sent.length, 0);
  assert.ok(field.error.textContent.includes("Changed in the Model"));
  var add = o.editor.root.querySelector("[data-builder-action='layers.add']");
  o.editor.dispose();
  click(add);
  field.commit();
  assert.strictEqual(o.sent.length, 0);
});
module.exports = { setup: setup };

test("each topology and descriptor gesture sends one operation with physical target IDs", function () {
  var cases = [
    ["layers.add", { anchor_layer_id: "layer_studs", side: "outside" }],
    ["layers.remove", { layer_id: "layer_studs" }],
    ["layers.move", { layer_id: "layer_studs", direction: "outward" }],
    ["layers.flip", {}], ["layers.flip_orientation", {}],
    ["layers.set_air_barrier", { layer_id: "layer_studs", face: "interior" }],
    ["segments.remove", { layer_id: "layer_studs", segment_id: "seg_steel" }],
    ["segments.update", { layer_id: "layer_studs", segment_id: "seg_steel",
      values: { is_continuous_insulation: true } }], ["segments.mirror", {}]
  ];
  cases.forEach(function (entry) {
    var o = setup();
    assert.ok(o.editor.action(entry[0], entry[1]));
    assert.strictEqual(o.sent.length, 1);
    assert.strictEqual(o.sent[0].payload.name, ASSEMBLIES + "." + entry[0]);
    assert.strictEqual(o.sent[0].payload.params.id, "asm_a");
    Object.keys(entry[1]).forEach(function (key) {
      assert.deepStrictEqual(JSON.parse(JSON.stringify(o.sent[0].payload.params[key])), entry[1][key]);
    });
    o.editor.dispose();
  });
});
test("membranes draw as rules and air barrier faces follow orientation without changing dimensions", function () {
  var o = setup(), values = o.record.values, canvas = o.modules["features/assemblies/canvas"];
  var materials = o.modules["features/assemblies/editor_shared"].lookup(o.state.sections[MATERIALS].value.records);
  materials.mat_b.category = "membrane";
  values.air_barrier = { layer_id: "layer_studs", face: "exterior" };
  var layout = canvas.geometry(values, materials);
  assert.strictEqual(layout.layers[0].heightMm, 9);
  assert.strictEqual(layout.layers[0].isMembrane, true);
  assert.strictEqual(layout.airBarrier.yMm, 9);
  values.orientation = "last_layer_outside";
  assert.strictEqual(canvas.geometry(values, materials).airBarrier.yMm, 149);
  assert.strictEqual(values.layers[0].thickness_mm, 12);
});
test("pointer drops reject outside/removed targets and dispatch exactly one accepted assignment", function () {
  var o = setup(), sidebar = o.editor.sidebar, drag = sidebar.drag, entry = sidebar.entries.mat_a;
  var hit = o.editor.main.querySelectorAll(".assembly-hit-target").filter(function (node) {
    return node.getAttribute("data-segment-id") === "seg_steel";
  })[0];
  var event = { button: 0, clientX: 30, clientY: 30, preventDefault: function () {} };
  o.document.elementFromPoint = function () { return null; };
  drag.start(entry, event);
  drag.update(Object.assign({}, event, { clientX: 50 }));
  drag.up(event);
  assert.strictEqual(o.sent.length, 0);
  o.document.elementFromPoint = function () { return hit; };
  drag.start(entry, event);
  drag.update(Object.assign({}, event, { clientX: 50 }));
  assert.ok(hit.classList.contains("is-drop-target"));
  drag.up(event);
  assert.strictEqual(o.sent.length, 1);
  assert.strictEqual(o.sent[0].payload.params.segment_id, "seg_steel");
  assert.strictEqual(hit.classList.contains("is-drop-target"), false);
  assert.strictEqual(drag.entry, null);
});
test("a dimension blur and sidebar toggle retain typing without writes; a completed snapshot settles it", function () {
  var o = setup(), field = o.editor.dimensions["thickness:layer_studs"].field;
  typed(field, "160");
  field.input.blur();
  o.editor.sidebar.toggle();
  assert.strictEqual(o.sent.length, 0);
  assert.strictEqual(field.input.value, "160");
  o.editor.commitDimension("thickness:layer_studs");
  o.record.values.layers[1].thickness_mm = 160;
  result(o);
  assert.strictEqual(field.editing, false);
  assert.strictEqual(field.input.disabled, false);
  assert.strictEqual(o.editor.guard(), null);
});
test("withdrawal resets a pending Builder and retained toolbar/sidebar callbacks cannot write", function () {
  var o = setup(), add = o.editor.root.querySelector("[data-builder-action='layers.add']");
  var entry = o.editor.sidebar.entries.mat_a;
  o.editor.action("layers.add", {});
  delete o.state.sections[ASSEMBLIES];
  o.editor.refresh(o.state, o.record.id);
  assert.strictEqual(o.editor.requests.busy(), false);
  click(add);
  o.editor.sidebar.use(entry.row, { layerId: "layer_studs", segmentId: "seg_steel" });
  assert.strictEqual(o.sent.length, 1);
});

test("assigned removal confirms consequences, Cancel writes nothing, and confirmation uses frozen guards", function () {
  var o = setup();
  o.editor.select({ layerId: "layer_studs", segmentId: "seg_wool" });
  click(o.editor.root.querySelector("[data-builder-action='segments.remove']"));
  assert.strictEqual(o.sent.length, 0);
  assert.strictEqual(o.editor.removal.hidden, false);
  assert.ok(text(o.editor.removal).includes("Material assignment"));
  // The dialog's top-right close does what Cancel does.
  click(o.editor.removal.querySelector(".phc-dialog-close"));
  assert.strictEqual(o.editor.removal.hidden, true);
  assert.strictEqual(o.sent.length, 0);
  click(o.editor.root.querySelector("[data-builder-action='layers.remove']"));
  var expected = JSON.parse(JSON.stringify(o.record.values.layers));
  o.record.values.layers[1].thickness_mm = 180;
  click(o.editor.removal.querySelector(".primary"));
  assert.strictEqual(o.sent.length, 1);
  assert.strictEqual(o.sent[0].payload.name, ASSEMBLIES + ".layers.remove");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(o.sent[0].payload.params.expected_values.layers)), expected);
});
test("drawing selection restores keyed focus so Escape deselects after repaint", function () {
  var o = setup(), hit = o.editor.main.querySelector(".assembly-hit-target");
  hit.focus();
  click(hit);
  assert.strictEqual(o.document.activeElement.parentNode !== null, true);
  assert.notStrictEqual(o.document.activeElement, hit);
  assert.strictEqual(o.document.activeElement.getAttribute("data-segment-id"), "seg_board");
  var prevented = false;
  o.editor.root.listeners.keydown({ key: "Escape", preventDefault: function () { prevented = true; } });
  assert.strictEqual(prevented, true);
  assert.strictEqual(o.editor.selection, null);
  assert.strictEqual(o.sent.length, 0);
});
test("outside drag only suppresses its trailing pointer click and permits keyboard details", async function () {
  var o = setup(), sidebar = o.editor.sidebar, entry = sidebar.entries.mat_a, drag = sidebar.drag;
  var event = { button: 0, clientX: 30, clientY: 30, preventDefault: function () {} };
  o.document.elementFromPoint = function () { return null; };
  drag.start(entry, event);
  drag.update(Object.assign({}, event, { clientX: 50 }));
  drag.up(event);
  entry.button.listeners.click({ detail: 1 });
  assert.strictEqual(Boolean(sidebar.detail), false);
  entry.button.listeners.click({ detail: 0 });
  assert.ok(sidebar.detail);
  sidebar.closeDetails();
  drag.start(entry, event);
  drag.update(Object.assign({}, event, { clientX: 50 }));
  drag.up(event);
  await new Promise(function (resolve) { setTimeout(resolve, 1); });
  assert.strictEqual(entry.suppressClick, false);
  assert.strictEqual(o.sent.length, 0);
});

test("the toolbar shows a selection's tools only while a Layer-Segment is selected", function () {
  var o = setup(), bar = o.editor.root.querySelector(".assembly-toolbar");
  var selection = bar.querySelector(".assembly-selection-tools");
  assert.strictEqual(selection.querySelectorAll("button").length, 0);
  assert.strictEqual(selection.children[0].textContent, "Select a Layer-Segment");
  assert.strictEqual(o.editor.root.querySelectorAll("[data-builder-action='segments.add']").length, 0);
  ["segments.mirror", "layers.flip", "layers.flip_orientation"].forEach(function (action) {
    assert.ok(bar.querySelector("[data-builder-action='" + action + "']"), action + " is in the menu");
  });
  o.editor.select({ layerId: "layer_studs", segmentId: "seg_steel" });
  bar = o.editor.root.querySelector(".assembly-toolbar");
  ["Add segment", "Delete segment", "Segment properties"].forEach(function (label) {
    assert.ok(bar.querySelectorAll("button").some(function (node) {
      return node.getAttribute("aria-label") === label; }), label + " is an icon named for what it does");
  });
  assert.strictEqual(o.editor.root.querySelector(".assembly-back").getAttribute("aria-label"), "Back to Assemblies");
});
