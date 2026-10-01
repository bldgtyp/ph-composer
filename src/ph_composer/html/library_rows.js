/* Stable local-record rows and read-only details. Use is the only command owned by this placement. */
PhComposerUI.define("library_rows", ["units", "workspace"], function (units, ui) {
  "use strict";
  var el = ui.element;
  var methods = {};
  methods.renderList = function () {
    var self = this, adapter = this.adapter, query = this.search.value.trim().toLowerCase();
    var categories = adapter.categories(this.state), grouped = Object.create(null);
    this.visible = [];
    this.list.replaceChildren();
    this.records.filter(function (row) { return adapter.searchText(row).toLowerCase().includes(query); })
      .sort(function (a, b) { return adapter.compare(adapter.name(a), adapter.name(b)); })
      .forEach(function (row) {
        var category = adapter.category(row);
        (grouped[category] || (grouped[category] = [])).push(row);
      });
    Object.keys(grouped).sort(function (a, b) { return adapter.compare(a, b); }).forEach(function (key) {
      var info = categories.filter(function (entry) { return entry.id === key; })[0];
      var group = el("section", "library-sidebar-group");
      var heading = ui.button(info ? info.label : (key || "Uncategorized"), function () {
        self.expanded[key] = self.expanded[key] === false;
        self.renderList();
      });
      heading.className = "library-sidebar-group-heading";
      heading.setAttribute("aria-expanded", String(self.expanded[key] !== false));
      group.appendChild(heading);
      if (self.expanded[key] !== false) grouped[key].forEach(function (row) {
        var entry = self.entries[row.id];
        if (!entry) entry = self.entries[row.id] = self.makeRow(row);
        entry.row = row;
        entry.name.textContent = adapter.name(row);
        self.visible.push(entry);
        group.appendChild(entry.root);
      });
      self.list.appendChild(group);
    });
    this.count.textContent = this.visible.length + " shown · " + this.records.length + " in this file";
    if (!Object.keys(grouped).length) this.list.appendChild(el("p", "muted",
      query ? "No records match this search." : adapter.emptyText));
  };
  methods.makeRow = function (row) {
    var self = this, entry = { row: row, root: el("div", "library-sidebar-row") };
    entry.button = ui.button("", function (event) {
      var suppressed = entry.suppressClick && event.detail !== 0;
      entry.suppressClick = false;
      if (!suppressed) self.openDetails(entry);
    });
    entry.button.className = "library-sidebar-row-button";
    entry.button.setAttribute("data-library-row", row.id);
    this.adapter.decorate(entry.button, row);
    entry.name = el("span", "library-sidebar-name", this.adapter.name(row));
    entry.button.appendChild(entry.name);
    entry.button.addEventListener("mousedown", function (event) { self.drag.start(entry, event); });
    entry.button.addEventListener("keydown", function (event) {
      if (event.key === "ArrowDown" || event.key === "ArrowUp") {
        event.preventDefault();
        var next = self.visible[self.visible.indexOf(entry) + (event.key === "ArrowDown" ? 1 : -1)];
        if (next) next.button.focus();
      }
    });
    entry.bubble = new ui.Bubble(entry.button, this.adapter.name(row), { side: true, ownTrigger: true,
      onOpen: function () { self.detail = entry; self.renderDetails(); } });
    entry.bubble.panel.classList.add("library-record-card");
    entry.root.appendChild(entry.bubble.root);
    return entry;
  };
  methods.openDetails = function (entry) {
    if (this.disposed || !this.enabled || !entry) return;
    this.detail = entry;
    this.renderDetails();
    entry.bubble.open();
  };
  methods.closeDetails = function () {
    if (this.detail) this.detail.bubble.close(false);
    this.detail = null;
  };
  methods.renderDetails = function () {
    var self = this, entry = this.detail;
    if (!entry) return;
    var content = entry.bubble.content, values = entry.row.values;
    content.replaceChildren();
    this.adapter.properties.forEach(function (item) {
      var value = values[item[1]];
      content.appendChild(ui.propertyRow(item[0], item[2] ? units.format(value, item[2], units.profile(item[2])) :
        (ui.blank(value) ? "—" : value), ""));
    });
    content.appendChild(el("p", "muted", values.notes || "No notes."));
    entry.use = ui.button("Use", function () { self.use(entry.row); });
    entry.use.setAttribute("aria-label", "Use on selected target");
    entry.hint = el("small", "muted");
    content.appendChild(entry.hint);
    content.appendChild(entry.use);
    this.paintActions();
  };
  methods.paintActions = function () {
    if (!this.detail) return;
    var target = this.adapter.target(this.context);
    this.detail.use.disabled = !this.enabled || this.busy() || Boolean(target.hint);
    this.detail.hint.textContent = target.hint || "";
  };
  return methods;
});
