"use strict";

/* Column-scoped paint choices use the public viewport commands and preserve Attached zone drafts. */
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
  context.window = context; dom.attachEvents(context);
  var modules = panelSource.start(context, ["features/zones/classify"]);
  var classify = modules["features/zones/classify"];
  modules.panel.section("test.paint", function (root, state, send) { classify.refresh(state, send); });
  return { context: context, panel: modules.panel, sent: sent, classify: classify,
    section: function () { return this.menu && !this.menu.hidden ? this.menu : undefined; } };
}

function snapshot(tool, records) {
  return { product: "PH-Composer", version: "0.1.0-dev", session: "session-a", revision: 4,
    file_name: "house.skp", edit_path: [], preferences: {
      unit_system: "SI", dimension_formats: {}, number_format: { decimal: ".", locale: "en-US" }
    }, sections: {
      "ph_composer.zones.faces.palette": { status: "completed", value: tool },
      "ph_composer.zones.faces.attached_zone.list": { status: "completed", value: { records: records || [] } },
      "ph_composer.zones.faces.assemblies": { status: "completed", value: { assemblies: [
        { id: "asy_wall", name: "Wall assembly", type: "Wall" },
        { id: "asy_roof", name: "Roof assembly", type: "RoofCeiling" }
      ] } }
    } };
}
function palette(chosen, active) {
  return { active: Boolean(active), palette: chosen || {}, face_types: ["Wall", "RoofCeiling", "Floor"],
    boundary_conditions: ["Outdoors", "Ground", "Adiabatic", "AttachedZone", "Surface"] };
}
function receive(p, state) { p.panel.receive({ type: "panel.snapshot", payload: state }); }
function label(field) { return { face_type: "Type", boundary_condition: "Boundary", assembly_id: "Assembly" }[field]; }
function glyph(p, field) {
  var descriptor = p.classify.header(field, label(field));
  if (!descriptor.node.isConnected) p.context.document.body.appendChild(descriptor.node);
  return descriptor.node;
}
function open(p, field) {
  glyph(p, field);
  if (!p.anchor) { p.anchor = p.context.document.createElement("button");
    p.context.document.body.appendChild(p.anchor); }
  if (!p.menu) { p.menu = p.context.document.createElement("div"); p.context.document.body.appendChild(p.menu); }
  p.menu.hidden = false; p.menu.replaceChildren();
  p.close = function (focus) { p.menu.hidden = true; p.closedWithFocus = focus; if (focus) p.anchor.focus(); };
  p.reopen = function () { open(p, field); };
  p.classify.extra(field, p.menu, p.anchor, p.close, p.reopen);
  return p.anchor;
}
function paint(p, field, value, word) {
  var descriptor = p.classify.paint(field, value, word);
  descriptor.run(p.anchor, p.close, p.reopen);
  return descriptor;
}
function params(p, index) { return JSON.parse(JSON.stringify(p.sent[index || 0].payload.params)); }
function escape(p, handled) {
  var event = { key: "Escape", defaultPrevented: Boolean(handled),
    preventDefault: function () { this.defaultPrevented = true; } };
  p.context.document.listeners.keydown(event); return event;
}
function openNew(p) {
  receive(p, snapshot(palette())); open(p, "boundary_condition");
  var trigger = p.section().querySelectorAll("button").filter(function (node) {
    return node.textContent === "New attached zone";
  })[0];
  trigger.listeners.click({});
  return { trigger: trigger, dialog: p.context.document.querySelector("dialog") };
}

test("paint values include every declared choice and local Assembly with glossary labels", function () {
  var p = page(); receive(p, snapshot(palette()));
  function entries(field) { return JSON.parse(JSON.stringify(p.classify.values(field))); }
  assert.deepStrictEqual(entries("face_type"), [
    { value: "Wall", label: "Wall" }, { value: "RoofCeiling", label: "Roof or ceiling" },
    { value: "Floor", label: "Floor" }
  ]);
  assert.ok(entries("boundary_condition").some(function (entry) { return entry.value === "Surface"; }));
  assert.ok(entries("boundary_condition").some(function (entry) {
    return entry.value === "Adiabatic" && entry.label === "To neighbour";
  }));
  assert.ok(entries("assembly_id").some(function (entry) { return entry.value === "asy_roof"; }));
  assert.strictEqual(p.classify.header("face_type", "Type").node.hidden, true);
  assert.strictEqual(p.context.document.querySelector("[data-section='ph_composer.classify']"), null);
  assert.strictEqual(p.context.document.querySelector("[data-section='ph_composer.classify.toggle']"), null);
  assert.strictEqual(p.classify.action, undefined, "there is no separate paint action or picker");
});

