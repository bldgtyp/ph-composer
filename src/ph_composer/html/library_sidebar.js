/* One persistent In-this-file browser beside a work surface. No provider, source or adoption state. */
PhComposerUI.define("library_sidebar", ["library_adapters", "library_drag", "library_rows", "workspace"],
  function (adapters, Drag, rows, ui) {
    "use strict";
    var el = ui.element;
    function Sidebar(options) {
      var self = this;
      this.adapter = adapters.adapter(options.adapter);
      this.onUse = options.onUse;
      this.busy = options.busy || function () { return false; };
      this.entries = Object.create(null);
      this.expanded = Object.create(null);
      this.context = {};
      this.records = [];
      this.enabled = false;
      this.collapsed = window.innerWidth < 900;
      this.root = el("aside", "library-sidebar-root");
      this.root.setAttribute("aria-label", this.adapter.title);
      this.toggleButton = ui.button(this.adapter.title, function () { self.toggle(); });
      this.toggleButton.className = "library-sidebar-toggle";
      this.toggleButton.setAttribute("data-editor-local", "");
      this.content = el("div", "library-sidebar-content");
      this.content.appendChild(el("small", "library-sidebar-source", "In this file"));
      this.search = el("input");
      this.search.type = "search";
      this.search.placeholder = "Search name, category or notes";
      this.search.setAttribute("aria-label", "Search " + this.adapter.title.toLowerCase());
      this.search.addEventListener("input", function () { self.renderList(); });
      this.count = el("small", "muted");
      this.list = el("div", "library-sidebar-list");
      this.content.appendChild(this.search);
      this.content.appendChild(this.count);
      this.content.appendChild(this.list);
      this.root.appendChild(this.toggleButton);
      this.root.appendChild(this.content);
      this.drag = new Drag(this);
      this.paint();
    }
    Sidebar.prototype.paint = function () {
      this.content.hidden = this.collapsed;
      this.root.classList.toggle("is-collapsed", this.collapsed);
      this.toggleButton.setAttribute("aria-expanded", String(!this.collapsed));
    };
    Sidebar.prototype.toggle = function () {
      if (this.disposed) return;
      this.closeDetails();
      this.collapsed = !this.collapsed;
      this.paint();
    };
    Sidebar.prototype.refresh = function (state, context, enabled) {
      if (this.disposed) return;
      this.state = state;
      this.context = context;
      this.enabled = Boolean(enabled);
      this.records = this.adapter.read(state);
      var live = this.records.map(function (row) { return row.id; }), self = this;
      Object.keys(this.entries).forEach(function (id) {
        if (live.indexOf(id) !== -1) return;
        if (self.detail === self.entries[id]) self.closeDetails();
        delete self.entries[id];
      });
      this.renderList();
      if (this.detail) this.renderDetails();
      this.paintActions();
      if (!this.enabled) this.drag.end();
    };
    Sidebar.prototype.use = function (row, selection) {
      if (this.disposed || !this.enabled || this.busy() || !this.records.some(function (live) {
        return live.id === row.id;
      })) return false;
      var target = this.adapter.target(Object.assign({}, this.context, selection ? { selection: selection } : {}));
      if (target.hint) return false;
      return this.onUse(row, target.params);
    };
    Sidebar.prototype.reveal = function (id) {
      if (this.disposed) return;
      this.collapsed = false;
      this.paint();
      if (!id) { this.search.focus(); return; }
      this.search.value = "";
      this.expanded = Object.create(null);
      this.renderList();
      this.openDetails(this.entries[id]);
    };
    Sidebar.prototype.dispose = function () {
      this.disposed = true;
      this.enabled = false;
      this.drag.end();
      this.closeDetails();
    };
    Object.assign(Sidebar.prototype, rows);
    return Sidebar;
  });
