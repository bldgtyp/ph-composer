"use strict";

var assert = require("assert"), test = require("node:test");
var dom = require("./support/dom_stub"), panelSource = require("./support/panel_source");
function setup(options) {
  var context = { document: dom.buildDocument(""), Intl: Intl, innerWidth: 900, innerHeight: 700 };
  context.window = context; dom.attachEvents(context);
  var modules = panelSource.start(context, ["unit_field"]), busy = false, sent = [], cancelled = 0;
  modules.unit_preferences.replace({ unit_system: "SI", dimension_formats: {} });
  var trigger = modules.workspace.button("Depth");
  var edit = new modules.unit_field.ValueBubble(Object.assign({ trigger: trigger, title: "Install depth",
    field: { quantity: "length", unit: "m", allowZero: true }, value: 0.1,
    busy: function () { return busy; }, onCancel: function () { cancelled += 1; },
    apply: function (value, done) { busy = true; sent.push({ value: value, done: done }); }
  }, options));
  context.document.body.appendChild(edit.bubble.root); edit.bubble.open();
  return { edit: edit, sent: sent, document: context.document, modules: modules,
    settle: function () { busy = false; }, cancelled: function () { return cancelled; } };
}
function type(edit, value) { edit.field.input.value = value; edit.field.input.listeners.input({}); }
function enter(edit) { edit.field.input.listeners.keydown({ key: "Enter", preventDefault: function () {} }); }

test("Enter, blur and outside close share a single-flight quantity commit", function () {
  ["enter", "blur", "outside"].forEach(function (route) {
    var o = setup(), edit = o.edit; type(edit, "200 mm");
    if (route === "enter") enter(edit);
    else if (route === "blur") edit.field.input.listeners.blur({});
    else edit.bubble.close(false);
    enter(edit); edit.bubble.close(false);
    assert.strictEqual(o.sent.length, 1); assert.strictEqual(o.sent[0].value, 0.2);
    assert.strictEqual(edit.field.input.disabled, true); assert.strictEqual(edit.bubble.panel.hidden, false);
    o.settle(); o.sent[0].done(); assert.strictEqual(edit.bubble.panel.hidden, true);
    assert.strictEqual(edit.field.baseline, 0.2);
  });
});

test("invalid and refused values keep their draft, retry uses its starting units, Escape restores", function () {
  var o = setup(), edit = o.edit; type(edit, "abc"); edit.bubble.close(false);
  assert.strictEqual(o.sent.length, 0); assert.strictEqual(edit.bubble.panel.hidden, false);
  assert.strictEqual(edit.field.input.getAttribute("aria-invalid"), "true");
  type(edit, "200 mm"); enter(edit); o.settle(); edit.refuse("Changed elsewhere.", true);
  assert.strictEqual(edit.field.input.value, "200 mm"); assert.strictEqual(edit.field.input.disabled, false);
  assert.strictEqual(edit.field.error.textContent, "Changed elsewhere.");
  o.modules.unit_preferences.replace({ unit_system: "IP", dimension_formats: {} }); enter(edit);
  assert.strictEqual(o.sent[1].value, 0.2); o.settle(); edit.refuse("Retry."); edit.field.cancel();
  assert.strictEqual(edit.bubble.panel.hidden, true); assert.strictEqual(edit.field.baseline, 0.1);
  assert.strictEqual(o.cancelled(), 1);
});

test("blur preserves another control's focus and disposal ignores late acceptance and draft events", function () {
  var o = setup(), edit = o.edit, elsewhere = o.modules.workspace.element("input");
  o.document.body.appendChild(elsewhere); type(edit, "0.1"); elsewhere.focus(); edit.field.input.listeners.blur({});
  assert.strictEqual(edit.bubble.panel.hidden, true); assert.strictEqual(o.document.activeElement, elsewhere);
  edit.bubble.open(); type(edit, "300 mm"); enter(edit); edit.dispose(); o.settle(); o.sent[0].done();
  edit.field.cancel(); enter(edit); edit.bubble.close(true);
  assert.strictEqual(o.sent.length, 1); assert.strictEqual(o.cancelled(), 0);
  assert.strictEqual(edit.field.baseline, 0.1); assert.strictEqual(edit.field.disposed, true);
});

test("an older acceptance cannot close a newer retry and one-use editors dispose after acceptance", function () {
  var o = setup({ once: true }), edit = o.edit; type(edit, "200 mm"); enter(edit);
  o.settle(); edit.refuse("Changed."); type(edit, "300 mm"); enter(edit); o.sent[0].done();
  assert.strictEqual(edit.bubble.panel.hidden, false); assert.strictEqual(edit.field.input.value, "300 mm");
  o.settle(); o.sent[1].done(); assert.strictEqual(edit.field.disposed, true);
  assert.strictEqual(edit.field.baseline, 0.3); assert.strictEqual(edit.bubble.panel.hidden, true);
});
