"use strict";

/* Help & Diagnostics (html/support/page.js): what the window shows, a preview that is the text copied or
   saved, and confirmations that come before anything leaves the window or is removed. */

var assert = require("assert"), test = require("node:test");
var dom = require("./support/dom_stub"), source = require("./support/panel_source");

var STATE = {
  about: { version: "0.1.0-dev", build: "development", development: true, commit: null, manifest: "abc123def456",
    host: { sketchup: "26.1.188", platform: "macOS", ruby: "3.2.2", supported: true,
      supported_text: "SketchUp 2023 or later on macOS" },
    log: { writing: true, last_error: null } },
  problems: [{ time: "2026-10-19T14:02:00Z", label: "An edit or read could not be completed", incident: "PHC-3FA9C1" },
    { time: "2026-10-18T09:40:00Z", label: "The panel could not show part of a page", incident: "PHC-07B2D4" }],
  incident: "PHC-07B2D4", retention_days: 7,
  resettable: ["Display units (back to SI)", "Remembered table views"]
};
var REPORT = "PH-Composer support report\nReport format: 1\n--- log ---\n{\"event\":\"probe\"}\n";

function setup(options) {
  var settings = options || {};
  var page = { document: dom.buildDocument(""), Intl: Intl, innerWidth: 560, innerHeight: 640,
    setTimeout: setTimeout, clearTimeout: clearTimeout, navigator: {} };
  page.window = page; dom.attachEvents(page);
  page.document.execCommand = function () { return !settings.copyFails; };
  var modules = source.start(page, ["support/page"]), sent = [];
  var view = new modules["support/page"].Page(function (type, payload) {
    sent.push({ type: type, payload: payload });
  });
  view.receive({ type: "support.state", payload: Object.assign({}, STATE, settings.state || {}) });
  return { view: view, sent: sent, page: page };
}
function named(root, label) {
  return root.querySelectorAll("button").find(function (button) { return button.textContent === label; });
}
function click(node) { node.dispatchEvent({ type: "click" }); }
function sent(o) { return JSON.parse(JSON.stringify(o.sent)); }

test("it shows the build, the host, the log and the recent problems, marking the one asked about", function () {
  var o = setup();
  assert.strictEqual(o.view.identity.textContent, "PH-Composer 0.1.0-dev  ·  Development build");
  var rows = o.view.installation.children.map(function (row) { return row.children[1].textContent; });
  assert.deepStrictEqual(rows, ["Supported", "Writing"]);
  var items = o.view.problems.querySelectorAll("li");
  assert.strictEqual(items.length, 2);
  assert.ok(items[1].classList.contains("is-selected"));
  assert.ok(!items[0].classList.contains("is-selected"));
});

test("an unsupported host and a log that is not writing read as warnings, never as passed", function () {
  var o = setup({ state: { about: Object.assign({}, STATE.about, {
    host: Object.assign({}, STATE.about.host, { sketchup: "22.0.354", supported: false }),
    log: { writing: false, last_error: "Errno::EACCES" } }), problems: [] } });
  var values = o.view.installation.children.map(function (row) { return row.children[1]; });
  assert.strictEqual(values[0].textContent, "Not supported (SketchUp 2023 or later on macOS)");
  assert.strictEqual(values[0].getAttribute("data-tone"), "warning");
  assert.match(values[1].textContent, /^Not writing/);
  assert.strictEqual(o.view.problems.children[0].textContent, "No problems were recorded in the last 7 days.");
});

test("Copy diagnostics previews the capture and copies exactly what it shows", function () {
  var o = setup();
  click(o.view.copy);
  assert.deepStrictEqual(sent(o), [{ type: "support.capture", payload: { purpose: "copy" } }]);

  o.view.receive({ type: "support.capture", payload: { capture_id: "c1", captured_at: "2026-10-19T14:05:00Z",
    text: REPORT, purpose: "copy" } });
  assert.strictEqual(o.view.preview.hidden, false);
  assert.strictEqual(o.view.previewText.value, REPORT, "the preview is the capture, byte for byte");
  assert.strictEqual(o.view.previewPrimary.textContent, "Copy");

  click(o.view.previewPrimary);
  assert.strictEqual(o.view.preview.hidden, true);
  assert.strictEqual(sent(o).length, 1, "copying sends nothing to the host");
});

test("a copy that fails keeps the preview and offers Save, which saves that same capture", function () {
  var o = setup({ copyFails: true });
  click(o.view.copy);
  o.view.receive({ type: "support.capture", payload: { capture_id: "c2", captured_at: "2026-10-19T14:05:00Z",
    text: REPORT, purpose: "copy" } });

  click(o.view.previewPrimary);
  assert.strictEqual(o.view.preview.hidden, false);
  assert.match(o.view.previewStatus.textContent, /Save the report instead/);
  assert.strictEqual(o.view.previewPrimary.textContent, "Save…");
  click(o.view.previewPrimary);
  assert.deepStrictEqual(sent(o).pop(), { type: "support.save", payload: { capture_id: "c2" } });

  o.view.receive({ type: "support.result", payload: { action: "support.save", status: "failed",
    message: "The support report could not be saved there. Choose another location." } });
  assert.strictEqual(o.view.preview.hidden, false, "a failed save leaves the preview to try again");
  assert.match(o.view.previewStatus.textContent, /Choose another location/);
});

test("Refresh captures again rather than copying an older capture", function () {
  var o = setup();
  click(o.view.save);
  o.view.receive({ type: "support.capture", payload: { capture_id: "c3", captured_at: "2026-10-19T14:05:00Z",
    text: REPORT, purpose: "save" } });
  click(named(o.view.preview, "Refresh"));
  assert.deepStrictEqual(sent(o).pop(), { type: "support.capture", payload: { purpose: "save" } });
});

test("Report a problem says the issue is public before it opens anything", function () {
  var o = setup();
  click(named(o.view.root, "Report a problem…"));
  assert.strictEqual(sent(o).length, 0);
  assert.strictEqual(o.view.confirmDialog.hidden, false);
  assert.match(o.view.confirmBody.children[0].textContent, /public GitHub issue/);

  click(o.view.confirmAction);
  assert.deepStrictEqual(sent(o), [{ type: "support.report_problem", payload: {} }]);
});

test("reset lists what it resets, clearing history is destructive, and Cancel sends nothing", function () {
  var o = setup();
  o.view.confirmReset();
  var list = o.view.confirmBody.querySelectorAll("li").map(function (item) { return item.textContent; });
  assert.deepStrictEqual(list, STATE.resettable);
  click(o.view.confirmCancel);
  assert.strictEqual(sent(o).length, 0);

  o.view.confirmClear();
  assert.ok(/phc-action-delete/.test(o.view.confirmAction.className));
  click(o.view.confirmAction);
  assert.deepStrictEqual(sent(o), [{ type: "support.clear_history", payload: {} }]);
});
