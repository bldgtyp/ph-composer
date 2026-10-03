/* The Classify tool's palette in the panel: face type chips, boundary condition chips, the Attached
 * zone picker with its inline New route, and the control that gives the viewport back.
 *
 * A chip with nothing chosen means keep what each Face has, so the tool can set only the boundary
 * condition on already-typed Faces, or only the type. Choosing any chip also gives the tool the
 * viewport, which is what the native Classify menu does.
 *
 * Surface is shown and refused: Solve adjacencies writes it, and a palette that offered it would
 * let a user break a pair by painting over one of its ends.
 */
PhComposerUI.define("features/zones/classify", ["panel", "workspace", "request", "snapshot",
  "face_words", "features/zones/attached_zone_fields", "features/zones/assembly_assignment"],
function (panel, ui, requests, snapshot, words, attachedFields, assemblies) {
  "use strict";
  var KEEP = "";
  var screen = null;

  // Editors and bubbles consume their own Escape first. A modal dialog receives the native
  // cancel event after keydown, so leave that press to it even before it marks the event handled.
  // Otherwise panel focus must not trap the viewport's Classify tool.
  document.addEventListener("keydown", function (event) {
    if (event.key !== "Escape" || event.defaultPrevented || !screen || !screen.active ||
        screen.view.busy()) return;
    if (Array.from(document.querySelectorAll("dialog")).some(function (dialog) { return dialog.open; })) return;
    event.preventDefault();
    screen.view.run("ph_composer.zones.faces.stop_classifying", {});
  });

  function forSession(session, send) {
    if (screen && screen.session === session) return screen;
    if (screen) { screen.disposed = true; screen.view.reset(); screen.edits.reset(); }
    if (screen && screen.draft) screen.draft.close();
    screen = { session: session, chooseWhenFree: null, draft: null,
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
    if (state !== screen || state.disposed || !state.available ||
        (field === "assembly_id" && !snapshot.value(state.snapshot, "ph_composer.zones.faces.assemblies"))) return;
    state.view.run("ph_composer.zones.faces.choose", { field: field, value: value });
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

  /* This palette has no pending Face proposal: saving creates a definition, then choosing it sets
     the next paint gesture. Cancelling the draft changes neither definitions nor the palette. */
  function newAttachedZone(state, records) {
    var create = ui.element("button", "", "New attached zone");
    create.disabled = state.edits.busy() || state.view.busy();
    create.addEventListener("click", function () { openAttachedZone(state, records); });
    state.createButton = create;
    return create;
  }

  function openAttachedZone(state, records) {
    if (state.draft) return;
    var dialog = ui.formDialog("", cancel);
    var form = ui.element("form");
    var inputs = attachedFields.build(form, records, submit);
    var name = inputs.name;
    var error = ui.element("div", "cell-error");
    error.setAttribute("role", "status");
    var cancelButton = ui.button("Cancel", cancel);
    var save = ui.element("button", "primary", "Create and choose");
    save.type = "submit";
    form.appendChild(ui.actionRow(cancelButton, save, false));
    form.addEventListener("submit", function (event) {
      event.preventDefault();
      submit();
    });
    function submit() {
      if (state !== screen || state.disposed || !state.available || state.edits.busy()) return;
      var values = inputs.values();
      if (!values) {
        error.textContent = inputs.message();
        return;
      }
      save.disabled = true;
      cancelButton.disabled = true;
      inputs.setDisabled(true);
      state.edits.run("ph_composer.zones.faces.attached_zone.save", { values: values }, {
        onDone: function (outcome) {
          if (outcome.value && outcome.value.id) state.chooseWhenFree = outcome.value.id;
          close(true);
        },
        onFail: function (outcome) {
          save.disabled = false;
          cancelButton.disabled = false;
          inputs.setDisabled(false);
          error.textContent = outcome.message || "The Attached zone could not be created. Nothing was written.";
        }
      });
    }
    dialog.appendChild(ui.element("h2", "", "New attached zone"));
    dialog.appendChild(form);
    dialog.appendChild(error);
    state.draft = { close: close };
    document.body.appendChild(dialog);
    dialog.openModal();
    name.focus();
    name.select();

    function cancel() {
      if (!state.edits.busy()) close();
    }
    function close(afterRender) {
      state.returnFocus = afterRender === true;
      dialog.closeModal();
      if (dialog.parentNode) dialog.parentNode.removeChild(dialog);
      inputs.dispose();
      state.draft = null;
      if (state.createButton && state.createButton.isConnected) state.createButton.focus();
    }
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
      state.view.run("ph_composer.zones.faces.stop_classifying", {});
    });
    return stop;
  }

  function render(root, state, send) {
    var tool = snapshot.value(state, "ph_composer.zones.faces.palette") ||
      { active: false, palette: {}, face_types: [], boundary_conditions: [] };
    var records = (snapshot.value(state, "ph_composer.zones.faces.attached_zone.list") ||
      { records: [] }).records;
    var screenState = forSession(state.session, send);
    screenState.active = Boolean(tool.active);
    screenState.available = Boolean(snapshot.value(state, "ph_composer.zones.faces.palette"));
    screenState.snapshot = state;
    screenState.view.consume(state);
    screenState.edits.consume(state);
    sendPending(screenState);
    // Repainted only when the palette, the records or a pending request have changed. A snapshot
    // follows every Face the user paints, and rebuilding the chips each time would take the focus
    // out from under them mid-gesture.
    ui.memoPaint(root, "palette", [state.session, tool, records,
      snapshot.value(state, "ph_composer.zones.faces.assemblies"), screenState.view.busy(),
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
      // Painting an Assembly starts from that Assembly's own row; the palette only says which one it is.
      var painting = assemblies.choices(state, []).filter(function (record) {
        return record.id === tool.palette.assembly_id;
      })[0];
      if (tool.palette.assembly_id) {
        var inHand = ui.element("div", "phc-chips");
        var drop = ui.button("Stop painting it", function () { choose(screenState, "assembly_id", null); });
        drop.disabled = screenState.view.busy();
        inHand.appendChild(ui.element("span", "phc-palette-value", painting ? painting.name : "Missing Assembly"));
        inHand.appendChild(drop);
        body.appendChild(field("Assembly", null, inHand));
      }
      root.className = "phc-classify" + (tool.active ? " is-active" : "");
      root.replaceChildren(heading, body);
    });
    if (screenState.returnFocus) {
      screenState.returnFocus = false;
      screenState.createButton.focus();
    }
  }

  /* The palette is the inspector's while the tool has the viewport or the user has opened it, and the
     toggle is pressed while either holds. Pressing it during painting gives the viewport back. When the
     tool ends any other way (Escape, Stop, another tool) the palette closes with it. The button is built
     once a session and repainted, so pressing it never drops the focus it holds. */
  function renderToggle(root, state, send) {
    var tool = snapshot.value(state, "ph_composer.zones.faces.palette");
    var screenState = forSession(state.session, send), active = Boolean(tool && tool.active);
    screenState.view.consume(state);
    if (screenState.wasActive && !active) screenState.open = false;
    screenState.wasActive = active;
    if (!screenState.toggle || screenState.toggle.parentNode !== root) {
      screenState.toggle = ui.iconButton("Classify faces", "paint_bucket", function () {
        var pressed = screenState.wasActive || screenState.open;
        var held = !pressed && panel.inspectorHeld(root.closest("[data-pane]").getAttribute("data-pane"));
        if (held) { panel.notify("Save or cancel the draft in the inspector first.", "warning"); return; }
        if (screenState.wasActive) screenState.view.run("ph_composer.zones.faces.stop_classifying", {});
        screenState.open = !pressed;
        panel.repaint();
      });
      root.className = "phc-classify-toggle";
      root.replaceChildren(screenState.toggle);
    }
    screenState.toggle.setAttribute("aria-pressed", String(active || Boolean(screenState.open)));
    screenState.toggle.disabled = !tool || screenState.view.busy();
  }

  panel.section("ph_composer.classify.toggle", renderToggle, { region: "tools", order: 10 });
  panel.section("ph_composer.classify", render, { region: "inspector", tier: "tool",
    when: function () { return Boolean(screen && (screen.active || screen.open)); } });
});
