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
  var modules = panelSource.start(context, ["sections/shell", "features/zones/overview"]);
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
      "ph_composer.zones.faces.palette": { status: "completed", value: {
        active: false, palette: {}, face_types: ["Wall", "RoofCeiling", "Floor"],
        boundary_conditions: ["Outdoors", "Ground", "Adiabatic", "AttachedZone", "Surface"]
      } },
      "ph_composer.zones.overview": { status: "completed", value: {
        zones: [{ id: "zon_a", schema_version: 1, user_data: {}, extension_data: {},
          reference: { zone_id: "zon_a", zone_path: [100] }, state: "found", face_count: 2,
          values: { name: "Zone 1", building_segment: "house", level: null, ground_depth_mm: 0 } }],
        make_zone: { parent_path: [], entity_ids: [200] }, units: { ground_depth_mm: "mm" }
      } },
      "ph_composer.zones.faces.faces": { status: "completed", value: { units: { area_m2: "m2" }, faces: [{
        reference: { zone_id: "zon_a", zone_path: [100], entity_path: [101], entity_id: "fac_a" },
        zone_name: "Zone 1", area_m2: 12, state: "classified",
        values: { face_type: "Wall", boundary_condition: "Outdoors" },
        suggested: { face_type: "Wall", boundary_condition: "Outdoors" }
      }, {
        reference: { zone_id: "zon_a", zone_path: [100], entity_path: [102], entity_id: null },
        zone_name: "Zone 1", area_m2: 8, state: "unclassified", values: {},
        suggested: { face_type: "Floor", boundary_condition: "Ground" }
      }] } }
    }
  };
}

/* The Zone details form, which the inspector holds. */
function zoneCard(p) {
  return p.query("[data-section='ph_composer.zones.details']").querySelector(".phc-zone-card");
}

/* A control by its accessible name, anywhere in the root's pane: the tree is the work surface, and the
   Zone details and the Face selection are in the inspector beside it. */
function byLabel(root, label) {
  var scope = root.closest("[data-pane]") || root;
  return scope.querySelectorAll("input, select, button").filter(function (node) {
    return node.getAttribute("aria-label") === label;
  })[0];
}

function settingsPage() {
  var p = page(), state = snapshot();
  state.sections["ph_composer.zones.settings"] = { status: "completed", value: {
    suggest_on_make: true, roof_angle_deg: 60, floor_angle_deg: 130
  } };
  p.panel.receive({ type: "panel.snapshot", payload: state });
  p.section = p.query("[data-section='ph_composer.overview']");
  p.settings = byLabel(p.section, "Zones / Faces settings");
  p.settings.listeners.click({});
  return p;
}

test("Zones / Faces settings commit Enter once with the reviewed values and revision", function () {
  var p = settingsPage(), roof = byLabel(p.section, "Roof maximum tilt [deg]");
  assert.ok(panelSource.markup("index.html").includes('data-tab="overview">Zones / Faces'));
  roof.value = "45";
  roof.listeners.keydown({ key: "Enter", preventDefault: function () {} });
  roof.listeners.change({});

  assert.strictEqual(p.sent.length, 1);
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.zones.settings.update");
  assert.strictEqual(p.sent[0].payload.expected_revision, 4);
  assert.deepStrictEqual(p.sent[0].payload.params, {
    values: { suggest_on_make: true, roof_angle_deg: 45, floor_angle_deg: 130 },
    expected_values: { suggest_on_make: true, roof_angle_deg: 60, floor_angle_deg: 130 }
  });
  p.panel.showTab("export");
  assert.strictEqual(p.panel.state.ui.activeTab, "overview");
  var bubble = p.section.querySelector(".phc-bubble");
  bubble._bubble.close(true);
  assert.strictEqual(bubble.hidden, false, "the pending operation keeps its work surface visible");
});

test("Zones / Faces settings reject invalid angles locally and Escape restores the field", function () {
  var p = settingsPage(), roof = byLabel(p.section, "Roof maximum tilt [deg]");
  roof.value = "140";
  roof.listeners.change({});
  assert.strictEqual(p.sent.length, 0);
  assert.ok(p.section.querySelector(".phc-form-status").textContent.includes("roof angle below"));
  roof.listeners.keydown({ key: "Escape" });
  assert.strictEqual(roof.value, "60");
});


function rowAction(root, id) {
  return root.querySelectorAll("[data-row-action]").filter(function (node) {
    return node.getAttribute("data-row-action") === id;
  })[0];
}

function suggest(root) {
  return rowAction(root, "suggest");
}

test("Overview has no placeholder section beneath the feature work surface", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });

  assert.strictEqual(Boolean(p.query("[data-section='overview']")), false);
  assert.strictEqual(p.query("[data-pane='overview']").textContent.includes("Nothing to show yet."), false);
});

test("area headers and Zone and Face values follow the display profile together", function () {
  var p = page(), payload = snapshot();
  payload.preferences.unit_system = "IP";
  var faces = payload.sections["ph_composer.zones.faces.faces"].value.faces;
  faces[0].area_m2 = 1;
  var additional = JSON.parse(JSON.stringify(faces[0]));
  additional.area_m2 = 3;
  additional.reference.entity_path = [103];
  additional.reference.entity_id = "fac_c";
  faces.push(additional);
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  var section = p.query("[data-section='ph_composer.overview']");
  assert.ok(section.querySelectorAll("select").some(function (node) {
    return node.classList.contains("phc-enum-cell") && node.classList.contains("phc-cell-input");
  }), "a Face's type and boundary chips are the kit's enum cell");
  function areas() {
    return section.querySelectorAll(".col-area_m2").filter(function (node) { return node.tagName === "td"; })
      .map(function (node) { return node.textContent; });
  }
  function header() {
    return section.querySelectorAll(".col-area_m2").filter(function (node) { return node.tagName === "th"; })[0];
  }

  assert.ok(header().textContent.includes("Gross area ft²"));
  assert.deepStrictEqual(areas(), ["129.17", "10.76", "32.29", "86.11", "86.11"],
    "the Zone over every Face it has, its two recorded Faces, then the unclassified as a group and one by one");
  p.modules.unit_preferences.set("unit_system", "SI");
  p.panel.repaint();
  assert.ok(header().textContent.includes("Gross area m²"));
  assert.deepStrictEqual(areas(), ["12", "1", "3", "8", "8"]);
  assert.strictEqual(faces[0].area_m2, 1, "display changes leave the canonical snapshot alone");
});

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

