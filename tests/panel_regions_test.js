"use strict";

/* A pane's regions: `main`, an `inspector` that shows one section at a time, `tools` the work surface
   places in its own control row and `actions` its page header places in the authoring toolbar. */

var assert = require("assert");
var test = require("node:test");
var dom = require("./support/dom_stub");
var panelSource = require("./support/panel_source");

function page() {
  var context = {
    document: dom.buildDocument(panelSource.markup("index.html")), Intl: Intl,
    innerWidth: 1280, innerHeight: 800, setTimeout: setTimeout, clearTimeout: clearTimeout,
    sketchup: { ph_composer_message: function () {} }
  };
  context.window = context;
  dom.attachEvents(context);
  var panel = panelSource.start(context, ["panel"]).panel;
  function snapshot() {
    panel.receive({ type: "panel.snapshot", payload: { product: "PH-Composer", version: "0.1.0-dev",
      session: "session-a", revision: 1, file_name: "house.skp", edit_path: [], sections: {},
      preferences: { unit_system: "SI", dimension_formats: {}, number_format: { decimal: ".", locale: "en-US" } } } });
  }
  return { panel: panel, snapshot: snapshot, document: context.document,
    query: function (selector) { return context.document.querySelector(selector); } };
}

function paint(text) { return function (root) { root.textContent = text; }; }

test("a pane with only main sections keeps its sections as direct children", function () {
  var p = page();
  p.panel.section("example.work", paint("work"), { order: 10 });
  p.snapshot();
  assert.strictEqual(p.query("[data-section='example.work']").parentNode, p.query("[data-pane='overview']"));
  assert.strictEqual(p.query("[data-phc-region]"), null);
});

test("an inspector shows the first section, in order, that has something to show", function () {
  var p = page(), wants = { tool: false, selection: true };
  p.panel.section("example.work", paint("work"), { order: 10 });
  p.snapshot();
  p.panel.section("example.selection", paint("selection"), { region: "inspector", tier: "selection",
    when: function () { return wants.selection; } });
  p.panel.section("example.tool", paint("tool"), { region: "inspector", tier: "tool",
    when: function () { return wants.tool; } });
  var work = p.query("[data-section='example.work']"), inspector = p.query("[data-phc-region='inspector']");
  var tool = p.query("[data-section='example.tool']"), selection = p.query("[data-section='example.selection']");
  assert.strictEqual(work.parentNode.getAttribute("data-phc-region"), "main", "what was there becomes main");
  assert.deepStrictEqual([tool.hidden, selection.hidden, inspector.hidden], [true, false, false]);
  assert.strictEqual(tool.textContent, "tool", "a hidden section still renders, to consume its results");
  wants.tool = true;
  p.panel.repaint();
  assert.deepStrictEqual([tool.hidden, selection.hidden], [false, true],
    "a tool in use outranks a selection, whatever order they registered in");
  wants.tool = wants.selection = false;
  p.panel.repaint();
  assert.strictEqual(inspector.hidden, true, "nothing to show, no column");
});

test("tools lead the main region until the work surface places them", function () {
  var p = page();
  p.panel.section("example.work", function (root) {
    if (root.firstChild) return;
    root.appendChild(dom.element("div"));
    root.firstChild.appendChild(p.panel.region("overview", "tools"));
  }, { order: 10 });
  p.panel.section("example.toggle", paint("toggle"), { region: "tools" });
  p.snapshot();
  var tools = p.query("[data-phc-region='tools']");
  assert.strictEqual(p.query("[data-section='example.toggle']").parentNode, tools);
  assert.strictEqual(tools.parentNode.parentNode, p.query("[data-section='example.work']"));
  assert.strictEqual(p.panel.region("overview", "tools"), tools, "asking again returns the same node");
});

test("authoring actions are a region of their own that the page header places, apart from tools", function () {
  var p = page();
  p.panel.section("example.work", function (root) {
    if (root.firstChild) return;
    root.appendChild(dom.element("div"));
    root.firstChild.appendChild(p.panel.region("overview", "actions"));
  }, { order: 10 });
  p.panel.section("example.author", paint("author"), { region: "actions" });
  p.snapshot();
  var actions = p.query("[data-phc-region='actions']");
  assert.ok(actions.classList.contains("phc-pane-actions"));
  assert.ok(p.query("[data-section='example.author']").parentNode === actions);
  assert.ok(p.query("[data-phc-region='tools']") === null, "no tools region until a section asks for one");
});

test("a section that holds keeps the inspector over a higher tier, and focus follows what is shown", function () {
  var p = page(), wants = { tool: false, record: "hold" }, input = dom.element("input");
  p.panel.section("example.record", function (root) { if (!root.firstChild) root.appendChild(input); },
    { region: "inspector", tier: "record", when: function () { return wants.record; } });
  p.panel.section("example.tool", paint("tool"), { region: "inspector", tier: "tool",
    when: function () { return wants.tool; } });
  p.snapshot();
  var record = p.query("[data-section='example.record']"), tool = p.query("[data-section='example.tool']");
  input.focus();
  wants.tool = true;
  p.panel.repaint();
  assert.deepStrictEqual([record.hidden, tool.hidden], [false, true], "a held draft is not hidden by a tool");
  wants.record = true;
  p.panel.repaint();
  assert.deepStrictEqual([record.hidden, tool.hidden], [true, false]);
  assert.strictEqual(p.document.activeElement, tool, "focus moves out of the hidden section");
});

test("an unknown region, an inspector without a tier and an unknown tier are refused by name", function () {
  var p = page();
  assert.throws(function () { p.panel.section("example.a", paint(""), { region: "inpsector" }); },
    /no region "inpsector"/);
  assert.throws(function () { p.panel.section("example.b", paint(""), { region: "inspector" }); }, /needs a tier/);
  assert.throws(function () { p.panel.section("example.c", paint(""), { region: "inspector", tier: "first" }); },
    /needs a tier/);
  assert.throws(function () { p.panel.region("overview", "sidebar"); }, /no pane region "sidebar"/);
});
