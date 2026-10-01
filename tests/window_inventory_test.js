"use strict";
var assert = require("assert"), test = require("node:test"), dom = require("./support/dom_stub"),
  source = require("./support/panel_source"), fixtures = require("./support/window_fixtures");
function setup(kind) {
  var document = dom.buildDocument(""), context = { document: document, Intl: Intl, innerWidth: 1280,
    setTimeout: setTimeout, clearTimeout: clearTimeout }; context.window = context; dom.attachEvents(context);
  var modules = source.start(context, ["window_inventory"]), state = fixtures.state(), sent = [];
  var view = new modules.window_inventory.Inventory(document.body, "session", function (type, payload) {
    sent.push({ type: type, payload: payload }); }, kind || "frames", function () {}); view.render(state);
  return { view: view, state: state, sent: sent, modules: modules };
}
test("Window product inventory uses shared grid edits with quantity descriptors", function () {
  var o = setup(); assert.ok(o.view.inventory.grid); assert.ok(o.view.inventory.edits);
  assert.ok(o.view.inventory.edits.fields.indexOf("width_m") >= 0);
  assert.strictEqual(o.view.inventory.edits.quantities.width_m.unit, "m");
});
test("used product deletion freezes the complete guard and requires replacement", function () {
  var o = setup(), record = o.state.sections["ph_composer.windows.frames"].value.records[0];
  record.use_count = 1; o.view.form.open("delete", record, [record]); o.view.form.submit();
  assert.strictEqual(o.sent.length, 0); assert.ok(o.view.form.error.textContent.includes("replacement"));
  o.view.form.records.push(fixtures.record("frm_b", { name: "Replacement" }));
  o.view.form.replacement.value = "frm_b"; o.view.form.submit();
  assert.strictEqual(o.sent.length, 1); assert.strictEqual(o.sent[0].payload.params.replacement_id, "frm_b");
  assert.strictEqual(o.sent[0].payload.params.expected_values.name, "Timber frame");
});
test("default updates carry both settings and preserve unsigned depth; disposed callbacks refuse", function () {
  var o = setup("psi_install_types"); o.view.defaultPsi.value = ""; o.view.saveDefaults();
  assert.strictEqual(o.sent.length, 1); assert.strictEqual(o.sent[0].payload.name,
    "ph_composer.windows.settings.update");
  assert.strictEqual(o.sent[0].payload.params.values.default_psi_install_id, null);
  assert.strictEqual(o.sent[0].payload.params.values.default_install_depth_m, 0.1);
  o.view.dispose(); o.view.saveDefaults(); assert.strictEqual(o.sent.length, 1);
});
test("withdrawn settings reset a pending defaults channel and retained Apply cannot dispatch", function () {
  var o = setup("psi_install_types"); o.view.depth.input.value = "200 mm";
  o.view.depth.input.listeners.input({}); o.view.saveDefaults(); assert.ok(o.view.requests.busy());
  delete o.state.sections["ph_composer.windows.settings"]; o.view.render(o.state);
  assert.strictEqual(o.view.requests.busy(), false); assert.strictEqual(o.view.defaultDirty, false);
  assert.strictEqual(o.view.guard(), null); o.view.saveDefaults(); assert.strictEqual(o.sent.length, 1);
});
test("a refused creation keeps the form draft and permits retry after a new snapshot", function () {
  var o = setup(); o.view.form.open("create", null, o.view.records); o.view.form.fields.name.value = "New Frame";
  o.view.form.submit(); o.state.ui.actionResult = { session: "session", request_id: o.sent[0].payload.request_id,
    outcome: { status: "refused", message: "The name is already used." } }; o.view.render(o.state);
  assert.strictEqual(o.view.form.fields.name.value, "New Frame");
    assert.strictEqual(o.view.form.submitButton.disabled, false);
  o.view.form.fields.name.value = "Other Frame"; o.view.form.submit(); assert.strictEqual(o.sent.length, 2);
});
test("new Frame parses authored width and thermal quantities and completion releases the form", function () {
  var o = setup(), form = o.view.form; form.open("create", null, o.view.records);
  form.fields.name.value = " New frame "; form.fields.manufacturer.value = " Synthetic maker ";
  form.fields.width_m.value = "80 mm"; form.fields.uf_w_m2k.value = "1.2"; form.fields.psi_g_w_mk.value = "0.03";
  form.submit(); assert.strictEqual(o.sent.length, 1);
  var values = o.sent[0].payload.params.values; assert.strictEqual(values.name, "New frame");
  assert.strictEqual(values.manufacturer, "Synthetic maker"); assert.strictEqual(values.width_m, 0.08);
  assert.strictEqual(values.uf_w_m2k, 1.2); assert.strictEqual(values.psi_g_w_mk, 0.03);
  o.state.ui.actionResult = { session: "session", request_id: o.sent[0].payload.request_id,
    outcome: { status: "completed", value: { id: "frm_created" } } }; o.view.render(o.state);
  assert.ok(form.root.hidden); assert.strictEqual(o.view.guard(), null);
});
test("new Glazing rejects an out-of-range g-value and preserves the draft for corrected Apply", function () {
  var o = setup("glazings"), form = o.view.form; form.open("create", null, o.view.records);
  form.fields.name.value = "New glazing"; form.fields.ug_w_m2k.value = "0.6"; form.fields.g_value.value = "1.2";
  form.submit(); assert.strictEqual(o.sent.length, 0); assert.ok(form.error.textContent);
  assert.strictEqual(form.fields.name.value, "New glazing"); assert.strictEqual(form.root.hidden, false);
  form.fields.g_value.value = "0.5"; form.submit(); assert.strictEqual(o.sent.length, 1);
  assert.strictEqual(o.sent[0].payload.name, "ph_composer.windows.glazings.create");
  assert.strictEqual(o.sent[0].payload.params.values.ug_w_m2k, 0.6);
  assert.strictEqual(o.sent[0].payload.params.values.g_value, 0.5);
});
