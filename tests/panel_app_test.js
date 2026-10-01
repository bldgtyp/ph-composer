"use strict";

/* The panel page as one client: what it renders from a snapshot, what it sends, and what it refuses to
   paint. Each case builds a fresh page from the shipped index.html, so no state crosses cases. */

var assert = require("assert");
var test = require("node:test");
var dom = require("./support/dom_stub");
var panelSource = require("./support/panel_source");

function page() {
  var sent = [];
  var context = {
    document: dom.buildDocument(panelSource.markup("index.html")), Intl: Intl,
    innerWidth: 1280, innerHeight: 800, setTimeout: setTimeout, clearTimeout: clearTimeout,
    sketchup: { ph_composer_message: function (message) { sent.push(JSON.parse(message)); } }
  };
  context.window = context;
  dom.attachEvents(context);
  var modules = panelSource.start(context, ["sections/shell", "sections/export", "request"]);
  var panel = modules.panel;
  return {
    context: context, modules: modules, panel: panel, sent: sent,
    receive: function (type, payload) { panel.receive({ type: type, payload: payload }); },
    query: function (selector) { return context.document.querySelector(selector); },
    notice: function () { return context.document.querySelector(".phc-floating-notice"); }
  };
}

function snapshot(session, revision, extra) {
  return Object.assign({
    product: "PH-Composer", version: "0.1.0-dev", session: session, revision: revision, file_name: "house.skp",
    edit_path: [], sections: {},
    preferences: { unit_system: "SI", dimension_formats: {}, number_format: { decimal: ".", locale: "en-US" } }
  }, extra || {});
}

function types(sent) { return sent.map(function (message) { return message.type; }); }

test("query results stay keyed, reject another session and clear on Model switch", function () {
  var p = page(); p.receive("panel.snapshot", snapshot("session-a", 7));
  p.receive("query.result", { request_id: "q1", session: "session-a", outcome: { status: "completed", value: [] } });
  p.receive("query.result", { request_id: "q2", session: "session-b", outcome: { status: "completed" } });
  assert.strictEqual(p.panel.state.ui.queryResults.q1.request_id, "q1");
  assert.strictEqual(p.panel.state.ui.queryResults.q2, undefined);
  assert.strictEqual(p.panel.state.ui.actionResult, null);
  p.receive("panel.snapshot", snapshot("session-b", 1));
  assert.deepStrictEqual(Object.keys(p.panel.state.ui.queryResults), []);
});

test("ready asks for the first snapshot, which fills the status bar", function () {
  var p = page();
  p.panel.ready();
  assert.deepStrictEqual(types(p.sent), ["panel.ready"]);

  p.receive("panel.snapshot", snapshot("session-a", 3, { edit_path: ["Level 1", ""] }));

  var footer = p.query("[data-section='footer']").children.map(function (node) { return node.textContent; });
  assert.deepStrictEqual(footer, ["PH-Composer 0.1.0-dev", "Editing: Level 1 / Unnamed group"]);
});

test("opening Export reads preflight and retained tasks without starting a write", function () {
  var p = page();
  p.receive("panel.snapshot", snapshot("session-a", 1));
  p.query("[data-tab='export']").listeners.click({});

  assert.strictEqual(p.query("[data-pane='export']").hidden, false);
  assert.strictEqual(p.query("[data-pane='overview']").hidden, true);
  assert.strictEqual(p.query("[data-tab='export']").getAttribute("aria-pressed"), "true");
  assert.strictEqual(p.query("[data-section='export']").querySelector("h1").textContent, "Export");
  assert.deepStrictEqual(types(p.sent), ["export.preflight", "export.latest"]);
});

test("an action names the shown session and the revision the panel last rendered", function () {
  var p = page();
  p.receive("panel.snapshot", snapshot("session-a", 7));
  var channel = p.modules.request.channel("session-a", p.panel.send, "edit");
  var id = channel.run("example.foundation.update_parts", { edits: [] });

  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent)), [{ type: "action.invoke", payload: {
    request_id: id, session: "session-a", name: "example.foundation.update_parts", params: { edits: [] },
    expected_revision: 7 } }]);
});

test("a refusal stays on screen as a warning and a failure as an error, until dismissed", function () {
  var p = page();
  p.receive("panel.snapshot", snapshot("session-a", 7));
  p.receive("action.result", { request_id: "r1", session: "session-a", outcome: {
    status: "refused", code: "revision.stale", message: "The Model changed. Nothing was written." } });

  var notice = p.notice();
  assert.strictEqual(notice.hidden, false);
  assert.strictEqual(notice.message.textContent, "The Model changed. Nothing was written.");
  assert.strictEqual(notice.getAttribute("data-tone"), "warning");
  assert.strictEqual(notice.getAttribute("data-persistent"), "true");
  assert.strictEqual(p.panel.state.ui.actionResult.request_id, "r1", "the owning view can read the outcome");

  p.receive("action.result", { request_id: "r2", session: "session-a", outcome: {
    status: "failed", code: "operation.failed", message: "The change could not be completed." } });
  assert.strictEqual(notice.getAttribute("data-tone"), "error");
  notice.dismissButton.listeners.click({});
  assert.strictEqual(notice.hidden, true);
});

