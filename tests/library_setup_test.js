"use strict";
var assert = require("assert"), test = require("node:test"), dom = require("./support/dom_stub"),
  source = require("./support/panel_source");
function setup(setupState) {
  var context = { document: dom.buildDocument(""), Intl: Intl, innerWidth: 1280, innerHeight: 800,
    setTimeout: setTimeout, clearTimeout: clearTimeout };
  context.window = context; dom.attachEvents(context);
  var modules = source.start(context, ["library/setup"]), sent = [];
  var dialog = new modules["library/setup"]("session", function (type, payload) {
    sent.push({ type: type, payload: payload });
  }, function () {});
  context.document.body.appendChild(dialog.root);
  dialog.refresh({ session: "session", revision: 1, ui: { queryResults: {}, setupResults: {} }, sections: {
    "ph_composer.library.provider_catalogs": { status: "completed", value: [] },
    "ph_composer.library.provider_setup": { status: "completed", value: { state: setupState } } } });
  return { dialog: dialog, sent: sent };
}
test("an unreadable setup offers only Reset, which sends the reset setup command", function () {
  var o = setup("unreadable");
  assert.strictEqual(o.dialog.unreadableNotice.hidden, false);
  assert.ok(o.dialog.file.disabled && o.dialog.folder.disabled);
  assert.ok(!o.dialog.list.textContent.includes("No libraries configured."));
  o.dialog.reset.dispatchEvent({ type: "click" });
  assert.deepStrictEqual(o.sent.map(function (item) { return [item.type, item.payload.name]; }),
    [["setup.invoke", "ph_composer.library.providers.reset"]]);
});
test("a readable setup hides the reset notice and allows adding", function () {
  var o = setup("readable");
  assert.strictEqual(o.dialog.unreadableNotice.hidden, true);
  assert.ok(!o.dialog.file.disabled && !o.dialog.folder.disabled);
});
