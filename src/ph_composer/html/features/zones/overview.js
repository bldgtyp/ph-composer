/* The Zones screen: one table spanning the pane, with no inspector. Zones are rows; a Zone's own fields are
 * columns on its row, and the Faces view (faces_view.js) supplies the rows beneath each Zone and the columns
 * that describe them. Colour by, sort and value filters live in the column headers, the shared view controls
 * above the table hold the text filter, the count and Table options, and a selection bar floats over the
 * bottom of the table while Faces are checked.
 *
 * The table is the shared record table; this file holds the Zone rows, the Name column, the Zone's own cells,
 * the filter, the expansion and the one call that paints the table, and asks the view for everything else
 * through the hooks the view module returns. The view reaches this screen's state only through `host`.
 */
PhComposerUI.define("features/zones/overview", ["panel", "workspace", "request", "snapshot", "units",
  "unit_preferences", "table", "view_controls", "column_menu", "sections/colour_by", "fields",
  "features/zones/zone_cells", "features/zones/classify", "features/zones/zone_options",
  "features/zones/option_dialog", "features/zones/faces_view"],
function (panel, ui, requests, snapshot, units, preferences, tables, viewControls, columnMenus, colourBy, fields,
          ZoneCells, classify, zoneOptions, OptionDialog, view) {
  "use strict";
  var AREA = fields.AREA_M2;
  var ORDER_FIELDS = [["name", "Name"], ["area_m2", "Area"]];
  // What the Zones read says is wrong with a Zone occurrence, in the words the user needs. Both the
  // original and its copy carry the state, so the marker names the condition, not which one is the copy.
  // A shared Zone's marker is an alert icon: no word fits beside "Zone" in the Hierarchy column.
  // Every write to such a Zone refuses, so its cells are read only.
  var ZONE_STATES = {
    ambiguous: { text: "Shared", icon: "alert",
      tooltip: "Another Zone carries the same identity, as a copy does. Its cells are read only until it is " +
        "made independent, because an edit here could reach the other one." },
    shared_definition: { text: "Shared", icon: "alert",
      tooltip: "This Zone shares its Faces with another occurrence: a copy, or another instance of the same " +
        "component. Its cells are read only, because an edit here would reach both." },
    wrong_hierarchy: { text: "nested",
      tooltip: "This Zone sits inside another Zone. A Zone is one Room, so a Zone within a Zone " +
        "cannot be exported as it stands." }
  };

  var screen = null;
  var ZONE_DRAFT = "Finish or cancel the Zone edit first.";
  var HELP = "Select Faces in SketchUp, or check their rows, to edit them together in the bar under the table. " +
    "A column's palette icon colours the Model by that column; its menu sorts and filters.";

  /* This screen's own state, rebuilt whenever the panel shows a different Model. */
  function forSession(session, send) {
    if (screen && screen.session === session) return screen;
    if (screen) { screen.disposed = screen.host.disposed = true; screen.edits.reset(); screen.look.reset(); }
    if (screen && screen.optionDialog) screen.optionDialog.dispose();
    if (screen && screen.zoneCells) screen.zoneCells.dispose();
    if (screen && screen.view) view.dispose(screen.view);
    if (screen && screen.independenceDialog) {
      screen.independenceDialog.closeModal();
      var stale = screen.independenceDialog;
      if (stale.parentNode) stale.parentNode.removeChild(stale);
    }
    screen = { session: session, expanded: Object.create(null),
      columnWidths: {}, menus: Object.create(null), toggles: Object.create(null), hiddenColumns: {},
      edits: requests.channel(session, send, "overview"),
      look: requests.channel(session, send, "locate", "view.invoke") };
    // What the view may reach of this screen; `render` keeps its snapshot fields current.
    screen.host = { session: session, send: send, edits: screen.edits, look: screen.look, disposed: false,
      gated: Object.create(null), draftReason: function () { return draftReason(screen); }, refuse: refuse };
    screen.zoneCells = new ZoneCells(session, send, refuse, function (field) { screen.optionDialog.open(field); },
      function () { return draftReason(screen, true); });
    screen.optionDialog = new OptionDialog(session, send, function () { return draftReason(screen); },
      function (message, tone) { panel.notify(message, tone); }, function (collection, result) {
        reconcileOptionFilters(screen, collection, result);
      });
    screen.options = tableOptions(screen);
    screen.help = ui.helpButton("Zones / Faces", HELP);
    screen.view = view.create(screen.host);
    screen.controls = new viewControls.ViewControls({
      label: "Zones", placeholder: "Zone, type or boundary", fields: ORDER_FIELDS, initialOrder: "name",
      columnSort: true,
      count: zoneCount, expansion: expansion(screen), guard: function () { return draftReason(screen); },
      refused: refuse
    }, function () { panel.repaint(); });
    return screen;
  }

  /* Work in hand that a filter, a tab change or another assignment must not hide or race. */
  function draftReason(state, skipCells) {
    if (state && state.optionDialog && state.optionDialog.active()) return "Finish the managed options draft first.";
    if (!skipCells && state && state.zoneCells && state.zoneCells.active()) {
      return ZONE_DRAFT;
    }
    return state && state.view ? view.draftReason(state.view) : null;
  }

  /* A refusal because a Zone edit is held offers to cancel it from the notice, so the way out is in view. */
  function refuse(reason) {
    var cells = screen && screen.zoneCells;
    panel.notify(reason, "warning", reason === ZONE_DRAFT && cells ? { label: "Cancel the Zone edit",
      run: function () { cells.cancelAll(); panel.repaint(); } } : null);
  }

  /* Held category filters follow explicit merge/removal results; rename keeps the same ID. */
  function reconcileOptionFilters(state, collection, result) {
    var replacements = result.replacement_ids || {};
    if (state.optionDialog.adopting) {
      delete state.controls.columnFilters.building_segment; delete state.controls.columnFilters.level; return;
    }
    var held = state.controls.columnFilters[collection]; if (!held) return;
    var mapped = held.map(function (id) {
      if (!Object.prototype.hasOwnProperty.call(replacements, id)) return id;
      return replacements[id] || (collection === "level" ? "" : null);
    }).filter(function (id, index, every) { return id !== null && every.indexOf(id) === index; });
    if (mapped.length) state.controls.columnFilters[collection] = mapped;
    else delete state.controls.columnFilters[collection];
  }

  /* The control row's count: Zones, how many a filter leaves, and how many column filters apply. */
  function zoneCount(shown, total, filtered, columnFilters) {
    var noun = total === 1 ? " Zone" : " Zones";
    var text = filtered && shown !== total ? shown + " of " + total + noun : total + noun;
    return columnFilters ? text + " · " + columnFilters + (columnFilters === 1 ? " filter" : " filters") : text;
  }

  /* What each column's menu offers. A Zone field orders the Zones and the view's fields order the rows
     beneath each Zone; the Zone fields with a value filter are listed here, the view's with the view. */
  var SORTED = ["name", "building_segment", "level", "ground_depth_mm"].concat(view.sorted);
  var ZONE_FILTERED = { building_segment: true, level: true };

  function filtered(field) {
    return Boolean(ZONE_FILTERED[field] || view.filteredFields[field]);
  }

  /* A Zone record keeps its stored values in `values`. */
  function filterValue(record, field) {
    var value = zoneOptions.value(record, field);
    return value === null || value === undefined ? "" : String(value);
  }

  /* A value's words in a filter. */
  function filterLabel(state, field, value) {
    if (view.filteredFields[field]) return view.filterLabel(state.view, field, value);
    if (field === "building_segment" || field === "level") {
      var choice = zoneOptions.find(zoneOptions.read(state.snapshot), field, value);
      if (choice) return choice.values.name;
      var source = (state.zoneRecords || []).filter(function (zone) { return filterValue(zone, field) === value; })[0];
      return source ? zoneOptions.label(zoneOptions.read(state.snapshot), source,
        field) : value ? "Choose a replacement" : "Not set";
    }
    return value || "Not set";
  }

  function columnMenu(state, field, label) {
    var menu = state.menus[field];
    if (!menu) {
      menu = state.menus[field] = new columnMenus.ColumnMenu({ label: label,
        valueAction: function (entry) { return classify.paint(field, entry.value, entry.label); },
        extra: function (root, anchor, close, reopen) {
          classify.extra(field, root, anchor, close, reopen);
          if (field === "building_segment" || field === "level") {
            var manage = ui.button("Manage " + zoneOptions.title(field) + "…", function () {
              close(); anchor.focus(); state.optionDialog.open(field);
            });
            manage.className = "phc-action-menu-item"; root.appendChild(manage);
          }
        },
        sort: { current: function () { return state.controls.columnDirection(field); },
          choose: function (direction) { state.controls.sortBy(field, direction); } },
        filter: filtered(field) ? { values: function () { return filterValues(state, field); },
          shown: function () { return state.controls.columnFilter(field); },
          set: function (values) { return state.controls.filterColumn(field, values); } } : null });
    }
    // The label carries a unit (Ground depth), which a unit switch changes.
    menu.options.label = label;
    menu.paint();
    return menu;
  }

  /* Present values plus every declared choice, in reading order, with the blank last. A view's field lists
     its own. */
  function filterValues(state, field) {
    var seen = Object.create(null), values = [];
    if (view.filteredFields[field]) values = view.filterValues(state.view, field);
    else {
      (state.zoneRecords || []).forEach(function (record) {
        var value = filterValue(record, field);
        if (!seen[value]) { seen[value] = true; values.push(value); }
      });
      zoneOptions.list(zoneOptions.read(state.snapshot), field).forEach(function (choice) {
        if (!seen[choice.id]) { seen[choice.id] = true; values.push(choice.id); }
      });
    }
    return values.map(function (value) { return { value: value, label: filterLabel(state, field, value),
      colour: filterColour(state, field, value) }; })
      .sort(function (a, b) { return Number(!a.value) - Number(!b.value) || ui.compareText(a.label, b.label); });
  }

  function filterColour(state, field, value) {
    var choice = zoneOptions.find(zoneOptions.read(state.snapshot), field, value);
    if (choice && /^#[0-9a-f]{6}$/i.test(choice.values.colour)) {
      return [1, 3, 5].map(function (start) { return parseInt(choice.values.colour.slice(start, start + 2), 16); });
    }
    return colourBy.colour(state.snapshot, COLOUR_BY[field], value);
  }

  /* The Colour-by mode each column shows the values of: the Zone columns' own, then the view's. */
  var COLOUR_BY = Object.assign({ name: { mode: "ph_composer.zones.by_zone" },
    building_segment: { mode: "ph_composer.zones.by_building_segment" }, level: { mode: "ph_composer.zones.by_level" }
  }, view.colourBy);

  function headerActions(state, field, label) {
    var actions = [];
    if (COLOUR_BY[field] && !state.hiddenColumns[field]) {
      var toggle = state.toggles[field] || (state.toggles[field] = new colourBy.HeaderToggle(COLOUR_BY[field]));
      if (toggle.paint(state.snapshot)) actions.push({ node: toggle.node, persistent: toggle.pressed });
    }
    var paint = classify.header(field, label);
    if (paint) actions.push(paint);
    if (SORTED.indexOf(field) < 0) return actions;
    var menu = columnMenu(state, field, label);
    return actions.concat([{ node: menu.root, persistent: menu.filtered() }]);
  }

  /* A mode a visible column offers; every other registered mode is offered in Table options. */
  function boundToColumn(state, mode) {
    return Object.keys(COLOUR_BY).some(function (field) {
      var binding = COLOUR_BY[field];
      return !state.hiddenColumns[field] && (binding.mode ? binding.mode === mode.name : binding.group === mode.group);
    });
  }

  /* Table options: show or hide Ground depth, and Colour by for a mode no visible column offers. */
  function tableOptions(state) {
    var menu = new ui.ActionMenu("Table options", { onOpen: function () { fill(); } });
    function toggle(text, pressed, handler) {
      var item = menu.add(text, handler);
      item.classList.add("phc-setting-choice");
      item.setAttribute("aria-pressed", String(pressed));
    }
    function fill() {
      var legend = snapshot.value(panel.state, "ph_composer.colour_by.legend") || { mode: null };
      menu.content.replaceChildren();
      toggle("Ground depth column", !state.hiddenColumns.ground_depth_mm, function () {
        state.hiddenColumns.ground_depth_mm = !state.hiddenColumns.ground_depth_mm;
        panel.repaint();
      });
      colourBy.modes(panel.state).filter(function (mode) { return !boundToColumn(state, mode); })
        .forEach(function (mode) {
          var on = legend.mode === mode.name;
          toggle("Colour by " + mode.label, on, function () { colourBy.activate(panel.state, on ? null : mode.name); });
        });
    }
    menu.root.classList.add("phc-table-options");
    return menu;
  }

  /* Collapse all and Expand all act on the tree, because this screen groups by the tree rather than
     by a field: a Zone is the group its Faces sit in. */
  function expansion(state) {
    return {
      collapseAll: function () { state.zoneKeys.forEach(function (key) { state.expanded[key] = false; }); },
      expandAll: function () { state.zoneKeys.forEach(function (key) { state.expanded[key] = true; }); },
      canCollapse: function () { return state.zoneKeys.some(function (key) { return open(state, key); }); },
      canExpand: function () { return state.zoneKeys.some(function (key) { return !open(state, key); }); }
    };
  }

  function open(state, key) {
    return Object.prototype.hasOwnProperty.call(state.expanded, key) ? state.expanded[key] : true;
  }

  function columns(profile) {
    var depth = units.profile(ZoneCells.GROUND_DEPTH, preferences.current());
    return [["actions", "Actions"], ["hierarchy", "Hierarchy"], ["name", "Name"]].concat(ZoneCells.columns(depth),
      view.columns(profile));
  }

  /* One row per Zone occurrence from the Zones read, each followed by the rows the view puts beneath it.
     A Zone row is keyed by the path that names one Zone occurrence, not by the Zone's record id: a copied Zone
     Group shares its original's dictionary until the copy is repaired, so two occurrences can carry one id,
     and the Zones read reports both and says so in `state`. Keying on the id would put the copy's rows under
     the original's and drop one Zone off the screen entirely. */
  function project(zones, state) {
    var rows = [];
    zones.forEach(function (zone) {
      var key = JSON.stringify(["Zone", zone.reference.zone_path]);
      var row = { key: key, parent: null, tier: "Zone", depth: 0,
        record: view.zoneRecord(state.view, { id: key, name: zone.values.name, zone: zone, state: zone.state }) };
      rows.push(row);
      rows.push.apply(rows, view.children(state.view, row));
    });
    return rows;
  }

  function occurrence(path) {
    return JSON.stringify(path || []);
  }

  function value(row, field, profile) {
    if (field === "name") return row.record.name;
    if (ZONE_FIELDS[field]) return "";
    return view.value(row, field, profile);
  }

  var ZONE_FIELDS = { building_segment: true, level: true, ground_depth_mm: true };

  /* What is wrong with the Zone comes before what the view says of it. A Zone that shares its identity with a
     copy is the first thing to say, because every edit made here names one occurrence and nothing else on the
     screen tells the user there are two. */
  function marker(row) {
    var trouble = ZONE_STATES[row.record.state];
    if (trouble) return { text: trouble.text, icon: trouble.icon, tooltip: (trouble.tooltip + " " +
      independenceHint(row.record.zone && row.record.zone.independence)).trim() };
    return view.zoneMarker(row);
  }

  /* What the user can do about a shared Zone: the row's Make independent action, or what comes first. */
  function independenceHint(independence) {
    if (!independence) return "";
    return independence.available ? "Make it independent from its row's actions." : independence.reason || "";
  }

  /* The view's row actions, with Make independent on a Zone row before the view's own Zone actions. */
  function actions(state, row) {
    var items = view.actions(state.view, row);
    if (row.depth !== 0) return items;
    var independence = row.record.zone.independence;
    if (independence && independence.available) {
      items.push({ id: "independent", icon: "repair", label: "Make " + row.record.name + " independent" });
    }
    return items.concat(view.zoneActions(row));
  }

  /* A press in the panel outside a Locate control clears Locate's outline. */
  document.addEventListener("pointerdown", function (event) {
    if (!screen) return;
    for (var node = event.target; node; node = node.parentNode) {
      if (node.getAttribute && node.getAttribute("data-row-action") === "locate") return;
    }
    view.clearLocate(screen.view);
  }, true);

  /* Escape unwinds one layer on this screen: an open bubble or menu takes its own first (it marks the event
     handled), then the view's. */
  document.addEventListener("keydown", function (event) {
    if (event.key !== "Escape" || event.defaultPrevented || !screen || !panel.state ||
        panel.state.ui.activeTab !== "overview") return;
    if (Array.from(document.querySelectorAll("dialog")).some(function (dialog) { return dialog.open; })) return;
    if (view.escape(screen.view)) event.preventDefault();
  });

  /* Make Zone independent names the occurrence it acts on and what it costs before it writes. Either
     occurrence can be the one that takes the new identity, and both can carry the same name, so the
     dialog offers Locate and says what the other keeps. */
  function confirmIndependent(state, row) {
    var reason = draftReason(state);
    if (reason) return refuse(reason);
    var zone = row.record.zone, retired = zone.independence.retired_pairs, dialog = state.independenceDialog;
    if (!dialog) {
      dialog = state.independenceDialog = ui.formDialog("", function () { dialog.closeModal(); });
      document.body.appendChild(dialog);
    }
    var consequence = "This occurrence gets its own Faces and a new identity. The other occurrence keeps the " +
      "current identity." + (retired ? " " + retired + (retired === 1 ? " Surface pair on this occurrence's " +
        "Faces is" : " Surface pairs on this occurrence's Faces are") + " retired; run Solve adjacencies " +
        "again afterwards." : "");
    var cancel = ui.button("Cancel", function () { dialog.closeModal(); });
    var footer = ui.actionRow(cancel,
      ui.button("Make independent", function () {
        dialog.closeModal();
        if (state.disposed || state.edits.busy()) return;
        state.edits.run("ph_composer.zones.make_independent", { zone_path: zone.reference.zone_path });
        panel.repaint();
      }));
    footer.insertBefore(ui.button("Locate", function () { view.locate(state.view, row); }), footer.firstChild);
    dialog.replaceChildren(ui.element("h2", "", "Make " + row.record.name + " independent"),
      ui.element("p", "", consequence), footer);
    dialog.openModal();
    cancel.focus();
  }

  /* The page header is built once a session and repainted in place, so a press on any of its controls
     (Classify faces, the gear) keeps its focus through the snapshot that follows.
     It holds the authoring toolbar and settings gear. Make Zone lives in SketchUp's context menu;
     view controls stay in the control row. */
  function header(state, pane) {
    if (state.header) return state.header;
    var parts = { toolbar: ui.element("div", "phc-toolbar") };
    parts.toolbar.setAttribute("role", "toolbar");
    parts.toolbar.setAttribute("aria-label", "Zone and Face tools");
    parts.toolbar.appendChild(panel.region(pane, "actions"));
    parts.page = ui.pageHeader({ title: "Zones", actions: [parts.toolbar, view.settings(state.view)] });
    state.header = parts;
    return parts;
  }

  function render(root, state, send) {
    var zones = snapshot.value(state, "ph_composer.zones.overview") || { zones: [], make_zone: null };
    var screenState = forSession(state.session, send), profile = units.profile(AREA, preferences.current());
    var host = screenState.host;
    screenState.send = host.send = send;
    screenState.snapshot = host.snapshot = state;
    screenState.zoneRecords = zones.zones;
    host.gated = Object.create(null);
    zones.zones.forEach(function (zone) {
      if (ZoneCells.gated(zone)) host.gated[occurrence(zone.reference.zone_path)] = true;
    });
    screenState.revision = host.revision = state.revision;
    screenState.optionDialog.consume(state, zoneOptions.read(state));
    view.consume(screenState.view, state, send);
    var rows = project(zones.zones, screenState);
    // A row the view adds may open by default. That is decided once, when the row first appears, so it does
    // not snap shut or open under the user as what it holds changes.
    rows.forEach(function (row) {
      var open = row.depth === 0 ? null : view.initiallyOpen(row);
      if (open !== null && !Object.prototype.hasOwnProperty.call(screenState.expanded, row.key)) {
        screenState.expanded[row.key] = open;
      }
    });
    screenState.edits.consume(state);
    screenState.look.consume(state);
    // Collapse all and Expand all reach everything that opens: Zones and the view's rows that open by default.
    screenState.zoneKeys = rows.filter(function (row) {
      return row.depth === 0 || view.initiallyOpen(row) !== null;
    }).map(function (row) { return row.key; });
    if (!root.querySelector(".phc-table-mount")) {
      root.className = "phc-overview";
      root.replaceChildren(ui.element("div", "phc-heading-mount"), screenState.controls.root,
        ui.element("div", "phc-table-mount"));
    }
    // The pane's tools (whatever sections registered there) end this screen's control row. Found before the
    // row changes hands, so a new session's row inherits them instead of leaving them in the old one.
    var tools = panel.region(root.closest("[data-pane]").getAttribute("data-pane"), "tools");
    var row = root.children[1];
    if (row !== screenState.controls.root) {
      root.insertBefore(screenState.controls.root, row);
      root.removeChild(row);
    }
    if (screenState.options.root.parentNode !== screenState.controls.root) {
      screenState.controls.root.insertBefore(screenState.options.root, screenState.controls.count.nextSibling);
      screenState.controls.root.insertBefore(screenState.help, screenState.options.root.nextSibling);
    }
    if (tools.parentNode !== screenState.controls.root) screenState.controls.root.appendChild(tools);
    var heading = header(screenState, root.closest("[data-pane]").getAttribute("data-pane")).page.root;
    var headingMount = root.querySelector(".phc-heading-mount");
    if (heading.parentNode !== headingMount) headingMount.replaceChildren(heading);
    // Set before the tree paints, so the selection bar never works from an earlier pass if painting fails.
    screenState.rows = rows;
    screenState.zoneCells.refresh(rows.filter(depth(0)), state);
    paintTable(root.querySelector(".phc-table-mount"), rows, screenState, profile);
  }

  /* The view's selection bar floats over the bottom of the table. */
  function renderBar(root, state) {
    var overview = document.querySelector("[data-section='ph_composer.overview']");
    if (!screen || screen.session !== state.session || !overview) return;
    var bar = view.selectionBar(screen.view, overview);
    root.hidden = true;
    var mount = overview.querySelector(".phc-table-mount");
    if (mount) bar.reserve(mount);
  }

  function depth(wanted) {
    return function (row) { return row.depth === wanted; };
  }

  /* The view controls order and filter Zones, because a Zone is what the tree is built from; the view's rows
     follow it, ordered among themselves by the same field. They project the Zone records, and `rows` tells
     them how a view's row traces back to the Zone that decides whether it shows. Filtering reads the view's
     rows too, so a search for "Ground" keeps the Zone that has a Ground Face. */
  function paintTable(mount, rows, state, profile) {
    var zoneRows = rows.filter(depth(0));
    var byId = Object.create(null);
    zoneRows.forEach(function (row) { byId[row.record.id] = row; });
    var projection = state.controls.project(zoneRows.map(function (row) { return row.record; }), {
      id: function (record) { return record.id; },
      value: function (record, field) {
        if (field === "area_m2") return record.area;
        if (field === "name") return record.name;
        return view.filteredFields[field] ? null : field === "building_segment" || field === "level" ?
          zoneOptions.label(zoneOptions.read(state.snapshot), record.zone, field) : record.zone.values[field];
      },
      search: function (record) { return searchText(record, state); },
      // A Zone shows while its own values pass the Zone filters and the view's filters pass it too; a view's
      // row shows while the view says it does.
      columnMatch: function (record, filters) {
        return zoneMatches(record, filters) && view.zoneMatch(record, filters);
      },
      rowMatch: function (row, filters) { return view.rowMatch(row, filters); },
      rows: function () { return rows; }
    });
    var labels = Object.create(null);
    columns(profile).forEach(function (column) { labels[column[0]] = column[1]; });
    var shown = ordered(projection.records, byId, rows, state.controls, state);
    var visible = shown.filter(function (row) { return !projection.hidden(row); });
    var filters = state.controls.columnFilters;
    var filterFaces = view.filterFaces(visible.filter(depth(0)), filters);
    // Only column Show filters affect the viewport. Text search and collapsed rows remain table navigation.
    var matchingPaths = state.controls.filterCount() ? zoneRows.reduce(function (all, row) {
      if (!zoneMatches(row.record, filters)) return all;
      return all.concat(view.viewportPaths(row.record, filters));
    }, []).sort(function (a, b) { return ui.compareText(JSON.stringify(a), JSON.stringify(b)); }) : null;
    colourBy.filter(state.snapshot, matchingPaths);
    view.painted(state.view, zoneRows, filterFaces);
    var parents = Object.create(null);
    rows.forEach(function (row) { if (row.parent) parents[row.parent] = true; });
    tables.table(mount, rows, {
      // Sized so the whole table shows at the panel's usual width; labels have their own band above the icons,
      // and the user can still drag any column wider.
      defaultWidths: { name: 142, building_segment: 136, level: 84, ground_depth_mm: 128, face_type: 126,
        boundary_condition: 110, area_m2: 104, assembly_id: 156 },
      tree: true, rows: shown, columns: columns(profile),
      expanded: state.expanded,
      expandable: function (row) { return Boolean(parents[row.key]); },
      decorate: view.decorate,
      columnWidths: state.columnWidths, visibleCount: projection.visibleCount, disabled: state.edits.busy(),
      empty: zoneRows.length ? "No Zones match this filter." :
        "No Zones yet. Select geometry in SketchUp, then right-click and choose Make Zone.",
      value: function (row, field) { return value(row, field, profile); },
      cell: function (td, row, field) {
        return state.zoneCells.render(td, row, field) || view.cell(state.view, td, row, field);
      },
      marker: marker, actions: function (row) { return actions(state, row); }, rowHidden: projection.hidden,
      hiddenColumns: state.hiddenColumns, revealRowActions: true,
      check: view.check(state.view, visible, filterFaces),
      headerActions: function (field) { return headerActions(state, field, labels[field]); },
      inspect: function (row) { view.inspect(state.view, row); },
      columnResize: function (field, width) {
        if (field === null) state.columnWidths = {};
        else if (width === null) delete state.columnWidths[field];
        else state.columnWidths[field] = width;
      },
      action: function (row, item) {
        if (item.id === "independent") confirmIndependent(state, row);
        else view.action(state.view, row, item);
      }
    });
  }

  /* Whether a Zone's own values pass the Zone filters; the view's fields are the view's to judge. */
  function zoneMatches(record, filters) {
    return Object.keys(filters).every(function (field) {
      return view.filteredFields[field] || filters[field].indexOf(filterValue(record.zone, field)) >= 0;
    });
  }

  function searchText(record, state) {
    return [record.name, zoneOptions.label(zoneOptions.read(state.snapshot), record.zone, "building_segment"),
      zoneOptions.label(zoneOptions.read(state.snapshot), record.zone, "level"),
      view.search(state.view, record)].join(" ");
  }

  /* The Zone order the controls settled on, each Zone followed by its own rows in the order the view gives
     them for the sorted column. */
  function ordered(records, byId, rows, controls, state) {
    var children = Object.create(null), field = controls.sortField(), direction = controls.sortDirection();
    rows.forEach(function (row) {
      if (row.parent) (children[row.parent] = children[row.parent] || []).push(row);
    });
    function withChildren(row) {
      return view.sort(state.view, children[row.key] || [], field, direction).reduce(function (all, child) {
        return all.concat(withChildren(child));
      }, [row]);
    }
    return records.reduce(function (all, record) { return all.concat(withChildren(byId[record.id])); }, []);
  }

  // First in its pane: the Zone tree is the screen's work surface, and the palette and column menus
  // are controls that act on what it shows.
  // A refused tab change restates its reason through `refuse`, so a held Zone edit's notice offers Cancel too.
  panel.navigationGuard("ph_composer.overview", function () { return draftReason(screen); },
    function () { var reason = draftReason(screen); if (reason) refuse(reason); });
  // A refused Zone write says what to do about a shared Zone rather than naming its duplicated id.
  panel.outcomeText(function (result) {
    if (!screen || result.session !== screen.session || !screen.zoneCells.owns(result.request_id)) return null;
    return ZoneCells.refusalText(result.outcome);
  }, { owner: "ph_composer.zones" });
  /* Another tab can open this one with Faces checked and, with `locate: true`, framed
     (`panel.navigate("overview", { check: references, locate: true })`), as the Assemblies tab's "Select
     faces using" does. Locating here keeps the outline this screen's to clear. */
  panel.section("ph_composer.overview", render, { order: 10, onNavigate: function (root, intent) {
    if (!screen || !intent.check) return;
    view.navigate(screen.view, intent);
    panel.repaint();
  } });
  panel.workedOn("ph_composer.zones", "overview");
  panel.section("ph_composer.zones.selection_bar", renderBar, { order: 1000 });
});