test("a value's paint action sends one explicit field intent and closes its column menu", function () {
  [ ["face_type", "RoofCeiling", "Roof or ceiling"], ["boundary_condition", "Adiabatic", "To neighbour"],
    ["assembly_id", "asy_wall", "Wall assembly"] ].forEach(function (entry) {
    var p = page(); receive(p, snapshot(palette())); open(p, entry[0]);
    var action = paint(p, entry[0], entry[1], entry[2]);
    assert.strictEqual(action.label, "Paint " + entry[2]); assert.strictEqual(action.icon, "paint_bucket");
    assert.strictEqual(action.disabled, false); assert.strictEqual(action.pressed, false);
    assert.strictEqual(p.sent[0].type, "view.invoke");
    assert.strictEqual(p.sent[0].payload.name, "ph_composer.zones.faces.choose");
    assert.deepStrictEqual(params(p), { field: entry[0], value: entry[1], reset: true });
    assert.strictEqual(p.menu.hidden, true);
    assert.strictEqual(p.context.document.activeElement, p.anchor);
  });
});

test("Surface, Attached zone and None have no row paint action", function () {
  var p = page(); receive(p, snapshot(palette()));
  assert.strictEqual(p.classify.paint("boundary_condition", "Surface", "Surface"), null);
  assert.strictEqual(p.classify.paint("boundary_condition", "AttachedZone", "Attached zone"), null);
  assert.strictEqual(p.classify.paint("assembly_id", null, "None"), null);
  assert.strictEqual(p.classify.paint("assembly_id", "", "None"), null);
});

test("Boundary adds its Attached zone select, New route and Surface explanation inline", function () {
  var p = page(); receive(p, snapshot(palette(), [{ id: "atz_1", values: { name: "Garage" } }]));
  open(p, "boundary_condition");
  var picker = p.section().querySelector("select");
  assert.ok(picker.children.some(function (node) { return node.textContent === "Garage"; }));
  assert.ok(p.section().querySelectorAll("p").some(function (node) {
    return node.textContent === "Surface is set by Solve adjacencies.";
  }));
  picker.value = "atz_1"; picker.listeners.change({});
  assert.deepStrictEqual(params(p), { field: "attached_zone_id", value: "atz_1", reset: true });
  assert.strictEqual(p.menu.hidden, true);
  var type = page(); receive(type, snapshot(palette())); open(type, "face_type");
  assert.strictEqual(type.section().children.length, 0, "other columns add no Attached zone controls");
});

test("active fields have persistent stop-only glyphs, including external multi-field intent", function () {
  var p = page(); receive(p, snapshot(palette({ face_type: "Wall", boundary_condition: "Ground",
    assembly_id: "asy_wall" }, true)));
  ["face_type", "boundary_condition", "assembly_id"].forEach(function (field) {
    var header = p.classify.header(field, label(field));
    assert.strictEqual(header.persistent, true); assert.strictEqual(header.node.hidden, false);
    assert.strictEqual(header.node.tagName, "button", "a bare glyph has no nested picker");
  });
  assert.strictEqual(p.classify.paint("face_type", "Wall", "Wall").pressed, true);
  assert.strictEqual(p.classify.paint("face_type", "Floor", "Floor").pressed, false);
  glyph(p, "face_type").listeners.click({});
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.zones.faces.stop_classifying");
  assert.strictEqual(p.context.document.querySelector(".phc-bubble"), null);
});

test("idle glyphs are hidden and Escape stops active painting once through its public command", function () {
  var p = page(); receive(p, snapshot(palette()));
  assert.strictEqual(glyph(p, "face_type").hidden, true);
  assert.strictEqual(escape(p).defaultPrevented, false);
  receive(p, snapshot(palette({ face_type: "Wall" }, true)));
  escape(p, true); assert.strictEqual(p.sent.length, 0);
  assert.strictEqual(escape(p).defaultPrevented, true); escape(p);
  assert.strictEqual(p.sent.length, 1); assert.strictEqual(p.sent[0].type, "view.invoke");
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.zones.faces.stop_classifying");
});

test("a modal receives Escape before the active paint tool", function () {
  var p = page(), opened = openNew(p);
  receive(p, snapshot(palette({ face_type: "Wall" }, true)));
  assert.strictEqual(escape(p).defaultPrevented, false); assert.strictEqual(p.sent.length, 0);
  opened.dialog.listeners.cancel({ preventDefault: function () {} });
  assert.strictEqual(p.context.document.querySelector("dialog"), null);
  escape(p); assert.strictEqual(p.sent[0].payload.name, "ph_composer.zones.faces.stop_classifying");
});

