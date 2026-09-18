/* The shell's own sections: the Overview pane's heading and the status bar. The Overview holds nothing else
   until features add to it. */
PhComposerUI.define("sections/shell", ["panel", "workspace"], function (panel, ui) {
  "use strict";
  var element = ui.element;

  function renderOverview(root, state) {
    var heading = element("div", "phc-heading");
    heading.appendChild(element("h1", "", "Overview"));
    if (state.file_name) heading.appendChild(element("span", "phc-heading-note", state.file_name));
    ui.memoPaint(root, "overview", [state.file_name], function () {
      root.replaceChildren(heading, element("p", "empty", "Nothing to show yet."));
    });
  }

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

  panel.section("overview", renderOverview);
  panel.section("footer", renderFooter);
});
