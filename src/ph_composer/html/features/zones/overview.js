/* The Zones / Faces screen: the model tree of Zones with their Faces beneath, the shared view controls
 * above it, and the inspector's Face selection beside it. A Zone's own fields are columns on its row.
 *
 * The table is the shared record table; this file holds only this screen's vocabulary: its columns,
 * what each cell reads, its row actions and its editable chips. Every write goes through a registered
 * action carrying the values the row was painted from, and Locate goes through the view command,
 * which changes the selection and the camera and writes nothing.
 *
 * A Face with no record is a row too, under its Zone's "N unclassified Faces" summary. The Zone's row
 * carries their count and the Suggest classification action that gives them all a record.
 */
PhComposerUI.define("features/zones/overview", ["panel", "workspace", "request", "snapshot", "units",
  "unit_preferences", "table", "view_controls", "fields", "face_words",
  "features/zones/attached_zone_assignment", "features/zones/zone_settings", "features/zones/selection_assignment",
  "features/zones/assembly_assignment", "features/zones/zone_cells"],
function (panel, ui, requests, snapshot, units, preferences, tables, viewControls, fields, words,
          attachedAssignment, ZoneSettings, SelectionAssignment, assemblies, ZoneCells) {
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

  var screen = null;

  /* This screen's own state, rebuilt whenever the panel shows a different Model. */
  function forSession(session, send) {
    if (screen && screen.session === session) return screen;
    if (screen) { screen.disposed = true; screen.edits.reset(); screen.look.reset(); }
    if (screen && screen.zoneCells) screen.zoneCells.dispose();
    if (screen && screen.attachedDraft) screen.attachedDraft.dispose();
    if (screen && screen.settings) screen.settings.dispose();
    if (screen && screen.selectionAssignment) screen.selectionAssignment.dispose();
    screen = { session: session, expanded: Object.create(null), showAll: Object.create(null),
      columnWidths: {},
      edits: requests.channel(session, send, "overview"),
      look: requests.channel(session, send, "locate", "view.invoke") };
    screen.zoneCells = new ZoneCells(session, send, refuse);
    screen.settings = new ZoneSettings(session, send, function () { return draftReason(screen); }, refuse);
    screen.selectionAssignment = new SelectionAssignment(session, send, function () {
      return draftReason(screen);
    }, refuse);
    screen.controls = new viewControls.ViewControls({
      label: "Zones", placeholder: "Zone, type or boundary", fields: ORDER_FIELDS, initialOrder: "name",
      count: zoneCount, expansion: expansion(screen), guard: function () { return draftReason(screen); },
      refused: refuse
    }, function () { panel.repaint(); });
    return screen;
  }

  /* Work in hand that a filter, a tab change or another assignment must not hide or race. */
  function draftReason(state) {
    if (state && state.attachedDraft) return "Finish the Attached zone assignment first.";
    if (state && state.selectionAssignment && state.selectionAssignment.active()) {
      return "Finish the selected Faces assignment first.";
    }
    if (state && state.settings && state.settings.busy()) return "Wait for the Zone settings change to finish.";
    return null;
  }

  function refuse(reason) {
    panel.notify(reason, "warning");
  }

  /* The control row's count: Zones, and how many a filter leaves. */
  function zoneCount(shown, total, filtered) {
    var noun = total === 1 ? " Zone" : " Zones";
    return filtered ? shown + " of " + total + noun : total + noun;
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
    return [["actions", "Actions"], ["hierarchy", "Hierarchy"], ["name", "Name"]].concat(ZoneCells.columns(depth), [
      ["face_type", "Type"], ["boundary_condition", "Boundary"],
      ["area_m2", units.header("Gross area", AREA, profile)], ["assembly_id", "Assembly"]]);
  }

  /* Zone rows from the Zones read, their Faces from the Faces read, matched by the path that names
     one Zone occurrence. Not by the Zone's record id: a copied Zone Group shares its original's
     dictionary until the copy is repaired, so two occurrences can carry one id, and the
     zones read reports both and says so in `state`. Keying on the id would put the copy's Faces
     under the original's row, sum both areas into it and drop one Zone off the screen entirely.

     A Face with no record is a row too, so the tree lists everything that is left to do. Those rows
     sit together under one summary row per Zone, after the recorded Faces: a short list opens by
     itself, a long one waits to be opened, and a very long one shows its first rows and offers the
     rest, because a new Zone can hold hundreds. */
  var OPEN_UP_TO = 10, SHOWN_AT_FIRST = 50;

  function project(zones, faces, showAll) {
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
        record: { id: key, name: zone.values.name, zone: zone, faces: recorded, every: own,
          state: zone.state, unclassified: own.length - recorded.length } });
      function faceRow(face, parent, depth) {
        return { key: JSON.stringify(["Face", zone.reference.zone_path, face.reference.entity_path]),
          parent: parent, tier: "Face", depth: depth,
          record: { id: face.reference.entity_id, name: faceName(face, own), place: own.indexOf(face) + 1,
            face: face } };
      }
      recorded.forEach(function (face) { rows.push(faceRow(face, key, 1)); });
      var waiting = own.filter(function (face) { return face.state === "unclassified"; });
      if (!waiting.length) return;
      var summary = JSON.stringify(["Unclassified", zone.reference.zone_path]);
      var all = Boolean(showAll && showAll[summary]) || waiting.length <= SHOWN_AT_FIRST;
      rows.push({ key: summary, parent: key, tier: "Faces", depth: 1,
        record: { id: summary, faces: waiting, summary: true,
          name: waiting.length + (waiting.length === 1 ? " unclassified Face" : " unclassified Faces") } });
      (all ? waiting : waiting.slice(0, SHOWN_AT_FIRST)).forEach(function (face) {
        rows.push(faceRow(face, summary, 2));
      });
      if (!all) {
        rows.push({ key: JSON.stringify(["More", zone.reference.zone_path]), parent: summary, tier: "Show all",
          depth: 2, record: { id: summary, faces: [], more: summary,
            name: (waiting.length - SHOWN_AT_FIRST) + " more unclassified " +
              (waiting.length - SHOWN_AT_FIRST === 1 ? "Face" : "Faces") } });
      }
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
    if (ZONE_FIELDS[field]) return "";
    if (!face) {
      return field === "area_m2" && !row.record.more ?
        area(totalArea(row.record.every || row.record.faces), profile) : "";
    }
    if (field === "assembly_id") return "";
    if (field === "face_type") return words.faceType(face.values.face_type);
    if (field === "boundary_condition") {
      return words.boundary(face.values.boundary_condition);
    }
    return area(face.area_m2, profile);
  }

  var ZONE_FIELDS = { building_segment: true, level: true, ground_depth_mm: true };

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
    if (row.record.more) return [];
    var locatable = row.record.face || (row.record.every || row.record.faces).length;
    var items = [{ id: "locate", icon: "locate", disabled: !locatable,
      label: locatable ? "Locate " + row.record.name : "Nothing to locate: " + row.record.name + " has no Faces" }];
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

  /* A value a chip cannot set here (a paired Surface, an Air boundary) shows as the same pill, read only,
     with what sets it in its tooltip. An earlier control, if the cell had one, is forgotten. */
  function readOnly(td, field, face) {
    var stored = face.values[field];
    td.className = "col-" + field + (stored ? " phc-pill-cell" : "");
    td._chip = td._attachedChip = td._chipValues = null;
    if (!stored) {
      // The table paints the text; a pill this cell held before goes with it.
      if (td._pill && td._pill.parentNode === td) td.removeChild(td._pill);
      td._pill = null;
      return false;
    }
    var pill = td._pill;
    if (!pill || pill.parentNode !== td) {
      pill = td._pill = ui.element("span", "phc-enum-pill");
      td.replaceChildren(pill);
    }
    pill.textContent = chipLabel(field, stored);
    words.paintFill(pill, field, stored);
    td.title = words.UNCHOOSABLE[stored] ? pill.textContent + ": " + words.UNCHOOSABLE[stored] : pill.textContent;
    flag(td, problem(face, field));
    return true;
  }

  /* Type and boundary are editable chips; area is read only. An edit sends the values the row was
     painted from, so a Model that changed underneath refuses rather than overwriting.

     The control is built once per cell and repainted afterwards. Rebuilding it on every snapshot
     would take the user's open dropdown with it, and a snapshot follows every viewport click.

     A stored value the chip does not offer is shown as text rather than silently missing from the
     control: an `AirBoundary` Face, or one the solver paired, reads what it is and refuses the edit. */
  function cell(td, row, field, text, state) {
    var face = row.record.face, offered, chip;
    if (state.zoneCells.render(td, row, field)) return true;
    // A Face with no record has nothing to hang an Assembly on yet; its type or boundary comes first.
    if (field === "assembly_id") {
      if (!face || face.state !== "unclassified") return assemblies.cell(td, row, state, draftReason, refuse);
      // Back to text: the control this cell may have held (the Face had a record until an Undo) is forgotten.
      if (td._assemblyChip) { td._assemblyChip = null; td.className = "col-assembly_id"; }
      return false;
    }
    if (!face || (field !== "face_type" && field !== "boundary_condition")) return false;
    var issue = problem(face, field);
    if (field === "boundary_condition" && face.values.boundary_condition === "AttachedZone") {
      attachedCell(td, row, state);
      flag(td, issue);
      return true;
    }
    td._attachedChip = null;
    offered = choices(state, field);
    if (!offered.length) return readOnly(td, field, face);
    if (face.values[field] && offered.indexOf(face.values[field]) < 0) return readOnly(td, field, face);
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
        words.paintFill(chip, field, chip.value);
        if (field === "boundary_condition" && chip.value === "AttachedZone") {
          openAttached(td._state, td._face, chip);
          chip.value = td._face.values[field] || "";
          words.paintFill(chip, field, chip.value);
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
    words.paintFill(chip, field, face.values[field]);
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
      : (row.record.every || row.record.faces).map(function (face) { return face.reference; });
    if (references.length) state.look.run("ph_composer.zones.faces.locate", { faces: references });
  }

  function suggest(state, row) {
    state.edits.run("ph_composer.zones.faces.auto_classify", { zone: row.record.zone.reference });
  }

  /* The page header is built once a session and repainted in place, so a press on any of its controls
     (Classify faces, the gear, Make Zone) keeps its focus through the snapshot that follows. It holds the
     authoring toolbar (the pane's `actions`, then Solve adjacencies), the settings gear, the reason Make Zone
     is unavailable when it is, and Make Zone last. View controls stay in the control row. */
  function header(state, pane) {
    if (state.header) return state.header;
    var parts = { make: ui.element("button", "primary", "Make Zone"), solve: ui.element("button", "phc-toolbar-button"),
      toolbar: ui.element("div", "phc-toolbar"), reason: makeZoneReason() };
    parts.make.addEventListener("click", function () {
      if (state.makeTarget) state.edits.run("ph_composer.zones.make", state.makeTarget);
    });
    parts.solve.innerHTML = ui.svgIcon("link", 16);
    parts.solve.appendChild(ui.element("span", "", "Solve adjacencies"));
    parts.solve.setAttribute("data-tooltip", "Pair Faces that touch across Zones, so they read as Surface");
    parts.solve.setAttribute("aria-label", "Solve adjacencies for all Zones in this Model");
    parts.solve.addEventListener("click", function () {
      var reason = draftReason(state);
      if (reason) return refuse(reason);
      state.edits.run("ph_composer.zones.solve_adjacency", {
        zones: state.zoneRecords.map(function (zone) { return zone.reference; })
      });
    });
    parts.toolbar.setAttribute("role", "toolbar");
    parts.toolbar.setAttribute("aria-label", "Zone and Face tools");
    parts.toolbar.appendChild(panel.region(pane, "actions"));
    parts.toolbar.appendChild(parts.solve);
    parts.page = ui.pageHeader({ title: "Zones", actions: [parts.toolbar, state.settings.bubble.root],
      primary: parts.make });
    parts.actions = parts.page.root.querySelector(".phc-heading-actions");
    state.header = parts;
    return parts;
  }

  function paintHeader(state, pane, zones) {
    var parts = header(state, pane), busy = state.edits.busy(), target = zones.make_zone;
    state.makeTarget = target;
    state.zoneRecords = zones.zones;
    parts.make.textContent = busy ? "Making Zone…" : "Make Zone";
    parts.make.disabled = busy || !target;
    parts.make.setAttribute("aria-label", target ? "Make Zone from the current selection" :
      "Select one Group or loose geometry to make a Zone");
    parts.solve.disabled = busy || !zones.zones.length;
    // The reason alone comes and goes, just before Make Zone, so no other control is moved or loses focus.
    if (!target && parts.reason.parentNode !== parts.actions) parts.actions.insertBefore(parts.reason, parts.make);
    if (target && parts.reason.parentNode === parts.actions) parts.actions.removeChild(parts.reason);
    return parts.page.root;
  }

  function makeZoneReason() {
    return ui.reasonButton("Make Zone", "Make Zone needs one Group, or loose Faces and Edges, selected in " +
      "SketchUp and not already part of a Zone.");
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
    var rows = project(zones.zones, faces, screenState.showAll);
    // A short list of unclassified Faces opens by itself. That is decided once, when the list first
    // appears, so it does not snap shut or open under the user as the count changes.
    rows.forEach(function (row) {
      if (row.record.summary && !Object.prototype.hasOwnProperty.call(screenState.expanded, row.key)) {
        screenState.expanded[row.key] = row.record.faces.length <= OPEN_UP_TO;
      }
    });
    screenState.edits.consume(state);
    screenState.look.consume(state);
    screenState.settings.consume(state, snapshot.value(state, "ph_composer.zones.settings"));
    // Collapse all and Expand all reach everything that opens: Zones and their unclassified summaries.
    screenState.zoneKeys = rows.filter(function (row) { return row.depth === 0 || row.record.summary; })
      .map(function (row) { return row.key; });
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
    var heading = paintHeader(screenState, root.closest("[data-pane]").getAttribute("data-pane"), zones);
    var headingMount = root.querySelector(".phc-heading-mount");
    if (heading.parentNode !== headingMount) headingMount.replaceChildren(heading);
    // Set before the tree paints, so the inspector never works from an earlier pass if painting fails.
    screenState.rows = rows;
    screenState.targets = (snapshot.value(state, "ph_composer.zones.faces.selected") || {}).targets || [];
    screenState.zoneCells.refresh(rows.filter(depth(0)), state);
    paintTable(root.querySelector(".phc-table-mount"), rows, screenState, profile);
  }

  function renderHint(root) {
    if (root.children.length) return;
    root.className = "phc-inspector-hint";
    root.appendChild(ui.element("p", "phc-empty", "Select Faces in SketchUp to edit them here. Colour by and " +
      "Classify faces open here too."));
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
     follow it, ordered among themselves by the same field. They project the Zone records, and `rows`
     tells them how a Face row traces back to the Zone that decides whether it shows. Filtering reads a
     Zone's Faces too, so a search for "Ground" keeps the Zone that has one. */
  function paintTable(mount, rows, state, profile) {
    var zoneRows = rows.filter(depth(0));
    var byId = Object.create(null);
    zoneRows.forEach(function (row) { byId[row.record.id] = row; });
    var projection = state.controls.project(zoneRows.map(function (row) { return row.record; }), {
      id: function (record) { return record.id; },
      value: function (record, field) { return field === "area_m2" ? totalArea(record.every) : record.name; },
      search: function (record) { return searchText(record, state); },
      rows: function () { return rows; }
    });
    var parents = Object.create(null);
    rows.forEach(function (row) { if (row.parent) parents[row.parent] = true; });
    tables.table(mount, rows, {
      // Sized so the whole table shows beside the inspector at the panel's usual width; the user can still
      // drag any column wider.
      defaultWidths: { name: 142, building_segment: 120, level: 84, ground_depth_mm: 104, face_type: 126,
        boundary_condition: 110, area_m2: 92, assembly_id: 156 },
      tree: true, rows: ordered(projection.records, byId, rows, state.controls), columns: columns(profile),
      expanded: state.expanded,
      expandable: function (row) { return Boolean(parents[row.key]); },
      decorate: function (td, row, field) { flag(td, problem(row.record.face, field)); },
      columnWidths: state.columnWidths, visibleCount: projection.visibleCount, disabled: state.edits.busy(),
      empty: zoneRows.length ? "No Zones match this filter." : "No Zones yet. Select geometry and choose Make Zone.",
      value: function (row, field) { return value(row, field, profile); },
      cell: function (td, row, field, text) { return cell(td, row, field, text, state); },
      marker: marker, actions: actions, rowHidden: projection.hidden,
      inspect: function (row) {
        if (row.record.more) { state.showAll[row.record.more] = true; panel.repaint(); }
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
    var zone = record.zone.values;
    var own = [record.name, zone.building_segment || "", zone.level || "", record.unclassified ? "unclassified" : ""];
    return own.concat(record.faces.map(function (face) {
      var assigned = assemblies.choices(state.snapshot, []).filter(function (record) {
        return record.id === face.values.assembly_id;
      })[0];
      return words.faceType(face.values.face_type) + " " + words.boundary(face.values.boundary_condition) + " " +
        (assigned ? assigned.name : face.values.assembly_id || "");
    })).join(" ");
  }

  /* The Zone order the controls settled on, each Zone followed by its own Face rows in the same order:
     Order by and its direction apply within a Zone too, so they change something even when the Model has
     one Zone. A Face's name orders by its place number, not its text: the text starts with the Face's type,
     and choosing a type in a chip must not move the row out from under the user. A summary row
     ("N unclassified Faces") and "Show all" keep their place after the Faces. */
  function ordered(records, byId, rows, controls) {
    var children = Object.create(null), field = controls.orderBy.value;
    var sign = controls.direction.value === "desc" ? -1 : 1;
    rows.forEach(function (row) {
      if (row.parent) (children[row.parent] = children[row.parent] || []).push(row);
    });
    function faceValue(row) { return field === "area_m2" ? Number(row.record.face.area_m2) || 0 : row.record.place; }
    function byFace(a, b) {
      return (faceValue(a) - faceValue(b)) * sign || a.record.place - b.record.place;
    }
    function sorted(list) {
      var faces = list.filter(function (row) { return row.record.face; }).sort(byFace);
      return faces.concat(list.filter(function (row) { return !row.record.face; }));
    }
    function withChildren(row) {
      return sorted(children[row.key] || []).reduce(function (all, child) {
        return all.concat(withChildren(child));
      }, [row]);
    }
    return records.reduce(function (all, record) { return all.concat(withChildren(byId[record.id])); }, []);
  }

  // First in its pane: the Zone tree is the screen's work surface, and the palette and the legend
  // are controls that act on what it shows.
  panel.navigationGuard("ph_composer.overview", function () { return draftReason(screen); });
  panel.section("ph_composer.overview", render, { order: 10 });
  panel.workedOn("ph_composer.zones", "overview");
  panel.section("ph_composer.zones.selection", renderSelection, { region: "inspector", tier: "selection",
    order: 11, when: selectionWanted });
  // Last in line and always wanted, so the inspector column is always there: the tree keeps its width
  // whether the user selects something, opens Colour by or starts Classify faces.
  panel.section("ph_composer.zones.hint", renderHint, { region: "inspector", tier: "ambient", order: 1000,
    when: function () { return true; } });
});
