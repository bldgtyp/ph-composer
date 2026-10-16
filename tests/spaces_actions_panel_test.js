"use strict";

/* The Spaces view's row actions, finding markers, open row and weighting factor filter. */

var assert = require("assert");
var test = require("node:test");
var dom = require("./support/dom_stub");
var panelSource = require("./support/panel_source");
var fixture = require("./support/spaces_fixture");

function page() {
  var sent = [];
  var context = {
    document: dom.buildDocument(panelSource.markup("index.html")), Intl: Intl,
    innerWidth: 1280, innerHeight: 800, setTimeout: setTimeout, clearTimeout: clearTimeout,
    sketchup: { ph_composer_message: function (message) { sent.push(JSON.parse(message)); } }
  };
  context.window = context;
  dom.attachEvents(context);
  var modules = panelSource.start(context, ["sections/shell", "features/zones/overview", "features/zones/faces_view",
    "features/spaces/view"]);
  var p = { context: context, panel: modules.panel, modules: modules, sent: sent };
  p.section = function () { return context.document.querySelector("[data-section='ph_composer.overview']"); };
  p.receive = function (state) { p.panel.receive({ type: "panel.snapshot", payload: state }); };
  p.action = function (label) {
    return p.section().querySelectorAll("[data-row-action]").filter(function (node) {
      return node.getAttribute("aria-label") === label;
    })[0];
  };
  p.click = function (node) { node.listeners.click({ preventDefault: function () {} }); };
  p.result = function (message, outcome) {
    p.panel.receive({ type: message.type === "view.invoke" ? "view.result" : "action.result",
      payload: { request_id: message.payload.request_id, session: "session-a", outcome: outcome } });
  };
  return p;
}

function snapshot(change, editPath) {
  var state = {
    product: "PH-Composer", version: "0.1.0-dev", session: "session-a", revision: 4, file_name: "house.skp",
    edit_path: editPath || [], preferences: { unit_system: "SI", dimension_formats: {}, number_format: {
      decimal: ".", locale: "en-US" }, table_views: { "ph_composer.zones": "ph_composer.spaces" } },
    sections: {
      "ph_composer.zones.overview": { status: "completed", value: { zones: fixture.zones(), make_zone: null,
        units: {} } },
      "ph_composer.spaces.spaces": { status: "completed", value: fixture.section() }
    }
  };
  if (change) change(state.sections["ph_composer.spaces.spaces"].value);
  return state;
}

function expandAll(p) {
  p.section().querySelectorAll("button").filter(function (node) { return node.textContent === "Expand all"; })[0]
    .listeners.click({ preventDefault: function () {} });
}

function last(p) { return p.sent[p.sent.length - 1]; }

test("Locate selects and frames one row through the view command, with the issuing session", function () {
  var p = page();
  p.receive(snapshot());
  p.click(p.action("Locate Living"));
  var message = last(p);
  assert.strictEqual(message.type, "view.invoke");
  assert.strictEqual(message.payload.name, "ph_composer.spaces.locate");
  assert.strictEqual(message.payload.session, "session-a");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(message.payload.params)),
    { reference: { space_id: "spc_101", entity_path: [100, 101] } });
});

test("the open row follows the snapshot's edit path, offering Close where it is open", function () {
  var p = page();
  p.receive(snapshot(null, [100, 101]));
  var living = p.section().querySelectorAll("[data-row-key]").filter(function (node) {
    return node.getAttribute("data-row-key") === JSON.stringify(["Space", [100, 101]]);
  })[0];
  assert.ok(living.classList.contains("host-selected"));
  assert.ok(p.action("Close Living"));
  assert.ok(p.action("Open Bath"));
  p.click(p.action("Close Living"));
  assert.strictEqual(last(p).payload.name, "ph_composer.spaces.context.close");
});

test("Enter unprotects a protected Volume, then opens it once that has completed", function () {
  var p = page();
  p.receive(snapshot());
  expandAll(p);
  p.click(p.section().querySelectorAll("[data-row-action]").filter(function (node) {
    return node.getAttribute("aria-label") === "Enter Volume 1";
  })[0]);
  var unprotect = last(p);
  assert.strictEqual(unprotect.payload.name, "ph_composer.spaces.volumes.unprotect");
  assert.strictEqual(unprotect.payload.expected_revision, 4, "a stale row refuses on the host");
  p.result(unprotect, { status: "completed", effect: "committed", value: { volume_id: "svl_100_101_1" } });
  p.receive(snapshot());
  var open = last(p);
  assert.strictEqual(open.payload.name, "ph_composer.spaces.context.open");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(open.payload.params)),
    { reference: { volume_id: "svl_100_101_1", entity_path: [100, 101, 1] } });
});

