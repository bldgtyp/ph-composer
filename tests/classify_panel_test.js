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

test("New attached zone waits for form submit, then creates and chooses it", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette(),
    [{ kind: "ph_composer.face_assignment.attached_zone", id: "atz_1", values: { name: "Garage" } }]) });
  var create = p.section().querySelectorAll("button").filter(function (node) {
    return node.textContent === "New attached zone";
  })[0];

  create.listeners.click({});

  assert.strictEqual(p.sent.length, 0, "opening the form writes nothing");
  var dialog = p.context.document.querySelector("dialog");
  dialog.querySelector("form").listeners.submit({ preventDefault: function () {} });

  assert.strictEqual(p.sent[0].type, "action.invoke", "a record is a Model change, unlike the palette");
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.face_assignment.attached_zone.save");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0].payload.params)),
    { values: { name: "Attached zone 1", kind: "other", temperature_reduction_factor: 0.95 } },
    "the first name nothing is called yet, so a delete does not make two records share one");

  p.panel.receive({ type: "action.result", payload: { request_id: p.sent[0].payload.request_id,
    session: "session-a", outcome: { status: "completed", value: { id: "atz_2" } } } });

  assert.strictEqual(p.context.document.querySelector("dialog"), null);
  assert.strictEqual(p.context.document.activeElement.textContent, "New attached zone");
  assert.strictEqual(p.context.document.activeElement.isConnected, true);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[1].payload.params)),
    { field: "attached_zone_id", value: "atz_2" });
});

test("Stop classifying appears only while the tool has the viewport", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette()) });

  assert.strictEqual(p.section().querySelectorAll("button").filter(function (node) {
    return node.textContent === "Stop classifying";
  }).length, 0, "nothing to stop, so no control for it");

  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette({ face_type: "Wall" }, true)) });
  var running = p.section().querySelectorAll("button")[0];
  assert.strictEqual(running.textContent, "Stop classifying");
  running.listeners.click({});

  assert.strictEqual(p.sent[0].payload.name, "ph_composer.face_assignment.stop_classifying");
});

function escape(p, handled) {
  var event = { key: "Escape", defaultPrevented: Boolean(handled),
    preventDefault: function () { this.defaultPrevented = true; } };
  p.context.document.listeners.keydown(event);
  return event;
}

test("panel Escape stops the active tool once through its public view command", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette({ face_type: "Wall" }, true)) });
  assert.strictEqual(escape(p).defaultPrevented, true);
  escape(p);
  assert.strictEqual(p.sent.length, 1, "a pending stop is not submitted twice");
  assert.strictEqual(p.sent[0].type, "view.invoke");
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.face_assignment.stop_classifying");
});

test("panel Escape respects an editor's consumed press and an inactive tool", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette({}, true)) });
  escape(p, true);
  assert.strictEqual(p.sent.length, 0);
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette({}, false)) });
  assert.strictEqual(escape(p).defaultPrevented, false);
  assert.strictEqual(p.sent.length, 0);
});

test("a modal gets Escape before Classify, then the next press stops the tool", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette({}, true)) });
  p.section().querySelectorAll("button").filter(function (node) {
    return node.textContent === "New attached zone";
  })[0].listeners.click({});
  var dialog = p.context.document.querySelector("dialog");
  assert.strictEqual(escape(p).defaultPrevented, false);
  assert.strictEqual(p.sent.length, 0);
  dialog.listeners.cancel({ preventDefault: function () {} });
  assert.strictEqual(p.context.document.querySelector("dialog"), null);
  escape(p);
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.face_assignment.stop_classifying");
});

test("Escape targets the currently displayed Model session", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette({}, true)) });
  var next = snapshot(palette({}, true));
  next.session = "session-b";
  p.panel.receive({ type: "panel.snapshot", payload: next });
  escape(p);
  assert.strictEqual(p.sent[0].payload.session, "session-b");
});

/* A snapshot arrives after every Face the user paints; the palette must not be rebuilt under them. */
test("an unchanged snapshot leaves the controls exactly where they were", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette()) });
  var before = chip(p, "Wall");

  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette()) });

  assert.strictEqual(chip(p, "Wall"), before, "the same control, not a replacement");

  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette({ face_type: "Wall" })) });
  assert.notStrictEqual(chip(p, "Wall"), before, "and repainted once the palette really changes");
});

function openNew(p) {
  p.panel.receive({ type: "panel.snapshot", payload: snapshot(palette()) });
  var trigger = p.section().querySelectorAll("button").filter(function (node) {
    return node.textContent === "New attached zone";
  })[0];
  trigger.listeners.click({});
  return { trigger: trigger, dialog: p.context.document.querySelector("dialog") };
}

test("Cancel and Escape discard the draft without changing the Model or palette", function () {
  ["button", "escape"].forEach(function (route) {
    var p = page(), opened = openNew(p);
    opened.dialog.querySelector("input").value = "Uncommitted garage";
    if (route === "escape") opened.dialog.listeners.cancel({ preventDefault: function () {} });
    else opened.dialog.querySelectorAll("button").filter(function (node) {
      return node.textContent === "Cancel";
    })[0].listeners.click({});
    assert.strictEqual(p.sent.length, 0);
    assert.strictEqual(p.context.document.querySelector("dialog"), null);
    assert.strictEqual(p.context.document.activeElement, opened.trigger);
  });
});

test("a refused create keeps the draft and can be corrected and resubmitted", function () {
  var p = page(), opened = openNew(p), form = opened.dialog.querySelector("form");
  var name = opened.dialog.querySelector("[aria-label='Name']");
  var factor = opened.dialog.querySelector("[aria-label='Temperature reduction factor']");
  name.value = "Garage";
  factor.value = "0.8";
  form.listeners.submit({ preventDefault: function () {} });
  opened.dialog.listeners.cancel({ preventDefault: function () {} });
  assert.strictEqual(p.context.document.querySelector("dialog"), opened.dialog, "pending cannot be cancelled");
  p.panel.receive({ type: "action.result", payload: { request_id: p.sent[0].payload.request_id,
    session: "session-a", outcome: { status: "refused", message: "Try again. Nothing was written." } } });
  assert.strictEqual(p.context.document.querySelector("dialog"), opened.dialog);
  assert.strictEqual(name.value, "Garage");
  assert.strictEqual(factor.value, "0.8");
  assert.strictEqual(p.sent.length, 1, "a refusal never chooses a record");
  form.listeners.submit({ preventDefault: function () {} });
  assert.strictEqual(p.sent.length, 2);
});

test("empty names and invalid factors keep the form open without a request", function () {
  var p = page(), opened = openNew(p), form = opened.dialog.querySelector("form");
  var name = opened.dialog.querySelector("[aria-label='Name']");
  var factor = opened.dialog.querySelector("[aria-label='Temperature reduction factor']");
  name.value = " ";
  form.listeners.submit({ preventDefault: function () {} });
  name.value = "Garage";
  ["", "-1", "1.1", "bad"].forEach(function (value) {
    factor.value = value;
    form.listeners.submit({ preventDefault: function () {} });
  });
  assert.strictEqual(p.sent.length, 0);
  assert.strictEqual(p.context.document.querySelector("dialog"), opened.dialog);
});

test("changing Model session discards an unsaved Attached zone draft", function () {
  var p = page(), opened = openNew(p), next = snapshot(palette());
  next.session = "session-b";
  p.panel.receive({ type: "panel.snapshot", payload: next });
  assert.strictEqual(p.context.document.querySelector("dialog"), null);
  assert.strictEqual(opened.dialog.isConnected, false);
  assert.strictEqual(p.sent.length, 0);
});