test("whole-model Solve includes unsafe occurrences for all-or-nothing refusal", function () {
  var p = page(), state = snapshot();
  var zones = state.sections["ph_composer.zones.overview"].value.zones;
  var copy = JSON.parse(JSON.stringify(zones[0]));
  copy.reference.zone_path = [300];
  copy.state = "ambiguous";
  zones.push(copy);
  p.panel.receive({ type: "panel.snapshot", payload: state });
  var section = p.query("[data-section='ph_composer.overview']");
  var button = byLabel(section, "Solve adjacencies for all Zones in this Model");
  button.listeners.click({});

  assert.strictEqual(p.sent[0].payload.name, "ph_composer.zones.solve_adjacency");
  assert.strictEqual(p.sent[0].payload.expected_revision, 4);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0].payload.params)), {
    zones: [{ zone_id: "zon_a", zone_path: [100] }, { zone_id: "zon_a", zone_path: [300] }]
  });
});

test("a Face chip sets one field, keeps the other, and guards on the values it painted", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });
  var section = p.query("[data-section='ph_composer.overview']");
  var chip = byLabel(section, "Wall 1 boundary");

  chip.value = "Ground";
  chip.listeners.change({});

  var sent = p.sent[0].payload;
  assert.strictEqual(sent.name, "ph_composer.zones.faces.classify");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(sent.params)), {
    faces: [{ zone_id: "zon_a", zone_path: [100], entity_path: [101], entity_id: "fac_a" }],
    intent: {
      face_type: { mode: "keep" },
      boundary_condition: { mode: "set", value: "Ground" }
    },
    expected_values: { face_type: "Wall", boundary_condition: "Outdoors" }
  });
});

test("an unclassified Face is a row under its Zone's summary, and choosing a value classifies it", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });
  var section = p.query("[data-section='ph_composer.overview']");

  var names = section.querySelectorAll(".col-name").filter(function (node) { return node.tagName === "td"; })
    .map(function (node) { return node.textContent; });
  assert.deepStrictEqual(names, ["Zone 1", "Wall 1", "1 unclassified Face", "Face 2"]);
  assert.strictEqual(section.querySelector(".phc-row-marker").textContent, "1", "the Zone still counts them");

  var type = byLabel(section, "Set Face 2 type");
  assert.strictEqual(byLabel(section, "Face 2 Assembly"), undefined, "no Assembly before there is a record");
  type.value = "Floor";
  type.listeners.change({});
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.zones.faces.classify");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0].payload.params)), {
    faces: [{ zone_id: "zon_a", zone_path: [100], entity_path: [102], entity_id: null }],
    intent: { face_type: { mode: "set", value: "Floor" }, boundary_condition: { mode: "keep" } },
    expected_values: {}
  });

  p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });
  suggest(p.query("[data-section='ph_composer.overview']")).listeners.click({});
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.zones.faces.auto_classify");
});

test("a long list of unclassified Faces waits to be opened and shows its first fifty", function () {
  var p = page(), payload = snapshot();
  var faces = payload.sections["ph_composer.zones.faces.faces"].value.faces, index;
  for (index = 0; index < 60; index += 1) {
    faces.push({ reference: { zone_id: "zon_a", zone_path: [100], entity_path: [500 + index], entity_id: null },
      zone_name: "Zone 1", area_m2: 1, state: "unclassified", values: {}, suggested: {} });
  }
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  var section = p.query("[data-section='ph_composer.overview']");
  function count() { return section.querySelectorAll("[data-row-key]").length; }
  assert.strictEqual(count(), 3, "the Zone, its Face and the summary: sixty-one rows are not painted unasked");
  var chevron = section.querySelectorAll(".row-chevron").filter(function (node) {
    return /unclassified/.test(node.getAttribute("aria-label"));
  })[0];
  chevron.listeners.click({});
  assert.strictEqual(count(), 3 + 50 + 1, "fifty Faces and one row offering the rest");
  var more = section.querySelectorAll(".row-target").filter(function (node) {
    return node.textContent === "Show all";
  })[0];
  more.listeners.click({});
  assert.strictEqual(count(), 3 + 61);
});

/* A copied Zone Group shares its original's dictionary until it is repaired, so two occurrences can
   carry one record id. The tree is built from occurrences, not ids, or the copy takes the
   original's place and its Faces and area are summed into it. */
test("two Zone occurrences sharing one record id are two rows", function () {
  var p = page();
  var payload = snapshot();
  var overview = payload.sections["ph_composer.zones.overview"].value;
  var faces = payload.sections["ph_composer.zones.faces.faces"].value;
  overview.zones = overview.zones.concat([{ id: "zon_a", schema_version: 1, user_data: {}, extension_data: {},
    reference: { zone_id: "zon_a", zone_path: [200] }, state: "ambiguous", face_count: 1,
    values: { name: "Zone 1 copy", building_segment: "house", level: null, ground_depth_mm: 0 } }]);
  overview.zones[0].state = "ambiguous";
  faces.faces = faces.faces.concat([{
    reference: { zone_id: "zon_a", zone_path: [200], entity_path: [201], entity_id: "fac_b" },
    zone_name: "Zone 1 copy", area_m2: 5, state: "classified",
    values: { face_type: "Floor", boundary_condition: "Ground" },
    suggested: { face_type: "Floor", boundary_condition: "Ground" }
  }]);
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  var section = p.query("[data-section='ph_composer.overview']");

  var names = section.querySelectorAll(".col-name").filter(function (node) { return node.tagName === "td"; })
    .map(function (node) { return node.textContent; });
  assert.deepStrictEqual(names, ["Zone 1", "Wall 1", "1 unclassified Face", "Face 2", "Zone 1 copy", "Floor 1"],
    "each occurrence keeps its own row and its own Faces");
  assert.strictEqual(section.querySelectorAll(".phc-row-marker")[0].textContent, "shared identity",
    "and the panel says why, because an edit here names one of the two");
});

