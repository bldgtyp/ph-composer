"use strict";
var assert = require("assert"), test = require("node:test"), dom = require("./support/dom_stub"),
  source = require("./support/panel_source"), fixtures = require("./support/window_fixtures");
function setup() {
  var document = dom.buildDocument(""), context = { document: document, Intl: Intl, innerWidth: 1280,
    setTimeout: setTimeout, clearTimeout: clearTimeout }; context.window = context; dom.attachEvents(context);
  var modules = source.start(context, ["window_editor"]), state = fixtures.state(), sent = [];
  var editor = new modules.window_editor.View(document.body, state.session, function (type, payload) {
    sent.push({ type: type, payload: payload }); }); editor.render(state);
  return { editor: editor, state: state, sent: sent, modules: modules, document: document };
}
function click(node) { node.listeners.click({ preventDefault: function () {}, stopPropagation: function () {} }); }
function text(node) { return node.textContent + node.children.map(text).join(" "); }
test("drawing renders explicit three elements including Empty and canonical U headlines", function () {
  var o = setup(); assert.strictEqual(o.editor.canvas.root.querySelectorAll("[data-window-element]").length, 3);
  assert.ok(text(o.editor.uwMetric).includes("0.8")); assert.ok(text(o.editor.installedMetric).includes("0.9"));
  assert.strictEqual(o.sent.length, 0);
  o.state.sections["ph_composer.windows.types"].value.records[0].display.thermal.u_w = null;
  o.editor.render(o.state); assert.strictEqual(o.editor.uwMetric.textContent, "—");
});
test("toolbar sends one named grid action with explicit IDs and raw expected values", function () {
  var o = setup(); o.editor.select("wel_a"); o.editor.select("wel_b", { shiftKey: true });
  click(o.editor.root.querySelector("[data-window-action='merge']"));
  assert.strictEqual(o.sent.length, 1); assert.strictEqual(o.sent[0].payload.name,
    "ph_composer.windows.types.grid.merge");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(o.sent[0].payload.params.ids)), ["wel_a", "wel_b"]);
  assert.ok(o.sent[0].payload.params.expected_values.elements);
  click(o.editor.root.querySelector("[data-window-action='flip']")); assert.strictEqual(o.sent.length, 1);
});
test("dimension unit draft survives a unit switch and navigation is guarded", function () {
  var o = setup(); o.editor.dimension("columns_m", 0, o.editor.title);
  var field = o.editor.dimensionField; field.input.value = "500 mm"; field.input.listeners.input({});
  o.modules.unit_preferences.set("unit_system", "IP"); o.editor.render(o.state);
  assert.strictEqual(field.input.value, "500 mm"); assert.ok(o.editor.guard());
  field.cancel(); assert.strictEqual(o.sent.length, 0);
});
test("Installs stage locally, exclude shared edge, Save once and Cancel never writes", function () {
  var o = setup(), installs = o.editor.installEditor; installs.open(o.editor.rawRecord()); installs.selected = "psi_a";
  assert.strictEqual(installs.paintEdge("wel_a", "right"), false); assert.strictEqual(o.sent.length, 0);
  installs.paintEdge("wel_a", "top"); assert.ok(installs.guard()); assert.strictEqual(o.sent.length, 0);
  installs.saveAction(); installs.saveAction(); assert.strictEqual(o.sent.length, 1);
  assert.strictEqual(o.sent[0].payload.name, "ph_composer.windows.types.installs.save");
  assert.strictEqual(o.sent[0].payload.params.types[0].installs[0].sides.top, "psi_a");
  var other = setup(); other.editor.installEditor.open(other.editor.rawRecord());
  other.editor.installEditor.paintEdge("wel_a", "top"); other.editor.installEditor.cancelSession(true);
  assert.strictEqual(other.sent.length, 0); assert.ok(other.editor.installEditor.root.hidden);
});
test("disposed Builder and withdrawn snapshots forbid retained actions", function () {
  var o = setup(), button = o.editor.addType; o.editor.dispose(); click(button); assert.strictEqual(o.sent.length, 0);
  o = setup(); delete o.state.sections["ph_composer.windows.types"]; o.editor.render(o.state);
  click(o.editor.addType); assert.strictEqual(o.sent.length, 0); assert.strictEqual(o.editor.guard(), null);
});
function outcome(o, status) {
  o.state.ui.actionResult = { session: "session", request_id: o.sent[o.sent.length - 1].payload.request_id,
    outcome: { status: status, message: "Changed in the Model. Cancel and reopen." } };
  o.editor.render(o.state);
}
test("one and two-element drawings are independent of missing thermal data", function () {
  var o = setup(), record = o.state.sections["ph_composer.windows.types"].value.records[0];
  record.values.elements = record.values.elements.slice(0, 2); record.values.columns_m = [0.5, null];
  record.display.thermal = { elements: [], u_w: null, u_effective: null, findings: ["Enter all grid dimensions."] };
  o.editor.render(o.state);
    assert.strictEqual(o.editor.canvas.root.querySelectorAll("[data-window-element]").length, 2);
  assert.ok(o.editor.canvas.root.querySelector("[aria-label='Set column 2 width']"));
  record.values.elements = record.values.elements.slice(0, 1); record.values.columns_m = [null];
  o.editor.render(o.state);
    assert.strictEqual(o.editor.canvas.root.querySelectorAll("[data-window-element]").length, 1);
  o.editor.installEditor.open(record); o.editor.installEditor.selected = "psi_a";
  assert.strictEqual(o.editor.installEditor.paintEdge("wel_a", "top"), true);
  assert.strictEqual(o.sent.length, 0, "missing dimensions do not prevent local edge staging");
});
test("split, dimension, operation and repeated eyedropper paste carry their exact public shapes", function () {
  var o = setup(); o.editor.selected = ["wel_a"];
  o.editor.change("split", { id: "wel_a" });
  assert.strictEqual(o.sent[0].payload.params.id, "wnt_a");
  assert.strictEqual(o.sent[0].payload.params.element_id, "wel_a"); outcome(o, "completed");
  o.editor.change("element", { id: "wel_a", field: "operation", value: { type: "swing", directions: ["right"] } });
  assert.strictEqual(o.sent[1].payload.name, "ph_composer.windows.types.grid.element");
  assert.strictEqual(o.sent[1].payload.params.element_id, "wel_a"); outcome(o, "completed");
  o.editor.togglePick(); o.editor.select("wel_c"); assert.ok(o.editor.picking, "Empty cannot be the source");
  o.editor.select("wel_a"); o.editor.select("wel_c"); assert.strictEqual(o.sent.length, 2, "Empty cannot be pasted");
  o.editor.select("wel_b"); assert.strictEqual(o.sent[2].payload.params.source_id, "wel_a");
  outcome(o, "completed"); o.editor.select("wel_b"); assert.strictEqual(o.sent.length, 4);
  assert.strictEqual(o.editor.source, "wel_a");
});
test("dimension commit uses shared parsing, holds refusal text and prevents other writes", function () {
  var o = setup(); o.editor.dimension("columns_m", 0, o.editor.title);
  var field = o.editor.dimensionField; field.input.value = "600 mm"; field.input.listeners.input({});
  o.editor.createType(); assert.strictEqual(o.sent.length, 0);
  field.commit(); assert.strictEqual(o.sent[0].payload.params.value, 0.6);
  outcome(o, "refused"); assert.strictEqual(field.input.value, "600 mm"); assert.ok(field.editing);
  assert.ok(field.error.textContent.includes("Changed in the Model"));
  field.cancel(); assert.strictEqual(o.editor.guard(), null);
});
test("type depth resets through a null patch and numeric drafts retain full raw guards", function () {
  var o = setup(); o.editor.depthOverride(); var field = o.editor.dimensionField;
  field.input.value = "200 mm"; field.input.listeners.input({}); field.commit();
  assert.strictEqual(o.sent[0].payload.name, "ph_composer.windows.types.update");
  assert.strictEqual(o.sent[0].payload.params.values.install_depth_m, 0.2);
  assert.ok(!Object.prototype.hasOwnProperty.call(o.sent[0].payload.params.expected_values, "install_depth_m"));
  outcome(o, "completed"); assert.strictEqual(o.editor.dimensionField, null);
});
test("Installs copies compatible topology with independent element IDs and refuses changed shape", function () {
  var o = setup(), installs = o.editor.installEditor;
  var original = o.editor.rawRecord(), target = JSON.parse(JSON.stringify(original)); target.id = "wnt_b";
  target.values.name = "Other"; target.values.elements.forEach(function (cell) { cell.id += "_other"; });
  o.state.sections["ph_composer.windows.types"].value.records.push(target); o.editor.render(o.state);
  installs.open(original); installs.selected = "psi_a"; installs.paintEdge("wel_a", "top");
  assert.strictEqual(installs.copyTo(target), true);
  target.values.name = "Changed later"; installs.saveAction();
  var types = o.sent[0].payload.params.types;
  assert.strictEqual(types.length, 2); assert.strictEqual(types[1].expected_values.name, "Other");
  assert.strictEqual(types[1].installs[0].element_id, "wel_a_other");
  assert.strictEqual(types[1].installs[0].sides.top, "psi_a");
  outcome(o, "refused"); assert.ok(installs.dirty); assert.ok(!installs.root.hidden);
  target.values.columns_m = [2]; assert.strictEqual(installs.copyTo(target), false);
});
test("product cards retain input identity, warn on missing quantities and audit names Empty", function () {
  var o = setup(), frame = o.state.sections["ph_composer.windows.frames"].value.records[0];
  frame.values.uf_w_m2k = null; o.editor.render(o.state);
  assert.ok(o.editor.cards.wel_a.rows.top.row.className.includes("is-incomplete"));
  assert.strictEqual(o.editor.cards.wel_a.rows.top.cells[0].textContent, "—");
  var operation = o.editor.cards.wel_a.operation; o.editor.select("wel_a");
  assert.strictEqual(o.editor.cards.wel_a.operation, operation);
  o.editor.tabs.select("audit"); assert.ok(text(o.editor.audit).includes("Empty, excluded wall area"));
  assert.ok(text(o.editor.audit).includes("Installed U"));
});
test("local product sidebar has no provider controls and read-only details send no actions", function () {
  var o = setup(), sidebar = o.editor.sidebars.frames;
  assert.ok(sidebar.source.hidden); assert.strictEqual(sidebar.store, undefined);
  sidebar.openDetails(sidebar.entries.frm_a); assert.strictEqual(o.sent.length, 0);
  o.editor.select("wel_a"); sidebar.use(sidebar.entries.frm_a.row);
  assert.strictEqual(o.sent[0].payload.params.field, "frames");
  assert.strictEqual(o.sent[0].payload.params.value.top, "frm_a");
});
test("leaving a dirty Installs session asks, then discards locally and continues only after confirmation", function () {
  var o = setup(), installs = o.editor.installEditor, continued = false;
  installs.open(o.editor.rawRecord()); installs.selected = "psi_a"; installs.paintEdge("wel_a", "top");
  installs.cancelSession(false, function () { continued = true; });
  assert.ok(!installs.confirm.hidden); assert.strictEqual(continued, false); assert.strictEqual(o.sent.length, 0);
  var discard = installs.confirm.querySelectorAll("button").filter(function (button) {
    return button.textContent === "Discard changes";
  })[0]; click(discard);
  assert.strictEqual(continued, true); assert.ok(installs.root.hidden); assert.strictEqual(o.sent.length, 0);
});
test("renaming retains a refused draft, rejects empty names locally, then permits Cancel", function () {
  var o = setup(); o.editor.renameInline(); var input = o.editor.root.querySelector(".window-title-input");
  input.value = ""; input.listeners.keydown({ key: "Enter", preventDefault: function () {} });
  assert.strictEqual(o.sent.length, 0); assert.ok(o.editor.renameDraft);
  input.value = "Renamed"; input.listeners.keydown({ key: "Enter", preventDefault: function () {} });
  assert.strictEqual(o.sent[0].payload.name, "ph_composer.windows.types.update");
  outcome(o, "refused"); assert.strictEqual(input.value, "Renamed"); assert.strictEqual(input.disabled, false);
  input.listeners.keydown({ key: "Escape", preventDefault: function () {} });
  assert.strictEqual(o.editor.guard(), null);
});
test("rail rename remains keyed and visible when the Model name changes", function () {
  var o = setup(), anchor = o.editor.list.querySelector("button");
  o.editor.renameInline(o.editor.record(), anchor);
  var input = o.editor.renameNodes[0]; input.value = "Local name draft";
  o.editor.rawRecord().values.name = "Changed elsewhere"; o.editor.render(o.state);
  assert.strictEqual(o.editor.root.querySelector(".window-title-input"), input);
  assert.strictEqual(input.value, "Local name draft"); assert.ok(o.editor.guard());
  click(o.editor.renameNodes[2]); assert.strictEqual(o.editor.guard(), null);
  assert.ok(text(o.editor.list).includes("Changed elsewhere")); assert.strictEqual(o.sent.length, 0);
});
test("missing rename target and withdrawn types explicitly cancel header and rail drafts", function () {
  [true, false].forEach(function (header) {
    var o = setup(); o.editor.renameInline(o.editor.record(), header ? o.editor.title :
      o.editor.list.querySelector("button")); var input = o.editor.renameNodes[0]; input.value = "Draft";
    if (header) delete o.state.sections["ph_composer.windows.types"];
    else o.state.sections["ph_composer.windows.types"].value.records = [];
    o.editor.render(o.state); assert.strictEqual(o.editor.guard(), null);
    assert.strictEqual(o.editor.renameNodes, null);
    input.listeners.keydown({ key: "Enter", preventDefault: function () {} });
    assert.strictEqual(o.sent.length, 0);
  });
});
test("Element name draft guards type, subtab and section navigation and bubble dismissal", function () {
  var o = setup(), other = JSON.parse(JSON.stringify(o.editor.rawRecord())); other.id = "wnt_b";
  o.state.sections["ph_composer.windows.types"].value.records.push(other); o.editor.render(o.state);
  o.editor.editName(o.editor.record().elements[0], o.editor.title);
  var bubble = o.editor.bubble, form = bubble.content.querySelector("form"), input = form.querySelector("input");
  input.value = "Unsaved name"; input.listeners.input({});
  o.editor.choose("wnt_b"); assert.strictEqual(o.editor.active, "wnt_a");
  assert.strictEqual(o.editor.tabs.select("audit"), false);
  assert.ok(o.editor.guard(), "the section navigation guard must retain this form");
  assert.strictEqual(bubble.close(false), false); assert.strictEqual(bubble.panel.hidden, false);
  assert.strictEqual(input.value, "Unsaved name"); assert.strictEqual(o.sent.length, 0);
  form.listeners.submit({ preventDefault: function () {} });
  assert.strictEqual(o.sent.length, 1); assert.strictEqual(o.sent[0].payload.params.value, "Unsaved name");
  outcome(o, "refused"); assert.strictEqual(bubble.panel.hidden, false); assert.ok(o.editor.guard());
  click(form.querySelectorAll("button")[0]); assert.strictEqual(o.editor.guard(), null);
  o.editor.choose("wnt_b"); assert.strictEqual(o.editor.active, "wnt_b");
});
test("withdrawn or disposed Element name form cancels and retained Apply cannot write", function () {
  [true, false].forEach(function (withdraw) {
    var o = setup(); o.editor.editName(o.editor.record().elements[0], o.editor.title);
    var bubble = o.editor.bubble, form = bubble.content.querySelector("form"), input = form.querySelector("input");
    input.value = "Unsaved"; input.listeners.input({});
    if (withdraw) { delete o.state.sections["ph_composer.windows.types"]; o.editor.render(o.state); }
    else o.editor.dispose();
    assert.strictEqual(bubble.panel.hidden, true); assert.strictEqual(o.editor.guard(), null);
    form.listeners.submit({ preventDefault: function () {} }); assert.strictEqual(o.sent.length, 0);
  });
});
test("Window section navigation uses the Element name guard and missing target cancels pending Apply", function () {
  var o = setup(), sectionGuard, context = { document: o.document }; context.window = context;
  var modules = source.start(context, ["sections/windows"], {
    panel: { section: function () {}, navigationGuard: function (name, guard) { sectionGuard = guard; } },
    window_editor: { View: function () { return o.editor; } },
    window_inventory: { definitions: {} }, "sections/library": { registerSurface: function () {} }
  });
  modules["sections/windows"].render(o.document.body, o.state, function () {});
  o.editor.editName(o.editor.record().elements[0], o.editor.title);
  var bubble = o.editor.bubble, form = bubble.content.querySelector("form"), input = form.querySelector("input");
  input.value = "Pending name"; input.listeners.input({}); assert.ok(sectionGuard("library"));
  form.listeners.submit({ preventDefault: function () {} }); assert.strictEqual(o.sent.length, 1);
  o.editor.rawRecord().values.elements.shift(); o.editor.render(o.state);
  assert.strictEqual(sectionGuard("library"), null); assert.strictEqual(bubble.panel.hidden, true);
  form.listeners.submit({ preventDefault: function () {} }); assert.strictEqual(o.sent.length, 1);
});
