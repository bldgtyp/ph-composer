"use strict";

// Review evidence only. Reuse the existing fixture constructors without executing their test cases.
// Run from the repository root: node planning/code-review/evidence/javascript_probes.cjs
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const { createRequire } = require("node:module");

const root = path.resolve(__dirname, "../../..");

function fixture(relative) {
  const file = path.join(root, relative);
  const source = fs.readFileSync(file, "utf8");
  const firstTest = source.indexOf('\ntest("');
  assert.ok(firstTest >= 0, "Fixture must have a recognizable first top-level test: " + relative);
  const context = { require: createRequire(file), __dirname: path.dirname(file),
    console, setTimeout, clearTimeout };
  vm.createContext(context);
  vm.runInContext(source.slice(0, firstTest), context, { filename: file });
  return context;
}

function example() {
  return fixture("tests/example_editor_test.js").editor();
}

function openNewPart(editor) {
  editor.section.querySelectorAll("button").find(node => node.textContent === "New part").listeners.click({});
  return editor.section.querySelector(".phc-form-dialog");
}

function lengthInput(form) {
  return form.querySelectorAll("input").find(node => node.getAttribute("aria-label") === "Length");
}

function report(result) {
  console.log(JSON.stringify(result));
}

// JS-03: Enter commits the quantity field and prevents native submit, but never creates the part.
{
  const editor = example();
  const form = openNewPart(editor);
  const field = lengthInput(form);
  field.value = "3 ft";
  field.listeners.input({});
  let prevented = false;
  field.listeners.keydown({ key: "Enter", preventDefault() { prevented = true; } });
  const result = { probe: "example Enter in New part Length", prevented,
    invokes: editor.invokes().length, formStillOpen: !form.hidden,
    storedParts: editor.host.parts.length, inputAfterEnter: field.value };
  assert.equal(result.prevented, true);
  assert.equal(result.invokes, 0);
  assert.equal(result.formStillOpen, true);
  assert.equal(result.storedParts, 2);
  assert.equal(result.inputAfterEnter, "914.4");
  report(result);
}

// JS-04: The old form's UnitField remains subscribed after it leaves the document.
{
  const editor = example();
  const oldField = lengthInput(openNewPart(editor));
  let value = oldField.value;
  let repaints = 0;
  Object.defineProperty(oldField, "value", {
    get() { return value; },
    set(next) { value = next; repaints += 1; },
    configurable: true
  });
  editor.host.session = "another-session";
  editor.host.snapshot();
  repaints = 0;
  editor.preferences.set("unit_system", "IP");
  const result = { probe: "old form field after Model switch", oldInputConnected: oldField.isConnected,
    repaintsAfterPreferenceChange: repaints };
  assert.equal(result.oldInputConnected, false);
  assert.equal(result.repaintsAfterPreferenceChange, 1);
  report(result);
}

// JS-04: A retained old form callback dispatches an obsolete-session request; the host refuses it.
{
  const editor = example();
  const oldForm = openNewPart(editor);
  editor.host.session = "session-b";
  editor.host.snapshot();
  oldForm.querySelector("form").listeners.submit({ preventDefault() {} });
  const result = { probe: "retained New part submit after Model switch",
    sent: editor.invokes().map(message => ({ name: message.payload.name, session: message.payload.session })),
    currentSession: editor.host.session, parts: editor.host.parts.length };
  assert.equal(result.sent.length, 1);
  assert.equal(result.sent[0].name, "example.foundation.create_parts");
  assert.equal(result.sent[0].session, "preview-session");
  assert.equal(result.currentSession, "session-b");
  assert.equal(result.parts, 2);
  report(result);
}

// JS-02: An optional translator exception prevents correlated-result reduction and settlement.
{
  const helpers = fixture("tests/panel_app_test.js");
  const page = helpers.page();
  page.receive("panel.snapshot", helpers.snapshot("session-a", 1));
  const channel = page.modules.request.channel("session-a", () => {}, "probe");
  const id = channel.run("example.edit", {});
  page.panel.outcomeText(() => { throw new Error("broken contributor translator"); });
  let error;
  try {
    page.receive("action.result", { request_id: id, session: "session-a",
      outcome: { status: "refused", message: "Nothing was written." } });
  } catch (caught) {
    error = caught.message;
  }
  channel.consume(page.panel.state);
  const result = { probe: "throwing optional outcome translator", error,
    resultRecorded: Boolean(page.panel.state.ui.actionResult), requestStillBusy: channel.busy() };
  assert.equal(result.error, "broken contributor translator");
  assert.equal(result.resultRecorded, false);
  assert.equal(result.requestStillBusy, true);
  report(result);
}

console.log("Four JavaScript review probes reproduced the recorded baseline behavior.");
