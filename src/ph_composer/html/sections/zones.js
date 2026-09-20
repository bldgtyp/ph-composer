/* P1-B's first authoring surface: explicit Make Zone, Zone details, and one-face classification.
 * It is deliberately a compact proof surface; the model tree, table drafts and viewport Classify
 * gesture arrive in P1-D. Every write uses the same registered actions available to scripts. */
PhComposerUI.define("sections/zones", ["panel", "workspace", "request", "snapshot", "units", "unit_preferences",
  "unit_field"], function (panel, ui, requests, snapshot, units, preferences, unitFields) {
    "use strict";
    var zoneChannel = null, faceChannel = null, session = null;

    function channel(current, send, name) {
      if (session !== current) {
        session = current;
        zoneChannel = requests.channel(current, send, "zones");
        faceChannel = requests.channel(current, send, "faces");
      }
      return name === "zones" ? zoneChannel : faceChannel;
    }

    function label(text, control) {
      var node = ui.element("label");
      node.appendChild(ui.element("span", "", text));
      node.appendChild(control);
      return node;
    }

    function input(name, value) {
      var node = ui.element("input");
      node.setAttribute("aria-label", name);
      node.value = value === null || value === undefined ? "" : String(value);
      return node;
    }

    function option(value, text) {
      var node = ui.element("option", "", text);
      node.value = value;
      return node;
    }

    function select(name, choices, current) {
      var node = ui.element("select");
      node.setAttribute("aria-label", name);
      choices.forEach(function (choice) { node.appendChild(option(choice[0], choice[1])); });
      node.value = current;
      return node;
    }

    function heading(title, action) {
      var node = ui.element("div", title === "Zones" ? "phc-zone-heading" : "phc-face-heading");
      node.appendChild(ui.element("h2", "", title));
      if (action) node.appendChild(action);
      return node;
    }

    function renderZones(root, state, send) {
      var value = snapshot.value(state, "ph_composer.zones.overview") || { zones: [], make_zone: null };
      var request = channel(state.session, send, "zones"), result = request.consume(state), make, list;
      make = ui.element("button", "primary", request.busy() ? "Making Zone…" : "Make Zone");
      make.disabled = request.busy() || !value.make_zone;
      make.setAttribute("aria-label", value.make_zone ? "Make Zone from the current selection" :
        "Select one Group or loose geometry to make a Zone");
      make.addEventListener("click", function () {
        if (value.make_zone) request.run("ph_composer.zones.make", value.make_zone);
      });
      list = ui.element("div", "phc-zone-list");
      value.zones.forEach(function (zone) { list.appendChild(zoneCard(zone, request)); });
      if (!value.zones.length) list.appendChild(ui.element("p", "phc-empty", "No Zones yet."));
      ui.memoPaint(root, "zones", [state.session, state.revision, value, request.busy(), result], function () {
        root.className = "phc-zones";
        root.replaceChildren(heading("Zones", make), list);
      });
    }

    function zoneCard(zone, request) {
      var values = zone.values, card = ui.element("form", "phc-zone-card");
      var name = input("Zone name", values.name), segment = input("Building-Segment", values.building_segment);
      var level = input("Level", values.level), depthValue = values.ground_depth_mm;
      var depth = new unitFields.UnitField({
        field: { quantity: "length_mm", unit: "mm", label: "Ground depth", scope: "ph_composer.zones.details" },
        value: depthValue,
        onCommit: function (value) { depthValue = value; }
      });
      var save = ui.element("button", "", "Save");
      save.type = "submit";
      card.appendChild(label("Name", name));
      card.appendChild(label("Building-Segment", segment));
      card.appendChild(label("Level", level));
      card.appendChild(label("Ground depth", depth.root));
      card.appendChild(save);
      card.addEventListener("submit", function (event) {
        event.preventDefault();
        var committed = depth.commit();
        if (!committed.ok) return;
        request.run("ph_composer.zones.update", {
          reference: zone.reference,
          values: { name: name.value, building_segment: segment.value, level: level.value || null,
            ground_depth_mm: depthValue },
          expected_values: values
        });
      });
      return card;
    }

    function renderFaces(root, state, send) {
      var value = snapshot.value(state, "ph_composer.face_assignment.faces") || { faces: [] };
      var request = channel(state.session, send, "faces"), result = request.consume(state), list;
      list = ui.element("div", "phc-face-list");
      value.faces.forEach(function (face, index) { list.appendChild(faceRow(face, index, request)); });
      if (!value.faces.length) list.appendChild(ui.element("p", "phc-empty", "Make a Zone to classify its faces."));
      ui.memoPaint(root, "faces", [state.session, state.revision, value, request.busy(), result], function () {
        root.className = "phc-faces";
        root.replaceChildren(heading("Faces"), list);
      });
    }

    function faceRow(face, index, request) {
      var row = ui.element("form", "phc-face-row"), identity = ui.element("div", "phc-face-identity");
      var currentType = face.values.face_type || "", currentBoundary = face.values.boundary_condition || "";
      var faceType = select("Face " + (index + 1) + " type", [["", "Keep"], ["Wall", "Wall"],
        ["RoofCeiling", "Roof or ceiling"], ["Floor", "Floor"]], currentType);
      var boundary = select("Face " + (index + 1) + " boundary", [["", "Keep"], ["Outdoors", "Outdoors"],
        ["Ground", "Ground"], ["Adiabatic", "To neighbour"]], currentBoundary);
      var apply = ui.element("button", "", "Apply");
      apply.type = "submit";
      identity.appendChild(ui.element("strong", "", face.zone_name));
      identity.appendChild(ui.element("span", "", units.format(face.area_m2, { quantity: "area" },
        { system: preferences.current().unitSystem, numberFormat: preferences.current().numberFormat })));
      row.appendChild(identity);
      row.appendChild(ui.element("span", "", face.values.face_type || "Unclassified"));
      row.appendChild(label("Face type", faceType));
      row.appendChild(label("Boundary", boundary));
      row.appendChild(apply);
      row.addEventListener("submit", function (event) {
        event.preventDefault();
        request.run("ph_composer.face_assignment.classify", {
          faces: [face.reference],
          intent: {
            face_type: { mode: faceType.value ? "set" : "keep", value: faceType.value || null },
            boundary_condition: { mode: boundary.value ? "set" : "keep", value: boundary.value || null }
          },
          expected_values: face.values
        });
      });
      return row;
    }

    panel.section("ph_composer.zones", renderZones);
    panel.section("ph_composer.faces", renderFaces);
  });