/* A Face row must not be rekeyed or renamed because a neighbour was classified: the table drops a
   rekeyed row's cached entry, and with it the selection and any edit in progress. */
test("classifying one Face leaves its neighbours' rows alone", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });
  var section = p.query("[data-section='ph_composer.overview']");
  var before = section.querySelectorAll("[data-row-key]").map(function (node) {
    return node.getAttribute("data-row-key");
  });

  var payload = snapshot();
  var faces = payload.sections["ph_composer.zones.faces.faces"].value.faces;
  faces[1].state = "classified";
  faces[1].values = { face_type: "Floor", boundary_condition: "Ground" };
  p.panel.receive({ type: "panel.snapshot", payload: payload });

  var after = section.querySelectorAll("[data-row-key]").map(function (node) {
    return node.getAttribute("data-row-key");
  });
  assert.ok(after.every(function (key) { return before.indexOf(key) >= 0; }),
    "every row still there keeps its key, the newly classified Face included");
  assert.strictEqual(after.length, before.length - 1, "only the emptied summary row goes");
  var names = section.querySelectorAll(".col-name").filter(function (node) { return node.tagName === "td"; })
    .map(function (node) { return node.textContent; });
  assert.deepStrictEqual(names, ["Zone 1", "Wall 1", "Floor 2"],
    "and a Face is numbered among every Face of its Zone, not among the classified ones");
});

/* A stored value no chip offers reads as what it is rather than vanishing from the control. */
test("a Face the chips cannot set keeps its value and stays read only", function () {
  var p = page();
  var payload = snapshot();
  payload.sections["ph_composer.zones.faces.faces"].value.faces[0].values = {
    face_type: "AirBoundary", boundary_condition: "Surface"
  };
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  var section = p.query("[data-section='ph_composer.overview']");

  assert.strictEqual(byLabel(section, "Air boundary 1 type"), undefined, "no chip offers Air boundary");
  var cells = section.querySelectorAll(".col-face_type").filter(function (node) { return node.tagName === "td"; });
  assert.strictEqual(cells[1].querySelector(".phc-enum-pill").textContent, "Air boundary",
    "the cell says what the Face is, as a read-only pill");
});

test("Locate goes to the viewport channel and never to an action", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });
  var section = p.query("[data-section='ph_composer.overview']");

  rowAction(section, "locate").listeners.click({});

  assert.strictEqual(p.sent[0].type, "view.invoke");
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.zones.faces.locate");
  assert.strictEqual(p.sent[0].payload.params.faces.length, 2,
    "a Zone locates every Face it has, recorded or not, as its rows now list them");
  assert.strictEqual(p.sent[0].payload.expected_revision, undefined, "a view command guards no revision");
});

test("Zone details appear for the selected Zone and save against the values last read", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });
  var section = p.query("[data-section='ph_composer.overview']");
  assert.strictEqual(zoneCard(p), null, "nothing is selected yet");

  section.querySelector(".row-target").listeners.click({});
  byLabel(section, "Zone name").value = "North Zone";
  zoneCard(p).listeners.submit({ preventDefault: function () {} });

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
  zoneCard(p).listeners.submit({ preventDefault: function () {} });

  assert.strictEqual(p.sent[0].payload.params.values.ground_depth_mm, 304.8);
});

test("a pristine selected Zone follows an authoritative snapshot refresh", function () {
  var p = page(), payload = snapshot();
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  var section = p.query("[data-section='ph_composer.overview']");
  section.querySelector(".row-target").listeners.click({});
  payload = snapshot();
  payload.sections["ph_composer.zones.overview"].value.zones[0].values = {
    name: "north", building_segment: "tower", level: "2", ground_depth_mm: 12
  };
  p.panel.receive({ type: "panel.snapshot", payload: payload });

  assert.strictEqual(byLabel(section, "Zone name").value, "north");
  assert.strictEqual(byLabel(section, "Building-Segment").value, "tower");
  assert.strictEqual(byLabel(section, "Level").value, "2");
  assert.strictEqual(byLabel(section, "Ground depth").value, "12");
});

