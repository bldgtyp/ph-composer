/* The Classify tool's palette in the panel (face-assignment PRD "The Classify tool"): face type
 * chips, boundary condition chips, the Attached zone picker with its inline New route, and the
 * control that gives the viewport back.
 *
 * A chip with nothing chosen means keep what each Face has, so the tool can set only the boundary
 * condition on already-typed Faces, or only the type. Choosing any chip also gives the tool the
 * viewport, which is what the native Classify menu does and what the PRD asks for.
 *
 * Surface is shown and refused: Solve adjacencies writes it, and a palette that offered it would
 * let a user break a pair by painting over one of its ends.
 */
PhComposerUI.define("sections/classify", ["panel", "workspace", "request", "snapshot", "sections/face_words"],
function (panel, ui, requests, snapshot, words) {
  "use strict";
  var KEEP = "";
  var DEFAULT_ATTACHED_ZONE = { kind: "other" };
  var screen = null;

  function forSession(session, send) {
    if (screen && screen.session === session) return screen;
    screen = { session: session, chooseWhenFree: null,
      view: requests.channel(session, send, "palette", "view.invoke"),
      edits: requests.channel(session, send, "attached_zone") };
    return screen;
  }

  /* One row of chips for one palette field. The chosen chip is marked the way an active sidebar row
     is, and pressing it again clears the field back to keeping what the Face has. */
  function chips(state, field, values, chosen, table) {
    var row = ui.element("div", "phc-chips");
    values.forEach(function (value) {
      var word = table[value] || value, reason = words.UNCHOOSABLE[value];
      var chip = ui.element("button", "phc-chip", reason ? word + " · " + reason : word);
      var current = chosen === value;
      chip.setAttribute("aria-pressed", String(current));
      chip.setAttribute("aria-label", reason ? word + ", " + reason : word);
      chip.disabled = state.view.busy() || Boolean(reason);
      chip.addEventListener("click", function () { choose(state, field, current ? null : value); });
      row.appendChild(chip);
    });
    return row;
  }

  function choose(state, field, value) {
    state.view.run("ph_composer.face_assignment.choose", { field: field, value: value });
  }

  function field(title, hint, body) {
    var node = ui.element("div", "phc-palette-field");
    var heading = ui.element("h3", "", title);
    if (hint) heading.appendChild(ui.element("span", "phc-palette-hint", " " + hint));
    node.appendChild(heading);
    node.appendChild(body);
    return node;
  }

  /* The Attached zone picker. Choosing a record sets the boundary condition and the record together,
     because an Attached zone boundary without one is an incomplete Face. */
  function attachedZones(state, palette, records) {
    var body = ui.element("div", "phc-chips");
    var picker = ui.element("select");
    var none = ui.element("option", "", "None");
    none.value = KEEP;
    picker.appendChild(none);
    records.forEach(function (record) {
      var option = ui.element("option", "", record.values.name);
      option.value = record.id;
      picker.appendChild(option);
    });
    picker.value = palette.attached_zone_id || KEEP;
    picker.disabled = state.view.busy() || state.edits.busy();
    picker.setAttribute("aria-label", "Attached zone");
    picker.addEventListener("change", function () {
      choose(state, "attached_zone_id", picker.value === KEEP ? null : picker.value);
    });
    body.appendChild(picker);
    body.appendChild(newAttachedZone(state, records));
    return body;
  }

  /* The first "Attached zone N" nothing is called yet, so a name is not reused after a delete. Zones
     name a new Zone the same way. */
  function freeName(records) {
    var taken = {}, number = 1;
    records.forEach(function (record) { taken[record.values.name] = true; });
    while (taken["Attached zone " + number]) number += 1;
    return "Attached zone " + number;
  }

  /* New acts at once under a free default name, as every other record does in this app; the user
     renames it in the Attached zones surface rather than answering a dialog first.

     The record is created and then chosen, and choosing goes down the viewport channel, which may be
     carrying something else. A dropped choice would leave the user with a record they asked for and
     a palette that does not name it, so the choice waits its turn rather than being lost. */
  function newAttachedZone(state, records) {
    var create = ui.element("button", "", "New attached zone");
    create.disabled = state.edits.busy() || state.view.busy();
    create.addEventListener("click", function () {
      var values = { name: freeName(records), kind: DEFAULT_ATTACHED_ZONE.kind };
      state.edits.run("ph_composer.face_assignment.attached_zone.save", { values: values }, {
        onDone: function (outcome) {
          if (outcome.value && outcome.value.id) state.chooseWhenFree = outcome.value.id;
        }
      });
    });
    return create;
  }

  /* A choice the create route could not send yet, sent as soon as the channel is free. */
  function sendPending(state) {
    if (!state.chooseWhenFree || state.view.busy()) return;
    var id = state.chooseWhenFree;
    state.chooseWhenFree = null;
    choose(state, "attached_zone_id", id);
  }

  /* Offered only while the tool has the viewport. A permanently mounted control that is almost always
     disabled is furniture, not an affordance; choosing a chip is what starts the tool. */
  function stopButton(state) {
    var stop = ui.element("button", "", "Stop classifying");
    stop.disabled = state.view.busy();
    stop.setAttribute("aria-label", "Give the viewport back to the previous tool");
    stop.addEventListener("click", function () {
      state.view.run("ph_composer.face_assignment.stop_classifying", {});
    });
    return stop;
  }

  function render(root, state, send) {
    var tool = snapshot.value(state, "ph_composer.face_assignment.palette") ||
      { active: false, palette: {}, face_types: [], boundary_conditions: [] };
    var records = (snapshot.value(state, "ph_composer.face_assignment.attached_zone.list") ||
      { records: [] }).records;
    var screenState = forSession(state.session, send);
    screenState.view.consume(state);
    screenState.edits.consume(state);
    sendPending(screenState);
    // Repainted only when the palette, the records or a pending request have changed. A snapshot
    // follows every Face the user paints, and rebuilding the chips each time would take the focus
    // out from under them mid-gesture.
    ui.memoPaint(root, "palette", [state.session, tool, records, screenState.view.busy(),
      screenState.edits.busy()], function () {
      var heading = ui.element("div", "phc-zone-heading");
      var body = ui.element("div", "phc-palette");
      heading.appendChild(ui.element("h2", "", "Classify faces"));
      if (tool.active) heading.appendChild(stopButton(screenState));
      body.appendChild(field("Face type", "blank keeps what each Face has",
        chips(screenState, "face_type", tool.face_types, tool.palette.face_type, words.FACE_TYPES)));
      body.appendChild(field("Boundary condition", "blank keeps what each Face has",
        chips(screenState, "boundary_condition", tool.boundary_conditions,
          tool.palette.boundary_condition, words.BOUNDARIES)));
      body.appendChild(field("Attached zone", null, attachedZones(screenState, tool.palette, records)));
      root.className = "phc-classify" + (tool.active ? " is-active" : "");
      root.replaceChildren(heading, body);
    });
  }

  panel.section("ph_composer.classify", render, { order: 30 });
});
