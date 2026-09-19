/* The Export pane. The destination dialog opens and closes, and nothing is written: no exporter is installed,
   so the host answers that export is unavailable. Nothing here starts the runtime.

   The host answers `export.start` with `export.result` (`{ request_id, session, outcome }`), which panel.js
   keeps in `state.ui.exportResult` for the shown session. */
PhComposerUI.define("sections/export", ["panel", "workspace"], function (panel, ui) {
  "use strict";
  var element = ui.element;
  var sequence = 0;
  var pending = null;
  var session = null;
  var last = null;

  function choose() {
    if (pending || !last) return;
    pending = "export:" + String(sequence += 1);
    last.send("export.start", { request_id: pending, session: last.state.session });
    render(last.root, last.state, last.send);
  }

  function render(root, state, send) {
    var result = state.ui.exportResult;
    var outcome = result && result.session === state.session ? result.outcome : null;
    last = { root: root, state: state, send: send };
    if (state.session !== session) { session = state.session; pending = null; }
    if (pending && result && result.request_id === pending) pending = null;
    ui.memoPaint(root, "export", [session, Boolean(pending), outcome && outcome.message], function () {
      var heading = element("div", "phc-heading");
      var actions = element("div", "phc-export-actions");
      var status = element("p", "phc-export-status", outcome ? outcome.message : "");
      status.setAttribute("role", "status");
      heading.appendChild(element("h1", "", "Export"));
      actions.appendChild(ui.button(pending ? "Choosing destination…" : "Choose destination…", choose,
        Boolean(pending)));
      root.replaceChildren(heading, element("p", "empty", "No exporter is installed. Export writes nothing yet."),
        actions, status);
    });
  }

  panel.section("export", render, { pane: "export" });
});