test("a selected Zone keeps its draft and stale guard through a native unit refresh", function () {
  var p = page(), initial = snapshot(), refreshed;
  initial.sections["ph_composer.zones.overview"].value.zones[0].values.name = "east";
  p.panel.receive({ type: "panel.snapshot", payload: initial });
  var section = p.query("[data-section='ph_composer.overview']");
  section.querySelector(".row-target").listeners.click({});
  var name = byLabel(section, "Zone name"), depth = byLabel(section, "Ground depth");
  name.value = "Unsaved east draft";
  name.listeners.input({});
  depth.value = "12 in";
  depth.listeners.input({});

  p.modules.unit_preferences.set("unit_system", "SI");
  p.panel.repaint();
  refreshed = snapshot();
  refreshed.sections["ph_composer.zones.overview"].value.zones[0].values.name = "native east";
  p.panel.receive({ type: "panel.snapshot", payload: refreshed });

  assert.strictEqual(byLabel(section, "Zone name"), name);
  assert.strictEqual(byLabel(section, "Zone name").value, "Unsaved east draft");
  assert.strictEqual(byLabel(section, "Ground depth"), depth);
  assert.strictEqual(byLabel(section, "Ground depth").value, "12 in");
  zoneCard(p).listeners.submit({ preventDefault: function () {} });
  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0].payload.params)), {
    reference: { zone_id: "zon_a", zone_path: [100] },
    values: { name: "Unsaved east draft", building_segment: "house", level: null, ground_depth_mm: 304.8 },
    expected_values: { name: "east", building_segment: "house", level: null, ground_depth_mm: 0 }
  });
  assert.strictEqual(name.disabled, true);
  assert.strictEqual(depth.disabled, true);
  assert.strictEqual(zoneCard(p).querySelectorAll("button").filter(function (node) {
    return node.textContent === "Save";
  })[0].disabled, true);
  refreshed = snapshot();
  refreshed.sections["ph_composer.zones.overview"].value.zones[0].values = {
    name: "Unsaved east draft", building_segment: "house", level: null, ground_depth_mm: 304.8
  };
  p.panel.receive({ type: "panel.snapshot", payload: refreshed });
  p.panel.receive({ type: "action.result", payload: { request_id: p.sent[0].payload.request_id,
    session: "session-a", outcome: { status: "completed", value: { zone_id: "zon_a" } } } });
  assert.strictEqual(name.disabled, false);
  assert.strictEqual(depth.disabled, false);
  refreshed = snapshot();
  refreshed.sections["ph_composer.zones.overview"].value.zones[0].values = {
    name: "canonical east", building_segment: "house", level: null, ground_depth_mm: 305
  };
  p.panel.receive({ type: "panel.snapshot", payload: refreshed });
  assert.strictEqual(name.value, "canonical east");
  assert.strictEqual(depth.value, "305");
  name.value = "Saved east draft";
  name.listeners.input({});
  zoneCard(p).listeners.submit({ preventDefault: function () {} });
  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[1].payload.params.expected_values)), {
    name: "canonical east", building_segment: "house", level: null, ground_depth_mm: 305
  });
  p.panel.receive({ type: "action.result", payload: { request_id: p.sent[1].payload.request_id,
    session: "session-a", outcome: { status: "refused", message: "The Zone changed." } } });
  assert.strictEqual(name.disabled, false, "a refused save leaves the draft available for correction");
  assert.strictEqual(depth.disabled, false);
});

function attachedDialog(p, payload) {
  p.panel.receive({ type: "panel.snapshot", payload: payload || snapshot() });
  var chip = byLabel(p.query("[data-section='ph_composer.overview']"), "Wall 1 boundary");
  if (chip.tagName === "button") chip.listeners.click({});
  else { chip.value = "AttachedZone"; chip.listeners.change({}); }
  return p.query("dialog");
}

test("inline Attached-zone creation cancels without writing or changing the Face chip", function () {
  var p = page(), dialog = attachedDialog(p);
  assert.strictEqual(p.sent.length, 0);
  assert.strictEqual(byLabel(p.query("[data-section='ph_composer.overview']"), "Wall 1 boundary").value, "Outdoors");
  dialog.listeners.cancel({ preventDefault: function () {} });
  assert.strictEqual(p.sent.length, 0);
  assert.strictEqual(p.query("dialog"), null);
  assert.strictEqual(p.context.document.activeElement.getAttribute("aria-label"), "Wall 1 boundary");
});

test("inline create-and-assign sends one action with the original Face and reviewed revision", function () {
  var p = page(), dialog = attachedDialog(p);
  var newer = snapshot(); newer.revision = 9;
  p.panel.receive({ type: "panel.snapshot", payload: newer });
  dialog.querySelector("form").listeners.submit({ preventDefault: function () {} });
  assert.strictEqual(p.sent.length, 1);
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.zones.faces.attached_zone.create_and_assign");
  assert.strictEqual(p.sent[0].payload.expected_revision, 4);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[0].payload.params)), {
    faces: [snapshot().sections["ph_composer.zones.faces.faces"].value.faces[0].reference],
    expected_values: { face_type: "Wall", boundary_condition: "Outdoors" },
    values: { name: "Attached zone 1", kind: "other", temperature_reduction_factor: 0.95 }
  });
  dialog.listeners.cancel({ preventDefault: function () {} });
  assert.strictEqual(p.query("dialog"), dialog, "pending writes keep their controls visible");
  dialog.querySelector("form").listeners.submit({ preventDefault: function () {} });
  assert.strictEqual(p.sent.length, 1, "one in-flight request");
});

test("a refused inline assignment preserves the draft; success closes and restores focus", function () {
  var p = page(), dialog = attachedDialog(p), form = dialog.querySelector("form");
  byLabel(dialog, "Name").value = "Garage draft";
  form.listeners.submit({ preventDefault: function () {} });
  p.panel.receive({ type: "action.result", payload: { request_id: p.sent[0].payload.request_id,
    session: "session-a", outcome: { status: "refused", message: "The Face changed." } } });
  assert.strictEqual(p.query("dialog"), dialog);
  assert.strictEqual(byLabel(dialog, "Name").value, "Garage draft");
  assert.strictEqual(dialog.querySelector("[role='status']").textContent, "The Face changed.");
  assert.strictEqual(dialog.querySelector(".phc-action-apply").disabled, false);
  form.listeners.submit({ preventDefault: function () {} });
  p.panel.receive({ type: "action.result", payload: { request_id: p.sent[1].payload.request_id,
    session: "session-a", outcome: { status: "completed", value: { id: "atz_new", face_ids: ["fac_a"] } } } });
  assert.strictEqual(p.query("dialog"), null);
  assert.strictEqual(p.context.document.activeElement.getAttribute("aria-label"), "Wall 1 boundary");
});

test("an existing Attached-zone choice assigns without creating a definition", function () {
  var p = page(), payload = snapshot();
  payload.sections["ph_composer.zones.faces.attached_zone.list"] = { status: "completed", value: {
    records: [{ id: "atz_existing", values: { name: "Garage" } }]
  } };
  var dialog = attachedDialog(p, payload), picker = byLabel(dialog, "Attached zone");
  picker.value = "atz_existing"; picker.listeners.change({});
  assert.strictEqual(byLabel(dialog, "Name").disabled, true);
  dialog.querySelector("form").listeners.submit({ preventDefault: function () {} });
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.zones.faces.classify");
  assert.strictEqual(p.sent[0].payload.params.intent.attached_zone_id.value, "atz_existing");
  assert.strictEqual(p.sent[0].payload.params.values, undefined);
});

