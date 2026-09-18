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

test("ready asks for the first snapshot, which fills the Overview and the status bar", function () {
  var p = page();
  p.panel.ready();
  assert.deepStrictEqual(types(p.sent), ["panel.ready"]);

  p.receive("panel.snapshot", snapshot("session-a", 3, { edit_path: ["Level 1", ""] }));

  var overview = p.query("[data-section='overview']");
  assert.strictEqual(overview.querySelector("h1").textContent, "Overview");
  assert.strictEqual(overview.querySelector(".phc-heading-note").textContent, "house.skp");
  var footer = p.query("[data-section='footer']").children.map(function (node) { return node.textContent; });
  assert.deepStrictEqual(footer, ["PH-Composer 0.1.0-dev", "Editing: Level 1 / Unnamed group"]);
});

test("switching tabs is presentation only: panes toggle and nothing is sent", function () {
  var p = page();
  p.receive("panel.snapshot", snapshot("session-a", 1));
  p.query("[data-tab='export']").listeners.click({});

  assert.strictEqual(p.query("[data-pane='export']").hidden, false);
  assert.strictEqual(p.query("[data-pane='overview']").hidden, true);
  assert.strictEqual(p.query("[data-tab='export']").getAttribute("aria-pressed"), "true");
  assert.strictEqual(p.query("[data-section='export']").querySelector("h1").textContent, "Export");
  assert.deepStrictEqual(p.sent, []);
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
  assert.strictEqual(p.query("[data-section='overview']").querySelector(".phc-heading-note").textContent,
    "other.skp");
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
