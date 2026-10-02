"use strict";
/* The panel's directories are its layers: the kit at the top of html/, the foundation's own screens
   under sections/ and library/, and one folder per feature under features/. Only a feature may name
   a feature, so a contributor reading the kit or the Library pane never meets a built-in special case. */
var assert = require("assert");
var fs = require("fs");
var test = require("node:test");
var manifest = require("../tools/panel_manifest");

var FEATURE_ID = /ph_composer\.(assemblies|zones|windows)\b/;

test("no module outside features/ depends on a feature module or names a feature id", function () {
  var definitions = manifest.graph().definitions;
  Object.keys(definitions).filter(function (name) { return name.indexOf("features/") !== 0; })
    .forEach(function (name) {
      var definition = definitions[name];
      assert.strictEqual(definition.dependencies.filter(function (dependency) {
        return dependency.indexOf("features/") === 0;
      }).join(", "), "", name);
      assert.ok(!FEATURE_ID.test(fs.readFileSync(definition.file, "utf8")), name + " names a feature id");
    });
});
