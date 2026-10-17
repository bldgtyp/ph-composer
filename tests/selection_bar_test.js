"use strict";

/* The shared selection bar's place over its work surface: it floats and pads the scroll area while it
   leaves the area's header in view, and docks beneath the surface where it would cover it. */

var assert = require("assert");
var test = require("node:test");
var dom = require("./support/dom_stub");
var panelSource = require("./support/panel_source");

function harness() {
  var context = {
    document: dom.buildDocument("<body><div data-scroll></div></body>"), Intl: Intl,
    innerWidth: 360, innerHeight: 520, setTimeout: setTimeout, clearTimeout: clearTimeout
  };
  context.window = context;
  dom.attachEvents(context);
  var bars = panelSource.start(context, ["selection_bar"]).selection_bar;
  var bar = new bars.SelectionBar("Checked rows", function () {});
  var scroll = context.document.querySelector("[data-scroll]");
  scroll.rect = { top: 100, bottom: 400, left: 0, right: 360, width: 360, height: 300 };
  bar.root.offsetHeight = 200;
  return { bar: bar, scroll: scroll };
}

test("the bar floats while it leaves the header in view, docks where it would cover it, and floats again", function () {
  var h = harness(), fits = [], floatingTop = 120;
  // The owner's fit lays the surface out; a floating bar then sits where that layout puts it. The surface's
  // height can follow its content, so each fit must see the padding of the place being tried.
  var fit = function () {
    fits.push((h.bar.root.classList.contains("is-docked") ? "docked " : "floating ") + h.scroll.style.paddingBottom);
    h.bar.root.rect = { top: floatingTop, bottom: floatingTop + 200, left: 0, right: 360, width: 360, height: 200 };
  };
  h.bar.show("2 rows checked", true);
  h.bar.reserve(h.scroll, 60, fit);
  assert.equal(h.bar.root.classList.contains("is-docked"), true, "a bar at 120 would cover the header to 160");
  assert.equal(h.scroll.style.paddingBottom, "", "a docked bar covers nothing, so it pads nothing");
  assert.deepEqual(fits, ["floating 216px", "docked "], "fitted floating, then again around the docked bar");

  floatingTop = 300;
  fits = [];
  h.bar.reserve(h.scroll, 60, fit);
  assert.equal(h.bar.root.classList.contains("is-docked"), false, "the decision does not depend on the last one");
  assert.equal(h.scroll.style.paddingBottom, "216px", "the floating bar pads by its height and clearance");
  assert.deepEqual(fits, ["floating 216px"]);

  h.bar.hide();
  h.bar.reserve(h.scroll, 60, fit);
  assert.equal(h.scroll.style.paddingBottom, "", "a hidden bar gives the padding back");
});
