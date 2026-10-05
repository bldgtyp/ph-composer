/* The panel's Colour by, as parts a pane places:
 *
 * - `HeaderToggle(binding)`, a column header's toggle for the mode that colours by what the column shows. A
 *   binding names one mode (`{ mode }`) or a group of modes (`{ group }`), which a mode declares when it
 *   registers. One mode is on at a time: pressing an unpressed toggle turns its mode on and releases any
 *   other, and pressing the pressed one turns Colour by Off. A group with several modes opens a menu of them.
 * - The legend strip, in the pane's `tools` region (the end of the work surface's control row): the mode's
 *   name, then one chip per colour with its count. A chip selects and zooms to what it counts; the eye on it
 *   fades every other colour in the viewport (the table is unchanged), and Show all puts them back. The strip
 *   is empty while Colour by is off, and its slot keeps its place, so the table never moves.
 * - `modes(state)` and `activate(state, name)`, so a screen can offer a mode no column binds (an options
 *   menu) through the same command.
 *
 * Nothing here names a mode, a face type or a Zone. The modes, rows, labels, colours and counts all come from
 * the shared service's legend, so a feature that registers a mode reaches the panel without a line added here.
 * Every control sends a view command: none writes to the Model, so none leaves an Undo entry. Hover-to-
 * highlight is not built: it would send one command per pointer move, and its cost has to be measured first.
 */
