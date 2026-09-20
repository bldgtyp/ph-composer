"use strict";

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
  var modules = panelSource.start(context, ["sections/shell", "sections/overview"]);
  return { context: context, panel: modules.panel, modules: modules, sent: sent,
    query: function (selector) { return context.document.querySelector(selector); } };
}

function snapshot() {
  return {
    product: "PH-Composer", version: "0.1.0-dev", session: "session-a", revision: 4,
    file_name: "house.skp", edit_path: [], preferences: {
      unit_system: "SI", dimension_formats: {}, number_format: { decimal: ".", locale: "en-US" }
    },
    sections: {
      "ph_composer.zones.overview": { status: "completed", value: {
        zones: [{ id: "zon_a", schema_version: 1, user_data: {}, extension_data: {},
          reference: { zone_id: "zon_a", zone_path: [100] }, state: "found", face_count: 2,
          values: { name: "Zone 1", building_segment: "house", level: null, ground_depth_mm: 0 } }],
        make_zone: { parent_path: [], entity_ids: [200] }, units: { ground_depth_mm: "mm" }
      } },
      "ph_composer.face_assignment.faces": { status: "completed", value: { units: { area_m2: "m2" }, faces: [{
        reference: { zone_id: "zon_a", zone_path: [100], entity_path: [101], entity_id: "fac_a" },
        zone_name: "Zone 1", area_m2: 12, state: "classified",
        values: { id: "fac_a", face_type: "Wall", boundary_condition: "Outdoors" },
        suggested: { face_type: "Wall", boundary_condition: "Outdoors" }
      }, {
        reference: { zone_id: "zon_a", zone_path: [100], entity_path: [102], entity_id: null },
        zone_name: "Zone 1", area_m2: 8, state: "unclassified", values: {},
        suggested: { face_type: "Floor", boundary_condition: "Ground" }
      }] } }
    }
  };
}

function byLabel(root, label) {
  return root.querySelectorAll("input, select").filter(function (node) {
    return node.getAttribute("aria-label") === label;
  })[0];
}


function rowAction(root, id) {
  return root.querySelectorAll("[data-row-action]").filter(function (node) {
    return node.getAttribute("data-row-action") === id;
  })[0];
}

function suggest(root) {
  return rowAction(root, "suggest");
}

test("Overview exposes Make Zone and sends its explicit selection target", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });
  var section = p.query("[data-section='ph_composer.overview']");
  var make = section.querySelectorAll("button").filter(function (node) { return node.textContent === "Make Zone"; })[0];

  make.listeners.click({});

  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0])), { type: "action.invoke", payload: {
    request_id: "session-a:overview:1", session: "session-a", name: "ph_composer.zones.make",
    params: { parent_path: [], entity_ids: [200] }, expected_revision: 4
  } });
});

test("a Face chip sets one field, keeps the other, and guards on the values it painted", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });
  var section = p.query("[data-section='ph_composer.overview']");
  var chip = byLabel(section, "Wall 1 boundary");

  chip.value = "Ground";
  chip.listeners.change({});

  var sent = p.sent[0].payload;
  assert.strictEqual(sent.name, "ph_composer.face_assignment.classify");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(sent.params)), {
    faces: [{ zone_id: "zon_a", zone_path: [100], entity_path: [101], entity_id: "fac_a" }],
    intent: {
      face_type: { mode: "keep" },
      boundary_condition: { mode: "set", value: "Ground" }
    },
    expected_values: { id: "fac_a", face_type: "Wall", boundary_condition: "Outdoors" }
  });
});

test("an unclassified Face is its Zone's count and its Suggest action, not a row of its own", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });
  var section = p.query("[data-section='ph_composer.overview']");

  assert.strictEqual(section.querySelectorAll("[data-row-key]").length, 2, "one Zone row and one Face row");
  assert.strictEqual(section.querySelector(".phc-row-marker").textContent, "1 unclassified");

  suggest(section).listeners.click({});
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.face_assignment.auto_classify");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0].payload.params)),
    { zone: { zone_id: "zon_a", zone_path: [100] } });
});

test("Locate goes to the viewport channel and never to an action", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });
  var section = p.query("[data-section='ph_composer.overview']");

  rowAction(section, "locate").listeners.click({});

  assert.strictEqual(p.sent[0].type, "view.invoke");
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.face_assignment.locate");
  assert.strictEqual(p.sent[0].payload.params.faces.length, 1, "a Zone locates only its recorded Faces");
  assert.strictEqual(p.sent[0].payload.expected_revision, undefined, "a view command guards no revision");
});

test("Zone details appear for the selected Zone and save against the values last read", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });
  var section = p.query("[data-section='ph_composer.overview']");
  assert.strictEqual(section.querySelector(".phc-zone-card"), null, "nothing is selected yet");

  section.querySelector(".row-target").listeners.click({});
  byLabel(section, "Zone name").value = "North Zone";
  section.querySelector("form").listeners.submit({ preventDefault: function () {} });

  var sent = p.sent[0].payload;
  assert.strictEqual(sent.name, "ph_composer.zones.update");
  assert.strictEqual(sent.params.values.name, "North Zone");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(sent.params.expected_values)), {
    name: "Zone 1", building_segment: "house", level: null, ground_depth_mm: 0
  });
});

test("Zone ground depth follows display units and sends canonical millimetres", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });
  p.modules.unit_preferences.set("unit_system", "IP");
  var section = p.query("[data-section='ph_composer.overview']");
  section.querySelector(".row-target").listeners.click({});
  var depth = byLabel(section, "Ground depth");
  depth.value = "1 ft";
  depth.listeners.input({});
  section.querySelector("form").listeners.submit({ preventDefault: function () {} });

  assert.strictEqual(p.sent[0].payload.params.values.ground_depth_mm, 304.8);
});
