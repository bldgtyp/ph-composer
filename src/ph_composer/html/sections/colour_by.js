/* The panel's Colour-by legend (face-assignment PRD Q18): the mode control, one row per colour with
 * its label and count, click a row to select and zoom to what it counts, and "Show only this" to set
 * every other row aside.
 *
 * Nothing here names a mode, a face type or a Zone. The rows, their labels, their colours and their
 * counts all come from the shared service's legend, so a feature that registers a mode reaches this
 * screen without a line added below.
 *
 * Every control sends a view command: turning a mode on, selecting a row and showing one row on its
 * own all change what the host draws and none of them writes to the Model, so none leaves an Undo
 * entry. Hover-to-highlight, the fourth affordance Q18 names, is not built: it would send one command
 * per pointer move and its cost is a question only a host can answer (planning/phase-one/PLAN.md).
 */
PhComposerUI.define("sections/colour_by", ["panel", "workspace", "request", "snapshot"],
function (panel, ui, requests, snapshot) {
  "use strict";
  var OFF = "";
  var screen = null;

  function forSession(session, send) {
    if (screen && screen.session === session) return screen;
    screen = { session: session, view: requests.channel(session, send, "colour_by", "view.invoke") };
    return screen;
  }

  function rowKey(row) {
    return { value: row.value === undefined ? null : row.value, state: row.state };
  }

  function modeControl(state, legend) {
    var choices = ui.element("select");
    var off = ui.element("option", "", "Off");
    off.value = OFF;
    choices.appendChild(off);
    legend.modes.forEach(function (mode) {
      var option = ui.element("option", "", mode.label);
      option.value = mode.name;
      choices.appendChild(option);
    });
    choices.value = legend.mode || OFF;
    choices.disabled = state.view.busy();
    choices.setAttribute("aria-label", "Colour by");
    choices.addEventListener("change", function () {
      state.view.run("ph_composer.colour_by.activate", { mode: choices.value === OFF ? null : choices.value });
    });
    return choices;
  }

  function swatch(colour) {
    var node = ui.element("span", "phc-legend-swatch");
    node.style.background = "rgb(" + colour.join(",") + ")";
    node.setAttribute("aria-hidden", "true");
    return node;
  }

  /* The row itself is the Locate control, as Q18 asks: clicking it selects and zooms to what it
     counts. "Show only this" is a separate toggle, because it changes the drawing rather than the
     selection, and pressing it again puts everything back. */
  function legendRow(state, row) {
    var node = ui.element("div", "phc-legend-row");
    var locate = ui.element("button", "phc-legend-locate");
    var only = ui.element("button", "phc-legend-only", row.isolated ? "Show all" : "Show only this");
    locate.appendChild(swatch(row.colour));
    locate.appendChild(ui.element("span", "phc-legend-label", row.label));
    locate.appendChild(ui.element("span", "phc-legend-count", String(row.count)));
    locate.setAttribute("aria-label", "Select and zoom to " + row.count + " " + row.label);
    locate.disabled = state.view.busy();
    locate.addEventListener("click", function () {
      state.view.run("ph_composer.colour_by.select_row", { row: rowKey(row) });
    });
    only.setAttribute("aria-pressed", String(Boolean(row.isolated)));
    only.setAttribute("aria-label", row.isolated ? "Show every colour again" : "Show only " + row.label);
    only.disabled = state.view.busy();
    only.addEventListener("click", function () {
      state.view.run("ph_composer.colour_by.isolate", row.isolated ? {} : { row: rowKey(row) });
    });
    node.appendChild(locate);
    node.appendChild(only);
    return node;
  }

  /* Repainted only when what it shows has changed. A snapshot follows every viewport command, and
     rebuilding these controls each time would close a dropdown the user had open and take the focus
     out of whatever they were pressing. */
  function render(root, state, send) {
    var legend = snapshot.value(state, "ph_composer.colour_by.legend") || { mode: null, modes: [], rows: [] };
    var screenState = forSession(state.session, send);
    screenState.view.consume(state);
    ui.memoPaint(root, "legend", [state.session, legend, screenState.view.busy()], function () {
      var heading = ui.element("div", "phc-zone-heading");
      var body = ui.element("div", "phc-legend");
      heading.appendChild(ui.element("h2", "", "Colour by"));
      heading.appendChild(modeControl(screenState, legend));
      if (legend.mode) {
        legend.rows.forEach(function (row) { body.appendChild(legendRow(screenState, row)); });
        if (!legend.rows.length) body.appendChild(ui.element("p", "phc-empty", "Nothing to colour yet."));
      } else {
        body.appendChild(ui.element("p", "phc-empty", "Choose what to colour the model by."));
      }
      root.className = "phc-colour-by";
      root.replaceChildren(heading, body);
    });
  }

  panel.section("ph_composer.colour_by", render, { order: 20 });
});
