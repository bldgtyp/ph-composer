"use strict";

/* The synthetic editor (tools/examples/foundation/editor.js) on the real panel and the preview's stand-in
   host: typed entry with suffixes, invalid input kept with its message, regional numbers, a draft that
   keeps its starting unit through a display switch, Save and Cancel in the New part form, and a refused
   edit that leaves the Model's value in the field (Units A1, A4 to A6, A10, A15). */

var assert = require("assert");
var fs = require("fs");
var path = require("path");
var test = require("node:test");
var vm = require("vm");
var dom = require("./support/dom_stub");
var panelSource = require("./support/panel_source");

var root = require("./support/panel_files").root;
var PARTS = [
  { id: "exp_Aa11Bb22Cc33", label: "Sill", length_mm: 1200 },
  { id: "exp_Dd44Ee55Ff66", label: "Head", length_mm: 1231.9 }
];

function run(context, relative) {
  var file = path.join(root, relative);
  vm.runInContext(fs.readFileSync(file, "utf8"), context, { filename: file });
}

function editor(options) {
  var context = {
    document: dom.buildDocument(panelSource.markup("index.html")), Intl: Intl, innerWidth: 1280,
    innerHeight: 800, setTimeout: setTimeout, clearTimeout: clearTimeout, JSON: JSON
  };
  context.window = context;
  dom.attachEvents(context);
  vm.createContext(context);
  panelSource.start(context, ["sections/shell", "sections/export", "request", "snapshot", "record_form",
    "unit_field"]);
  run(context, "tools/ui-preview/host.js");
  var host = context.PhComposerPreviewHost.install(context, Object.assign({ parts: PARTS }, options));
  context.PhComposerUI.get("panel").ready();
  run(context, "tools/examples/foundation/editor.js");
  var section = context.document.querySelector("[data-section='example.foundation.editor']");
  function input(label) {
    return section.querySelectorAll("input").filter(function (node) {
      return node.getAttribute("aria-label") === label;
    })[0];
  }
  return {
    context: context, host: host, section: section, input: input,
    preferences: context.PhComposerUI.get("unit_preferences"),
    type: function (label, text) { var node = input(label); node.value = text; node.listeners.input({}); },
    press: function (label, key) { input(label).listeners.keydown({ key: key, preventDefault: function () {} }); },
    invokes: function () { return host.sent.filter(function (message) { return message.type === "action.invoke"; }); },
    notice: function () { return context.document.querySelector(".phc-floating-notice"); }
  };
}

test("each part shows its stored length in the display unit, and an edit is one update", function () {
  var e = editor();
  assert.strictEqual(e.input("Sill length").value, "1200");
  e.type("Sill length", "4 ft");
  e.press("Sill length", "Enter");

  var sent = e.invokes()[0].payload;
  assert.strictEqual(sent.name, "example.foundation.update_parts");
  assert.deepStrictEqual(JSON.parse(JSON.stringify(sent.params)), { edits: [{ id: "exp_Aa11Bb22Cc33",
    values: { length_mm: 1219.2 }, expected_values: { length_mm: 1200 } }] });
  assert.strictEqual(sent.expected_revision, 1);
  assert.strictEqual(e.host.parts[0].length_mm, 1219.2);
  assert.strictEqual(e.input("Sill length").value, "1219.2", "repainted from the Model's value");
});

test("an invalid entry keeps its text and message and sends nothing", function () {
  var e = editor();
  e.type("Sill length", "2 kg");
  e.press("Sill length", "Enter");

  var node = e.input("Sill length");
  assert.strictEqual(node.value, "2 kg");
  assert.strictEqual(node.getAttribute("aria-invalid"), "true");
  var error = e.section.querySelectorAll(".phc-unit-error").filter(function (item) { return !item.hidden; })[0];
  assert.strictEqual(error.textContent, "Expected a length; kg is a mass unit.");
  assert.strictEqual(e.invokes().length, 0);
});

test("a draft keeps its starting unit through a display switch until Enter, and stores SI", function () {
  var e = editor();
  e.type("Head length", "1300");
  e.context.document.querySelector("[data-unit-system='IP']").listeners.click({});

  assert.strictEqual(e.input("Head length").value, "1300", "the draft text is untouched");
  assert.strictEqual(e.input("Sill length").value, "47.244094", "a field at rest repaints in inches");
  e.press("Head length", "Enter");
  assert.strictEqual(e.host.parts[1].length_mm, 1300, "an unsuffixed draft commits in the unit it began in");
  assert.strictEqual(e.input("Head length").value, "51.181102");
});

