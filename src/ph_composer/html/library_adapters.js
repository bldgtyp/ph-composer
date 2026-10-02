/* A placement supplies its record kind, presentation and target validation. The sidebar knows no feature. */
PhComposerUI.define("library_adapters", ["workspace"], function (ui) {
  "use strict";
  function adapter(options) {
    return Object.assign({ title: "Library", read: function () { return []; },
      categories: function () { return []; }, properties: [],
      name: function (row) { return row.values.name || row.id; },
      searchText: function (row) { return [row.values.name, row.values.category, row.values.notes].join(" "); },
      category: function (row) { return row.values.category || ""; },
      decorate: function () {}, target: function () { return { hint: "Choose a target first." }; },
      emptyText: "No records in this file.", compare: function (a, b) { return ui.compareText(a, b); }
    }, options);
  }
  return { adapter: adapter };
});
