/* Window screen composition and local product Library surfaces use the same public UI contracts. */
PhComposerUI.define("sections/windows", ["panel", "window_editor", "window_inventory", "sections/library"],
  function (panel, editor, inventories, library) {
    "use strict";
    var pages = Object.create(null), current, leaving;
    Object.keys(inventories.definitions).forEach(function (kind) {
      var recordKind = { frames: "frame", glazings: "glazing", psi_install_types: "psi_install_type" }[kind];
      library.registerSurface({ id: kind, recordKind: "ph_composer.windows." + recordKind,
        label: inventories.definitions[kind].title,
        build: function (root, state, send) {
          return new inventories.Inventory(root, state.session, send, kind, panel.repaint);
        } });
    });
    function render(root, state, send) {
      if (!root._view || root._view.session !== state.session) {
        if (root._view) root._view.dispose();
        root._view = new editor.View(root, state.session, send,
          pages[state.session] || (pages[state.session] = {}));
      }
      current = root._view; current.render(state);
    }
    panel.navigationGuard("windows", function (next) {
      leaving = next; return next === "windows" || !current ? null : current.guard();
    }, function () {
      if (!current) return;
      if (!current.installEditor.root.hidden && current.installEditor.dirty) {
        var destination = leaving;
        current.installEditor.cancelSession(false, function () { panel.navigate(destination); });
      } else current.notice.show(current.guard());
    });
    panel.section("windows", render, { pane: "windows", onNavigate: function (root, intent) {
      if (root._view && intent.use) root._view.openUse(intent.use);
    } });
    return { render: render };
  });