test("an incomplete AttachedZone Face can open and cancel inline creation", function () {
  var p = page(), payload = snapshot();
  payload.sections["ph_composer.zones.faces.faces"].value.faces[0].values.boundary_condition = "AttachedZone";
  var dialog = attachedDialog(p, payload);
  assert.ok(dialog);
  dialog.listeners.cancel({ preventDefault: function () {} });
  assert.strictEqual(p.sent.length, 0);
  assert.strictEqual(payload.sections["ph_composer.zones.faces.faces"].value.faces[0]
    .values.attached_zone_id, undefined);
});

test("switching Models withdraws the pending Attached-zone draft", function () {
  var p = page(); attachedDialog(p);
  var other = snapshot(); other.session = "session-b";
  p.panel.receive({ type: "panel.snapshot", payload: other });
  assert.strictEqual(p.query("dialog"), null);
  assert.strictEqual(p.sent.length, 0);
});

function batchSnapshot(token) {
  var payload = snapshot();
  payload.sections["ph_composer.zones.faces.selection_assignment"] = { status: "completed", value: {
    token: token || "review-1", revision: 4,
    faces: payload.sections["ph_composer.zones.faces.faces"].value.faces.map(function (face) { return face.reference; })
  } };
  return payload;
}

test("native assignment retries a refused tab switch after the guard releases", function () {
  var p = page(), blocked = true;
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });
  p.panel.showTab("export");
  p.panel.navigationGuard("export-work", function () { return blocked ? "Export is busy." : null; });
  p.panel.receive({ type: "panel.snapshot", payload: batchSnapshot() });
  assert.strictEqual(p.panel.state.ui.activeTab, "export");
  assert.strictEqual(p.query("dialog"), null);
  blocked = false;
  p.panel.repaint();
  assert.strictEqual(p.panel.state.ui.activeTab, "overview");
  assert.ok(p.query("dialog"));
  assert.strictEqual(p.sent.length, 0);
});

test("native batch assignment switches to Zones / Faces and freezes heterogeneous targets and revision", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });
  p.panel.showTab("export");
  p.panel.receive({ type: "panel.snapshot", payload: batchSnapshot() });
  assert.strictEqual(p.panel.state.ui.activeTab, "overview");
  var dialog = p.query("dialog");
  assert.ok(dialog);
  assert.strictEqual(p.sent.length, 0);
  var newer = batchSnapshot(); newer.revision = 12;
  p.panel.receive({ type: "panel.snapshot", payload: newer });
  dialog.querySelector("form").listeners.submit({ preventDefault: function () {} });
  var sent = JSON.parse(JSON.stringify(p.sent[0].payload));
  assert.strictEqual(sent.name, "ph_composer.zones.faces.attached_zone.create_and_assign");
  assert.strictEqual(sent.expected_revision, 4);
  var reviewedFaces = batchSnapshot().sections["ph_composer.zones.faces.selection_assignment"].value.faces;
  assert.deepStrictEqual(sent.params.faces, reviewedFaces);
  assert.strictEqual(sent.params.expected_values, undefined);
  p.panel.showTab("export");
  assert.strictEqual(p.panel.state.ui.activeTab, "overview");
  dialog.listeners.cancel({ preventDefault: function () {} });
  assert.strictEqual(p.query("dialog"), dialog, "pending batch cannot disappear");
  p.panel.receive({ type: "action.result", payload: { session: "session-a", request_id: sent.request_id,
    outcome: { status: "refused", message: "The Model changed." } } });
  assert.strictEqual(p.query("dialog"), dialog);
  assert.strictEqual(dialog.querySelector("[role='status']").textContent, "The Model changed.");
  dialog.listeners.cancel({ preventDefault: function () {} });
  assert.strictEqual(p.query("dialog"), null);
  assert.strictEqual(p.sent[1].type, "view.invoke");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(p.sent[1].payload.params)), { token: "review-1" });
  p.panel.repaint();
  assert.strictEqual(p.query("dialog"), null, "unchanged handoff snapshot cannot reopen a closed form");
});

test("native batch handoff waits for dirty Zone details and opens after Cancel", function () {
  var p = draftPage();
  type(byLabel(p.section, "Zone name"), "Unsaved draft");
  p.panel.receive({ type: "panel.snapshot", payload: batchSnapshot() });
  assert.strictEqual(p.query("dialog"), null);
  assert.strictEqual(byLabel(p.section, "Zone name").value, "Unsaved draft");
  assert.match(p.notice().message.textContent, /Save or cancel the Zone details/);
  p.button("Cancel").listeners.click({});
  assert.ok(p.query("dialog"));
  assert.strictEqual(p.sent.length, 0);
});

test("native batch assignment can select an existing definition and closes its handoff on success", function () {
  var p = page(), payload = batchSnapshot();
  payload.sections["ph_composer.zones.faces.attached_zone.list"] = { status: "completed", value: {
    records: [{ id: "atz_existing", values: { name: "Garage" } }]
  } };
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  var dialog = p.query("dialog"), picker = byLabel(dialog, "Attached zone");
  picker.value = "atz_existing"; picker.listeners.change({});
  dialog.querySelector("form").listeners.submit({ preventDefault: function () {} });
  assert.strictEqual(p.sent[0].payload.name, "ph_composer.zones.faces.classify");
  assert.strictEqual(p.sent[0].payload.params.expected_values, undefined);
  assert.strictEqual(p.sent[0].payload.params.faces.length, 2);
  p.panel.receive({ type: "action.result", payload: { session: "session-a", request_id: p.sent[0].payload.request_id,
    outcome: { status: "completed", value: { face_ids: ["fac_a", "fac_b"] } } } });
  assert.strictEqual(p.query("dialog"), null);
  assert.strictEqual(p.sent[1].payload.name, "ph_composer.zones.faces.close_attached_assignment");
});

/* One Zone details draft at a time. While the form is dirty or its Save is pending, row
   selection, filtering and tab changes that would hide it are refused with a warning notice. */