test("Delete confirms in the shared dialog, naming what goes, and Cancel sends nothing", function () {
  var p = page();
  p.receive(snapshot());
  p.click(p.action("Delete Bath"));
  var dialog = p.context.document.querySelector("dialog");
  assert.match(dialog.querySelector("h2").textContent, /Delete Bath/);
  p.click(dialog.querySelectorAll("button").filter(function (node) { return node.textContent === "Cancel"; })[0]);
  assert.strictEqual(p.sent.length, 0);
  p.click(p.action("Delete Bath"));
  p.click(dialog.querySelectorAll("button").filter(function (node) { return node.textContent === "Delete"; })[0]);
  assert.strictEqual(last(p).payload.name, "ph_composer.spaces.delete");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(last(p).payload.params)),
    { space: { space_id: "spc_102", entity_path: [100, 102] } });
});

test("Move to Zone offers the other Zones and sends the chosen one", function () {
  var p = page();
  p.receive(snapshot());
  p.click(p.action("Move Living to another Zone"));
  var dialog = p.context.document.querySelector("dialog");
  var select = dialog.querySelector("select");
  assert.deepStrictEqual(select.querySelectorAll("option").map(function (node) { return node.textContent; }),
    ["Zone B"]);
  p.click(dialog.querySelectorAll("button").filter(function (node) { return node.textContent === "Move"; })[0]);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(last(p).payload.params)), {
    space: { space_id: "spc_101", entity_path: [100, 101] }, zone: { zone_id: "zon_b", zone_path: [200] } });
});

test("a finding's repair is the row's action; a refusal says why", function () {
  var p = page();
  p.receive(snapshot(function (section) {
    section.spaces[0].volumes[0].moved = true;
    section.spaces[0].volumes[0].findings = [{ code: "space.volume_moved", blocks_export: false,
      message: "Volume 1 moved inside its Space. Restore its position.", repair: "restore_position" }];
  }));
  expandAll(p);
  p.click(p.section().querySelectorAll("[data-row-action]").filter(function (node) {
    return node.getAttribute("aria-label") === "Restore the position of Volume 1";
  })[0]);
  var restore = last(p);
  assert.strictEqual(restore.payload.name, "ph_composer.spaces.volumes.restore_position");
  p.result(restore, { status: "refused", code: "target.changed", effect: "none",
    message: "The Volume changed after it was read. Nothing was written." });
  assert.match(p.panel.state.ui.notice.message, /Nothing was written/);
});

test("a row's findings are its marker, those that block export named first", function () {
  var p = page();
  p.receive(snapshot(function (section) {
    section.spaces[1].volumes[0].findings = [
      { code: "space.volume_unprotected", blocks_export: false, message: "Volume 1 is not protected." },
      { code: "space.height_missing", blocks_export: true, message: "Volume 1 needs a height." }];
  }));
  expandAll(p);
  var markers = p.section().querySelectorAll(".phc-row-marker").filter(function (node) { return !node.hidden; })
    .map(function (node) { return node.getAttribute("aria-label"); });
  assert.ok(markers.indexOf("Blocks export. Volume 1 needs a height. Volume 1 is not protected.") >= 0, markers);
});

test("the weighting factor column filters by band and its toggle colours the Model by it", function () {
  var p = page(), state = snapshot();
  state.sections["ph_composer.colour_by.legend"] = { status: "completed", value: { mode: null, rows: [], modes: [
    { name: "ph_composer.spaces.by_weighting_factor", label: "Weighting factor", group: null }] } };
  p.receive(state);
  expandAll(p);
  assert.ok(p.section().querySelectorAll("button").some(function (node) {
    return node.getAttribute("aria-label") === "Colour by Weighting factor";
  }), "the column header carries the mode's toggle");
  var menu = p.section().querySelectorAll("button").filter(function (node) {
    return node.getAttribute("aria-label") === "Weighting factor column menu";
  })[0];
  p.click(menu);
  var boxes = menu.parentNode.querySelectorAll("input").filter(function (node) { return node.type === "checkbox"; });
  assert.deepStrictEqual(boxes.map(function (box) { return box.parentNode.children[1].textContent; }),
    ["0.00", "1.00"]);
  boxes[1].checked = false; boxes[1].listeners.change({});
  var shown = p.section().querySelectorAll("[data-row-key]").filter(function (node) { return !node.hidden; })
    .map(function (node) { return JSON.parse(node.getAttribute("data-row-key"))[0]; });
  assert.deepStrictEqual(shown, ["Zone", "Space", "Volume", "Segment"], "Zone A's Hall, Volume 2 and its Segment");
  var filter = p.sent.filter(function (message) { return message.payload.name === "ph_composer.colour_by.filter"; });
  assert.deepStrictEqual(JSON.parse(JSON.stringify(filter[filter.length - 1].payload.params)),
    { paths: [[100, 103, 2, 1]] });
});
