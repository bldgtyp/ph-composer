/* The Export pane. Empty until the first exporter lands: nothing here starts the runtime or writes a file. */
PhComposerUI.define("sections/export", ["panel", "workspace"], function (panel, ui) {
  "use strict";
  var element = ui.element;

  function render(root) {
    ui.memoPaint(root, "export", [], function () {
      var heading = element("div", "phc-heading");
      heading.appendChild(element("h1", "", "Export"));
      root.replaceChildren(heading, element("p", "empty", "No exporter is installed."));
    });
  }

  panel.section("export", render, { pane: "export" });
});
