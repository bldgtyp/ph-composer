"use strict";
/* Dragging a whole Layer by its grip: one layers.reorder action per changed drop, nothing on any other ending. */
var assert = require("assert");
var test = require("node:test");
var dom = require("./support/dom_stub");
var source = require("./support/panel_source");
var fixtures = require("./support/inventory_fixtures");
var ASSEMBLIES = "ph_composer.assemblies.assemblies";
var MATERIALS = "ph_composer.assemblies.materials";
// At zoom 1 the drawing's top is at 100 px: boundaries at 100, 112, 252, 261 and 276.
var DRAWING = { left: 200, top: 100, right: 800, bottom: 276, width: 600, height: 176 };
var FRAME = { left: 72, top: 60, right: 928, bottom: 330, width: 856, height: 270 };

function setup() {
  var document = dom.buildDocument("");
  var context = { document: document, Intl: Intl, innerWidth: 1280, innerHeight: 800, setTimeout: setTimeout,
    clearTimeout: clearTimeout };
  context.window = context;
  dom.attachEvents(context);
  var modules = source.start(context, ["features/assemblies/editor"]), sent = [], notices = [];
  var state = fixtures.state();
  state.sections[MATERIALS].value.records.push({ id: "mat_m", kind: "ph_composer.assemblies.material",
    schema_version: 1, user_data: {}, extension_data: {}, findings: [], uses: [], use_count: 0,
    values: { name: "Membrane", notes: "", category: "membrane", color: "#90a4ae" } });
  var record = state.sections[ASSEMBLIES].value.records[0];
  record.values.orientation = "first_layer_outside";
  record.values.air_barrier = { layer_id: "layer_sheathing", face: "interior" };
  record.values.layers = [
    { id: "layer_board", thickness_mm: 12, segments: [{ id: "seg_board", width_mm: 600, material_id: "mat_b" }] },
    { id: "layer_studs", thickness_mm: 140, segments: [
      { id: "seg_wool", width_mm: 560, material_id: "mat_a" },
      { id: "seg_steel", width_mm: 40, material_id: null, steel_stud_spacing_mm: 600 }] },
    { id: "layer_membrane", thickness_mm: 1, segments: [{ id: "seg_membrane", width_mm: 600, material_id: "mat_m" }] },
    { id: "layer_sheathing", thickness_mm: 15, segments: [
      { id: "seg_sheathing", width_mm: 600, material_id: "mat_b" }] }
  ];
  record.display = { total_thickness_mm: 167, thermal: { complete: true, u_effective_w_m2k: 0.21, warnings: [] } };
  var editor = new modules["features/assemblies/editor"].Editor("session", function (type, payload) {
    sent.push({ type: type, payload: payload });
  }, function (message) { notices.push(message); }, function () {});
  document.body.appendChild(editor.root);
  editor.refresh(state, record.id);
  var o = { editor: editor, modules: modules, state: state, record: record, sent: sent, notices: notices,
    document: document, window: context };
  editor.setZoom(1);
  return o;
}
function boxes(o) {
  o.editor.main.querySelector(".assembly-drawing").rect = DRAWING;
  o.editor.main.querySelector(".assembly-canvas-frame").rect = FRAME;
}
function grip(o, id) { return o.editor.main.querySelector("[data-layer-drag-trigger='" + id + "']"); }
function press(o, id, y) {
  boxes(o);
  grip(o, id).listeners.mousedown({ button: 0, clientX: 150, clientY: y, preventDefault: function () {} });
}
function move(o, x, y) {
  o.document.dispatchEvent({ type: "mousemove", clientX: x, clientY: y, preventDefault: function () {} });
}
// A move that reports which buttons are held, as a real pointer does.
function moveHolding(o, buttons, y) {
  o.document.dispatchEvent({ type: "mousemove", clientX: 300, clientY: y, buttons: buttons,
    preventDefault: function () {} });
}
function up(o, x, y) { o.document.dispatchEvent({ type: "mouseup", clientX: x, clientY: y }); }
// Pressed on a grip, then dragged well past the threshold to clientY.
function drag(o, id, from, to) { press(o, id, from); move(o, 150, from + (to < from ? -20 : 20)); move(o, 300, to); }
function ended(o) {
  assert.strictEqual(o.document.body.querySelector(".assembly-drag-ghost"), null);
  assert.strictEqual(o.editor.main.querySelector(".assembly-drop-line"), null);
  assert.strictEqual(o.editor.dragging, false);
  assert.strictEqual(o.document.body.classList.contains("assembly-layer-dragging"), false);
  ["mousemove", "mouseup", "keydown"].forEach(function (name) {
    assert.strictEqual((o.document.listenerLists[name] || []).length, 0, name);
  });
  assert.strictEqual((o.window.listenerLists.blur || []).length, 0);
}
function result(o, status, message) {
  o.state.ui.actionResult = { session: "session", request_id: o.sent[o.sent.length - 1].payload.request_id,
    outcome: { status: status || "completed", message: message || "Changed in the Model." } };
  o.editor.refresh(o.state, o.record.id);
}