test("a view result settles in its own slot and says why the viewport did not change", function () {
  var p = page();
  p.receive("panel.snapshot", snapshot("session-a", 7));
  p.receive("view.result", { request_id: "v1", session: "session-a", outcome: {
    status: "completed", value: { found: 4, missing: 0 } } });

  assert.strictEqual(p.panel.state.ui.viewResults.v1.request_id, "v1");
  assert.strictEqual(p.panel.state.ui.actionResult, null, "a view command is not an edit");
  assert.strictEqual(p.notice().hidden, true, "a viewport change that worked says nothing");

  p.receive("view.result", { request_id: "v2", session: "session-a", outcome: {
    status: "refused", code: "validation.failed", message: "There is no Colour-by mode named that." } });
  assert.strictEqual(p.notice().message.textContent, "There is no Colour-by mode named that.");
  assert.strictEqual(p.notice().getAttribute("data-tone"), "warning");
});

test("a result or notice for another Model is not painted, and a new Model clears the old one's", function () {
  var p = page();
  p.receive("panel.snapshot", snapshot("session-a", 7));
  p.receive("action.result", { request_id: "r1", session: "session-b", outcome: { status: "refused", message: "x" } });
  p.receive("panel.notice", { session: "session-b", message: "Elsewhere.", tone: "warning" });
  assert.strictEqual(p.panel.state.ui.actionResult, null);
  assert.strictEqual(p.notice().hidden, true);

  p.receive("panel.notice", { session: "session-a", message: "Checked 4 parts.", tone: "info" });
  assert.strictEqual(p.notice().hidden, false);
  p.receive("panel.snapshot", snapshot("session-b", 1, { file_name: "other.skp" }));
  assert.strictEqual(p.notice().hidden, true, "the other Model's notice is gone");
  assert.strictEqual(p.panel.state.file_name, "other.skp");
});

test("the unit switch applies at once, is remembered by the host, and never becomes a Model action", function () {
  var p = page();
  p.receive("panel.snapshot", snapshot("session-a", 7));
  var seen = [];
  p.modules.unit_preferences.subscribe(function (profile) { seen.push(profile.unitSystem); });

  p.query("[data-unit-system='IP']").listeners.click({});

  assert.deepStrictEqual(seen, ["IP"]);
  assert.strictEqual(p.query("[data-unit-system='IP']").getAttribute("aria-pressed"), "true");
  assert.deepStrictEqual(types(p.sent), ["preferences.set"]);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0].payload)),
    { request_id: "preferences:1", key: "unit_system", value: "IP" });

  p.query("[data-unit-system='IP']").listeners.click({});
  assert.strictEqual(p.sent.length, 1, "choosing the current system sends nothing");
});

test("a refused preference restores the previous value and says why", function () {
  var p = page();
  p.receive("panel.snapshot", snapshot("session-a", 7));
  p.panel.setPreference("dimension_format", "cm", { scope: "example.editor", system: "SI" });
  assert.strictEqual(p.modules.unit_preferences.dimensionFormat("example.editor", "SI"), "cm", "applied at once");

  p.receive("preferences.result", { request_id: "preferences:1", status: "refused",
    message: "Too many dimension formats are remembered.",
    preferences: { unit_system: "SI", dimension_formats: {}, number_format: {} } });

  assert.strictEqual(p.modules.unit_preferences.dimensionFormat("example.editor", "SI"), "mm");
  assert.strictEqual(p.notice().message.textContent, "Too many dimension formats are remembered.");
  assert.strictEqual(p.notice().getAttribute("data-tone"), "error");
});

test("a section registered after start mounts itself in its pane and renders from the current state", function () {
  var p = page();
  var renders = [];
  p.receive("panel.snapshot", snapshot("session-a", 2));
  p.panel.section("example.editor", function (root, state) { renders.push([root.getAttribute("data-section"),
    state.revision]); });

  var root = p.query("[data-section='example.editor']");
  assert.strictEqual(root.parentNode, p.query("[data-pane='overview']"));
  assert.deepStrictEqual(renders, [["example.editor", 2]]);
  p.receive("panel.snapshot", snapshot("session-a", 3));
  assert.deepStrictEqual(renders[1], ["example.editor", 3]);
  assert.throws(function () { p.panel.section("x.y", function () {}, { pane: "nowhere" }); }, /names no pane/);
});

test("a host failure is shown as an error; an unknown message type changes nothing", function () {
  var p = page();
  p.receive("panel.snapshot", snapshot("session-a", 2));
  var before = p.panel.state;
  p.receive("not.a.type", {});
  assert.strictEqual(p.panel.state, before);
  p.receive("panel.failure", { message: "The panel message is not JSON." });
  assert.strictEqual(p.notice().getAttribute("data-tone"), "error");
});

