"use strict";
var assert = require("assert"), test = require("node:test"), dom = require("./support/dom_stub"),
  source = require("./support/panel_source");
function setup() {
  var document = dom.buildDocument(""), context = { document: document }; context.window = context;
  var modules = source.start(context, ["library_export"]), sent = [], state = {
    session: "session", revision: 4, ui: { queryResults: {}, fileExportResults: {} } };
  var form = new modules.library_export(state.session, function (type, payload) {
    sent.push({ type: type, payload: payload }); }, function () {});
  document.body.appendChild(form.root); form.refresh(state);
  return { form: form, sent: sent, state: state };
}
function answer(o, message, value, status) {
  var slot = message.type === "query.invoke" ? "queryResults" : "fileExportResults";
  o.state.ui[slot][message.payload.request_id] = { session: "session", request_id: message.payload.request_id,
    outcome: { status: status || "completed", value: value, message: "Cancelled" } };
  o.form.refresh(o.state);
}
function projection(revision) {
  return { revision: revision, kinds: [{ kind: "materials", count: 2 }], omissions: [] };
}
test("export defaults to all even with selected rows and sends no filter or action mutation", function () {
  var o = setup(); o.form.open([{ record_kind: "material", id: "mat_a" }]);
  assert.strictEqual(o.sent[0].type, "query.invoke");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(o.sent[0].payload.params)), { scope: "all" });
  answer(o, o.sent[0], projection(4)); o.form.submit(); o.form.submit();
  assert.strictEqual(o.sent.length, 2); assert.strictEqual(o.sent[1].type, "file_export.invoke");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(o.sent[1].payload.params)),
    { scope: "all", identity: "new", expected_revision: 4 });
});
test("selection is frozen explicitly and scope changes reject late preview answers", function () {
  var o = setup(), selected = [{ record_kind: "material", id: "mat_a" }]; o.form.open(selected);
  var old = o.sent[0]; selected[0].id = "mat_b";
  o.form.scope.value = "selected"; o.form.scope.listeners.change({});
  assert.strictEqual(o.sent[1].payload.params.records[0].id, "mat_a");
  answer(o, old, projection(4)); assert.strictEqual(o.form.projection, null);
  answer(o, o.sent[1], projection(4)); o.form.identity.value = "update"; o.form.name.value = " Example ";
  o.form.submit(); assert.strictEqual(o.sent[2].payload.params.identity, "update");
  assert.strictEqual(o.sent[2].payload.params.library_name, "Example");
});
test("Cancel and withdrawn Model cannot send file commands; revision changes reread scope", function () {
  var o = setup(); o.form.open(); o.form.hide(); answer(o, o.sent[0], projection(4)); o.form.submit();
  assert.strictEqual(o.sent.length, 1); assert.strictEqual(o.form.projection, null);
  o.form.open(); answer(o, o.sent[1], projection(4)); o.state.revision = 5; o.form.refresh(o.state);
  assert.strictEqual(o.sent.length, 3); assert.strictEqual(o.form.projection, null);
  answer(o, o.sent[2], projection(5)); o.state.session = "other"; o.form.refresh(o.state); o.form.submit();
  assert.strictEqual(o.sent.length, 3); assert.ok(o.form.root.hidden);
});
test("native cancellation retains the form and completion closes it", function () {
  var o = setup(); o.form.open(); answer(o, o.sent[0], projection(4)); o.form.submit();
  o.form.hide(); assert.ok(!o.form.root.hidden);
  answer(o, o.sent[1], null, "cancelled"); assert.ok(!o.form.root.hidden);
  assert.strictEqual(o.form.error.textContent, "Cancelled"); o.form.submit();
  answer(o, o.sent[2], { written: true }); assert.ok(o.form.root.hidden);
});
test("a transport answering synchronously cannot overwrite the refusal or disable Cancel", function () {
  var o = setup(); o.form.open(); answer(o, o.sent[0], projection(4));
  o.form.requests.transport = function (type, payload) {
    answer(o, { type: type, payload: payload }, null, "refused");
  };
  o.form.submit(); assert.strictEqual(o.form.error.textContent, "Cancelled");
  assert.strictEqual(o.form.cancel.disabled, false); assert.strictEqual(o.form.busy(), false);
});
