/* global document */
/* Development-only interaction study. No Model, persistence or public API is involved. */
PhComposerUI.start();
(function () {
  "use strict";
  var dom = PhComposerUI.get("dom"), overlay = PhComposerUI.get("overlay");
  var element = dom.element, button = dom.button;
  var options = {
    segment: [{ id: "s1", name: "Building", colour: "#268589" }],
    level: [{ id: "l1", name: "Level 1", colour: "#5588BB" },
      { id: "l2", name: "Level 2", colour: "#9977AA" }]
  };
  var zones = [{ name: "Zone 1", segment: "s1", level: "l1" },
    { name: "Zone 2", segment: "s1", level: null }];
  var defaultSegment = "s1", serial = 3;
  function copy(value) { return JSON.parse(JSON.stringify(value)); }
  function key(name) { return name.trim().toLowerCase().replace(/[\s_-]+/g, " "); }
  function label(kind) { return kind === "segment" ? "Building Segments" : "Levels"; }
  function field(kind) { return kind === "segment" ? "Building Segment" : "Level"; }
  function status(text) { document.getElementById("status").textContent = text; }
  function paint() {
    var table = element("table"), head = element("tr");
    head.appendChild(element("th", "", "Name"));
    ["segment", "level"].forEach(function (kind) {
      var cell = element("th", "", field(kind));
      var menu = new overlay.ActionMenu(field(kind) + " column menu");
      menu.add("Manage " + label(kind) + "…", function () { manage(kind); });
      cell.appendChild(menu.root);
      head.appendChild(cell);
    });
    table.appendChild(head);
    zones.forEach(function (zone) {
      var row = element("tr");
      row.appendChild(element("td", "", zone.name));
      ["segment", "level"].forEach(function (kind) {
        var cell = element("td"), select = element("select", "option-chip");
        select.setAttribute("aria-label", zone.name + " " + field(kind));
        if (kind === "level") select.appendChild(dom.option("", "Not set"));
        options[kind].forEach(function (choice) { select.appendChild(dom.option(choice.id, choice.name)); });
        select.value = zone[kind] || "";
        var chosen = options[kind].find(function (choice) { return choice.id === zone[kind]; });
        if (chosen) select.style.backgroundColor = chosen.colour + "22";
        select.addEventListener("change", function () {
          zone[kind] = select.value || null;
          status(zone.name + " " + field(kind) + " assigned.");
          paint();
        });
        cell.appendChild(select);
        row.appendChild(cell);
      });
      table.appendChild(row);
    });
    document.getElementById("table").replaceChildren(table);
  }
  function manage(kind) {
    var draft = copy(options[kind]), draftZones = copy(zones), draftDefault = defaultSegment;
    var dialog = overlay.formDialog("options-dialog", cancel);
    var list = element("div", "option-list"), error = element("p", "error");
    error.setAttribute("role", "alert");
    var heading = element("h2", "", "Manage " + label(kind));
    var defaultSelect = element("select");
    defaultSelect.setAttribute("aria-label", "Default Building Segment");
    function cancel() { dialog.closeModal(); dialog.remove(); }
    function valid() {
      var keys = [];
      for (var i = 0; i < draft.length; i++) {
        var choice = draft[i], nameKey = key(choice.name);
        if (!nameKey) return "Enter a name for every option.";
        if (keys.indexOf(nameKey) >= 0) return "Equivalent name already exists: " + choice.name;
        if (!/^#[0-9A-Fa-f]{6}$/.test(choice.colour)) return "Enter a colour as #RRGGBB.";
        keys.push(nameKey);
      }
      return kind === "segment" && !draft.length ? "Keep at least one Building Segment." : "";
    }
    function remove(choice) {
      var area = element("div", "replacement"), select = element("select");
      select.setAttribute("aria-label", "Replacement for " + choice.name);
      select.appendChild(dom.option("pending", "Choose a replacement"));
      if (kind === "level") select.appendChild(dom.option("", "Not set"));
      draft.forEach(function (target) {
        if (target.id !== choice.id) select.appendChild(dom.option(target.id, target.name));
      });
      var used = draftZones.some(function (zone) { return zone[kind] === choice.id; });
      var required = used || (kind === "segment" && draftDefault === choice.id);
      var apply = button("Remove", function () {
        if (required && select.value === "pending") { error.textContent = "Choose a replacement."; return; }
        draftZones.forEach(function (zone) {
          if (zone[kind] === choice.id) zone[kind] = select.value === "pending" ? null : select.value || null;
        });
        if (kind === "segment" && draftDefault === choice.id) draftDefault = select.value;
        draft = draft.filter(function (entry) { return entry.id !== choice.id; });
        fill();
      });
      area.appendChild(element("span", "", choice.name + ": merge into another option or remove."));
      area.appendChild(select);
      area.appendChild(apply);
      area.appendChild(button("Keep", fill));
      list.appendChild(area);
      apply.disabled = required;
      select.addEventListener("change", function () { apply.disabled = required && select.value === "pending"; });
    }
    function fill() {
      list.replaceChildren();
      error.textContent = "";
      draft.forEach(function (choice) {
        var row = element("div", "option-row"), name = element("input"), colour = element("input");
        name.type = "text";
        name.value = choice.name;
        name.setAttribute("aria-label", choice.name + " name");
        name.addEventListener("input", function () { choice.name = name.value; error.textContent = valid(); });
        colour.type = "color";
        colour.value = choice.colour;
        colour.setAttribute("aria-label", choice.name + " colour");
        var hex = element("input", "hex");
        hex.type = "text";
        hex.value = choice.colour;
        hex.setAttribute("aria-label", choice.name + " hex colour");
        hex.addEventListener("input", function () {
          choice.colour = hex.value;
          error.textContent = valid();
          if (/^#[0-9A-Fa-f]{6}$/.test(hex.value)) colour.value = hex.value;
        });
        colour.addEventListener("input", function () { choice.colour = colour.value; hex.value = colour.value; });
        row.appendChild(name);
        row.appendChild(colour);
        row.appendChild(hex);
        var count = draftZones.filter(function (zone) { return zone[kind] === choice.id; }).length;
        row.appendChild(element("span", "usage", count + " Zones"));
        row.appendChild(button("Merge / Delete", function () { remove(choice); }));
        list.appendChild(row);
      });
      if (!draft.length) list.appendChild(element("p", "", "No Levels defined."));
      if (kind === "segment") {
        defaultSelect.replaceChildren();
        draft.forEach(function (choice) { defaultSelect.appendChild(dom.option(choice.id, choice.name)); });
        defaultSelect.value = draftDefault;
      }
    }
    dialog.appendChild(heading);
    dialog.appendChild(list);
    dialog.appendChild(button("Add", function () {
      draft.push({ id: "new" + serial++, name: "", colour: "#268589" });
      fill();
      list.querySelectorAll("input[type=text]")[Math.max(0, draft.length * 2 - 2)].focus();
    }));
    if (kind === "segment") {
      var defaultLabel = element("label", "", "Default Building Segment ");
      defaultLabel.appendChild(defaultSelect);
      defaultSelect.addEventListener("change", function () { draftDefault = defaultSelect.value; });
      dialog.appendChild(defaultLabel);
    }
    dialog.appendChild(error);
    dialog.appendChild(overlay.actionRow(button("Cancel", cancel), button("Save", function () {
      error.textContent = valid();
      if (error.textContent) return;
      options[kind] = copy(draft);
      zones = copy(draftZones);
      defaultSegment = draftDefault;
      cancel();
      paint();
      status(label(kind) + " saved together.");
    })));
    document.body.appendChild(dialog);
    fill();
    dialog.openModal();
  }
  paint();
  overlay.attachTooltip(document.body);
}());
