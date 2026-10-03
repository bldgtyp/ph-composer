/* The Overview screen: the model tree of Zones with their classified Faces beneath, the shared view
 * controls above it, and the selected Zone's own fields below.
 *
 * The table is the shared record table; this file holds only this screen's vocabulary: its columns,
 * what each cell reads, its row actions and its editable chips. Every write goes through a registered
 * action carrying the values the row was painted from, and Locate goes through the view command,
 * which changes the selection and the camera and writes nothing.
 *
 * An unclassified Face is not a row. Its Zone's row carries the count and the Suggest
 * classification action that gives those Faces a record.
 */
PhComposerUI.define("features/zones/overview", ["panel", "workspace", "request", "snapshot", "units",
  "unit_preferences", "unit_field", "table", "view_controls", "fields", "face_words",
  "features/zones/attached_zone_assignment", "features/zones/zone_settings", "features/zones/selection_assignment",
  "features/zones/assembly_assignment"],
function (panel, ui, requests, snapshot, units, preferences, unitFields, tables, viewControls, fields, words,
          attachedAssignment, ZoneSettings, SelectionAssignment, assemblies) {
  "use strict";
  var AREA = fields.AREA_M2;
  // What a chip offers comes from the host, through the same read the Classify palette uses, so this
  // screen cannot drift from what the feature will actually accept. What it subtracts is its own:
  // a value the palette lists but a chip cannot set on its own keeps its cell read only.
  var ORDER_FIELDS = [["name", "Name"], ["area_m2", "Area"]];
  // What the Zones read says is wrong with a Zone occurrence, in the words the user needs.
  var ZONE_STATES = {
    ambiguous: { text: "shared identity",
      tooltip: "Another Zone carries the same identity, which a copy does until it is repaired. " +
        "Repair it before classifying, or an edit here may reach the other one." },
    shared_definition: { text: "shared definition",
      tooltip: "This Zone is one of several instances of the same component, so editing it edits " +
        "them all. Make it unique before classifying." },
    wrong_hierarchy: { text: "nested",
      tooltip: "This Zone sits inside another Zone. A Zone is one Room, so a Zone within a Zone " +
        "cannot be exported as it stands." }
  };

  var DRAFT_OPEN = "Save or cancel the Zone details first.";
  var screen = null;

  /* This screen's own state, rebuilt whenever the panel shows a different Model. */
  function forSession(session, send) {
    if (screen && screen.session === session) return screen;
    if (screen) { screen.disposed = true; screen.edits.reset(); screen.look.reset(); }
    if (screen && screen.zoneEditor) screen.zoneEditor.dispose();
    if (screen && screen.attachedDraft) screen.attachedDraft.dispose();
    if (screen && screen.settings) screen.settings.dispose();
    if (screen && screen.selectionAssignment) screen.selectionAssignment.dispose();
    screen = { session: session, selected: null, expanded: Object.create(null), columnWidths: {},
      edits: requests.channel(session, send, "overview"),
      look: requests.channel(session, send, "locate", "view.invoke") };
    screen.settings = new ZoneSettings(session, send, function () { return draftReason(screen); }, refuse);
    screen.selectionAssignment = new SelectionAssignment(session, send, function () {
      return draftReason(screen);
    }, refuse);
    screen.controls = new viewControls.ViewControls({
      label: "Zones", placeholder: "Zone, type or boundary", fields: ORDER_FIELDS, initialOrder: "name",
      expansion: expansion(screen), guard: function () { return draftReason(screen); }, refused: refuse
    }, function () { panel.repaint(); });
    return screen;
  }

  /* One Zone details draft at a time. While the form holds unsaved edits or a Save in flight,
     anything that would hide it is refused rather than discarding the draft; the user saves or
     cancels first. Model switch still withdraws the editor, because that draft is for another Model. */
  function draftReason(state) {
    if (state && state.attachedDraft) return "Finish the Attached zone assignment first.";
    if (state && state.selectionAssignment && state.selectionAssignment.active()) {
      return "Finish the selected Faces assignment first.";
    }
    if (state && state.settings && state.settings.busy()) return "Wait for the Zone settings change to finish.";
    var editor = state && state.zoneEditor;
    return editor && (editor.dirty || editor.pending) ? DRAFT_OPEN : null;
  }

  function refuse(reason) {
    panel.notify(reason, "warning");
    if (screen && screen.zoneEditor) screen.zoneEditor.focus();
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
    return [["actions", "Actions"], ["hierarchy", "Hierarchy"], ["name", "Name"],
      ["face_type", "Type"], ["boundary_condition", "Boundary"],
      ["area_m2", units.header("Gross area", AREA, profile)], ["assembly_id", "Assembly"]];
  }

  /* Zone rows from the Zones read, their Faces from the Faces read, matched by the path that names
     one Zone occurrence. Not by the Zone's record id: a copied Zone Group shares its original's
     dictionary until the copy is repaired, so two occurrences can carry one id, and the
     zones read reports both and says so in `state`. Keying on the id would put the copy's Faces
     under the original's row, sum both areas into it and drop one Zone off the screen entirely.

     A Face with no record counts towards its Zone's marker rather than towards a row of its own. */
  function project(zones, faces) {
    var byZone = Object.create(null), rows = [];
    faces.forEach(function (face) {
      var key = occurrence(face.reference.zone_path);
      (byZone[key] = byZone[key] || []).push(face);
    });
    zones.forEach(function (zone) {
      var own = byZone[occurrence(zone.reference.zone_path)] || [];
      var recorded = own.filter(function (face) { return face.state !== "unclassified"; });
      var key = JSON.stringify(["Zone", zone.reference.zone_path]);
      rows.push({ key: key, parent: null, tier: "Zone", depth: 0,
        record: { id: key, name: zone.values.name, zone: zone, faces: recorded,
          state: zone.state, unclassified: own.length - recorded.length } });
      recorded.forEach(function (face) {
        rows.push({ key: JSON.stringify(["Face", zone.reference.zone_path, face.reference.entity_path]),
          parent: key, tier: "Face", depth: 1,
          record: { id: face.reference.entity_id, name: faceName(face, own), face: face } });
      });
    });
    return rows;
  }

  function occurrence(path) {
    return JSON.stringify(path || []);
  }

  /* A Face is named by what it is and where it sits among every Face of its Zone, counting the ones
     with no record. Numbering the recorded ones alone would renumber and rekey a Face the user never
     touched as soon as a neighbour was classified, which takes that row's selection and any edit in
     progress with it. */
  function faceName(face, all) {
    var place = all.indexOf(face) + 1;
    return (face.values.face_type ? words.faceType(face.values.face_type) : "Face") + " " + place;
  }

  function value(row, field, profile) {
    var face = row.record.face;
    if (field === "name") return row.record.name;
    if (!face) return field === "area_m2" ? area(totalArea(row.record.faces), profile) : "";
    if (field === "face_type") return words.faceType(face.values.face_type);
    if (field === "boundary_condition") {
      return words.boundary(face.values.boundary_condition);
    }
    return area(face.area_m2, profile);
  }

  function totalArea(faces) {
    return faces.reduce(function (sum, face) { return sum + face.area_m2; }, 0);
  }

  function area(square_metres, profile) {
    return units.format(square_metres, AREA, profile, { showUnit: false });
  }

  /* What is wrong with the Zone comes before what is unfinished in it. A Zone that shares its
     identity with a copy is the first thing to say, because every edit made here names one
     occurrence and nothing else on the screen tells the user there are two. */
  function marker(row) {
    var count = row.record.unclassified, trouble = ZONE_STATES[row.record.state];
    if (trouble) return { text: trouble.text, tooltip: trouble.tooltip };
    if (!count) return null;
    return { text: String(count),
      tooltip: count + " unclassified Faces in this Zone have no record yet. Suggest classification writes one " +
        "for each of them and leaves every Face that already has one alone." };
  }

  function actions(row) {
    var locatable = row.record.face || row.record.faces.length;
    var items = [{ id: "locate", icon: "locate", disabled: !locatable,
      label: locatable ? "Locate " + row.record.name :
        "Nothing to locate: no Face in " + row.record.name + " has a record yet" }];
    if (row.depth === 0 && row.record.unclassified) {
      items.push({ id: "suggest", icon: "sort", label: "Suggest classification for " + row.record.name });
    }
    return items;
  }

  /* What a chip in this column offers: the values the host published, less the ones a chip cannot
     set on its own. A Face already holding one of those keeps it and its cell stays read only. */
  function choices(state, field) {
    return (field === "face_type" ? state.faceTypes : state.boundaries)
      .filter(function (value) { return value === "AttachedZone" || !words.UNCHOOSABLE[value]; });
  }

  function chipLabel(field, value) {
    return field === "face_type" ? words.faceType(value) : words.boundary(value);
  }

  /* What a Face's type or boundary cell still needs, in words, or null. The host's verdict for the whole
     row is `state`; this says which cell it is about, so the flag sits where the fix is made. */
  function problem(face, field) {
    if (!face || (field !== "face_type" && field !== "boundary_condition")) return null;
    if (!face.values[field]) return field === "face_type" ? "Type not set" : "Boundary not set";
    if (field !== "boundary_condition") return null;
    if (face.attached_zone_state && face.attached_zone_state !== "resolved") {
      return "The Attached zone record is missing. Choose one.";
    }
    if (face.adjacency_state && face.adjacency_state !== "current") {
      return "This adjacency is out of date. Run Solve adjacencies.";
    }
    return null;
  }

  function flag(td, issue) {
    td.classList.toggle("is-flagged", Boolean(issue));
    if (issue) td.title = issue;
  }

  /* A cell that shows its value as text: an earlier control, if it had one, is forgotten. */
  function readOnly(td, field) {
    if (td._chip || td._attachedChip) td.className = "col-" + field;
    td._chip = td._attachedChip = td._chipValues = null;
    return false;
  }

  /* Type and boundary are editable chips; area is read only. An edit sends the values the row was
     painted from, so a Model that changed underneath refuses rather than overwriting.

     The control is built once per cell and repainted afterwards. Rebuilding it on every snapshot
     would take the user's open dropdown with it, and a snapshot follows every viewport click.

     A stored value the chip does not offer is shown as text rather than silently missing from the
     control: an `AirBoundary` Face, or one the solver paired, reads what it is and refuses the edit. */
  function cell(td, row, field, text, state) {
    var face = row.record.face, offered, chip;
    if (field === "assembly_id") return assemblies.cell(td, row, state, draftReason, refuse);
    if (!face || (field !== "face_type" && field !== "boundary_condition")) return false;
    var issue = problem(face, field);
    if (field === "boundary_condition" && face.values.boundary_condition === "AttachedZone") {
      attachedCell(td, row, state);
      flag(td, issue);
      return true;
    }
    td._attachedChip = null;
    offered = choices(state, field);
    if (!offered.length) return readOnly(td, field);
    if (face.values[field] && offered.indexOf(face.values[field]) < 0) return readOnly(td, field);
    chip = td._chip;
    // A Face with no value here yet reads "?": the flag sits on the cell that needs it.
    var missing = !face.values[field], signature = (missing ? "?," : "") + offered.join(",");
    if (!chip || td._chipValues !== signature) {
      var hadFocus = Boolean(chip) && document.activeElement === chip;
      chip = ui.element("select", "phc-cell-input phc-enum-cell");
      if (missing) {
        var unset = ui.option("", "?");
        unset.disabled = true;
        chip.appendChild(unset);
      }
      offered.forEach(function (choice) {
        var option = ui.element("option", "", chipLabel(field, choice));
        option.value = choice;
        chip.appendChild(option);
      });
      chip.addEventListener("change", function () {
        if (field === "boundary_condition" && chip.value === "AttachedZone") {
          openAttached(td._state, td._face, chip);
          chip.value = td._face.values[field] || "";
        } else apply(td._state, td._face, field, chip.value);
      });
      td.className = "col-" + field + " phc-editable-cell";
      td.replaceChildren(chip);
      td._chip = chip;
      td._chipValues = signature;
      // Filling a "?" rebuilds the control without it; the user's place in the table stays.
      if (hadFocus) chip.focus();
    }
    td._state = state;
    td._face = face;
    chip.value = face.values[field] || "";
    chip.disabled = state.edits.busy();
    chip.setAttribute("aria-label", (missing ? "Set " : "") + row.record.name +
      (field === "face_type" ? " type" : " boundary"));
    td.title = "";
    flag(td, issue);
    return true;
  }

  function attachedCell(td, row, state) {
    var chip = td._attachedChip;
    if (!chip) {
      chip = ui.button("Attached zone", function () { openAttached(td._state, td._face, chip); });
      chip.className = "phc-cell-input";
      td.className = "col-boundary_condition phc-editable-cell";
      td.replaceChildren(chip); td._attachedChip = chip; td._chip = null; td._chipValues = null;
    }
    td._state = state; td._face = row.record.face;
    chip.disabled = state.edits.busy();
    chip.setAttribute("aria-label", row.record.name + " boundary");
    chip.title = "Choose or create an Attached zone";
    return true;
  }

  function openAttached(state, face, trigger) {
    if (state.attachedDraft) return;
    state.attachedDraft = attachedAssignment.open(state.session, state.send, state.revision, face,
      state.attachedRecords, trigger, function () { state.attachedDraft = null; panel.repaint(); });
  }

  function apply(state, face, field, chosen) {
    var intent = { face_type: { mode: "keep" }, boundary_condition: { mode: "keep" } };
    intent[field] = { mode: "set", value: chosen };
    state.edits.run("ph_composer.zones.faces.classify",
      { faces: [face.reference], intent: intent, expected_values: face.values });
  }

  function locate(state, row) {
    var references = row.record.face ? [row.record.face.reference]
      : row.record.faces.map(function (face) { return face.reference; });
    if (references.length) state.look.run("ph_composer.zones.faces.locate", { faces: references });
  }

  function suggest(state, row) {
    state.edits.run("ph_composer.zones.faces.auto_classify", { zone: row.record.zone.reference });
  }

  function makeButton(state, target) {
    var make = ui.element("button", "primary", state.edits.busy() ? "Making Zone…" : "Make Zone");
    make.disabled = state.edits.busy() || !target;
    make.setAttribute("aria-label", target ? "Make Zone from the current selection" :
      "Select one Group or loose geometry to make a Zone");
    make.addEventListener("click", function () {
      if (target) state.edits.run("ph_composer.zones.make", target);
    });
    return make;
  }

  function makeZoneReason() {
    var reason = "Make Zone needs one Group, or loose Faces and Edges, selected in SketchUp and not " +
      "already part of a Zone.";
    var node = ui.iconButton("Why Make Zone is unavailable: " + reason, "alert", function () {
      panel.notify(reason);
    });
    node.className += " phc-blocked-reason";
    return node;
  }

  function solveButton(state, zones) {
    var button = ui.element("button", "", "Solve adjacencies");
    button.disabled = state.edits.busy() || !zones.length;
    button.setAttribute("aria-label", "Solve adjacencies for all Zones in this Model");
    button.addEventListener("click", function () {
      var reason = draftReason(state);
      if (reason) return refuse(reason);
      state.edits.run("ph_composer.zones.solve_adjacency", {
        zones: zones.map(function (zone) { return zone.reference; })
      });
    });
    return button;
  }

  function render(root, state, send) {
    var zones = snapshot.value(state, "ph_composer.zones.overview") || { zones: [], make_zone: null };
    var faces = (snapshot.value(state, "ph_composer.zones.faces.faces") || { faces: [] }).faces;
    var tool = snapshot.value(state, "ph_composer.zones.faces.palette") || {};
    var screenState = forSession(state.session, send), profile = units.profile(AREA, preferences.current());
    screenState.send = send;
    screenState.snapshot = state;
    screenState.assemblyEnabled = Boolean(snapshot.value(state, "ph_composer.zones.faces.assemblies") &&
      snapshot.value(state, "ph_composer.zones.faces.faces"));
    screenState.revision = state.revision;
    screenState.attachedRecords = (snapshot.value(state, "ph_composer.zones.faces.attached_zone.list") ||
      { records: [] }).records;
    if (screenState.attachedDraft) screenState.attachedDraft.consume(state);
    screenState.selectionAssignment.consume(state, screenState.attachedRecords);
    screenState.faceTypes = tool.face_types || [];
    screenState.boundaries = tool.boundary_conditions || [];
    var rows = project(zones.zones, faces);
    screenState.edits.consume(state);
    screenState.look.consume(state);
    screenState.settings.consume(state, snapshot.value(state, "ph_composer.zones.settings"));
    screenState.zoneKeys = rows.filter(depth(0)).map(function (row) { return row.key; });
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
    if (tools.parentNode !== screenState.controls.root) screenState.controls.root.appendChild(tools);
    var headerActions = [solveButton(screenState, zones.zones), screenState.settings.bubble.root];
    // Why the primary action is not available, beside it.
    if (!zones.make_zone) headerActions.push(makeZoneReason());
    root.querySelector(".phc-heading-mount").replaceChildren(ui.pageHeader({ title: "Zones",
      count: zones.zones.length, actions: headerActions,
      primary: makeButton(screenState, zones.make_zone) }).root);
    // Set before the tree paints, so the inspector never works from an earlier pass if painting fails.
    screenState.rows = rows;
    screenState.targets = (snapshot.value(state, "ph_composer.zones.faces.selected") || {}).targets || [];
    paintTable(root.querySelector(".phc-table-mount"), rows, screenState, profile);
  }

  /* The inspector's two sections. Both paint from what the tree's render just worked out, which the
     panel guarantees by rendering in order. Zone details hold the inspector while they carry a draft. */
  function renderDetails(root, state) {
    if (!screen || screen.session !== state.session || !screen.rows) { root.replaceChildren(); return; }
    paintDetails(root, screen.rows, screen);
  }

  function detailsWanted() {
    var editor = screen && screen.zoneEditor;
    return editor ? (editor.dirty || editor.pending ? "hold" : true) : false;
  }

  function renderSelection(root, state) {
    if (!screen || screen.session !== state.session) { root.replaceChildren(); return; }
    var controls = screen.selectionControls || (screen.selectionControls = selectionControls(screen));
    if (controls.root.parentNode !== root) { root.className = "phc-selection"; root.replaceChildren(controls.root); }
    controls.paint();
  }

  function selectionWanted() {
    return Boolean(screen && screen.targets && screen.targets.length);
  }

  /* What the selected Faces share, one attribute at a time: each choice applies at once to every Face
     selected, as one Undo step. A value they do not share reads "Mixed". Attached zone needs a record,
     so it is offered where a record can be chosen: a Face's own row and the right-click menu. */
  function selectionControls(state) {
    var root = ui.element("div", "phc-selection-controls"), title = ui.element("h2");
    var heading = ui.element("div", "phc-zone-heading");
    var fields = {};
    function common(field) {
      var values = state.targets.map(function (target) { return target.expected_values[field] || ""; });
      return values.every(function (value) { return value === values[0]; }) ? values[0] : null;
    }
    function control(field, label) {
      var select = ui.element("select"), wrap = ui.element("label", "phc-selection-field");
      select.setAttribute("aria-label", label + " for selected Faces");
      select.addEventListener("change", function () {
        var reason = draftReason(state), chosen = select.value;
        if (!chosen) { paint(); return; }
        if (reason) { paint(); refuse(reason); return; }
        var intent = { face_type: { mode: "keep" }, boundary_condition: { mode: "keep" } };
        var params = { faces: state.targets.map(function (target) { return target.reference; }), intent: intent };
        intent[field] = { mode: "set", value: chosen };
        // One Face is guarded by the values it was read with; several rarely share them, so the Model's
        // own checks stand alone.
        if (state.targets.length === 1) params.expected_values = state.targets[0].expected_values;
        state.edits.run("ph_composer.zones.faces.classify", params);
        paint();
      });
      wrap.appendChild(ui.element("span", "", label));
      wrap.appendChild(select);
      root.appendChild(wrap);
      fields[field] = select;
    }
    function paint() {
      var count = state.targets.length;
      title.textContent = count + (count === 1 ? " Face selected" : " Faces selected");
      Object.keys(fields).forEach(function (field) {
        var select = fields[field], shared = common(field);
        var offered = choices(state, field).filter(function (choice) { return choice !== "AttachedZone"; });
        var first = shared === null ? "Mixed" :
          shared && offered.indexOf(shared) < 0 ? chipLabel(field, shared) : "Not set";
        // A value the tree shows as read only (a paired Surface, an Air boundary, an Attached zone) is
        // read only here too: the Face's own row is where it can be changed.
        var locked = state.targets.some(function (target) {
          var stored = target.expected_values[field];
          return Boolean(stored) && offered.indexOf(stored) < 0;
        });
        var signature = first + "|" + offered.join(",");
        // Rebuilt only when what it offers changes: a snapshot follows every viewport click, and
        // rebuilding would close a dropdown the user has open.
        if (select._signature !== signature) {
          var placeholder = ui.option("", first);
          placeholder.disabled = true;
          select.replaceChildren(placeholder);
          offered.forEach(function (choice) { select.appendChild(ui.option(choice, chipLabel(field, choice))); });
          select._signature = signature;
        }
        select.value = shared && offered.indexOf(shared) >= 0 ? shared : "";
        select.disabled = state.edits.busy() || !offered.length || locked;
        select.title = locked ? "Set on the Face's own row" : "";
      });
      assembly.hidden = state.selectionAssignment.root.hidden;
    }
    var assembly = ui.element("label", "phc-selection-field");
    heading.appendChild(title);
    root.appendChild(heading);
    control("face_type", "Type");
    control("boundary_condition", "Boundary");
    assembly.appendChild(ui.element("span", "", "Assembly"));
    assembly.appendChild(state.selectionAssignment.root);
    root.appendChild(assembly);
    return { root: root, paint: paint };
  }

  function depth(wanted) {
    return function (row) { return row.depth === wanted; };
  }

  /* The view controls order and filter Zones, because a Zone is what the tree is built from; its Faces
     follow it in their own order. They project the Zone records, and `rows` tells them how a Face row
     traces back to the Zone that decides whether it shows. Filtering reads a Zone's Faces too, so a
     search for "Ground" keeps the Zone that has one. */
  function paintTable(mount, rows, state, profile) {
    var zoneRows = rows.filter(depth(0));
    var byId = Object.create(null);
    zoneRows.forEach(function (row) { byId[row.record.id] = row; });
    var projection = state.controls.project(zoneRows.map(function (row) { return row.record; }), {
      id: function (record) { return record.id; },
      value: function (record, field) { return field === "area_m2" ? totalArea(record.faces) : record.name; },
      search: function (record) { return searchText(record, state); },
      rows: function () { return rows; }
    });
    var parents = Object.create(null);
    rows.forEach(function (row) { if (row.parent) parents[row.parent] = true; });
    tables.table(mount, rows, {
      rows: ordered(projection.records, byId, rows), columns: columns(profile), expanded: state.expanded,
      expandable: function (row) { return Boolean(parents[row.key]); },
      decorate: function (td, row, field) { flag(td, problem(row.record.face, field)); },
      columnWidths: state.columnWidths, visibleCount: projection.visibleCount, disabled: state.edits.busy(),
      empty: zoneRows.length ? "No Zones match this filter." : "No Zones yet. Select geometry and choose Make Zone.",
      value: function (row, field) { return value(row, field, profile); },
      cell: function (td, row, field, text) { return cell(td, row, field, text, state); },
      marker: marker, actions: actions, rowHidden: projection.hidden,
      selected: function (row) { return state.selected === row.key; },
      inspect: function (row) {
        var reason = row.key !== state.selected && draftReason(state);
        if (reason) return refuse(reason);
        state.selected = row.key;
        panel.repaint();
      },
      columnResize: function (field, width) {
        if (field === null) state.columnWidths = {};
        else if (width === null) delete state.columnWidths[field];
        else state.columnWidths[field] = width;
      },
      action: function (row, item) {
        if (item.id === "locate") locate(state, row);
        if (item.id === "suggest") suggest(state, row);
      }
    });
  }

  function searchText(record, state) {
    return [record.name].concat(record.faces.map(function (face) {
      var assigned = assemblies.choices(state.snapshot, []).filter(function (record) {
        return record.id === face.values.assembly_id;
      })[0];
      return words.faceType(face.values.face_type) + " " + words.boundary(face.values.boundary_condition) + " " +
        (assigned ? assigned.name : face.values.assembly_id || "");
    })).join(" ");
  }

  /* The Zone order the controls settled on, each Zone followed by its own Face rows. */
  function ordered(records, byId, rows) {
    var children = Object.create(null);
    rows.filter(depth(1)).forEach(function (row) { (children[row.parent] = children[row.parent] || []).push(row); });
    return records.reduce(function (all, record) {
      var row = byId[record.id];
      return all.concat([row], children[row.key] || []);
    }, []);
  }

  /* The selected Zone's own fields. They belong to the Zone rather than to any one row, so they are a
     form in the inspector rather than more columns (UI polish: reveal contextual tools on selection). */
  function paintDetails(mount, rows, state) {
    var row = rows.filter(function (candidate) { return candidate.key === state.selected; })[0];
    if (!row || row.depth !== 0) {
      disposeZoneEditor(state);
      mount.replaceChildren();
      return;
    }
    if (state.zoneEditor && state.zoneEditor.key === row.key) {
      state.zoneEditor.sync(row.record.zone);
      return;
    }
    disposeZoneEditor(state);
    state.zoneEditor = zoneForm(row.key, row.record.zone, state);
    var title = ui.element("div", "phc-zone-heading");
    title.appendChild(ui.element("h2", "", "Zone details"));
    mount.className = "phc-zone-details";
    mount.replaceChildren(title, state.zoneEditor.root);
  }

  function disposeZoneEditor(state) {
    if (!state.zoneEditor) return;
    state.zoneEditor.dispose();
    state.zoneEditor = null;
  }

  function labelled(text, control) {
    var node = ui.element("label");
    node.appendChild(ui.element("span", "", text));
    node.appendChild(control);
    return node;
  }

  function input(name, current) {
    var node = ui.element("input");
    node.setAttribute("aria-label", name);
    node.value = current === null || current === undefined ? "" : String(current);
    return node;
  }

  function copyValues(values) {
    var copy = {};
    Object.keys(values).forEach(function (key) { copy[key] = values[key]; });
    return copy;
  }

  function zoneForm(key, zone, state) {
    var values = copyValues(zone.values), card = ui.element("form", "phc-zone-card");
    var name = input("Zone name", values.name), segment = input("Building-Segment", values.building_segment);
    var level = input("Level", values.level), depthValue = values.ground_depth_mm;
    var editor;
    var ground = new unitFields.UnitField({
      field: { quantity: "length_mm", unit: "mm", label: "Ground depth", scope: "ph_composer.zones.details" },
      value: depthValue,
      onCommit: function (committed) { depthValue = committed; }
    });
    var save = ui.element("button", "primary", "Save"), cancel = ui.button("Cancel", function () {
      editor.cancel(); panel.repaint();
    });
    // Save and Cancel belong to a draft, so they show once there is one.
    function paintActions() {
      var hide = !(editor.dirty || editor.pending), active = document.activeElement;
      if (hide && (active === save || active === cancel)) name.focus();
      save.hidden = cancel.hidden = hide;
    }
    save.type = "submit";
    cancel.type = "button";
    card.appendChild(labelled("Name", name));
    card.appendChild(labelled("Building-Segment", segment));
    card.appendChild(labelled("Level", level));
    card.appendChild(labelled("Ground depth", ground.root));
    card.appendChild(save);
    card.appendChild(cancel);
    editor = {
      key: key,
      root: card,
      reference: zone.reference,
      stored: zone,
      expectedValues: copyValues(values),
      dirty: false,
      pending: false,
      disposed: false,
      setPending: function (pending) {
        editor.pending = pending;
        [name, segment, level, save, cancel].forEach(function (control) { control.disabled = pending; });
        ground.setDisabled(pending);
        paintActions();
      },
      focus: function () { if (!save.disabled) save.focus(); },
      // The whole form goes back to what the Model last said, and the draft ends.
      cancel: function () {
        if (editor.pending) return;
        editor.dirty = false;
        editor.skipSync = false;
        ground.cancel();
        editor.sync(editor.stored);
        paintActions();
      },
      dispose: function () { editor.disposed = true; ground.dispose(); },
      accept: function (submitted) {
        editor.expectedValues = copyValues(submitted);
        editor.dirty = false;
        editor.skipSync = true;
        ground.setValue(submitted.ground_depth_mm);
        paintActions();
      },
      sync: function (authoritative) {
        editor.stored = authoritative;
        if (editor.skipSync) {
          editor.skipSync = false;
          return;
        }
        if (editor.dirty) return;
        values = copyValues(authoritative.values);
        editor.reference = authoritative.reference;
        editor.expectedValues = copyValues(values);
        name.value = values.name === null || values.name === undefined ? "" : String(values.name);
        segment.value = values.building_segment === null || values.building_segment === undefined ? "" :
          String(values.building_segment);
        level.value = values.level === null || values.level === undefined ? "" : String(values.level);
        depthValue = values.ground_depth_mm;
        ground.setValue(depthValue);
      }
    };
    [name, segment, level, ground.input].forEach(function (control) {
      control.addEventListener("input", function () { editor.dirty = true; paintActions(); });
    });
    paintActions();
    card.addEventListener("submit", function (event) {
      event.preventDefault();
      if (!ground.commit().ok) return;
      var submitted = { name: name.value, building_segment: segment.value, level: level.value || null,
        ground_depth_mm: depthValue };
      if (!state.edits.run("ph_composer.zones.update", {
        reference: editor.reference,
        values: submitted,
        expected_values: editor.expectedValues
      }, {
        onDone: function () {
          if (editor.disposed) return;
          editor.setPending(false);
          editor.accept(submitted);
        },
        onFail: function () {
          if (!editor.disposed) editor.setPending(false);
        }
      })) return;
      editor.setPending(true);
    });
    return editor;
  }

  // First in its pane: the Zone tree is the screen's work surface, and the palette and the legend
  // are controls that act on what it shows.
  panel.navigationGuard("ph_composer.overview", function () { return draftReason(screen); }, function () {
    if (screen && screen.zoneEditor) screen.zoneEditor.focus();
  });
  panel.section("ph_composer.overview", render, { order: 10 });
  panel.section("ph_composer.zones.selection", renderSelection, { region: "inspector", tier: "selection",
    order: 11, when: selectionWanted });
  panel.section("ph_composer.zones.details", renderDetails, { region: "inspector", tier: "record",
    order: 12, when: detailsWanted });
});
