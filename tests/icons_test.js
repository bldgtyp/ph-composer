"use strict";

/* Every icon name the panel source spells out is in the registry. An unknown name throws at render, so a typo
   would otherwise surface only when that control first paints in the host. */

var assert = require("assert");
var fs = require("fs");
var test = require("node:test");
var panelFiles = require("./support/panel_files");
var panelSource = require("./support/panel_source");

var context = {};
context.window = context;
var icons = panelSource.start(context, ["icons"]).icons;

// The call shapes that name an icon: an action descriptor (literal or ternary), a glyph, an icon button, a
// repaint and a raw icon.
var PATTERNS = [
  /\bicon:\s*"([a-z_]+)"/g,
  /\bicon:\s*[^,{}"]*\?\s*"([a-z_]+)"\s*:\s*"([a-z_]+)"/g,
  /\bglyph\("([a-z_]+)"\)/g,
  /\biconButton\([^,()]+,\s*"([a-z_]+)"/g,
  /\bpaintIconButton\([^,()]+,[^,()]+,\s*"([a-z_]+)"/g,
  /\bsvgIcon\("([a-z_]+)"/g
];

test("every icon literal in the panel source is registered", function () {
  var named = [];
  panelFiles.panelFiles().forEach(function (file) {
    var source = fs.readFileSync(file, "utf8");
    PATTERNS.forEach(function (pattern) {
      var match;
      pattern.lastIndex = 0;
      while ((match = pattern.exec(source))) {
        match.slice(1).forEach(function (name) { if (name) named.push({ name: name, file: file }); });
      }
    });
  });
  assert(named.length > 0, "the scan found the panel's icon names (" + named.length + ")");
  named.forEach(function (entry) {
    assert(icons.has(entry.name), "icon \"" + entry.name + "\" in " + entry.file + " is registered");
  });
});

test("an unknown icon name throws instead of painting an empty control", function () {
  assert.throws(function () { icons.svgIcon("not_an_icon", 16); }, /Unknown icon "not_an_icon"/);
  assert.match(icons.svgIcon("stop", 14), /^<svg width="14" height="14"/);
});
