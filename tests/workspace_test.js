"use strict";

/* The shared presentation kit: anchored bubbles, memoised paints, floating notices and the record form
   lifecycle. Transport-free. Browser layout is a separate gate; nothing here measures a box. */

var assert = require("assert");
var test = require("node:test");
var vm = require("vm");
var dom = require("./support/dom_stub");
var panelSource = require("./support/panel_source");

/* A whole stub document, not just a createElement: the bubble attaches listeners to the document, and a
   placement case has to be able to fire them. */
var context = {
  innerWidth: 1280, innerHeight: 800,
  document: dom.buildDocument(""),
  setTimeout: setTimeout,
  clearTimeout: clearTimeout
};
context.window = context;
vm.createContext(context);
var modules = panelSource.start(context, ["workspace", "record_form"]);
var ui = modules.workspace;

test("a bubble with no room below it opens above its trigger", function () {
  var trigger = dom.element("button");
  context.document.body.appendChild(trigger);
  var bubble = new ui.Bubble(trigger, "Options", {});
  context.document.body.appendChild(bubble.panel);
  bubble.panel.rect = { left: 0, top: 0, right: 300, bottom: 250, width: 300, height: 250 };
  bubble.content.rect = { left: 0, top: 60, right: 300, bottom: 250, width: 300, height: 190 };
  // Near the bottom of an 800px window: 250 of panel plus the gap does not fit under it, and
  // there is more room above.
  trigger.rect = { left: 100, top: 700, right: 160, bottom: 730, width: 60, height: 30 };

  bubble.open(false);

  assert.strictEqual(bubble.panel.classList.contains("is-above"), true);
  assert.strictEqual(bubble.panel.style.top, "440px", "the panel sits its own height above the trigger");
  bubble.close(false);
});

test("a bubble with room below it opens below, where it belongs", function () {
  var trigger = dom.element("button");
  context.document.body.appendChild(trigger);
  var bubble = new ui.Bubble(trigger, "Options", {});
  context.document.body.appendChild(bubble.panel);
  bubble.panel.rect = { left: 0, top: 0, right: 300, bottom: 250, width: 300, height: 250 };
  bubble.content.rect = { left: 0, top: 60, right: 300, bottom: 250, width: 300, height: 190 };
  trigger.rect = { left: 100, top: 100, right: 160, bottom: 130, width: 60, height: 30 };

  bubble.open(false);

  assert.strictEqual(bubble.panel.classList.contains("is-above"), false);
  assert.strictEqual(bubble.panel.style.top, "140px");
  bubble.close(false);
});

test("a memoised paint runs only when its inputs change, per owner and key", function () {
  var owner = {}, paints = 0;
  function paint() { paints += 1; }

  assert.strictEqual(ui.memoPaint(owner, "audit", [["rec_a"], "SI"], paint), true);
  assert.strictEqual(ui.memoPaint(owner, "audit", [["rec_a"], "SI"], paint), false, "unchanged inputs skip the paint");
  assert.strictEqual(ui.memoPaint(owner, "drawing", [["rec_a"], "SI"], paint), true, "another key memoises separately");
  assert.strictEqual(ui.memoPaint(owner, "audit", [["rec_a"], "IP"], paint), true);
  assert.strictEqual(ui.memoPaint(owner, "audit", [["rec_a"], "IP"]), false, "the paint callback is optional");
  assert.strictEqual(paints, 3);
});

test("a side bubble opens to the trigger's right, and flips left when the right has no room", function () {
  var trigger = dom.element("button");
  context.document.body.appendChild(trigger);
  var bubble = new ui.Bubble(trigger, "Submenu", { side: true });
  context.document.body.appendChild(bubble.panel);
  bubble.panel.rect = { left: 0, top: 0, right: 300, bottom: 250, width: 300, height: 250 };
  trigger.rect = { left: 100, top: 100, right: 160, bottom: 130, width: 60, height: 30 };

  bubble.open(false);
  assert.strictEqual(bubble.panel.classList.contains("is-submenu"), true);
  assert.strictEqual(bubble.panel.classList.contains("opens-left"), false);
  assert.strictEqual(bubble.panel.style.left, "168px", "right of the trigger by the side gap");
  assert.strictEqual(bubble.panel.style.top, "100px");
  bubble.close(false);

  // A trigger near the right edge of the 1280px window: the right side cannot hold 300px, the left side can.
  trigger.rect = { left: 1000, top: 100, right: 1060, bottom: 130, width: 60, height: 30 };
  bubble.open(false);
  assert.strictEqual(bubble.panel.classList.contains("opens-left"), true);
  assert.strictEqual(bubble.panel.style.left, "692px", "left of the trigger by the side gap");
  bubble.close(false);
});

test("a warning notice stays until dismissed; an information notice fades on the next interaction", function () {
  var owner = dom.element("div");
  dom.attachEvents(owner);
  context.document.body.appendChild(owner);
  var notice = ui.floatingNotice(owner);
  owner.appendChild(notice);

  notice.show("Nothing was written.", { tone: "warning", persistent: true });
  owner.dispatchEvent({ type: "pointerdown", target: owner });
  assert.strictEqual(notice.hidden, false, "a warning survives unrelated clicks");
  assert.strictEqual(notice.getAttribute("data-tone"), "warning");
  assert.strictEqual(notice.message.getAttribute("role"), "status");
  assert.strictEqual(notice.dismissButton.getAttribute("aria-label"), "Dismiss message");
  notice.dismissButton.listeners.click({});
  assert.strictEqual(notice.hidden, true, "Dismiss clears it");

  notice.show("Saved.");
  assert.strictEqual(notice.getAttribute("data-tone"), "info", "information is the default tone");
  notice.fade();
  assert.strictEqual(notice.classList.contains("is-dismissing"), true);
  notice.dispose();
});

test("a record form sends once, keeps Cancel disabled while pending and shows a refusal until closed", function () {
  var sent = [], changes = [];
  var form = new modules.record_form(
    "session-a", function (type, payload) { sent.push({ type: type, payload: payload }); },
    { title: "New part", action: "example.create", label: "create", submitLabel: "Create",
      pendingText: "Creating...", failureText: "The part was not created.",
      changed: function (arg) { changes.push(arg); } }
  );
  form.finish();
  form.show();
  assert.strictEqual(form.root.hidden, false);

  assert.notStrictEqual(form.run({ label: "Frame" }), false);
  assert.strictEqual(form.run({ label: "Frame" }), false, "single flight");
  assert.strictEqual(sent.length, 1);
  assert.strictEqual(form.cancel.disabled, true);
  form.hide();
  assert.strictEqual(form.root.hidden, false, "Cancel is refused while the request is pending");

  var outcome = { status: "refused", code: "params.invalid", message: "Label is required. Nothing was written." };
  var result = { request_id: sent[0].payload.request_id, session: "session-a", outcome: outcome };
  assert.strictEqual(form.settle({ ui: { actionResult: result } }), outcome);
  assert.strictEqual(form.error.textContent, outcome.message);
  assert.strictEqual(form.cancel.disabled, false);
  form.hide("cancelled");
  assert.strictEqual(form.root.hidden, true);
  assert.deepStrictEqual(changes, ["cancelled"]);
});
