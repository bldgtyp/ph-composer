"use strict";

var assert = require("assert");
var test = require("node:test");
var dom = require("./support/dom_stub");
var panelSource = require("./support/panel_source");

function setup(extra) {
  var document = dom.buildDocument("");
  var context = { document: document, Intl: Intl };
  context.window = context;
  var modules = panelSource.start(context, ["record_edits"]);
  var sent = [], notices = [];
  var quantity = { quantity: "conductivity", unit: "w_mk", label: "Conductivity", allowBlank: true };
  var options = Object.assign({ action: "example.update", fields: ["conductivity_w_mk"],
    quantities: { conductivity_w_mk: quantity } }, extra);
  var edits = new modules.record_edits("session", function (type, payload) {
    sent.push({ type: type, payload: payload });
  }, function (message) { notices.push(message); }, options);
  var row = { key: "part:a", record: { id: "a", values: { conductivity_w_mk: 0.04 } } };
  var td = document.createElement("td");
  document.body.appendChild(td);
  edits.refresh([row], { session: "session", ui: {} });
  edits.render(td, row, "conductivity_w_mk");
  return { edits: edits, cell: edits.cells["part:a:conductivity_w_mk"], row: row, sent: sent,
    notices: notices, modules: modules, document: document, quantity: quantity };
}
function type(o, text) { o.cell.input.value = text; o.cell.input.listeners.input({}); }
function result(o, outcome) {
  return { session: "session", ui: { actionResult: { session: "session",
    request_id: o.sent[0].payload.request_id, outcome: outcome } } };
}

test("an untouched blur sends nothing; Enter sends one action with expected_values", function () {
  var o = setup();
  o.cell.input.listeners.blur({});
  assert.strictEqual(o.sent.length, 0);
  type(o, "0.05");
  o.cell.input.listeners.keydown({ key: "Enter", preventDefault: function () {} });
  o.cell.input.listeners.blur({});
  assert.strictEqual(o.sent.length, 1);
  assert.strictEqual(o.sent[0].type, "action.invoke");
  assert.strictEqual(o.sent[0].payload.name, "example.update");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(o.sent[0].payload.params)), {
    id: "a", values: { conductivity_w_mk: 0.05 }, expected_values: { conductivity_w_mk: 0.04 }
  });
  o.edits.dispose();
});

test("a stale refusal keeps the typed draft until Escape restores the current Model value", function () {
  var o = setup();
  type(o, "0.05");
  o.edits.commit(o.cell);
  o.row.record.values.conductivity_w_mk = 0.06;
  o.edits.refresh([o.row], result(o, { status: "refused", code: "target.changed",
    message: "The record changed. Nothing was written." }));
  assert.strictEqual(o.cell.input.value, "0.05");
  assert.strictEqual(o.cell.error.textContent, "The record changed. Nothing was written.");
  o.cell.input.listeners.blur({});
  assert.strictEqual(o.sent.length, 1);
  o.cell.input.listeners.keydown({ key: "Escape", preventDefault: function () {} });
  assert.strictEqual(o.cell.input.value, "0.06");
  assert.strictEqual(o.cell.status, "clean");
  o.edits.dispose();
});

test("success requires both the correlated outcome and the authoritative value", function () {
  var o = setup();
  type(o, "0.05");
  o.edits.commit(o.cell);
  o.edits.refresh([o.row], result(o, { status: "completed" }));
  assert.strictEqual(o.cell.status, "error");
  assert.strictEqual(o.cell.input.value, "0.05");
  o.edits.cancel(o.cell);
  type(o, "0.07");
  o.edits.commit(o.cell);
  o.row.record.values.conductivity_w_mk = 0.07;
  o.edits.refresh([o.row], { ui: { actionResult: { session: "session",
    request_id: o.sent[1].payload.request_id, outcome: { status: "completed" } } } });
  assert.strictEqual(o.cell.status, "clean");
  assert.strictEqual(o.cell.baseline, 0.07);
  o.edits.dispose();
});

test("typing freezes units while clean cells follow preference changes", function () {
  var o = setup();
  o.modules.unit_preferences.set("unit_system", "IP");
  assert.strictEqual(o.cell.input.value, o.modules.units.formatEdit(0.04, o.quantity,
    o.modules.units.profile(o.quantity)));
  type(o, "0.3");
  var expected = o.edits.normalize("conductivity_w_mk", "0.3");
  o.modules.unit_preferences.set("unit_system", "SI");
  assert.strictEqual(o.cell.input.value, "0.3");
  o.edits.commit(o.cell);
  assert.strictEqual(o.sent[0].payload.params.values.conductivity_w_mk, expected);
  o.edits.dispose();
});

test("disposed and removed cells never commit through retained listeners", function () {
  ["dispose", "remove"].forEach(function (route) {
    var o = setup();
    type(o, "0.05");
    if (route === "dispose") o.edits.dispose();
    else o.edits.refresh([], { ui: {} });
    o.cell.input.listeners.blur({});
    o.edits.commit(o.cell);
    assert.strictEqual(o.sent.length, 0, route);
    o.edits.dispose();
  });
});

test("parse failures stay visible and editable; configured read-only cells cannot commit", function () {
  var o = setup();
  type(o, "-1");
  o.edits.commit(o.cell);
  assert.strictEqual(o.cell.status, "error");
  assert.strictEqual(o.cell.error.textContent, "Conductivity cannot be negative.");
  type(o, "0.05");
  o.edits.commit(o.cell);
  assert.strictEqual(o.sent.length, 1);
  o.edits.dispose();
  var locked = setup({ readOnly: function () { return true; } });
  type(locked, "0.05");
  locked.edits.commit(locked.cell);
  assert.strictEqual(locked.sent.length, 0);
  locked.edits.dispose();
});