test("a section that throws does not hide the refusal warning or stop the other sections", function () {
  var p = page(), later = [];
  p.receive("panel.snapshot", snapshot("session-a", 2));
  p.context.console = { error: function () {} };
  p.panel.section("broken.section", function () { throw new Error("render bug"); });
  p.panel.section("later.section", function (root, state) { later.push(state.revision); });
  p.receive("action.result", { request_id: "r1", session: "session-a", outcome: {
    status: "refused", code: "revision.stale", message: "The Model changed. Nothing was written." } });

  assert.strictEqual(p.notice().hidden, false);
  assert.strictEqual(p.notice().getAttribute("data-tone"), "warning");
  assert.deepStrictEqual(later, [2, 2]);
  assert.strictEqual(p.panel.state.ui.actionResult.request_id, "r1");
});

test("the current tab is scrolled into view, so a narrow panel never hides which tab is open", function () {
  var p = page(), scrolled = [];
  var tab = p.query("[data-tab='export']");
  tab.scrollIntoView = function (options) { scrolled.push(JSON.parse(JSON.stringify(options))); };
  p.receive("panel.snapshot", snapshot("session-a", 1));
  tab.listeners.click({});
  assert.deepStrictEqual(scrolled[scrolled.length - 1], { block: "nearest", inline: "nearest" });
});

function enterExport(p, findings) {
  p.panel.showTab("export");
  var requests = p.sent.slice(-2);
  p.receive("export.result", { request_id: requests[0].payload.request_id, session: "session-a",
    outcome: { status: "completed", value: { findings: findings || [], repairs: [] } } });
  p.receive("export.result", { request_id: requests[1].payload.request_id, session: "session-a",
    outcome: { status: "completed", value: null } });
  p.sent.length = 0;
}

test("Export asks for one destination and retains a cancellation message", function () {
  var p = page();
  p.receive("panel.snapshot", snapshot("session-a", 4));
  enterExport(p);
  var pane = function () { return p.query("[data-section='export']"); };
  var button = function () { return pane().querySelector("button"); };
  button().listeners.click({});
  button().listeners.click({});
  assert.strictEqual(p.sent.length, 1);
  assert.strictEqual(p.sent[0].type, "export.start");
  assert.deepStrictEqual(p.sent[0].payload.repairs, []);
  var id = p.sent[0].payload.request_id;
  assert.strictEqual(button().disabled, true);
  assert.strictEqual(button().textContent, "Choosing destination…");
  p.receive("export.result", { request_id: id, session: "session-b", outcome: { message: "Other Model." } });
  assert.strictEqual(button().disabled, true);
  p.receive("export.result", { request_id: id, session: "session-a",
    outcome: { status: "cancelled", code: "export.cancelled", message: "Export cancelled. Nothing was written." } });
  assert.strictEqual(button().disabled, false);
  assert.strictEqual(pane().querySelector(".phc-export-status").textContent, "Export cancelled. Nothing was written.");
});

test("blocking preflight disables destination selection and preserves its complete findings", function () {
  var p = page();
  p.receive("panel.snapshot", snapshot("session-a", 1));
  enterExport(p, [{ code: "construction.missing", message: "Assign an Assembly.", blocks_export: true }]);
  var pane = p.query("[data-section='export']");
  assert.strictEqual(pane.querySelector("button").disabled, true);
  assert.strictEqual(pane.querySelector("li").textContent, "Assign an Assembly.");
  pane.querySelector("button").listeners.click({});
  assert.deepStrictEqual(p.sent, []);
});

test("running Export remains visible until cancelled and a Model switch drops its handle", function () {
  var p = page();
  p.receive("panel.snapshot", snapshot("session-a", 1));
  enterExport(p);
  p.query("[data-section='export']").querySelector("button").listeners.click({});
  var start = p.sent[0].payload.request_id;
  p.receive("export.result", { request_id: start, session: "session-a", outcome: { status: "completed",
    value: { task_id: "task-a", stage: "reading", cancellable: true, outcome: null } } });
  p.panel.showTab("overview");
  assert.strictEqual(p.panel.state.ui.activeTab, "export");
  var buttons = p.query("[data-section='export']").querySelectorAll("button");
  buttons[1].listeners.click({});
  var cancellation = p.sent[p.sent.length - 1];
  assert.strictEqual(cancellation.type, "export.cancel");
  assert.strictEqual(cancellation.payload.task_id, "task-a");
  p.receive("export.result", { request_id: cancellation.payload.request_id, session: "session-a",
    outcome: { status: "completed", value: { task_id: "task-a", stage: "finished", cancellable: false,
      outcome: { status: "cancelled", message: "Cancelled.", findings: [] } } } });
  p.panel.showTab("overview");
  assert.strictEqual(p.panel.state.ui.activeTab, "overview");
  p.receive("panel.snapshot", snapshot("session-b", 1));
  assert.strictEqual(p.query("[data-section='export']").querySelector(".phc-export-status").textContent, "");
});
