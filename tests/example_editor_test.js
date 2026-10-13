"use strict";

/* The synthetic editor (tools/examples/foundation/editor.js) on the real panel and the preview's stand-in
   host: typed entry with suffixes, invalid input kept with its message, regional numbers, a draft that
   keeps its starting unit through a display switch, Save and Cancel in the New part form, and a refused
   edit that leaves the Model's value in the field. */

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
  // Test-only: every record form the editor builds, so a test can hold a retired form's methods.
  var RecordForm = context.PhComposerUI.get("record_form"), forms = [], finish = RecordForm.prototype.finish;
  RecordForm.prototype.finish = function () { forms.push(this); return finish.apply(this, arguments); };
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
    context: context, host: host, section: section, input: input, forms: forms,
    preferences: context.PhComposerUI.get("unit_preferences"),
    type: function (label, text) { var node = input(label); node.value = text; node.listeners.input({}); },
    press: function (label, key) { input(label).listeners.keydown({ key: key, preventDefault: function () {} }); },
    // Through the real capture and bubble path, so an ancestor's capture listener runs as in the host.
    dispatch: function (label, key) { return dom.dispatch(input(label), { type: "keydown", key: key }); },
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

test("a value changed elsewhere during a draft refuses the draft instead of overwriting the change", function () {
  var e = editor();
  e.type("Sill length", "1300");
  e.host.parts[0].length_mm = 1500;
  e.host.revision += 1;
  e.host.snapshot();
  e.press("Sill length", "Enter");

  assert.strictEqual(e.invokes()[0].payload.params.edits[0].expected_values.length_mm, 1200);
  assert.strictEqual(e.host.parts[0].length_mm, 1500, "the other change stands");
  assert.strictEqual(e.notice().getAttribute("data-tone"), "warning");
  assert.strictEqual(e.input("Sill length").value, "1500");
});

/* The New part dialog through its real routes: Enter in either field, the Create button, a pending create,
   and a Model switch that must retire the old form and everything still holding it. */
function newPart(e) {
  var form = e.section.querySelector(".phc-form-dialog");
  var button = function (root, text) {
    return root.querySelectorAll("button").filter(function (node) { return node.textContent === text; })[0];
  };
  return {
    form: form,
    open: function () { button(e.section, "New part").listeners.click({}); },
    fill: function (label, length) {
      var labelInput = form.querySelectorAll("input")[0];
      labelInput.value = label;
      e.type("Length", length);
    },
    // The Create button is the form's submit button, so its click is the form's submit event.
    create: function () { form.querySelector("form").listeners.submit({ preventDefault: function () {} }); },
    cancel: function () { button(form, "Cancel").listeners.click({}); },
    labelInput: function () { return form.querySelectorAll("input")[0]; }
  };
}

var IP = { unit_system: "IP", dimension_formats: {}, number_format: { decimal: ".", locale: "en-US" } };

function creates(e) {
  return e.invokes().filter(function (message) { return message.payload.name === "example.foundation.create_parts"; });
}

/* Holds the host's answers until `release`, so a create can be observed while it is pending. */
function holdHost(e) {
  var held = [], invoke = e.host.invoke;
  e.host.invoke = function (payload) { held.push(payload); };
  return { release: function () {
    e.host.invoke = invoke;
    held.splice(0).forEach(function (payload) { invoke.call(e.host, payload); });
  } };
}

test("Enter at Length creates the part once through the form's submit", function () {
  var e = editor(), d = newPart(e);
  d.open();
  d.fill("Jamb", "3 ft");
  var event = e.dispatch("Length", "Enter");

  assert.strictEqual(event.defaultPrevented, true);
  assert.strictEqual(creates(e).length, 1);
  assert.strictEqual(creates(e)[0].payload.params.parts[0].length_mm, 914.4);
  assert.strictEqual(d.form.hidden, true, "a completed create closes the form");
  assert.strictEqual(e.host.parts.length, 3);
  assert(e.input("Jamb length"), "the new part has its own field");
});

