/* Shared inventory controls (filter, group, order and direction) and the group heading tables and the library
   sidebar draw. They own view state only; callers supply domain values and labels through the projection config. */
PhComposerUI.define("view_controls", ["dom", "icons"], function (dom, icons) {
  "use strict";
  var element = dom.element, button = dom.button, blank = dom.blank, compareText = dom.compareText,
    glyph = icons.glyph;
  /* A group heading: chevron, category bar, label and count. Shared by tables and the library sidebar. */
  function groupToggle(onToggle) {
    var heading = { button: button("", onToggle) };
    heading.button.className = "phc-group-toggle";
    heading.marker = element("span", "phc-group-chevron");
    heading.marker.setAttribute("aria-hidden", "true"); heading.marker.appendChild(glyph("chevron"));
    heading.bar = element("span"); heading.label = element("span", "phc-group-label");
    heading.count = element("span", "phc-group-count");
    [heading.marker, heading.bar, heading.label, heading.count].forEach(function (node) {
      heading.button.appendChild(node);
    });
    return heading;
  }
  function paintGroupToggle(heading, group) {
    heading.button.setAttribute("aria-expanded", String(!group.collapsed));
    heading.bar.className = "phc-category-bar category-" + (group.tone || "neutral");
    heading.label.textContent = group.label; heading.count.textContent = String(group.count);
  }
  /* `options.guard`, when given, answers why the rows may not be narrowed right now (a draft on a row
     the filter could hide), or null. A refused filter edit keeps its previous text and hands the
     reason to `options.refused`. */
  function ViewControls(options, changed) {
    var self = this, filtered = "";
    function filterChanged() {
      var reason = options.guard && options.guard();
      if (reason) { self.filter.value = filtered; options.refused(reason); return false; }
      filtered = self.filter.value; changed(); return true;
    }
    this.options = options; this.root = element("div", "phc-inventory-controls");
    this.collapsed = Object.create(null); this.groups = [];
    function select(label, choices, initial, key) {
      var wrap = element("label", "phc-view-control", label), input = element("select");
      choices.forEach(function (choice) {
        var item = element("option", "", choice[1]); item.value = choice[0]; input.appendChild(item);
      });
      if (key) self[key + "Options"] = input;
      input.value = initial; input.setAttribute("aria-label", label); input.addEventListener("change", changed);
      wrap.appendChild(input); self.root.appendChild(wrap); return input;
    }
    var filterLabel = element("label", "phc-view-control", "Filter");
    this.filter = element("input"); this.filter.type = "search"; this.filter.placeholder = options.placeholder;
    this.filter.setAttribute("aria-label", "Filter " + options.label);
    this.filter.addEventListener("input", filterChanged);
    filterLabel.appendChild(this.filter); this.root.appendChild(filterLabel);
    this.clear = button("Clear", function () {
      self.filter.value = "";
      if (filterChanged()) self.filter.focus();
    });
    this.root.appendChild(this.clear);
    this.groupBy = select("Group by", [["", "None"]].concat(options.groups || []), "", "group");
    if (options.groups === undefined) this.groupBy.parentNode.hidden = true;
    this.orderBy = select("Order by", options.fields, options.initialOrder || "name", "field");
    this._fieldSignature = JSON.stringify(options.fields);
    this.direction = select("Direction", [["asc", "Ascending"], ["desc", "Descending"]], "asc");
    this.toggleGroup = function (key) { self.collapsed[key] = !self.collapsed[key]; changed(); };
    this.collapseAll = button("Collapse all", function () {
      if (options.expansion) options.expansion.collapseAll();
      else self.groups.forEach(function (group) { self.collapsed[group.key] = true; });
      changed();
    });
    this.expandAll = button("Expand all", function () {
      if (options.expansion) options.expansion.expandAll();
      else self.collapsed = Object.create(null);
      changed();
    });
    this.root.appendChild(this.collapseAll); this.root.appendChild(this.expandAll);
    this.count = element("span", "phc-view-count"); this.count.setAttribute("role", "status");
    this.root.appendChild(this.count);
  }
  ViewControls.prototype.setFields = function (fields) {
    var signature = JSON.stringify(fields);
    if (signature === this._fieldSignature) return;
    var selected = this.orderBy.value;
    this.orderBy.replaceChildren();
    fields.forEach(function (choice) {
      var item = element("option", "", choice[1]); item.value = choice[0]; this.orderBy.appendChild(item);
    }, this);
    this.orderBy.value = selected;
    this._fieldSignature = signature;
  };
  ViewControls.prototype.project = function (records, config) {
    var self = this, query = (this.filter.value || "").trim().toLocaleLowerCase(), groupField = this.groupBy.value;
    function id(record) { return config.id ? config.id(record) : record.id; }
    function group(record) {
      var raw = config.value(record, groupField), info = config.group(record, groupField);
      return { key: JSON.stringify([groupField, raw]), label: info.label, tone: info.tone || "neutral",
        blank: blank(raw) };
    }
    var matches = Object.create(null), retained = Object.create(null), groups = Object.create(null),
      count = 0, retainedCount = 0;
    records.forEach(function (record) {
      var key = id(record);
      matches[key] = (!config.include || config.include(record)) &&
        (!query || config.search(record).toLocaleLowerCase().indexOf(query) >= 0);
      retained[key] = !matches[key] && config.retain ? config.retain(record) : false;
      if (!matches[key] && !retained[key]) return;
      count += 1;
      if (retained[key]) retainedCount += 1;
      if (!groupField) return;
      var info = group(record);
      if (!groups[info.key]) {
        groups[info.key] = Object.assign(info, { count: 0, collapsed: Boolean(self.collapsed[info.key]) });
      }
      groups[info.key].count += 1;
    });
    var ordered = records.slice().sort(function (a, b) {
      if (groupField) {
        var ag = group(a), bg = group(b),
          order = Number(ag.blank) - Number(bg.blank) || compareText(ag.label, bg.label);
        if (order) return order;
      }
      var av = config.value(a, self.orderBy.value), bv = config.value(b, self.orderBy.value);
      if (blank(av) !== blank(bv)) return blank(av) ? 1 : -1;
      var difference = blank(av) ? 0 :
        (typeof av === "number" && typeof bv === "number" ? av - bv : compareText(av, bv));
      return difference * (self.direction.value === "desc" ? -1 : 1) ||
        (config.tie ? config.tie(a, b) : compareText(a.name, b.name) || compareText(a.id, b.id));
    });
    this.groups = Object.keys(groups).map(function (key) { return groups[key]; });
    // A nested projection (config.rows) filters a child row by its top-level record.
    var rowIds = Object.create(null);
    if (config.rows) {
      config.rows(ordered).forEach(function (row) {
        rowIds[row.key] = row.parent ? rowIds[row.parent] : id(row.record);
      });
    }
    function rowId(row) { return row.parent ? rowIds[row.key] : id(row.record); }
    var projection = { records: ordered, visibleCount: count, matchedCount: count - retainedCount,
      retainedCount: retainedCount,
      hidden: function (row) { var key = rowId(row); return !matches[key] && !retained[key]; },
      retained: function (row) { return row.depth === 0 ? retained[rowId(row)] : false; },
      group: groupField ? function (row) {
        var key = id(row.record);
        return matches[key] || retained[key] ? groups[group(row.record).key] : null;
      } : null };
    this.collapseAll.hidden = this.expandAll.hidden = !(groupField || this.options.expansion);
    var expansion = this.options.expansion;
    this.collapseAll.disabled = expansion ? !expansion.canCollapse(projection) :
      this.groups.every(function (entry) { return entry.collapsed; });
    this.expandAll.disabled = expansion ? !expansion.canExpand(projection) :
      this.groups.every(function (entry) { return !entry.collapsed; });
    this.clear.hidden = !query;
    this.count.textContent = this.options.count === false ? "" :
      (query ? count + " of " + records.length : "");
    return projection;
  };
  return { ViewControls: ViewControls, groupToggle: groupToggle, paintGroupToggle: paintGroupToggle };
});