test("a switch writes nothing to the Model and a repaint never writes a rounded value back", function () {
  var e = editor();
  e.context.document.querySelector("[data-unit-system='IP']").listeners.click({});
  e.context.document.querySelector("[data-unit-system='SI']").listeners.click({});
  e.input("Head length").listeners.blur({});

  assert.strictEqual(e.invokes().length, 0);
  assert.strictEqual(e.host.revision, 1);
  assert.strictEqual(e.host.parts[1].length_mm, 1231.9);
});

test("regional numbers are read and shown in the computer's own format", function () {
  var e = editor({ locale: "de-DE", decimal: "," });
  assert.strictEqual(e.input("Head length").value, "1231,9");
  e.type("Head length", "1.234,5");
  e.press("Head length", "Enter");
  assert.strictEqual(e.host.parts[1].length_mm, 1234.5);
});

test("the dimension format is the editor's own and survives a switch to IP and back", function () {
  var e = editor();
  var cm = e.section.querySelector("[data-dimension-format='cm']");
  cm.listeners.click({});
  assert.strictEqual(e.input("Sill length").value, "120");
  assert.strictEqual(e.host.preferences.dimension_formats["example.foundation.editor"].SI, "cm");
  e.context.document.querySelector("[data-unit-system='IP']").listeners.click({});
  e.context.document.querySelector("[data-unit-system='SI']").listeners.click({});
  assert.strictEqual(e.input("Sill length").value, "120");
});

test("New part saves a suffixed length in SI; Cancel closes without sending", function () {
  var e = editor();
  var form = e.section.querySelector(".phc-form-dialog");
  var create = e.section.querySelectorAll("button").filter(function (node) {
    return node.textContent === "New part";
  })[0];
  create.listeners.click({});
  assert.strictEqual(form.hidden, false);
  var cancel = form.querySelectorAll("button").filter(function (node) { return node.textContent === "Cancel"; })[0];
  cancel.listeners.click({});
  assert.strictEqual(form.hidden, true);
  assert.strictEqual(e.invokes().length, 0);

  create.listeners.click({});
  var length = form.querySelectorAll("input").filter(function (node) {
    return node.getAttribute("aria-label") === "Length";
  })[0];
  length.value = "3 ft";
  length.listeners.input({});
  form.querySelector("form").listeners.submit({ preventDefault: function () {} });

  assert.strictEqual(e.invokes()[0].payload.params.parts[0].length_mm, 914.4);
  assert.strictEqual(form.hidden, true, "a completed create closes the form");
  assert.strictEqual(e.host.parts.length, 3);
  assert(e.input("Part length"), "the new part has its own field");
});

test("a refused edit leaves the Model's value in the field and a warning on screen", function () {
  var e = editor();
  e.host.parts[0].length_mm = 1500;
  e.type("Sill length", "1300");
  e.press("Sill length", "Enter");

  assert.strictEqual(e.invokes()[0].payload.params.edits[0].expected_values.length_mm, 1200);
  assert.strictEqual(e.notice().getAttribute("data-tone"), "warning");
  assert.match(e.notice().message.textContent, /Nothing was written\.$/);
  assert.strictEqual(e.input("Sill length").value, "1500", "the next snapshot repaints what the Model holds");
});

test("a Model switch during a draft sends nothing to either Model", function () {
  var e = editor();
  var head = e.input("Head length");
  e.type("Head length", "13");
  e.host.session = "preview-session-b";
  e.host.revision = 1;
  e.host.snapshot();
  head.listeners.blur({});

  assert.strictEqual(e.invokes().length, 0);
  assert.strictEqual(e.host.parts[1].length_mm, 1231.9);
});

test("a part removed elsewhere leaves the focused draft where it is, untouched and unsent", function () {
  var e = editor();
  var head = e.input("Head length"), row = head.parentNode.parentNode;
  e.type("Head length", "13");
  e.host.parts.shift();
  e.host.revision += 1;
  e.host.snapshot();

  assert.strictEqual(e.section.querySelector(".example-parts").children[0], row, "the row was not moved");
  assert.strictEqual(e.input("Head length").value, "13");
  assert.strictEqual(e.input("Sill length"), undefined);
  assert.strictEqual(e.invokes().length, 0);
});
