/* The shell's status bar. Features own the work surfaces inside each pane. */
PhComposerUI.define("sections/shell", ["panel", "workspace"], function (panel, ui) {
  "use strict";
  var element = ui.element;

  /* Product and version, then the context new geometry would be created in, then the way to Help &
     Diagnostics, which also opens from the Extensions menu when the panel itself is the problem. */
  function renderFooter(root, state, send) {
    var path = state.edit_path || [];
    ui.memoPaint(root, "footer", [state.version, path], function () {
      var help = ui.button("Help & Diagnostics", function () { send("panel.support", { incident: null }); });
      help.className = "phc-footer-link";
      root.replaceChildren(
        element("span", "", state.product + " " + state.version),
        element("span", "", "Editing: " + (path.length ? path.map(function (name) {
          return name || "Unnamed group";
        }).join(" / ") : "Model")),
        help
      );
    });
  }

  panel.section("footer", renderFooter, { withoutModel: true });
});