function draftPage(payload) {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: payload || snapshot() });
  var section = p.query("[data-section='ph_composer.overview']");
  section.querySelector(".row-target").listeners.click({});
  p.section = section;
  p.notice = function () { return p.context.document.querySelector(".phc-floating-notice"); };
  p.button = function (text) {
    return section.closest("[data-pane]").querySelectorAll("button").filter(function (node) {
      return node.textContent === text;
    })[0];
  };
  p.selectedKey = function () {
    return section.querySelectorAll("[data-row-key]").filter(function (node) {
      return /host-selected/.test(node.className);
    }).map(function (node) { return node.getAttribute("data-row-key"); })[0];
  };
  return p;
}

function type(control, text) {
  control.value = text;
  control.listeners.input({});
}

function assertRefused(p, zoneKey, label, draft) {
  assert.strictEqual(p.selectedKey(), zoneKey, "the selection does not change");
  assert.strictEqual(p.notice().hidden, false);
  assert.strictEqual(p.notice().getAttribute("data-tone"), "warning");
  assert.match(p.notice().message.textContent, /Save or cancel the Zone details/);
  assert.strictEqual(byLabel(p.section, label).value, draft, "the draft and its controls stay");
  assert.ok(p.button("Save") && p.button("Cancel"));
  assert.strictEqual(p.sent.filter(function (m) { return m.type === "action.invoke"; }).length, 0);
}

test("a Zone details draft refuses the settings gear until it is cancelled", function () {
  var p = draftPage(), zoneKey = p.selectedKey(), gear = byLabel(p.section, "Zones / Faces settings");
  type(byLabel(p.section, "Zone name"), "Unsaved name");

  gear.listeners.click({});

  assertRefused(p, zoneKey, "Zone name", "Unsaved name");
  assert.strictEqual(gear.getAttribute("aria-expanded"), "false", "the settings bubble stays closed");
  p.button("Cancel").listeners.click({});
  gear.listeners.click({});
  assert.strictEqual(gear.getAttribute("aria-expanded"), "true");
});

test("a Zone details draft refuses selecting one of its Face rows", function () {
  [["Zone name", "Unsaved name"], ["Building-Segment", "annex"], ["Level", "L3"], ["Ground depth", "250"]]
    .forEach(function (pair) {
      var p = draftPage(), zoneKey = p.selectedKey();
      type(byLabel(p.section, pair[0]), pair[1]);

      p.section.querySelectorAll(".row-target")[1].listeners.click({});

      assertRefused(p, zoneKey, pair[0], pair[1]);
    });
});

test("a Zone details draft refuses selecting another Zone row", function () {
  var payload = snapshot(), overview = payload.sections["ph_composer.zones.overview"].value;
  overview.zones.push({ id: "zon_b", schema_version: 1, user_data: {}, extension_data: {},
    reference: { zone_id: "zon_b", zone_path: [300] }, state: "found", face_count: 0,
    values: { name: "Zone 2", building_segment: "house", level: null, ground_depth_mm: 0 } });
  var p = draftPage(payload), zoneKey = p.selectedKey();
  type(byLabel(p.section, "Zone name"), "Unsaved name");
  var other = p.section.querySelectorAll("[data-row-key]").map(function (node) {
    return node.getAttribute("data-row-key");
  }).indexOf(JSON.stringify(["Zone", [300]]));

  p.section.querySelectorAll(".row-target")[other].listeners.click({});

  assertRefused(p, zoneKey, "Zone name", "Unsaved name");
});

test("a Zone details draft refuses a filter change and a tab change", function () {
  var p = draftPage(), zoneKey = p.selectedKey(), filter = byLabel(p.section, "Filter Zones");
  type(byLabel(p.section, "Zone name"), "Unsaved name");

  type(filter, "nothing matches");
  assert.strictEqual(filter.value, "", "the filter keeps its value");
  assertRefused(p, zoneKey, "Zone name", "Unsaved name");

  p.query("[data-tab='export']").listeners.click({});
  assert.strictEqual(p.query("[data-pane='overview']").hidden, false);
  assertRefused(p, zoneKey, "Zone name", "Unsaved name");
  var tab = p.query("[data-tab='export']");
  p.context.document.activeElement = tab; // a real click leaves focus on the tab
  tab.listeners.click({});
  assert.ok(p.context.document.activeElement === p.button("Save"), "a refused tab change points at the form");
});

test("Cancel restores the stored values and unlocks navigation", function () {
  var p = draftPage();
  type(byLabel(p.section, "Zone name"), "Unsaved name");
  type(byLabel(p.section, "Ground depth"), "250");

  p.button("Cancel").listeners.click({});

  assert.strictEqual(byLabel(p.section, "Zone name").value, "Zone 1");
  assert.strictEqual(byLabel(p.section, "Ground depth").value, "0");
  p.section.querySelectorAll(".row-target")[1].listeners.click({});
  assert.notStrictEqual(p.selectedKey(), JSON.stringify(["Zone", [100]]));
  assert.strictEqual(byLabel(p.section, "Zone name"), undefined, "a Face row has no Zone details");
  assert.strictEqual(p.sent.length, 0);
});

test("a pending Save keeps the form and locks navigation; success unlocks it", function () {
  var p = draftPage(), zoneKey = p.selectedKey();
  type(byLabel(p.section, "Zone name"), "North Zone");
  zoneCard(p).listeners.submit({ preventDefault: function () {} });
  assert.strictEqual(p.sent.length, 1);
  assert.strictEqual(p.button("Cancel").disabled, true, "an in-flight Save cannot be cancelled");

  p.section.querySelectorAll(".row-target")[1].listeners.click({});
  assert.strictEqual(p.selectedKey(), zoneKey);
  assert.ok(p.button("Save"), "the pending request keeps its controls");

  p.panel.receive({ type: "action.result", payload: { request_id: p.sent[0].payload.request_id,
    session: "session-a", outcome: { status: "completed", value: { zone_id: "zon_a" } } } });
  p.section.querySelectorAll(".row-target")[1].listeners.click({});
  assert.notStrictEqual(p.selectedKey(), zoneKey);
  assert.strictEqual(p.sent.length, 1);
});

