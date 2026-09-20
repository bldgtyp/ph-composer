/* The Overview screen: the model tree of Zones with their classified Faces beneath, the shared view
 * controls above it, and the selected Zone's own fields below (zones Q13, face-assignment Q11,
 * planning/ui-baseline).
 *
 * The table is the shared record table; this file holds only this screen's vocabulary: its columns,
 * what each cell reads, its row actions and its editable chips. Every write goes through a registered
 * action carrying the values the row was painted from, and Locate goes through the view command,
 * which changes the selection and the camera and writes nothing.
 *
 * An unclassified Face is not a row (face-assignment PRD, "The faces table"). Its Zone's row carries
 * the count and the Suggest classification action that gives those Faces a record.
 */
PhComposerUI.define("sections/overview", ["panel", "workspace", "request", "snapshot", "units", "unit_preferences",
  "unit_field", "table", "view_controls", "fields", "sections/face_words"],
function (panel, ui, requests, snapshot, units, preferences, unitFields, tables, viewControls, fields, words) {
  "use strict";
  var AREA = fields.AREA_M2;
  // What a chip in this table offers. Surface is written by Solve adjacencies and Attached zone
  // needs a record picker, so a Face holding either keeps it and the cell stays read only.
  var FACE_TYPES = ["Wall", "RoofCeiling", "Floor"];
  var BOUNDARIES = ["Outdoors", "Ground", "Adiabatic"];
  var STATE_LABELS = { classified: "", incomplete: "Incomplete", unclassified: "Unclassified" };
  var ORDER_FIELDS = [["name", "Name"], ["area_m2", "Area"]];

  var screen = null;

  /* This screen's own state, rebuilt whenever the panel shows a different Model. */
  function forSession(session, send) {
    if (screen && screen.session === session) return screen;
    screen = { session: session, selected: null, expanded: Object.create(null), columnWidths: {},
      edits: requests.channel(session, send, "overview"),
      look: requests.channel(session, send, "locate", "view.invoke") };
    screen.controls = new viewControls.ViewControls({
      label: "Zones", placeholder: "Zone, type or boundary", fields: ORDER_FIELDS, initialOrder: "name",
      expansion: expansion(screen)
    }, function () { panel.repaint(); });
    return screen;
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
      ["area_m2", units.header("Area", AREA, profile)], ["state", "State"]];
  }

  /* Zone rows from the Zones read, their Faces from the Faces read, matched by the Zone id every Face
     reference carries. A Face with no record counts towards its Zone's marker, not towards a row. */
  function project(zones, faces) {
    var byZone = Object.create(null), unclassified = Object.create(null), rows = [];
    faces.forEach(function (face) {
      var id = face.reference.zone_id;
      if (face.state === "unclassified") { unclassified[id] = (unclassified[id] || 0) + 1; return; }
      (byZone[id] = byZone[id] || []).push(face);
    });
    zones.forEach(function (zone) {
      var own = byZone[zone.id] || [], key = JSON.stringify(["Zone", zone.id]);
      rows.push({ key: key, parent: null, tier: "Zone", depth: 0,
        record: { id: zone.id, name: zone.values.name, zone: zone, faces: own,
          unclassified: unclassified[zone.id] || 0 } });
      own.forEach(function (face, index) {
        rows.push({ key: JSON.stringify(["Face", zone.id, face.reference.entity_path, index]), parent: key,
          tier: "Face", depth: 1,
          record: { id: face.reference.entity_id, name: faceName(face, index), face: face } });
      });
    });
    return rows;
  }

  function faceName(face, index) {
    return (face.values.face_type ? words.faceType(face.values.face_type) : "Face") + " " + (index + 1);
  }

  function value(row, field, profile) {
    var face = row.record.face;
    if (field === "name") return row.record.name;
    if (!face) return field === "area_m2" ? area(totalArea(row.record.faces), profile) : "";
    if (field === "face_type") return words.faceType(face.values.face_type);
    if (field === "boundary_condition") {
      return words.boundary(face.values.boundary_condition);
    }
    if (field === "area_m2") return area(face.area_m2, profile);
    return STATE_LABELS[face.state];
  }

  function totalArea(faces) {
    return faces.reduce(function (sum, face) { return sum + face.area_m2; }, 0);
  }

  function area(square_metres, profile) {
    return units.format(square_metres, AREA, profile, { showUnit: false });
  }

  function marker(row) {
    var count = row.record.unclassified;
    if (!count) return null;
    return { text: count + " unclassified",
      tooltip: count + " Faces in this Zone have no record yet. Suggest classification gives them one." };
  }

  function actions(row) {
    var items = [{ id: "locate", icon: "locate", label: "Locate " + row.record.name }];
    if (row.depth === 0 && row.record.unclassified) {
      items.push({ id: "suggest", icon: "sort", label: "Suggest classification for " + row.record.name });
    }
    return items;
  }

  /* Type and boundary are editable chips; area and state are read only. An edit sends the values the
     row was painted from, so a Model that changed underneath refuses rather than overwriting. */
  function cell(td, row, field, text, state) {
    var face = row.record.face, chip;
    if (!face || (field !== "face_type" && field !== "boundary_condition")) return false;
    if (field === "boundary_condition" && words.UNCHOOSABLE[face.values.boundary_condition]) return false;
    chip = ui.element("select", "phc-cell-input");
    (field === "face_type" ? FACE_TYPES : BOUNDARIES).forEach(function (choice) {
      var option = ui.element("option", "",
        field === "face_type" ? words.faceType(choice) : words.boundary(choice));
      option.value = choice;
      chip.appendChild(option);
    });
    chip.value = face.values[field] || "";
    chip.disabled = state.edits.busy();
    chip.setAttribute("aria-label", row.record.name + (field === "face_type" ? " type" : " boundary"));
    chip.addEventListener("change", function () { apply(state, face, field, chip.value); });
    td.className = "col-" + field + " phc-editable-cell";
    td.replaceChildren(chip);
    return true;
  }

  function apply(state, face, field, chosen) {
    var intent = { face_type: { mode: "keep" }, boundary_condition: { mode: "keep" } };
    intent[field] = { mode: "set", value: chosen };
    state.edits.run("ph_composer.face_assignment.classify",
      { faces: [face.reference], intent: intent, expected_values: face.values });
  }

  function locate(state, row) {
    var references = row.record.face ? [row.record.face.reference]
      : row.record.faces.map(function (face) { return face.reference; });
    if (references.length) state.look.run("ph_composer.face_assignment.locate", { faces: references });
  }

  function suggest(state, row) {
    state.edits.run("ph_composer.face_assignment.auto_classify", { zone: row.record.zone.reference });
  }

  function heading(title, count, action) {
    var node = ui.element("div", "phc-zone-heading"), title_node = ui.element("h2", "", title);
    if (count !== null) title_node.appendChild(ui.element("span", "phc-view-count", " " + count));
    node.appendChild(title_node);
    if (action) node.appendChild(action);
    return node;
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

  function render(root, state, send) {
    var zones = snapshot.value(state, "ph_composer.zones.overview") || { zones: [], make_zone: null };
    var faces = (snapshot.value(state, "ph_composer.face_assignment.faces") || { faces: [] }).faces;
    var screenState = forSession(state.session, send), profile = preferences.current();
    var rows = project(zones.zones, faces);
    screenState.edits.consume(state);
    screenState.look.consume(state);
    screenState.zoneKeys = rows.filter(depth(0)).map(function (row) { return row.key; });
    if (!root.querySelector(".phc-table-mount")) {
      root.className = "phc-overview";
      root.replaceChildren(ui.element("div", "phc-heading-mount"), screenState.controls.root,
        ui.element("div", "phc-table-mount"), ui.element("div", "phc-details-mount"));
    }
    root.querySelector(".phc-heading-mount")
        .replaceChildren(heading("Zones", zones.zones.length, makeButton(screenState, zones.make_zone)));
    paintTable(root.querySelector(".phc-table-mount"), rows, screenState, profile);
    paintDetails(root.querySelector(".phc-details-mount"), rows, screenState);
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
      search: searchText,
      group: function () { return { label: "" }; },
      rows: function () { return rows; }
    });
    tables.table(mount, rows, {
      rows: ordered(projection.records, byId, rows), columns: columns(profile), expanded: state.expanded,
      columnWidths: state.columnWidths, visibleCount: projection.visibleCount, disabled: state.edits.busy(),
      empty: zoneRows.length ? "No Zones match this filter." : "No Zones yet. Select geometry and choose Make Zone.",
      value: function (row, field) { return value(row, field, profile); },
      cell: function (td, row, field, text) { return cell(td, row, field, text, state); },
      marker: marker, actions: actions, rowHidden: projection.hidden,
      selected: function (row) { return state.selected === row.key; },
      inspect: function (row) { state.selected = row.key; panel.repaint(); },
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

  function searchText(record) {
    return [record.name].concat(record.faces.map(function (face) {
      return words.faceType(face.values.face_type) + " " + words.boundary(face.values.boundary_condition);
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
     form beneath the table rather than more columns (UI polish: reveal contextual tools on selection). */
  function paintDetails(mount, rows, state) {
    var row = rows.filter(function (candidate) { return candidate.key === state.selected; })[0];
    if (!row || row.depth !== 0) { mount.replaceChildren(); return; }
    mount.replaceChildren(heading("Zone details", null, null), zoneForm(row.record.zone, state));
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

  function zoneForm(zone, state) {
    var values = zone.values, card = ui.element("form", "phc-zone-card");
    var name = input("Zone name", values.name), segment = input("Building-Segment", values.building_segment);
    var level = input("Level", values.level), depthValue = values.ground_depth_mm;
    var ground = new unitFields.UnitField({
      field: { quantity: "length_mm", unit: "mm", label: "Ground depth", scope: "ph_composer.zones.details" },
      value: depthValue,
      onCommit: function (committed) { depthValue = committed; }
    });
    var save = ui.element("button", "", "Save");
    save.type = "submit";
    card.appendChild(labelled("Name", name));
    card.appendChild(labelled("Building-Segment", segment));
    card.appendChild(labelled("Level", level));
    card.appendChild(labelled("Ground depth", ground.root));
    card.appendChild(save);
    card.addEventListener("submit", function (event) {
      event.preventDefault();
      if (!ground.commit().ok) return;
      state.edits.run("ph_composer.zones.update", {
        reference: zone.reference,
        values: { name: name.value, building_segment: segment.value, level: level.value || null,
          ground_depth_mm: depthValue },
        expected_values: values
      });
    });
    return card;
  }

  panel.section("ph_composer.overview", render);
});
