/* The shell's status bar. Features own the work surfaces inside each pane. */
PhComposerUI.define("sections/shell", ["panel", "workspace"], function (panel, ui) {
  "use strict";
  var element = ui.element;

  /* Product and version, then the context new geometry would be created in. */
  function renderFooter(root, state) {
    var path = state.edit_path || [];
    ui.memoPaint(root, "footer", [state.version, path], function () {
      root.replaceChildren(
        element("span", "", state.product + " " + state.version),
        element("span", "", "Editing: " + (path.length ? path.map(function (name) {
          return name || "Unnamed group";
        }).join(" / ") : "Model"))
      );
    });
  }

  panel.section("footer", renderFooter);
});