test("Create, Enter at Length and Enter at Label send the same create, once each", function () {
  var params = ["create", "length", "label"].map(function (route) {
    var e = editor(), d = newPart(e);
    d.open();
    d.fill("Jamb", "3 ft");
    if (route === "create") d.create();
    if (route === "length") e.dispatch("Length", "Enter");
    if (route === "label") {
      // Enter in a plain text input is the browser's implicit submission: a submit event on the form.
      dom.dispatch(d.labelInput(), { type: "keydown", key: "Enter" });
      d.form.querySelector("form").listeners.submit({ preventDefault: function () {} });
    }
    assert.strictEqual(creates(e).length, 1, route);
    return JSON.parse(JSON.stringify(creates(e)[0].payload.params));
  });
  assert.deepStrictEqual(params[1], params[0]);
  assert.deepStrictEqual(params[2], params[0]);
});

test("a blank label or an unusable length creates nothing and Cancel still closes", function () {
  [["", "3 ft"], ["Jamb", "0"], ["Jamb", "-2"], ["Jamb", "2 kg"]].forEach(function (draft) {
    var e = editor(), d = newPart(e);
    d.open();
    d.fill(draft[0], draft[1]);
    e.dispatch("Length", "Enter");
    assert.strictEqual(creates(e).length, 0, draft.join(" "));
    assert.strictEqual(d.form.hidden, false, draft.join(" "));
    d.cancel();
    assert.strictEqual(d.form.hidden, true, draft.join(" "));
  });
});

test("Enter while a create is pending sends no second create, and the result settles once", function () {
  var e = editor(), d = newPart(e), host = holdHost(e);
  d.open();
  d.fill("Jamb", "3 ft");
  e.dispatch("Length", "Enter");
  e.dispatch("Length", "Enter");
  d.create();
  assert.strictEqual(creates(e).length, 1);
  host.release();
  assert.strictEqual(e.host.parts.length, 3);
  assert.strictEqual(d.form.hidden, true);
});

function switchModel(e) {
  e.host.session = "preview-session-b";
  e.host.revision = 1;
  e.host.snapshot();
}

test("a Model switch ends the old form's length field subscription and the new one repaints", function () {
  var e = editor(), old = newPart(e);
  var oldLength = old.form.querySelectorAll("input")[1];
  switchModel(e);
  var fresh = newPart(e);
  var newLength = fresh.form.querySelectorAll("input")[1];
  assert.notStrictEqual(newLength, oldLength);
  oldLength.value = "untouched";
  e.preferences.replace(IP, {});
  assert.strictEqual(oldLength.value, "untouched", "the old input is not repainted");
  assert.notStrictEqual(newLength.value, "1000", "the active input follows the switch");
});

test("an old form's retained submit, run, show and Enter route send nothing after a Model switch", function () {
  var e = editor(), d = newPart(e);
  var form = d.form, old = e.forms[e.forms.length - 1];
  var retained = { submit: old.submit.bind(old), run: old.run.bind(old), show: old.show.bind(old) };
  d.open();
  d.fill("Jamb", "3 ft");
  d.cancel();
  var routes = form.querySelector("form").listeners;
  var lengthInput = form.querySelectorAll("input")[1];
  var header = e.section.querySelectorAll("button").filter(function (node) {
    return node.textContent === "New part";
  })[0];
  switchModel(e);

  routes.submit({ preventDefault: function () {} });
  dom.dispatch(lengthInput, { type: "keydown", key: "Enter" });
  header.listeners.click({});
  retained.submit();
  assert.strictEqual(retained.run({ definition_label: "Example", parts: [{ label: "Jamb", length_mm: 914.4 }] }),
    false);
  retained.show();
  assert.strictEqual(e.invokes().length, 0);
  assert.strictEqual(form.hidden, true, "the old dialog stays closed");
  assert.strictEqual(newPart(e).form.hidden, true, "the new dialog was not opened by the old header");
});

