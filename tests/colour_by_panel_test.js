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

function buttons(p) {
  return p.section().querySelectorAll("button");
}

function params(message) { return JSON.parse(JSON.stringify(message.payload.params)); }

function toggle(p, binding) {
  var made = new p.colourBy.HeaderToggle(binding);
  made.paint(p.panel.state);
  return made;
}

test("the legend strip is empty while Colour by is off and holds its slot in the control row", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(off()) });
  assert.strictEqual(p.section().children.length, 0);
  assert.strictEqual(p.section().parentNode.getAttribute("data-phc-region"), "tools");
  assert.strictEqual(p.context.document.querySelector("[data-phc-region='inspector']"), null, "no inspector legend");
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on()) });
  assert.strictEqual(p.section().querySelector(".phc-legend-title").textContent, "Side");
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

test("each chip carries its colour, label and count, and clicking one selects and zooms to it", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on()) });
  assert.strictEqual(p.section().querySelectorAll(".phc-legend-chip").length, 2);
  assert.strictEqual(p.section().querySelectorAll(".phc-legend-label")[0].textContent, "Inside");
  assert.strictEqual(p.section().querySelectorAll(".phc-legend-count")[0].textContent, "7");
  assert.strictEqual(p.section().querySelectorAll(".phc-legend-swatch")[0].style.background, "rgb(40,50,60)");
  p.section().querySelectorAll(".phc-legend-locate")[0].listeners.click({});
  assert.deepStrictEqual([p.sent[0].payload.name, params(p.sent[0])],
    ["ph_composer.colour_by.select_row", { row: { value: "inside", state: "classified" } }]);
});

test("the unclassified chip is a chip of the legend like any other", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on()) });
  p.section().querySelectorAll(".phc-legend-locate")[1].listeners.click({});
  assert.deepStrictEqual(params(p.sent[0]), { row: { value: null, state: "unclassified" } });
});

test("a chip's eye sets its colour apart, and the same control or Show all puts everything back", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on()) });
  var only = p.section().querySelectorAll(".phc-legend-only")[0];
  assert.strictEqual(only.getAttribute("aria-pressed"), "false");
  only.listeners.click({});
  assert.deepStrictEqual(params(p.sent[0]), { row: { value: "inside", state: "classified" } });
  p.panel.receive({ type: "view.result", payload: { request_id: p.sent[0].payload.request_id,
    session: "session-a", outcome: { status: "completed", value: {} } } });
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on({ value: "inside", state: "classified" })) });
  var pressed = p.section().querySelectorAll(".phc-legend-only")[0];
  assert.strictEqual(pressed.getAttribute("aria-pressed"), "true");
  p.section().querySelector(".phc-legend-show-all").listeners.click({});
  assert.deepStrictEqual(params(p.sent[1]), {}, "no row means show every colour again");
});

test("a request in flight leaves every legend control refusing until it settles", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on()) });
  p.section().querySelectorAll(".phc-legend-locate")[0].listeners.click({});
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on()) });
  assert.ok(buttons(p).every(function (node) { return node.disabled; }), "every control waits");
  assert.strictEqual(toggle(p, { mode: "outside.probe.by_side" }).node.querySelector("button").disabled, true);
  p.panel.receive({ type: "view.result", payload: { request_id: p.sent[0].payload.request_id,
    session: "session-a", outcome: { status: "completed", value: { selected: 7 } } } });
  assert.ok(buttons(p).every(function (node) { return !node.disabled; }), "and works again afterwards");
});
