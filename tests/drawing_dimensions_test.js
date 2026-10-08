"use strict";
var test = require("node:test"), assert = require("node:assert/strict");
var dom = require("./support/dom_stub"), source = require("./support/panel_source");
function setup() {
  var document = dom.buildDocument(""), context = { document: document };
  context.window = context;
  return source.start(context, ["drawing_dimensions"])["drawing_dimensions"];
}
test("drawing rules preserve owner coordinates and reverse boundary order", function () {
  var dimensions = setup();
  var horizontal = dimensions.rule({ axis: "horizontal", from: 100, to: 300, at: 214,
    extension: 203, points: [300, 220, 100], scale: 0.9 });
  var dots = horizontal.querySelectorAll("circle");
  assert.deepEqual(dots.map(function (dot) { return dot.getAttribute("cx"); }), ["300", "220", "100"]);
  assert.equal(dots[0].getAttribute("cy"), "214");
  assert.equal(dots[0].getAttribute("r"), "2.25");
  var vertical = dimensions.rule({ axis: "vertical", from: 40, to: 200, at: 86,
    extension: 97, points: [40, 200] });
  assert.equal(vertical.querySelector("circle").getAttribute("cx"), "86");
  assert.equal(vertical.querySelector("circle").getAttribute("cy"), "40");
  assert.equal(vertical.querySelector("circle").getAttribute("r"), "2.5");
});
test("SVG values activate by click, Enter and Space; HTML values remain real buttons", function () {
  var dimensions = setup(), activations = 0, prevented = 0;
  var options = { text: "800 mm", label: "Column 1 width", className: "window-dimension",
    activate: function () { activations += 1; }, svg: { x: 100, y: 30 } };
  var value = dimensions.value(options);
  assert.equal(value.getAttribute("role"), "button");
  assert.equal(value.getAttribute("aria-label"), options.label);
  assert.equal(value.getAttribute("tabindex"), "0");
  value.listeners.click({});
  ["Enter", " ", "ArrowLeft"].forEach(function (key) {
    value.listeners.keydown({ key: key, preventDefault: function () { prevented += 1; } });
  });
  assert.equal(activations, 3); assert.equal(prevented, 2);
  delete options.svg;
  var html = dimensions.value(options);
  assert.equal(html.tagName.toLowerCase(), "button"); assert.equal(html.type, "button");
  html.listeners.click({}); assert.equal(activations, 4);
  var missing = dimensions.value({ text: "?", className: "is-missing", svg: { x: 100 } });
  assert.equal(missing.getAttribute("tabindex"), null, "a missing value's enclosing control owns activation");
});
test("inline dimensions respect owner refusal and preserve an active editor on reconstruction", function () {
  var document = dom.buildDocument(""), context = { document: document }; context.window = context;
  var dimensions = source.start(context, ["drawing_dimensions"])["drawing_dimensions"];
  var allowed = false, trigger = dimensions.value({ text: "800 mm" }), editor = dom.element("div");
  var input = dom.element("input"); editor.appendChild(input);
  var inline = dimensions.inline({ trigger: trigger, editor: editor, input: input,
    begin: function () { return allowed; } }); document.body.appendChild(inline.root);
  trigger.listeners.click({}); assert.equal(editor.hidden, true);
  allowed = true; trigger.listeners.click({});
  assert.equal(editor.hidden, false); assert.equal(document.activeElement, input);
  inline = dimensions.inline({ trigger: dimensions.value({ text: "800 mm" }), editor: editor,
    input: input, active: true }); document.body.appendChild(inline.root);
  assert.equal(editor.hidden, false); assert.equal(inline.trigger.hidden, true);
  inline.show(false, true); assert.equal(document.activeElement, inline.trigger);
});
