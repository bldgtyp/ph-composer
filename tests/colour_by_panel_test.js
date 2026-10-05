"use strict";

/* The panel's Colour by: the header toggle a column binds to a mode or a group, the legend strip in the
   control row, and the commands they send. It names no mode, so this fixture invents them. */

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
  var modules = panelSource.start(context, ["sections/colour_by"]);
  return { context: context, panel: modules.panel, sent: sent, colourBy: modules["sections/colour_by"],
    section: function () { return context.document.querySelector("[data-section='ph_composer.colour_by']"); } };
}

function snapshot(legend) {
  return {
    product: "PH-Composer", version: "0.1.0-dev", session: "session-a", revision: 4,
    file_name: "house.skp", edit_path: [], preferences: {
      unit_system: "SI", dimension_formats: {}, number_format: { decimal: ".", locale: "en-US" }
    },
    sections: { "ph_composer.colour_by.legend": { status: "completed", value: legend } }
  };
}

var MODES = [{ name: "outside.probe.by_side", label: "Side", entity_kind: "side", group: null },
  { name: "outside.probe.by_kind", label: "Kind", entity_kind: "side", group: "probe" },
  { name: "outside.probe.by_make", label: "Make", entity_kind: "side", group: "probe" }];

function off() {
  return { mode: null, label: null, entity_kind: null, isolated: null, rows: [], modes: MODES };
}

function on(isolated) {
  return { mode: "outside.probe.by_side", label: "Side", entity_kind: "side", isolated: isolated || null,
    modes: MODES, rows: [
      { value: "inside", label: "Inside", colour: [40, 50, 60], count: 7, state: "classified",
        isolated: Boolean(isolated) },
      { value: null, label: "Unclassified", colour: [130, 130, 130], count: 2, state: "unclassified",
        isolated: false }
    ] };
}

function params(message) { return JSON.parse(JSON.stringify(message.payload.params)); }

function toggle(p, binding) {
  var made = new p.colourBy.HeaderToggle(binding);
  made.paint(p.panel.state);
  return made;
}

test("Colour by has no legend strip in either mode", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(off()) });
  assert.strictEqual(p.section(), null);
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on()) });
  assert.strictEqual(p.context.document.querySelector(".phc-legend-strip"), null);
});

test("a column's toggle turns its mode on, and pressing it while pressed turns Colour by off", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(off()) });
  var side = toggle(p, { mode: "outside.probe.by_side" }), button = side.node.querySelector("button");
  assert.deepStrictEqual([button.getAttribute("aria-label"), button.getAttribute("aria-pressed")],
    ["Colour by Side", "false"]);
  button.listeners.click({});
  assert.strictEqual(p.sent[0].type, "view.invoke");
  assert.deepStrictEqual([p.sent[0].payload.name, params(p.sent[0])],
    ["ph_composer.colour_by.activate", { mode: "outside.probe.by_side" }]);
  p.panel.receive({ type: "view.result", payload: { request_id: p.sent[0].payload.request_id,
    session: "session-a", outcome: { status: "completed", value: {} } } });
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on()) });
  side.paint(p.panel.state);
  assert.strictEqual(side.pressed, true);
  assert.strictEqual(side.node.querySelector("button"), button, "repainted in place, so a press keeps its focus");
  button.listeners.click({});
  assert.deepStrictEqual(params(p.sent[1]), { mode: null });
  assert.strictEqual(toggle(p, { mode: "outside.probe.missing" }).paint(p.panel.state), false,
    "a column whose mode is not registered offers nothing");
});

test("a group's toggle offers its modes in a menu, pressed while either is on", function () {
  var p = page(), legend = off();
  legend.mode = "outside.probe.by_make";
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(legend) });
  var group = toggle(p, { group: "probe" }), button = group.node.querySelector("button");
  assert.strictEqual(group.pressed, true);
  assert.strictEqual(button.getAttribute("aria-label"), "Colour by Make");
  button.listeners.click({});
  var items = group.node.querySelectorAll(".phc-action-menu-item");
  assert.deepStrictEqual(items.map(function (node) { return [node.textContent, node.getAttribute("aria-pressed")]; }),
    [["Kind", "false"], ["Make", "true"], ["Off", null]]);
  items[0].listeners.click({});
  assert.deepStrictEqual(params(p.sent[0]), { mode: "outside.probe.by_kind" });
});

test("the active column's Show choices receive their colour key", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on()) });
  assert.deepStrictEqual(p.colourBy.colour(p.panel.state, { mode: "outside.probe.by_side" }, "inside"), [40, 50, 60]);
  assert.deepStrictEqual(p.colourBy.colour(p.panel.state, { mode: "outside.probe.by_side" }, ""), [130, 130, 130]);
  assert.strictEqual(p.colourBy.colour(p.panel.state, { group: "probe" }, "inside"), null);
  assert.strictEqual(p.colourBy.colour(p.panel.state, null, "inside"), null);
  assert.strictEqual(p.colourBy.colour(p.panel.state, { mode: "outside.probe.by_side" }, "missing"), null);
  var mixed = on(); mixed.rows.push({ value: null, colour: [240, 180, 60], state: "incomplete" });
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(mixed) });
  assert.strictEqual(p.colourBy.colour(p.panel.state, { mode: "outside.probe.by_side" }, ""), null,
    "a value with several state colours cannot be represented by a single swatch");
});

test("viewport scopes coalesce without interfering with mode requests, and clear with null", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(off()) });
  p.colourBy.filter(p.panel.state, null);
  assert.strictEqual(p.sent.length, 0);
  p.colourBy.filter(p.panel.state, [[1, 2]]);
  p.colourBy.filter(p.panel.state, []);
  assert.strictEqual(p.sent.length, 1);
  assert.deepStrictEqual(params(p.sent[0]), { paths: [[1, 2]] });
  p.colourBy.activate(p.panel.state, "outside.probe.by_side");
  assert.strictEqual(p.sent.length, 2, "mode changes have an independent channel");
  p.panel.receive({ type: "view.result", payload: { request_id: p.sent[0].payload.request_id,
    session: "session-a", outcome: { status: "completed" } } });
  p.colourBy.filter(p.panel.state, []);
  assert.deepStrictEqual(params(p.sent[2]), { paths: [] });
  p.panel.receive({ type: "view.result", payload: { request_id: p.sent[2].payload.request_id,
    session: "session-a", outcome: { status: "completed" } } });
  p.colourBy.filter(p.panel.state, null);
  assert.deepStrictEqual(params(p.sent[3]), { paths: null });
});

test("a refused viewport scope reports once and a new Model does not inherit it", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(off()) });
  p.colourBy.filter(p.panel.state, []);
  p.panel.receive({ type: "view.result", payload: { request_id: p.sent[0].payload.request_id,
    session: "session-a", outcome: { status: "refused", message: "Unavailable" } } });
  p.colourBy.filter(p.panel.state, []);
  p.colourBy.filter(p.panel.state, []);
  assert.strictEqual(p.sent.length, 1, "no refusal loop on repaint");
  var next = snapshot(off()); next.session = "session-b";
  p.panel.receive({ type: "panel.snapshot", payload: next });
  p.colourBy.filter(p.panel.state, null);
  assert.strictEqual(p.sent.length, 1, "the new Model starts unfiltered");
  p.colourBy.filter(p.panel.state, [[5]]);
  assert.strictEqual(p.sent[1].payload.session, "session-b");
});
