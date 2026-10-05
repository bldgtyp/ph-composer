/* A column's menu, opened from an ellipsis in its header: Sort A to Z, Sort Z to A and, when the column offers
   values, a "Show" checklist with Clear filter. While the column is filtered, the ellipsis becomes a filter glyph
   and stays visible at rest. The menu owns no view state: `sort` and `filter` read and set what a screen's
   `ui.ViewControls` holds, and it names no record or field vocabulary.

   options: label (the column's name), sort { current() -> "asc" | "desc" | null, choose(direction) },
   filter { values() -> [{ value, label }], shown() -> [value] or null for every value, set([value] or null),
   answering false when the change was refused }. */
PhComposerUI.define("column_menu", ["dom", "icons", "overlay"], function (dom, icons, overlay) {
  "use strict";
  var element = dom.element, button = dom.button;

  function ColumnMenu(options) {
    var self = this;
    this.options = options;
    this.trigger = icons.iconButton("", "more");
    this.bubble = new overlay.Bubble(this.trigger, options.label, { onOpen: function () { self.fill(); } });
    this.bubble.root.classList.add("phc-action-menu-anchor", "phc-column-menu-anchor");
    this.bubble.panel.classList.add("phc-action-menu", "phc-column-menu");
    this.root = this.bubble.root;
    this.paint();
  }

  ColumnMenu.prototype.filtered = function () {
    return Boolean(this.options.filter && this.options.filter.shown());
  };

  /* The trigger says what the column holds now: filtered or not. */
  ColumnMenu.prototype.paint = function () {
    var filtered = this.filtered(), label = this.options.label;
    icons.paintIconButton(this.trigger, filtered ? label + ": filtered. Column menu" : label + " column menu",
      filtered ? "filter" : "more");
    this.trigger.classList.toggle("is-filtered", filtered);
  };

  function item(text, icon, pressed, handler) {
    var node = button(text, handler);
    node.className = "phc-action-menu-item phc-setting-choice";
    node.replaceChildren(icons.glyph(icon), element("span", "", text));
    if (pressed !== undefined) node.setAttribute("aria-pressed", String(pressed));
    return node;
  }

  /* Built each time the menu opens, from the values as they stand. */
  ColumnMenu.prototype.fill = function () {
    var self = this, options = this.options, content = this.bubble.content, sort = options.sort;
    content.replaceChildren();
    if (sort) {
      var current = sort.current();
      content.appendChild(item("Sort A to Z", "sort_ascending", current === "asc", function () {
        self.bubble.close(true); sort.choose("asc");
      }));
      content.appendChild(item("Sort Z to A", "sort_descending", current === "desc", function () {
        self.bubble.close(true); sort.choose("desc");
      }));
    }
    if (!options.filter) return;
    var values = options.filter.values(), shown = options.filter.shown();
    if (!values.length) return;
    var group = element("div", "phc-column-filter");
    group.setAttribute("role", "group"); group.setAttribute("aria-label", "Show");
    group.appendChild(element("span", "phc-column-filter-heading", "Show"));
    values.forEach(function (entry) {
      var label = element("label", "phc-column-filter-value"), box = element("input");
      box.type = "checkbox"; box.setAttribute("type", "checkbox");
      box.checked = !shown || shown.indexOf(entry.value) >= 0;
      box.addEventListener("change", function () { self.toggle(entry.value, box.checked); });
      label.appendChild(box); label.appendChild(element("span", "", entry.label));
      group.appendChild(label);
    });
    content.appendChild(group);
    var clear = button("Clear filter", function () { options.filter.set(null); self.paint(); self.fill(); });
    clear.className = "phc-column-filter-clear";
    clear.disabled = !shown;
    content.appendChild(clear);
  };

  /* Every value checked is no filter at all, so a column never reads filtered while it hides nothing. */
  ColumnMenu.prototype.toggle = function (value, show) {
    var filter = this.options.filter, every = filter.values().map(function (entry) { return entry.value; });
    var shown = (filter.shown() || every).filter(function (entry) { return entry !== value; });
    if (show) shown.push(value);
    var applied = filter.set(every.every(function (entry) { return shown.indexOf(entry) >= 0; }) ? null : shown);
    this.paint();
    // A refused change (the screen's guard) leaves the boxes as they were, so the menu shows them again.
    if (applied === false) this.fill();
  };

  return { ColumnMenu: ColumnMenu };
});