test("a refused Save keeps the draft locked and gives focus back to the form", function () {
  var p = draftPage(), zoneKey = p.selectedKey();
  type(byLabel(p.section, "Zone name"), "North Zone");
  zoneCard(p).listeners.submit({ preventDefault: function () {} });
  p.panel.receive({ type: "action.result", payload: { request_id: p.sent[0].payload.request_id,
    session: "session-a", outcome: { status: "refused", message: "The Zone changed." } } });

  p.section.querySelectorAll(".row-target")[1].listeners.click({});

  assert.strictEqual(p.selectedKey(), zoneKey);
  assert.strictEqual(byLabel(p.section, "Zone name").value, "North Zone");
  assert.strictEqual(p.context.document.activeElement, p.button("Save"));
});

test("switching Models withdraws a dirty Zone details draft", function () {
  var p = draftPage();
  type(byLabel(p.section, "Zone name"), "Unsaved name");
  var other = snapshot(); other.session = "session-b";

  p.panel.receive({ type: "panel.snapshot", payload: other });

  assert.strictEqual(byLabel(p.section, "Zone name"), undefined);
  assert.strictEqual(p.sent.length, 0);
});

test("inline create-and-assign reads the factor through the shared unit field", function () {
  var p = page(), dialog = attachedDialog(p), factor = byLabel(dialog, "Temperature reduction factor");
  assert.ok(factor.parentNode.className.includes("phc-unit-field"));
  factor.value = "1.1";
  dialog.querySelector("form").listeners.submit({ preventDefault: function () {} });
  assert.strictEqual(p.sent.length, 0);
  assert.ok(dialog.querySelector("[role='status']").textContent);
});

test("a Model switch brings the new session's control row, with the pane's tools still in it", function () {
  var p = page(), first = snapshot(), second = snapshot();
  p.panel.section("example.tool", function (root) { root.textContent = "tool"; }, { region: "tools" });
  p.panel.receive({ type: "panel.snapshot", payload: first });
  var section = p.query("[data-section='ph_composer.overview']"), tool = p.query("[data-section='example.tool']");
  var before = section.querySelector(".phc-inventory-controls");
  assert.strictEqual(tool.parentNode.parentNode, before, "the tools end the control row");
  second.session = "session-b";
  p.panel.receive({ type: "panel.snapshot", payload: second });
  var after = section.querySelector(".phc-inventory-controls");
  assert.notStrictEqual(after, before, "the new session's own controls are the ones on screen");
  assert.strictEqual(section.querySelectorAll(".phc-inventory-controls").length, 1);
  assert.strictEqual(p.query("[data-section='example.tool']"), tool);
  assert.strictEqual(tool.parentNode.parentNode, after);
});

test("a missing value is flagged on its cell, a Face row has nothing to expand, and State is gone", function () {
  var p = page(), payload = snapshot();
  var face = payload.sections["ph_composer.zones.faces.faces"].value.faces[0];
  delete face.values.boundary_condition;
  face.state = "incomplete";
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  var section = p.query("[data-section='ph_composer.overview']");
  var boundary = byLabel(section, "Set Wall 1 boundary");
  assert.ok(boundary, "the control names what is to be set");
  assert.deepStrictEqual([boundary.children[0].textContent, boundary.children[0].disabled], ["?", true]);
  assert.ok(boundary.parentNode.classList.contains("is-flagged"));
  assert.strictEqual(boundary.parentNode.title, "Boundary not set");
  assert.strictEqual(section.querySelector(".col-state"), null);
  var chevrons = section.querySelectorAll(".row-chevron");
  assert.deepStrictEqual(chevrons.map(function (node) { return node.classList.contains("is-leaf"); }),
    [false, true, false], "the Zone and its unclassified summary open; a recorded Face does not");

  // Filling the "?" rebuilds the control without it, and the focus stays on the cell.
  boundary.focus();
  face.values.boundary_condition = "Outdoors";
  face.state = "classified";
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  var filled = byLabel(section, "Wall 1 boundary");
  assert.strictEqual(filled.value, "Outdoors");
  assert.strictEqual(p.context.document.activeElement, filled);
  assert.strictEqual(filled.parentNode.classList.contains("is-flagged"), false);
});

test("what the old State column said about a boundary is said on the boundary cell", function () {
  var p = page(), payload = snapshot();
  var face = payload.sections["ph_composer.zones.faces.faces"].value.faces[0];
  face.values.boundary_condition = "Surface";
  face.adjacency_state = "stale";
  face.state = "incomplete";
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  var section = p.query("[data-section='ph_composer.overview']");
  var cell = section.querySelectorAll("td").filter(function (td) {
    return /col-boundary_condition/.test(td.className);
  })[1];
  assert.strictEqual(cell.querySelector(".phc-enum-pill").textContent, "Surface", "a paired Face stays read only");
  assert.ok(cell.classList.contains("is-flagged"));
  assert.match(cell.title, /out of date/);

  face.values.boundary_condition = "AttachedZone";
  face.adjacency_state = null;
  face.attached_zone_state = "dangling";
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  assert.ok(cell.classList.contains("is-flagged"));
  assert.match(cell.title, /Attached zone record is missing/);
});

test("a Zone with no Faces at all offers nothing to expand", function () {
  var p = page(), payload = snapshot();
  payload.sections["ph_composer.zones.faces.faces"].value.faces = [];
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  var chevrons = p.query("[data-section='ph_composer.overview']").querySelectorAll(".row-chevron");
  assert.deepStrictEqual(chevrons.map(function (node) { return node.classList.contains("is-leaf"); }), [true]);
});

