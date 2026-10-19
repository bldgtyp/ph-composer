"use strict";
var assert = require("assert"), test = require("node:test"), dom = require("./support/dom_stub"),
  source = require("./support/panel_source");
function setup() {
  var document = dom.buildDocument(""), context = { document: document }; context.window = context;
  var modules = source.start(context, ["library/export"]), sent = [], state = {
    session: "session", revision: 4, ui: { queryResults: {}, fileExportResults: {} } };
  var form = new modules["library/export"](state.session, function (type, payload) {
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
  return { revision: revision, projection_digest: "digest-" + revision,
    kinds: [{ kind: "materials", record_kind_label: "Material", count: 2 }], omissions: [] };
}
test("export defaults to all even with selected rows and sends no filter or action mutation", function () {
  var o = setup(); o.form.open([{ record_kind: "material", id: "mat_a" }]);
  assert.strictEqual(o.sent[0].type, "query.invoke");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(o.sent[0].payload.params)), { scope: "all" });
  answer(o, o.sent[0], projection(4)); o.form.submit(); o.form.submit();
  assert.strictEqual(o.sent.length, 2); assert.strictEqual(o.sent[1].type, "file_export.invoke");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(o.sent[1].payload.params)),
    { scope: "all", identity: "new", expected_revision: 4, projection_digest: "digest-4" });
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
test("the summary shows kind labels and one plain line per omitted kind and reason", function () {
  var o = setup(), frame = "ph_composer.windows.frame", value = projection(4); o.form.open();
  value.omissions = [
    { record_kind: frame, record_kind_label: "Frame", id: "frm_a", fields: ["source"],
      reason: "fields_not_in_wire_schema" },
    { record_kind: frame, record_kind_label: "Frame", id: "frm_b", fields: ["source"],
      reason: "fields_not_in_wire_schema" },
    { record_kind: "ph_composer.windows.window_type", record_kind_label: "Window Type", id: "wt_a", fields: [],
      reason: "unsupported_kind" },
    { record_kind: "outside.part", record_kind_label: "Part", id: "prt_a", fields: [], reason: "outside.reason" }];
  answer(o, o.sent[0], value);
  var lines = o.form.summary.children.map(function (node) { return node.textContent; });
  assert.deepStrictEqual(lines, ["Material: 2", "Frame (2): source attribution is not exported",
    "Window Type: not a library record; it stays in this Model", "Part: not exported"]);
  lines.forEach(function (line) { assert.ok(!/ph_composer\.|_/.test(line), line); });
  assert.ok(o.form.summary.children[3].getAttribute("data-tooltip").includes("outside.reason"));
});

test("stopping waiting for an export settles the form like a failure, with Cancel usable", function () {
  var o = setup(); o.form.open(); answer(o, o.sent[0], projection(4)); o.form.submit();
  assert.ok(o.form.cancel.disabled);

  o.form.requests.abandon(); o.form.refresh(o.state);

  assert.ok(!o.form.cancel.disabled);
  assert.match(o.form.error.textContent, /result is not known/);
  assert.ok(!o.form.submitButton.disabled);
});