test("missing palette or Assembly reads withdraw their paint actions", function () {
  var p = page(), state = snapshot(palette()); delete state.sections["ph_composer.zones.faces.assemblies"];
  receive(p, state); assert.strictEqual(p.classify.paint("assembly_id", "asy_wall", "Wall assembly"), null);
  assert.strictEqual(p.classify.paint("face_type", "Wall", "Wall").disabled, false);
  delete state.sections["ph_composer.zones.faces.palette"]; receive(p, state);
  assert.strictEqual(p.classify.paint("face_type", "Wall", "Wall"), null);
});

test("New attached zone creates a Model record, then paints it with a reset", function () {
  var p = page(), opened = openNew(p);
  assert.strictEqual(p.sent.length, 0); assert.strictEqual(p.menu.hidden, true);
  opened.dialog.querySelector("form").listeners.submit({ preventDefault: function () {} });
  assert.strictEqual(p.sent[0].type, "action.invoke");
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.zones.faces.attached_zone.save");
  assert.deepStrictEqual(params(p), { values: {
    name: "Attached zone 1", kind: "other", temperature_reduction_factor: 0.95
  } });
  p.panel.receive({ type: "action.result", payload: { request_id: p.sent[0].payload.request_id,
    session: "session-a", outcome: { status: "completed", value: { id: "atz_2" } } } });
  assert.strictEqual(p.context.document.querySelector("dialog"), null);
  assert.deepStrictEqual(params(p, 1), { field: "attached_zone_id", value: "atz_2", reset: true });
  assert.strictEqual(p.menu.hidden, true);
});

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
    assert.strictEqual(p.menu.hidden, false, "Cancel reopens the same column menu");
    assert.strictEqual(p.context.document.activeElement.textContent, "New attached zone");
    assert.strictEqual(p.context.document.activeElement.isConnected, true);
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


test("a created Attached zone waits for the viewport channel, then focuses its active glyph", function () {
  var p = page(), opened = openNew(p);
  receive(p, snapshot(palette({ face_type: "Wall" }, true)));
  glyph(p, "face_type").listeners.click({});
  opened.dialog.querySelector("form").listeners.submit({ preventDefault: function () {} });
  var stop = p.sent[0], create = p.sent[1];
  p.panel.receive({ type: "action.result", payload: { request_id: create.payload.request_id,
    session: "session-a", outcome: { status: "completed", value: { id: "atz_new" } } } });
  assert.strictEqual(p.sent.length, 2, "the new record waits for the pending viewport command");
  p.panel.receive({ type: "view.result", payload: { request_id: stop.payload.request_id,
    session: "session-a", outcome: { status: "completed" } } });
  assert.strictEqual(p.sent.length, 3);
  assert.deepStrictEqual(params(p, 2), { field: "attached_zone_id", value: "atz_new", reset: true });
  var chosen = snapshot(palette({ attached_zone_id: "atz_new", boundary_condition: "AttachedZone" }, true),
    [{ id: "atz_new", values: { name: "Garage" } }]);
  receive(p, chosen);
  p.panel.receive({ type: "view.result", payload: { request_id: p.sent[2].payload.request_id,
    session: "session-a", outcome: { status: "completed" } } });
  assert.strictEqual(p.context.document.activeElement,
    glyph(p, "boundary_condition"));
});

test("old callbacks or create results cannot paint after a Model switch", function () {
  var p = page(); receive(p, snapshot(palette())); open(p, "face_type");
  var oldAction = p.classify.paint("face_type", "Wall", "Wall");
  var next = snapshot(palette({}, true)); next.session = "session-b"; receive(p, next);
  oldAction.run(p.anchor, p.close, p.reopen);
  assert.strictEqual(p.sent.length, 0);
  escape(p); assert.strictEqual(p.sent[0].payload.session, "session-b");

  p = page(); var opened = openNew(p);
  opened.dialog.querySelector("form").listeners.submit({ preventDefault: function () {} });
  next = snapshot(palette()); next.session = "session-b"; receive(p, next);
  p.panel.receive({ type: "action.result", payload: { request_id: p.sent[0].payload.request_id,
    session: "session-a", outcome: { status: "completed", value: { id: "atz_old" } } } });
  assert.strictEqual(p.sent.length, 1); assert.strictEqual(p.context.document.querySelector("dialog"), null);
});
