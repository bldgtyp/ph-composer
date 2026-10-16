"use strict";

/* Create Space's review in the panel: what the context menu handed over opens in the shared dialog, Create
   sends `create` with the accepted Faces at the review's revision, Cancel sends nothing, a refusal stays in
   the dialog, and the review is closed by its own token. */

var assert = require("assert");
var test = require("node:test");
var dom = require("./support/dom_stub");
var panelSource = require("./support/panel_source");
var fixture = require("./support/spaces_fixture");

var ZONE = { zone_id: "zon_AAAAAAAAAAAA", zone_path: [100] };

function face(id) { return { zone_id: ZONE.zone_id, zone_path: [100], entity_path: [id], entity_id: null }; }

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
  var p = { context: context, panel: modules.panel, sent: sent };
  p.receive = function (state) { p.panel.receive({ type: "panel.snapshot", payload: state }); };
  p.dialog = function () {
    return context.document.querySelectorAll("dialog").filter(function (node) {
      return /phc-create-space/.test(node.className);
    })[0];
  };
  p.button = function (text) {
    return p.dialog().querySelectorAll("button").filter(function (node) { return node.textContent === text; })[0];
  };
  p.input = function (label) {
    return p.dialog().querySelectorAll("input").filter(function (node) {
      return node.getAttribute("aria-label") === label;
    })[0];
  };
  // The DOM stub keeps each element's own text, so the dialog's text is gathered from its elements.
  p.text = function () {
    return p.dialog().querySelectorAll("h2, p, li, div").map(function (node) { return node.textContent; }).join("\n");
  };
  p.click = function (node) { node.listeners.click({ preventDefault: function () {} }); };
  p.type = function (input, text) {
    input.value = text;
    if (input.listeners.input) input.listeners.input({ target: input });
  };
  p.messages = function (type) { return sent.filter(function (message) { return message.type === type; }); };
  p.result = function (message, outcome) {
    p.panel.receive({ type: message.type === "view.invoke" ? "view.result" : "action.result",
      payload: { request_id: message.payload.request_id, session: "session-a", outcome: outcome } });
  };
  return p;
}

function snapshot(review) {
  return {
    product: "PH-Composer", version: "0.1.0-dev", session: "session-a", revision: 6, file_name: "house.skp",
    edit_path: [100], preferences: { unit_system: "SI", dimension_formats: {}, number_format: { decimal: ".",
      locale: "en-US" }, table_views: { "ph_composer.zones": "ph_composer.spaces" } },
    sections: {
      "ph_composer.zones.overview": { status: "completed", value: { zones: fixture.zones(), make_zone: null,
        units: {} } },
      "ph_composer.spaces.spaces": { status: "completed", value: fixture.section() },
      "ph_composer.spaces.create_review": { status: "completed", value: review || { token: null, revision: null,
        zone: null, zone_name: "", accepted: [], left_out: [] } }
    }
  };
}

function review(accepted) {
  return { token: "review-1", revision: 5, zone: ZONE, zone_name: "Living Zone",
    accepted: accepted === undefined ? [face(1200), face(1210)] : accepted,
    left_out: [{ reference: face(1300), reason: "target.changed", message: "The Face is one of the Zone's own." },
      { reference: face(1301), reason: "target.changed", message: "The Face is one of the Zone's own." },
      { reference: face(1400), reason: "shares_edge", message: "The Face shares an Edge with an unselected Face." }] };
}

test("a review opens in the shared dialog, saying what is accepted and why each other Face is left out", function () {
  var p = page();
  p.receive(snapshot(review()));
  var dialog = p.dialog();
  assert.ok(dialog && !dialog.hidden);
  assert.strictEqual(dialog.querySelector("h2").textContent, "Create Space");
  var text = p.text();
  assert.match(text, /2 Faces in Living Zone become one Space with one Volume/);
  assert.match(text, /2 Faces: The Face is one of the Zone's own\./);
  assert.match(text, /1 Face: The Face shares an Edge/);
  assert.strictEqual(p.input("Number").getAttribute("placeholder"), "Next free");
});

test("Create sends create with the accepted Faces at the review's revision, and Enter does the same", function () {
  var p = page();
  p.receive(snapshot(review()));
  p.type(p.input("Name"), " Living ");
  p.input("Name").listeners.keydown({ key: "Enter", preventDefault: function () {} });
  var sent = p.messages("action.invoke");
  assert.strictEqual(sent.length, 1);
  assert.strictEqual(sent[0].payload.name, "ph_composer.spaces.create");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(sent[0].payload.params)),
    { zone: ZONE, faces: [face(1200), face(1210)], name: "Living" });
  assert.strictEqual(sent[0].payload.expected_revision, 5);
  p.click(p.button("Create"));
  assert.strictEqual(p.messages("action.invoke").length, 1, "one create in flight");
});

test("a refused create stays in the dialog; a completed one closes it and the review by its token", function () {
  var p = page();
  p.receive(snapshot(review()));
  p.type(p.input("Number"), "104");
  p.click(p.button("Create"));
  var create = p.messages("action.invoke")[0];
  assert.strictEqual(create.payload.params.number, "104");
  p.result(create, { status: "refused", code: "revision.stale", message: "The Model changed. Nothing was written." });
  assert.ok(!p.dialog().hidden);
  assert.match(p.text(), /The Model changed/);
  p.click(p.button("Create"));
  p.result(p.messages("action.invoke")[1], { status: "completed", message: "Created Space 104." });
  assert.ok(p.dialog().hidden);
  var close = p.messages("view.invoke").filter(function (message) {
    return message.payload.name === "ph_composer.spaces.create_review.close";
  });
  assert.deepStrictEqual(close.map(function (message) { return message.payload.params.token; }), ["review-1"]);
});

test("Cancel writes nothing and closes the review; with nothing accepted Create is unavailable", function () {
  var p = page();
  p.receive(snapshot(review([])));
  assert.match(p.text(), /None of the selected Faces can become a Space/);
  assert.strictEqual(p.button("Create").disabled, true);
  p.click(p.button("Cancel"));
  assert.ok(p.dialog().hidden);
  assert.strictEqual(p.messages("action.invoke").length, 0);
  assert.strictEqual(p.messages("view.invoke").filter(function (message) {
    return message.payload.name === "ph_composer.spaces.create_review.close";
  }).length, 1);
  p.receive(snapshot(review([])));
  assert.ok(p.dialog().hidden, "the same review does not reopen");
});
