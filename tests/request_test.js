"use strict";

/* The request channel: ids, single flight, correlation by id and Model session, and settling once. */

var assert = require("assert");
var test = require("node:test");
var panelSource = require("./support/panel_source");

var context = {};
context.window = context;
var request = panelSource.start(context, ["request"]).request;

function harness(session) {
  var sent = [];
  var channel = request.channel(session || "session-a", function (type, payload) {
    sent.push({ type: type, payload: payload });
  }, "form");
  return { sent: sent, channel: channel };
}
function state(result) { return { ui: { actionResult: result } }; }
function result(id, session, status, message) {
  return { request_id: id, session: session, outcome: { status: status, message: message } };
}

test("run sends one labelled, unique request and refuses while it is pending", function () {
  var h = harness();
  var id = h.channel.run("example.create", { label: "Frame" });
  assert.match(id, /^session-a:form:\d+$/);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(h.sent)), [{ type: "action.invoke",
    payload: { request_id: id, session: "session-a", name: "example.create", params: { label: "Frame" } } }]);
  assert.strictEqual(h.channel.run("example.create", {}), false, "a second run is refused while the first is pending");
  assert.strictEqual(h.sent.length, 1);
  assert.strictEqual(h.channel.busy(), true);
  assert.match(harness().channel.run("x.y", {}, { label: "other" }), /^session-a:other:\d+$/);
  assert.notStrictEqual(harness().channel.send("x.y", {}), harness().channel.send("x.y", {}),
    "ids are unique across channels");
});

test("consume settles only its own result for its own Model session, once", function () {
  var h = harness(), done = [], failed = [];
  var id = h.channel.run("example.create", {}, {
    onDone: function (outcome) { done.push(outcome); }, onFail: function (outcome) { failed.push(outcome); }
  });
  assert.strictEqual(h.channel.consume(state(result("other", "session-a", "completed"))), null);
  assert.strictEqual(h.channel.consume(state(result(id, "session-b", "completed"))), null,
    "the same id from another Model session is not this request");
  assert.strictEqual(h.channel.consume(state(null)), null);
  var mine = result(id, "session-a", "completed");
  assert.strictEqual(h.channel.consume(state(mine)), mine.outcome);
  assert.deepStrictEqual([done.length, failed.length], [1, 0]);
  assert.strictEqual(h.channel.busy(), false);
  assert.strictEqual(h.channel.consume(state(mine)), null, "a result settles once");
});

test("a refused outcome runs the failure handler and frees the channel; reset ignores a late result", function () {
  var h = harness(), failed = [];
  var id = h.channel.run("example.create", {}, { onFail: function (outcome) { failed.push(outcome.message); } });
  h.channel.consume(state(result(id, "session-a", "refused", "The Model changed. Nothing was written.")));
  assert.deepStrictEqual(failed, ["The Model changed. Nothing was written."]);
  assert.notStrictEqual(h.channel.run("example.create", {}), false, "the channel accepts the retry");
  var late = h.channel.pending;
  h.channel.reset();
  assert.strictEqual(h.channel.consume(state(result(late, "session-a", "completed"))), null);
});

test("send never refuses, and matches checks a given id", function () {
  var h = harness();
  var first = h.channel.send("example.update", { id: "a" }), second = h.channel.send("example.update", { id: "b" });
  assert.strictEqual(h.sent.length, 2);
  assert.strictEqual(h.channel.busy(), false, "send does not occupy the single-flight slot");
  assert.strictEqual(h.channel.matches({ request_id: second, session: "session-a" }, second), true);
  assert.strictEqual(h.channel.matches({ request_id: second, session: "session-a" }, first), false);
  assert.strictEqual(h.channel.matches({ request_id: first, session: "session-a" }, null), false);
});

test("a view channel sends view.invoke and settles from its own result slot", function () {
  var sent = [];
  var channel = request.channel("session-a", function (type, payload) {
    sent.push({ type: type, payload: payload });
  }, "legend", "view.invoke");
  var id = channel.run("ph_composer.colour_by.activate", { mode: null });

  assert.strictEqual(sent[0].type, "view.invoke");
  assert.deepStrictEqual(sent[0].payload.params, { mode: null });
  assert.strictEqual(channel.consume(state(result(id, "session-a", "completed"))), null,
    "an action result never settles a view request");
  assert.strictEqual(channel.consume({ ui: { viewResult: result(id, "session-a", "completed") } }).status,
    "completed");
});

test("a channel refuses a message the panel does not carry", function () {
  assert.throws(function () { request.channel("session-a", function () {}, "x", "sketchup.invoke"); },
    /does not carry/);
});