test("the drop index snaps to the nearest boundary, thin or thick, whatever the orientation", function () {
  var o = setup(), drop = o.modules["features/assemblies/layer_drag"].dropIndex;
  var shared = o.modules["features/assemblies/editor_shared"], canvas = o.modules["features/assemblies/canvas"];
  var materials = shared.lookup(o.state.sections[MATERIALS].value.records);
  var layout = canvas.geometry(o.record.values, materials);
  assert.strictEqual(drop(layout, 1, DRAWING, 40, 3), 0, "above the drawing is the first place");
  assert.strictEqual(drop(layout, 1, DRAWING, 500, 0), 3, "below the drawing is the last place");
  assert.strictEqual(drop(layout, 1, DRAWING, 255, 0), 1, "the membrane band's upper half is its top");
  assert.strictEqual(drop(layout, 1, DRAWING, 259, 0), 2, "the membrane band's lower half is its bottom");
  assert.strictEqual(drop(layout, 1, DRAWING, 112, 1), 1, "the source's own top boundary");
  assert.strictEqual(drop(layout, 1, DRAWING, 252, 1), 1, "the source's own bottom boundary");
  assert.strictEqual(drop(layout, 2, { top: 100 }, 124, 3), 1, "zoom scales the boundaries");
  var turned = canvas.geometry(Object.assign({}, o.record.values, { orientation: "last_layer_outside" }), materials);
  [40, 112, 255, 259, 500].forEach(function (y) {
    assert.strictEqual(drop(turned, 1, DRAWING, y, 0), drop(layout, 1, DRAWING, y, 0));
  });
});

test("a drop sends one reorder with the expected values and the drawing follows the result", function () {
  var o = setup();
  o.editor.select({ layerId: "layer_studs", segmentId: "seg_steel" });
  drag(o, "layer_sheathing", 268, 101);
  var line = o.editor.main.querySelector(".assembly-drop-line");
  assert.strictEqual(line.style.top, "0px");
  assert.strictEqual(line.classList.contains("is-noop"), false);
  assert.strictEqual(o.document.body.querySelector(".assembly-drag-ghost").textContent, "Layer 4");
  assert.strictEqual(o.editor.dragging, true);
  assert.strictEqual(o.sent.length, 0, "nothing is written while the Layer is held");
  up(o, 300, 101);
  ended(o);
  assert.strictEqual(o.sent.length, 1);
  var params = o.sent[0].payload.params;
  assert.strictEqual(o.sent[0].payload.name, ASSEMBLIES + ".layers.reorder");
  assert.deepStrictEqual([params.layer_id, params.index], ["layer_sheathing", 0]);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(params.expected_values)), { layers: o.record.values.layers,
    orientation: "first_layer_outside", air_barrier: { layer_id: "layer_sheathing", face: "interior" } });
  o.record.values.layers.unshift(o.record.values.layers.pop());
  result(o);
  assert.deepStrictEqual(o.editor.selection, { layerId: "layer_studs", segmentId: "seg_steel" });
  assert.strictEqual(o.editor.enabled, true);
  assert.strictEqual(grip(o, "layer_sheathing").getAttribute("aria-label"), "Drag Layer 1");
  assert.strictEqual(grip(o, "layer_board").getAttribute("aria-label"), "Drag Layer 2");
  drag(o, "layer_sheathing", 106, 290);
  up(o, 300, 290);
  assert.deepStrictEqual([o.sent[1].payload.params.layer_id, o.sent[1].payload.params.index], ["layer_sheathing", 3]);
  assert.strictEqual(o.sent.length, 2);
});

