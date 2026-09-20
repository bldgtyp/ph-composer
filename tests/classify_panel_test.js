"use strict";

/* The Classify tool's palette in the panel: the chips, what they send, the Attached zone picker and
   its inline New route, and the control that gives the viewport back. */

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
  var modules = panelSource.start(context, ["sections/classify"]);
  return { context: context, panel: modules.panel, sent: sent,
    section: function () { return context.document.querySelector("[data-section='ph_composer.classify']"); } };
}

function snapshot(tool, records) {
  return {
    product: "PH-Composer", version: "0.1.0-dev", session: "session-a", revision: 4,
    file_name: "house.skp", edit_path: [], preferences: {
      unit_system: "SI", dimension_formats: {}, number_format: { decimal: ".", locale: "en-US" }
    },
    sections: {
      "ph_composer.face_assignment.palette": { status: "completed", value: tool },
      "ph_composer.face_assignment.attached_zone.list": { status: "completed",
        value: { records: records || [] } }
    }
  };
}

function palette(chosen, active) {
  return { active: Boolean(active), palette: chosen || {},
    face_types: ["Wall", "RoofCeiling", "Floor"],
    boundary_conditions: ["Outdoors", "Ground", "Adiabatic", "AttachedZone", "Surface"] };
}

function chips(p) {
  return p.section().querySelectorAll(".phc-chip");
}

function chip(p, label) {
  return chips(p).filter(function (node) { return node.getAttribute("aria-label") === label; })[0];
}

test("the chips show the glossary words, not the stored ones", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette()) });

  assert.deepStrictEqual(chips(p).slice(0, 3).map(function (node) { return node.textContent; }),
    ["Wall", "Roof or ceiling", "Floor"]);
  assert.strictEqual(chip(p, "To neighbour").textContent, "To neighbour");
});

test("choosing a chip sets one field and gives the tool the viewport", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette()) });

  chip(p, "Roof or ceiling").listeners.click({});

  assert.strictEqual(p.sent[0].type, "view.invoke");
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.face_assignment.choose");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0].payload.params)),
    { field: "face_type", value: "RoofCeiling" });
});

test("pressing the chosen chip again goes back to keeping what each Face has", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette({ face_type: "Wall" })) });
  var wall = chip(p, "Wall");

  assert.strictEqual(wall.getAttribute("aria-pressed"), "true");
  wall.listeners.click({});

  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0].payload.params)),
    { field: "face_type", value: null });
});

test("Surface is shown and refused, with the reason on the control", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette()) });
  var surface = chip(p, "Surface, set by Solve adjacencies");

  assert.strictEqual(surface.textContent, "Surface · set by Solve adjacencies");
  assert.strictEqual(surface.disabled, true);
  assert.strictEqual(chip(p, "Attached zone, choose a record below").disabled, true,
    "an Attached zone is chosen by its record, not by its chip");
});

test("the picker lists the Attached zones and choosing one names it", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette(),
    [{ kind: "ph_composer.face_assignment.attached_zone", id: "atz_1", values: { name: "Garage" } }]) });
  var picker = p.section().querySelector("select");

  assert.deepStrictEqual(picker.children.map(function (node) { return node.textContent; }),
    ["None", "Garage"]);
  picker.value = "atz_1";
  picker.listeners.change({});

  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0].payload.params)),
    { field: "attached_zone_id", value: "atz_1" });
});

test("New attached zone creates one under a free name and chooses it", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette(),
    [{ kind: "ph_composer.face_assignment.attached_zone", id: "atz_1", values: { name: "Garage" } }]) });
  var create = p.section().querySelectorAll("button").filter(function (node) {
    return node.textContent === "New attached zone";
  })[0];

  create.listeners.click({});

  assert.strictEqual(p.sent[0].type, "action.invoke", "a record is a Model change, unlike the palette");
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.face_assignment.attached_zone.save");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0].payload.params)),
    { values: { name: "Attached zone 2", kind: "other" } });

  p.panel.receive({ type: "action.result", payload: { request_id: p.sent[0].payload.request_id,
    session: "session-a", outcome: { status: "completed", value: { id: "atz_2" } } } });

  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[1].payload.params)),
    { field: "attached_zone_id", value: "atz_2" });
});

test("Stop classifying is offered only while the tool has the viewport", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette()) });
  var idle = p.section().querySelectorAll("button")[0];

  assert.strictEqual(idle.textContent, "Not classifying");
  assert.strictEqual(idle.disabled, true);

  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette({ face_type: "Wall" }, true)) });
  var running = p.section().querySelectorAll("button")[0];
  assert.strictEqual(running.textContent, "Stop classifying");
  running.listeners.click({});

  assert.strictEqual(p.sent[0].payload.name, "ph_composer.face_assignment.stop_classifying");
});