PhComposerUI.define("sections/colour_by", ["panel", "workspace", "request", "snapshot"],
function (panel, ui, requests, snapshot) {
  "use strict";
  var screen = null;

  function forSession(session) {
    if (screen && screen.session === session) return screen;
    screen = { session: session, view: requests.channel(session, panel.send, "colour_by", "view.invoke") };
    return screen;
  }

  function legendOf(state) {
    return snapshot.value(state, "ph_composer.colour_by.legend") || { mode: null, modes: [], rows: [] };
  }

  function modes(state) { return legendOf(state).modes; }

  /* Turns `name` on, or Colour by off with null. Answers false while another request is in flight. */
  function activate(state, name) {
    var owner = forSession(state.session);
    owner.view.consume(state);
    return owner.view.run("ph_composer.colour_by.activate", { mode: name || null });
  }

  function HeaderToggle(binding) {
    this.binding = binding;
    this.node = ui.element("span", "phc-colour-toggle");
    this.signature = null;
    this.pressed = false;
  }

  HeaderToggle.prototype.matching = function (legend) {
    var binding = this.binding;
    return legend.modes.filter(function (mode) {
      return binding.mode ? mode.name === binding.mode : Boolean(binding.group) && mode.group === binding.group;
    });
  };

  /* Built when the modes it stands for change, and repainted in place otherwise, so a press keeps its focus
     through the snapshot that follows. Answers whether the column has a mode to offer. */
  HeaderToggle.prototype.paint = function (state) {
    var self = this, legend = legendOf(state), found = this.matching(legend), owner = forSession(state.session);
    owner.view.consume(state);
    var signature = found.map(function (mode) { return mode.name + ":" + mode.label; }).join("|");
    if (signature !== this.signature) {
      this.signature = signature;
      this.button = ui.iconButton("", "palette", found.length === 1 ? function () { self.press(); } : null);
      if (found.length > 1) {
        this.menu = new ui.Bubble(this.button, "Colour by", { onOpen: function () { self.fill(); } });
        this.menu.panel.classList.add("phc-action-menu");
        this.menu.root.classList.add("phc-action-menu-anchor");
        this.node.replaceChildren(this.menu.root);
      } else {
        this.menu = null;
        this.node.replaceChildren(found.length ? this.button : ui.element("span"));
      }
    }
    this.modes = found;
    var active = found.filter(function (mode) { return mode.name === legend.mode; })[0];
    this.pressed = Boolean(active);
    if (found.length) {
      var named = active ? active.label : found.map(function (mode) { return mode.label; }).join(" or ");
      ui.paintIconButton(this.button, "Colour by " + named, "palette");
      this.button.setAttribute("aria-pressed", String(this.pressed));
      this.button.disabled = owner.view.busy();
    }
    return found.length > 0;
  };

  HeaderToggle.prototype.press = function () {
    activate(panel.state, this.pressed ? null : this.modes[0].name);
  };

  /* A group's menu: one item per mode, the one on marked, and Off while one is. */
  HeaderToggle.prototype.fill = function () {
    var self = this, current = legendOf(panel.state).mode;
    this.menu.content.replaceChildren();
    function item(text, name, pressed) {
      var node = ui.button(text, function () { self.menu.close(true); activate(panel.state, name); });
      node.className = "phc-action-menu-item";
      if (pressed !== undefined) node.setAttribute("aria-pressed", String(pressed));
      self.menu.content.appendChild(node);
    }
    this.modes.forEach(function (mode) { item(mode.label, mode.name, mode.name === current); });
    if (this.pressed) item("Off", null);
  };

  function rowKey(row) {
    return { value: row.value === undefined ? null : row.value, state: row.state };
  }

  function swatch(colour) {
    var node = ui.element("span", "phc-legend-swatch");
    node.style.background = "rgb(" + colour.join(",") + ")";
    node.setAttribute("aria-hidden", "true");
    return node;
  }

  /* The chip itself selects and zooms to what it counts. The eye is a separate toggle, because it changes the
     drawing rather than the selection, and pressing it again puts everything back. */
  function chip(owner, row) {
    var node = ui.element("span", "phc-legend-chip" + (row.isolated ? " is-isolated" : ""));
    var locate = ui.element("button", "phc-legend-locate");
    locate.appendChild(swatch(row.colour));
    locate.appendChild(ui.element("span", "phc-legend-label", row.label));
    locate.appendChild(ui.element("span", "phc-legend-count", String(row.count)));
    locate.setAttribute("aria-label", "Select and zoom to " + row.count + " " + row.label);
    locate.disabled = owner.view.busy();
    locate.addEventListener("click", function () {
      owner.view.run("ph_composer.colour_by.select_row", { row: rowKey(row) });
    });
    var only = ui.iconButton(row.isolated ? "Show every colour again" : "Show only " + row.label + " in the viewport",
      "eye", function () {
        owner.view.run("ph_composer.colour_by.isolate", row.isolated ? {} : { row: rowKey(row) });
      });
    only.classList.add("phc-legend-only");
    only.setAttribute("aria-pressed", String(Boolean(row.isolated)));
    only.disabled = owner.view.busy();
    node.appendChild(locate);
    node.appendChild(only);
    return node;
  }

  /* Repainted only when what it shows has changed. A snapshot follows every viewport command, and rebuilding
     these controls each time would take the focus out of whatever the user was pressing. */
  function renderStrip(root, state) {
    var legend = legendOf(state), owner = forSession(state.session);
    owner.view.consume(state);
    ui.memoPaint(root, "legend", [state.session, legend, owner.view.busy()], function () {
      root.className = "phc-legend-strip";
      root.replaceChildren();
      if (!legend.mode) { root.removeAttribute("aria-label"); root.removeAttribute("role"); return; }
      root.setAttribute("aria-label", "Colour by " + legend.label);
      root.setAttribute("role", "group");
      root.appendChild(ui.element("span", "phc-legend-title", legend.label));
      legend.rows.forEach(function (row) { root.appendChild(chip(owner, row)); });
      if (!legend.rows.length) root.appendChild(ui.element("span", "phc-legend-empty", "Nothing to colour yet."));
      if (legend.rows.some(function (row) { return row.isolated; })) {
        var reset = ui.button("Show all", function () { owner.view.run("ph_composer.colour_by.isolate", {}); });
        reset.className = "phc-legend-show-all";
        reset.setAttribute("aria-label", "Show every colour again");
        reset.disabled = owner.view.busy();
        root.appendChild(reset);
      }
    });
  }

  panel.section("ph_composer.colour_by", renderStrip, { region: "tools", order: 20 });
  return { HeaderToggle: HeaderToggle, modes: modes, activate: activate };
});