test("a release on its own place, outside the frame or under the threshold sends nothing", function () {
  var o = setup();
  drag(o, "layer_studs", 180, 251);
  assert.ok(o.editor.main.querySelector(".assembly-drop-line").classList.contains("is-noop"));
  up(o, 300, 251);
  drag(o, "layer_studs", 180, 101);
  move(o, FRAME.right + 60, 101);
  assert.strictEqual(o.editor.main.querySelector(".assembly-drop-line").hidden, true);
  up(o, FRAME.right + 60, 101);
  ended(o);
  var click = { preventDefault: function () { this.prevented = true; }, stopPropagation: function () {} };
  grip(o, "layer_studs").listeners.click(click);
  assert.ok(click.prevented, "the trailing click after a drag is swallowed");
  press(o, "layer_studs", 180);
  move(o, 153, 183);
  up(o, 153, 183);
  click = { preventDefault: function () { this.prevented = true; }, stopPropagation: function () {} };
  grip(o, "layer_studs").listeners.click(click);
  assert.ok(!click.prevented, "a press that never became a drag leaves the click alone");
  assert.strictEqual(o.document.body.querySelector(".assembly-drag-ghost"), null);
  assert.strictEqual(o.sent.length, 0);
});

test("a lost release ends the drag and another button's release does not drop", function () {
  var o = setup();
  press(o, "layer_board", 106);
  moveHolding(o, 0, 270);
  assert.strictEqual(o.document.listenerLists.mousemove.length, 0, "a press whose release was lost lets go");
  drag(o, "layer_board", 106, 270);
  moveHolding(o, 0, 271);
  ended(o);
  up(o, 300, 271);
  assert.strictEqual(o.sent.length, 0, "a later release sends nothing");
  drag(o, "layer_board", 106, 270);
  o.document.dispatchEvent({ type: "mouseup", button: 2, clientX: 300, clientY: 270 });
  assert.strictEqual(o.editor.dragging, true, "the right button's release leaves the Layer held");
  assert.strictEqual(o.sent.length, 0);
  moveHolding(o, 1, 270);
  up(o, 300, 270);
  ended(o);
  assert.deepStrictEqual([o.sent.length, o.sent[0].payload.params.index], [1, 3]);
});
test("Escape, leaving the window, a repaint and disposal end a drag and send nothing", function () {
  var o = setup();
  o.editor.select({ layerId: "layer_studs", segmentId: "seg_wool" });
  drag(o, "layer_board", 106, 270);
  var escape = { key: "Escape", preventDefault: function () {}, stopImmediatePropagation: function () {} };
  o.document.listeners.keydown(escape);
  ended(o);
  assert.ok(o.editor.selection, "Escape ends the drag before it reaches the selection");
  drag(o, "layer_board", 106, 270);
  o.window.listeners.blur({});
  ended(o);
  drag(o, "layer_board", 106, 270);
  o.editor.refresh(o.state, o.record.id);
  ended(o);
  up(o, 300, 270);
  drag(o, "layer_board", 106, 270);
  o.editor.dispose();
  ended(o);
  up(o, 300, 270);
  assert.strictEqual(o.sent.length, 0);
});

