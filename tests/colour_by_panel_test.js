"use strict";

/* The panel's Colour-by legend: the mode control, the rows it paints from whatever the service
   reports, and the two commands a row can send. It names no mode, so this fixture invents one. */

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
  return { context: context, panel: modules.panel, sent: sent,
    section: function () { return context.document.querySelector("[data-section='ph_composer.colour_by']"); },
    mode: function () { return context.document.querySelector("[data-section='ph_composer.colour_by.mode']"); } };
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

var MODES = [{ name: "outside.probe.by_side", label: "Side", entity_kind: "side" }];

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

test("with Colour by off the mode control offers every registered mode and the inspector shows no legend", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(off()) });
  var control = p.mode().querySelector("select");

  assert.deepStrictEqual(control.children.map(function (node) { return node.textContent; }), ["Off", "Side"]);
  assert.strictEqual(control.value, "");
  assert.strictEqual(p.section().hidden, true, "no mode, no legend");
  assert.strictEqual(p.section().parentNode.hidden, true, "and an inspector with nothing to show is away");
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on()) });
  assert.deepStrictEqual([p.section().hidden, p.section().parentNode.hidden], [false, false]);
  assert.strictEqual(p.mode().parentNode.getAttribute("data-phc-region"), "tools");
});

test("choosing a mode sends the viewport command and never an action", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(off()) });
  var control = p.mode().querySelector("select");

  control.value = "outside.probe.by_side";
  control.listeners.change({});

  assert.strictEqual(p.sent[0].type, "view.invoke");
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.colour_by.activate");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0].payload.params)),
    { mode: "outside.probe.by_side" });
});

test("Off turns Colour by off rather than naming a mode", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on()) });
  var control = p.mode().querySelector("select");

  assert.strictEqual(control.value, "outside.probe.by_side");
  control.value = "";
  control.listeners.change({});

  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0].payload.params)), { mode: null });
});

test("each row carries its colour, label and count, and clicking one selects and zooms to it", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on()) });
  var rows = p.section().querySelectorAll(".phc-legend-row");

  assert.strictEqual(rows.length, 2);
  assert.strictEqual(p.section().querySelectorAll(".phc-legend-label")[0].textContent, "Inside");
  assert.strictEqual(p.section().querySelectorAll(".phc-legend-count")[0].textContent, "7");
  assert.strictEqual(p.section().querySelectorAll(".phc-legend-swatch")[0].style.background, "rgb(40,50,60)");

  p.section().querySelectorAll(".phc-legend-locate")[0].listeners.click({});

  assert.strictEqual(p.sent[0].payload.name, "ph_composer.colour_by.select_row");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0].payload.params)),
    { row: { value: "inside", state: "classified" } });
});

test("the unclassified row is a row of the legend like any other", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on()) });

  p.section().querySelectorAll(".phc-legend-locate")[1].listeners.click({});

  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0].payload.params)),
    { row: { value: null, state: "unclassified" } });
});

test("Show only this sets a row apart, and the same control puts everything back", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on()) });
  var only = p.section().querySelectorAll(".phc-legend-only")[0];

  assert.strictEqual(only.textContent, "Show only this");
  assert.strictEqual(only.getAttribute("aria-pressed"), "false");
  only.listeners.click({});
  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0].payload.params)),
    { row: { value: "inside", state: "classified" } });

  p.panel.receive({ type: "view.result", payload: { request_id: p.sent[0].payload.request_id,
    session: "session-a", outcome: { status: "completed", value: {} } } });
  p.panel.receive({ type: "panel.snapshot",
    payload: snapshot(on({ value: "inside", state: "classified" })) });
  var pressed = p.section().querySelectorAll(".phc-legend-only")[0];
  assert.strictEqual(pressed.textContent, "Show all");
  assert.strictEqual(pressed.getAttribute("aria-pressed"), "true");

  pressed.listeners.click({});
  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[1].payload.params)), {},
    "no row means show every row again");
});

test("a request in flight leaves every legend control refusing until it settles", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on()) });
  p.section().querySelectorAll(".phc-legend-locate")[0].listeners.click({});
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(on()) });

  assert.ok(buttons(p).every(function (node) { return node.disabled; }), "every control waits");
  assert.strictEqual(p.mode().querySelector("select").disabled, true);

  p.panel.receive({ type: "view.result", payload: { request_id: p.sent[0].payload.request_id,
    session: "session-a", outcome: { status: "completed", value: { selected: 7 } } } });

  assert.ok(buttons(p).every(function (node) { return !node.disabled; }), "and works again afterwards");
});