test("a blocked Make Zone says why beside it", function () {
  var p = page(), payload = snapshot();
  payload.sections["ph_composer.zones.overview"].value.make_zone = null;
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  var reason = p.query("[data-section='ph_composer.overview']").querySelector(".phc-blocked-reason");
  assert.strictEqual(reason.getAttribute("aria-label"), "Why Make Zone is unavailable");
  reason.listeners.click({});
  var bubble = reason.parentNode.querySelector(".phc-bubble");
  assert.strictEqual(bubble.hidden, false, "the reason opens beside the action, not as a page notice");
  assert.ok(/needs one Group, or loose Faces and Edges/.test(bubble.querySelector(".phc-blocked-reason-text")
    .textContent));
  var notice = p.query(".phc-floating-notice");
  assert.ok(!notice || notice.hidden, "and raises no page notice");
  payload.sections["ph_composer.zones.overview"].value.make_zone = { entity_path: [1] };
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  assert.strictEqual(p.query("[data-section='ph_composer.overview']").querySelector(".phc-blocked-reason"), null);
});

test("a Face that gains a record moves up under its Zone and lines up there; Undo moves it back", function () {
  var p = page(), payload = snapshot();
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  var section = p.query("[data-section='ph_composer.overview']");
  var key = JSON.stringify(["Face", [100], [102]]);
  function row() {
    return section.querySelectorAll("[data-row-key]").filter(function (node) {
      return node.getAttribute("data-row-key") === key;
    })[0];
  }
  var unclassified = row();
  assert.ok(/tier-2/.test(unclassified.className));
  assert.strictEqual(unclassified.querySelector(".row-chevron"), null, "a row under the summary has no chevron");

  var faces = payload.sections["ph_composer.zones.faces.faces"].value.faces;
  faces[1].state = "classified";
  faces[1].reference.entity_id = "fac_b";
  faces[1].values = { face_type: "Floor", boundary_condition: "Ground" };
  payload.sections["ph_composer.zones.faces.assemblies"] = { status: "completed", value: { assemblies: [] } };
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  assert.strictEqual(row(), unclassified, "the same row, so selection and focus go with it");
  assert.ok(/tier-1/.test(unclassified.className));
  var chevron = unclassified.querySelector(".row-chevron");
  assert.ok(chevron && chevron.classList.contains("is-leaf") && !chevron.hidden,
    "it takes the chevron's place its neighbours keep, so its label lines up");

  faces[1].state = "unclassified";
  faces[1].reference.entity_id = null;
  faces[1].values = {};
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  assert.ok(/tier-2/.test(row().className));
  assert.strictEqual(row().querySelector(".row-chevron").hidden, true);
});

test("Expand all and Collapse all reach the unclassified summary, and the filter finds unclassified", function () {
  var p = page(), payload = snapshot();
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  var section = p.query("[data-section='ph_composer.overview']");
  function count() {
    return section.querySelectorAll("[data-row-key]").filter(function (node) { return !node.hidden; }).length;
  }
  function byText(root, text) {
    return root.querySelectorAll("button").filter(function (node) { return node.textContent === text; })[0];
  }
  assert.strictEqual(count(), 4);
  byText(section, "Collapse all").listeners.click({});
  assert.strictEqual(count(), 1);
  byText(section, "Expand all").listeners.click({});
  assert.strictEqual(count(), 4);
  var filter = byLabel(section, "Filter Zones");
  filter.value = "unclassified";
  filter.listeners.input({});
  assert.strictEqual(count(), 4, "a Zone with unclassified Faces matches the word");
});

test("Order by and its direction order a Zone's Faces too, so one Zone still answers them", function () {
  var p = page(), payload = snapshot(), faces = payload.sections["ph_composer.zones.faces.faces"].value.faces;
  faces.push({ reference: { zone_id: "zon_a", zone_path: [100], entity_path: [103], entity_id: "fac_c" },
    zone_name: "Zone 1", area_m2: 30, state: "classified", values: { face_type: "Floor", boundary_condition: "Ground" },
    suggested: {} });
  p.panel.receive({ type: "panel.snapshot", payload: payload });
  var section = p.query("[data-section='ph_composer.overview']");
  function names() {
    return section.querySelectorAll("td").filter(function (td) { return /col-name/.test(td.className); })
      .map(function (td) { return td.textContent; });
  }
  // By name, Faces keep their place numbers in order, so choosing a type never moves a row; the
  // unclassified summary stays last.
  assert.deepStrictEqual(names(), ["Zone 1", "Wall 1", "Floor 3", "1 unclassified Face", "Face 2"]);
  byLabel(section, "Sort descending").listeners.click({});
  assert.deepStrictEqual(names(), ["Zone 1", "Floor 3", "Wall 1", "1 unclassified Face", "Face 2"]);
  var order = byLabel(section, "Order by");
  order.value = "area_m2";
  order.listeners.change({});
  assert.deepStrictEqual(names(), ["Zone 1", "Floor 3", "Wall 1", "1 unclassified Face", "Face 2"],
    "largest first");
  byLabel(section, "Sort ascending").listeners.click({});
  assert.deepStrictEqual(names(), ["Zone 1", "Wall 1", "Floor 3", "1 unclassified Face", "Face 2"]);
});

test("the header groups the authoring tools apart from Colour by, and the inspector column always stands", function () {
  var p = page();
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });
  var section = p.query("[data-section='ph_composer.overview']");
  var toolbar = section.querySelector("[role='toolbar']");
  assert.strictEqual(toolbar.getAttribute("aria-label"), "Zone and Face tools");
  assert.ok(byLabel(section, "Solve adjacencies for all Zones in this Model").parentNode === toolbar);
  var inspector = p.query("[data-phc-region='inspector']");
  assert.strictEqual(inspector.hidden, false,
    "with nothing selected the column still stands, so the tree keeps its width");
  assert.strictEqual(p.query("[data-section='ph_composer.zones.hint']").hidden, false);
  var header = section.querySelector(".phc-heading");
  p.panel.receive({ type: "panel.snapshot", payload: snapshot() });
  assert.ok(section.querySelector(".phc-heading") === header, "the header is repainted in place, not rebuilt");
});