test("a drag waits for drafts, requests and a Material drag, and holds both of the others off", function () {
  var o = setup();
  function refused(reason) {
    press(o, "layer_board", 106);
    move(o, 300, 270);
    assert.strictEqual(o.document.body.querySelector(".assembly-drag-ghost"), null, reason);
    assert.strictEqual(o.notices[o.notices.length - 1], reason);
  }
  var field = o.editor.dimensions["thickness:layer_studs"].field;
  field.input.value = "160"; field.input.listeners.input({});
  refused("Apply or cancel the Assembly draft before leaving.");
  field.cancel();
  o.editor.hasRecordDraft = function () { return true; };
  refused("Apply or cancel the Assembly draft before leaving.");
  delete o.editor.hasRecordDraft;
  o.editor.dragging = true;
  refused("Finish dragging the Material first.");
  o.editor.dragging = false;
  o.editor.action("layers.add", {});
  refused("Wait for the Assembly change to finish.");
  assert.strictEqual(o.sent.length, 1);
  o.editor.requests.reset();
  drag(o, "layer_board", 106, 270);
  assert.strictEqual(o.editor.guard(), "Finish moving the Layer first.");
  var sidebar = o.editor.sidebar;
  sidebar.drag.start(sidebar.entries.mat_a, { button: 0, clientX: 10, clientY: 10 });
  assert.strictEqual(sidebar.drag.entry, null, "no Material drag starts while a Layer is held");
  o.window.listeners.blur({});
  assert.strictEqual(o.editor.guard(), null);
  assert.strictEqual(o.sent.length, 1);
});

test("a refused reorder shows the ordinary failure and keeps the drawing truthful", function () {
  var o = setup();
  drag(o, "layer_board", 106, 270);
  up(o, 300, 270);
  assert.strictEqual(o.sent[0].payload.params.index, 3);
  result(o, "refused", "The Assembly changed in the Model. Nothing was written.");
  assert.strictEqual(o.notices[o.notices.length - 1], "The Assembly changed in the Model. Nothing was written.");
  assert.strictEqual(grip(o, "layer_board").getAttribute("aria-label"), "Drag Layer 1");
  assert.strictEqual(o.editor.busy(), false);
});

test("the grip sits after the thickness and the gear, keyless, and the hover corridor reaches both", function () {
  var o = setup(), handle = grip(o, "layer_studs"), cell = handle.parentNode;
  assert.strictEqual(handle.getAttribute("aria-label"), "Drag Layer 2");
  assert.strictEqual(handle.getAttribute("tabindex"), "-1");
  assert.ok(handle.classList.contains("assembly-layer-grip"));
  var inline = cell.querySelector(".phc-dimension-inline"), gear = cell.querySelector(".assembly-layer-gear");
  // The CSS hides both while the inline thickness field owns the gutter: `.is-editing ~` reaches later siblings.
  assert.ok(cell.children.indexOf(inline) < cell.children.indexOf(gear));
  assert.ok(cell.children.indexOf(gear) < cell.children.indexOf(handle));
  // The membrane's band is 9 px; its icons stand taller. Crossing below the band over them keeps its row.
  var thin = grip(o, "layer_membrane").parentNode, thinGear = thin.querySelector(".assembly-layer-gear");
  var frame = o.editor.main.querySelector(".assembly-canvas-frame");
  thin.rect = { left: 72, right: 200, top: 252, bottom: 261 };
  thinGear.rect = { left: 73, right: 97, top: 244, bottom: 268 };
  grip(o, "layer_membrane").rect = { left: 97, right: 121, top: 244, bottom: 268 };
  thinGear.closest = function (selector) { return selector === "[data-layer-row]" ? thin : thinGear; };
  frame.listeners.mousemove({ target: thinGear, clientX: 80, clientY: 256 });
  assert.ok(thin.classList.contains("is-layer-hovered"));
  o.editor.main.querySelector(".assembly-drawing").rect = DRAWING;
  [80, 110].forEach(function (x) {
    frame.listeners.mousemove({ target: frame, clientX: x, clientY: 266 });
    assert.ok(thin.classList.contains("is-layer-hovered"), "the corridor keeps the row at " + x);
  });
  frame.listeners.mousemove({ target: frame, clientX: 300, clientY: 266 });
  assert.ok(grip(o, "layer_sheathing").parentNode.classList.contains("is-layer-hovered"), "past it, the Layer below");
});
