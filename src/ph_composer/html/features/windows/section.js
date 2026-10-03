/* Window screen composition and local product Library surfaces use the same public UI contracts. */
PhComposerUI.define("features/windows/section", ["panel", "features/windows/editor", "features/windows/inventory",
  "library/section"],
  function (panel, editor, inventories, library) {
    "use strict";
    var pages = Object.create(null), current, leaving;
    Object.keys(inventories.definitions).forEach(function (kind, index) {
      var definition = inventories.definitions[kind];
      library.registerSurface({ id: kind, recordKind: definition.recordKind, label: definition.title, order: 30 + index,
        createLabel: "+ New " + definition.label, build: function (root, state, send) {
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
