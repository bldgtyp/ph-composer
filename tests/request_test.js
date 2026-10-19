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
function viewState(results) {
  var kept = {};
  results.forEach(function (one) { kept[one.request_id] = one; });
  return { ui: { viewResults: kept } };
}
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
  assert.strictEqual(channel.consume(viewState([result(id, "session-a", "completed")])).status, "completed");
});

test("one view channel's answer never strands another's", function () {
  var first = request.channel("session-a", function () {}, "legend", "view.invoke");
  var second = request.channel("session-a", function () {}, "table", "view.invoke");
  var a = first.run("ph_composer.colour_by.activate", { mode: null });
  var b = second.run("ph_composer.zones.faces.locate", { faces: [] });
  var held = viewState([result(b, "session-a", "completed"), result(a, "session-a", "refused")]);

  assert.strictEqual(second.consume(held).status, "completed");
  assert.strictEqual(first.consume(held).status, "refused", "the earlier request still settles");
  assert.strictEqual(first.busy(), false);
});

test("a channel refuses a message the panel does not carry", function () {
  assert.throws(function () { request.channel("session-a", function () {}, "x", "sketchup.invoke"); },
    /does not carry/);
});

test("file commands settle their own correlated result and consume no action slot", function () {
  var sent = [], channel = request.channel("session-a", function (type) { sent.push(type); }, "file",
    "file_export.invoke");
  var id = channel.run("example.write", {}), answer = result(id, "session-a", "cancelled");
  assert.deepStrictEqual(sent, ["file_export.invoke"]);
  assert.strictEqual(channel.consume(state(answer)), null);
  var held = {}; held[id] = answer;
  assert.strictEqual(channel.consume({ ui: { fileExportResults: held } }).status, "cancelled");
  assert.strictEqual(channel.busy(), false);
  assert.strictEqual(channel.consume({ ui: { fileExportResults: held } }), null);
});

test("read queries settle only their keyed query result and reset ignores a late answer", function () {
  var sent = [], channel = request.channel("session-a", function (type) { sent.push(type); }, "catalog",
    "query.invoke");
  var id = channel.run("example.catalog", {}), answer = result(id, "session-a", "completed");
  assert.deepStrictEqual(sent, ["query.invoke"]);
  assert.strictEqual(channel.consume(viewState([answer])), null);
  var held = {}; held[id] = answer;
  assert.strictEqual(channel.consume({ ui: { queryResults: held } }).status, "completed");
  channel.run("example.catalog", {}); channel.reset();
  assert.strictEqual(channel.consume({ ui: { queryResults: held } }), null);
});

/* REVIEW F04: a transport that drops the message left the channel busy forever with no recovery timer. */
test("an unanswered run warns once its recovery time passes and asks for its status without resending", function () {
  var timers = [], heard = [];
  var timed = { setTimeout: function (run, ms) { timers.push({ run: run, ms: ms }); return timers.length; },
    clearTimeout: function (id) { timers[id - 1] = null; } };
  timed.window = timed;
  var module = panelSource.start(timed, ["request"]).request;
  var stop = module.onUnconfirmed(function (channel) { heard.push(channel.pending); });
  var sent = [], channel = module.channel("session-a", function (type, payload) {
    sent.push({ type: type, payload: payload });
  }, "form");

  var id = channel.run("example.create", {});
  assert.strictEqual(timers.length, 1, "a recovery timer is registered");
  assert.strictEqual(timers[0].ms, module.RECOVERY_MS);
  timers[0].run();
  assert.deepStrictEqual(heard, [id]);
  assert.strictEqual(channel.unconfirmed, true);
  assert.strictEqual(channel.busy(), true, "still pending, so the edit is not sent twice");
  assert.strictEqual(channel.run("example.create", {}), false);

  assert.strictEqual(channel.checkStatus(), true);
  assert.deepStrictEqual(sent.map(function (one) { return one.type; }), ["action.invoke", "action.status"]);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(sent[1].payload)), { request_id: id, session: "session-a" });
  assert.strictEqual(timers.length, 2, "asking waits again");

  channel.consume(state(result(id, "session-a", "refused", "PH-Composer did not receive that change.")));
  assert.strictEqual(channel.busy(), false);
  assert.strictEqual(timers[1], null, "settling stops the timer");
  assert.strictEqual(channel.checkStatus(), false, "nothing left to ask about");
  stop();
});

test("only an action channel can ask the host for status", function () {
  var channel = request.channel("session-a", function () {}, "catalog", "query.invoke");
  channel.run("example.catalog", {});
  assert.strictEqual(channel.checkStatus(), false);
});

test("a transport that answers at once keeps the id it returns and arms no warning", function () {
  var timers = [], timed = { setTimeout: function () { timers.push(1); return timers.length; },
    clearTimeout: function () {} };
  timed.window = timed;
  var module = panelSource.start(timed, ["request"]).request, channel;
  channel = module.channel("session-a", function (type, payload) {
    channel.consume(state(result(payload.request_id, "session-a", "completed")));
  }, "form");

  var id = channel.run("example.create", {});
  assert.match(id, /^session-a:form:\d+$/);
  assert.strictEqual(channel.busy(), false);
  assert.strictEqual(timers.length, 0);
});