test("a create pending across a Model switch settles nowhere and the new form creates once", function () {
  var e = editor(), d = newPart(e), host = holdHost(e);
  d.open();
  d.fill("Jamb", "3 ft");
  e.dispatch("Length", "Enter");
  switchModel(e);
  host.release();
  assert.strictEqual(e.host.parts.length, 2, "the old Model's create was refused by session");

  var fresh = newPart(e);
  fresh.open();
  fresh.fill("Head", "2 ft");
  e.dispatch("Length", "Enter");
  assert.strictEqual(creates(e).length, 2);
  assert.strictEqual(e.host.parts.length, 3);
  assert.strictEqual(fresh.form.hidden, true);
});

test("after several Model switches only the active form's field follows preferences and it creates once", function () {
  var e = editor(), retired = [];
  ["b", "c", "d"].forEach(function (name) {
    retired.push(newPart(e).form.querySelectorAll("input")[1]);
    e.host.session = "preview-session-" + name;
    e.host.snapshot();
  });
  retired.forEach(function (node) { node.value = "retired"; });
  e.preferences.replace(IP, {});
  retired.forEach(function (node) { assert.strictEqual(node.value, "retired"); });

  var d = newPart(e);
  d.open();
  d.fill("Jamb", "3 ft");
  e.dispatch("Length", "Enter");
  assert.strictEqual(creates(e).length, 1);
  assert.strictEqual(creates(e)[0].payload.session, "preview-session-d");
});

test("dispose is permanent and safe twice; withdraw alone leaves a form reusable", function () {
  var e = editor(), live = e.forms[e.forms.length - 1], d = newPart(e);
  d.open();
  live.withdraw();
  assert.strictEqual(d.form.hidden, true);
  d.open();
  d.fill("Jamb", "3 ft");
  e.dispatch("Length", "Enter");
  assert.strictEqual(creates(e).length, 1, "a withdrawn form still creates after it is reopened");

  switchModel(e);
  assert.doesNotThrow(function () { live.dispose(); });
  live.show();
  assert.strictEqual(d.form.hidden, true);
  assert.strictEqual(creates(e).length, 1);
});

test("a refused or failed create keeps its message, and Create, correction, retry and Cancel all recover", function () {
  ["refused", "failed"].forEach(function (status) {
    var e = editor(), d = newPart(e), invoke = e.host.invoke, held = [];
    var create = d.form.querySelectorAll("button").filter(function (node) { return node.textContent === "Create"; })[0];
    var statusLine = d.form.querySelectorAll(".cell-error").filter(function (node) {
      return node.getAttribute("role") === "status";
    })[0];
    e.host.invoke = function (payload) { held.push(payload); };
    d.open();
    d.fill("Jamb", "3 ft");
    e.dispatch("Length", "Enter");
    assert.strictEqual(create.disabled, true, status + ": pending");
    e.context.PhComposerUI.get("panel").receive({ type: "action.result", payload: { request_id: held[0].request_id,
      session: held[0].session, outcome: { status: status, code: status === "failed" ? "operation.failed" :
        "validation.failed", message: "Not this time." } } });

    assert.strictEqual(statusLine.textContent, "Not this time.", status);
    assert.strictEqual(create.disabled, false, status + ": Create is available again");
    assert.strictEqual(d.form.hidden, false, status + ": the form stays open");
    e.host.invoke = invoke;
    d.fill("Jamb", "4 ft");
    d.create();
    assert.strictEqual(creates(e).length, 2, status + ": the corrected draft is sent once");
    assert.strictEqual(e.host.parts.length, 3, status);
    assert.strictEqual(d.form.hidden, true, status + ": a completed retry closes the form");

    d.open();
    assert.strictEqual(create.disabled, false, status + ": a reopened form can create");
    d.cancel();
    assert.strictEqual(d.form.hidden, true, status);
  });
});
