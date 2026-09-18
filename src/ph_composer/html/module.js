/* The panel's module registry. Every other panel file is one `PhComposerUI.define(name, dependencies,
 * factory)` call, where the name is the file's path under html/ without `.js`. `PhComposerUI.start()`
 * builds the modules in dependency order and throws on a missing or cyclic dependency, so a load
 * order mistake fails at start rather than as an undefined global in the middle of a render.
 *
 * The <script> list in index.html is generated from the same declarations
 * (tools/panel_manifest.js); script order carries no meaning, only the declared graph does.
 * Not ES modules: HtmlDialog serves files, and the panel stays on plain scripts.
 */
(function (global) {
  "use strict";

  var definitions = Object.create(null);
  var exports = null;

  function define(name, dependencies, factory) {
    if (exports) throw new Error("PhComposerUI.define(\"" + name + "\") after PhComposerUI.start()");
    if (definitions[name]) throw new Error("PhComposerUI.define(\"" + name + "\") is defined twice");
    definitions[name] = { name: name, dependencies: dependencies.slice(), factory: factory };
  }

  /* Depth-first, visiting names and dependencies in sorted order, so the order is the same for
     the same graph however the files were loaded. */
  function order() {
    var sorted = [], marks = Object.create(null);
    function visit(name, path) {
      var definition = definitions[name];
      if (marks[name] === "done") return;
      if (marks[name] === "visiting") {
        throw new Error("PhComposerUI: dependency cycle " + path.concat([name]).join(" -> "));
      }
      if (!definition) {
        throw new Error("PhComposerUI: \"" + path[path.length - 1] + "\" depends on undefined module \"" + name + "\"");
      }
      marks[name] = "visiting";
      definition.dependencies.slice().sort().forEach(function (dependency) { visit(dependency, path.concat([name])); });
      marks[name] = "done";
      sorted.push(name);
    }
    Object.keys(definitions).sort().forEach(function (name) { visit(name, []); });
    return sorted;
  }

  function start() {
    if (exports) return exports;
    var built = Object.create(null);
    order().forEach(function (name) {
      var definition = definitions[name];
      built[name] = definition.factory.apply(null, definition.dependencies.map(function (dependency) {
        return built[dependency];
      }));
    });
    exports = built;
    return exports;
  }

  /* A started module by name: the host's entry into the panel
     (`PhComposerUI.get("panel").receive(...)`), and a development script's way to reach the kit. */
  function get(name) {
    if (!exports) throw new Error("PhComposerUI.get(\"" + name + "\") before PhComposerUI.start()");
    if (!(name in exports)) throw new Error("PhComposerUI.get: no module \"" + name + "\"");
    return exports[name];
  }

  global.PhComposerUI = { define: define, start: start, get: get, order: order };
}(window));
