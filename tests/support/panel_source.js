"use strict";

/* One way to load panel source into a test's vm context.

   Every test file used to hand-roll `vm.runInNewContext`, and the three conventions they arrived
   at (a bare name, a joined relative path, an absolute path) are three different `filename`
   values in V8's coverage report for the same file. Loading through here means the report names
   the file on disk, so a new test file cannot silently drop its subject out of the score. */

var fs = require("fs");
var path = require("path");
var vm = require("vm");

var html = require("./panel_files").html;

function sourcePath(name) {
  return path.join(html, name);
}

/* Runs one panel file in `context`, identified by its absolute path. */
function load(context, name) {
  var absolute = sourcePath(name);
  vm.runInNewContext(fs.readFileSync(absolute, "utf8"), context, { filename: absolute });
  return context;
}

/* The shipped `index.html`, which the panel suites build their stub document from. */
function markup(name) {
  return fs.readFileSync(sourcePath(name), "utf8");
}

/* Starts the panel modules `roots` and everything they depend on, from the declared graph
   (tools/panel_manifest.js), and returns the started modules by name. `stubs` replaces a module
   by name with a test double, and its own dependencies are then not loaded. The context needs
   `window` pointing at itself, as a page's does. */
function start(context, roots, stubs) {
  var definitions = manifest().definitions;
  var doubles = stubs || {};
  var needed = [];
  function visit(name) {
    if (needed.indexOf(name) !== -1) return;
    needed.push(name);
    if (Object.prototype.hasOwnProperty.call(doubles, name)) return;
    if (!definitions[name]) throw new Error("no panel module named " + name);
    definitions[name].dependencies.forEach(visit);
  }
  roots.forEach(visit);
  load(context, "module.js");
  needed.forEach(function (name) {
    if (Object.prototype.hasOwnProperty.call(doubles, name)) context.PhComposerUI.define(name, [], function () {
      return doubles[name];
    });
    else load(context, name + ".js");
  });
  return context.PhComposerUI.start();
}

var cachedManifest = null;
function manifest() {
  // Every module under html/, other pages' included, so a suite can start any page's entry.
  if (!cachedManifest) cachedManifest = require("../../tools/panel_manifest").graph(true);
  return cachedManifest;
}

module.exports = { load: load, start: start, markup: markup, sourcePath: sourcePath };
