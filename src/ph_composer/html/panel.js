/* The panel page's one state and its message loop. The host sends the shown Model's snapshot, action
 * results, preference results and notices; a reducer folds each into the state and every registered section
 * re-renders from it. Presentation-only changes (the active tab) never touch the host.
 *
 * Sections register through section(name, render, options). A section whose mount node is not in the page
 * is created in its pane, so a feature, or a development script, adds a section without editing index.html.
 * A section owns its local editing state and resets it when `state.session` changes.
 *
 * The panel acts only on the Model it shows: `action.invoke` carries the shown session and the revision the
 * panel last rendered, and a result or notice for another session is not painted.
 */
PhComposerUI.define("panel", ["unit_preferences", "workspace"], function (preferences, ui) {
  "use strict";

  var sections = [];
  var navigationGuards = {};
  var DEFAULT_ORDER = 100;
  var state = initialState();
  var preferenceSequence = 0;
  var notice = null;
  var shownNotice = null;
  var api;

  var HANDLERS = {
    "panel.snapshot": reduceSnapshot,
    "action.result": reduceActionResult,
    "view.result": reduceViewResult,
    "preferences.result": reducePreferenceResult,
    "panel.notice": reduceNotice,
    "panel.failure": reduceFailure,
    "export.result": reduceExportResult
  };

  function initialState() {
    return { session: null, revision: null, sections: {},
      ui: { activeTab: "overview", actionResult: null, viewResults: {}, exportResult: null, notice: null,
        preferencePending: {} } };
  }

  function copy(object) {
    var result = {};
    Object.keys(object || {}).forEach(function (key) { result[key] = object[key]; });
    return result;
  }

  function withUI(previous, changes) {
    var result = copy(previous);
    result.ui = copy(previous.ui);
    Object.keys(changes).forEach(function (key) { result.ui[key] = changes[key]; });
    return result;
  }

  /* A snapshot for another Model drops the previous Model's result and notice; the tab stays. */
  function reduceSnapshot(previous, payload) {
    var next = copy(payload);
    next.ui = copy(previous.ui);
    if (previous.session !== next.session) {
      next.ui.actionResult = null;
      next.ui.viewResults = {};
      next.ui.exportResult = null;
      next.ui.notice = null;
    }
    preferences.replace(next.preferences, next.ui.preferencePending);
    return next;
  }

  /* The owning view reads the outcome; a refusal or failure also stays on screen as a warning until the
     user dismisses it (context/CONTRACTS.md, "Public interface": the client shows the message). */
  function reduceActionResult(previous, payload) {
    var outcome = payload.outcome || {};
    var changes = { actionResult: payload };
    if (payload.session !== previous.session) return previous;
    if (outcome.status !== "completed") {
      changes.notice = { message: outcome.message || "The change was not applied.",
        tone: outcome.status === "failed" ? "error" : "warning" };
    }
    return withUI(previous, changes);
  }

  /* A viewport-state command changes what the host shows and never the Model, so a refusal is a warning
     about the view, never about an edit the user should check. Results are kept by request id, because
     several views send them independently; the oldest are dropped once the page is clearly done with
     them, which is a bound on the map rather than a promise about any one entry. */
  function reduceViewResult(previous, payload) {
    var outcome = payload.outcome || {};
    var changes = { viewResults: recentResults(previous.ui.viewResults, payload) };
    if (payload.session !== previous.session) return previous;
    if (outcome.status !== "completed") {
      changes.notice = { message: outcome.message || "The viewport did not change.",
        tone: outcome.status === "failed" ? "error" : "warning" };
    }
    return withUI(previous, changes);
  }

  /* The Export pane reads it; Export writes nothing to the Model, so no notice is raised. */
  function reduceExportResult(previous, payload) {
    if (payload.session !== previous.session) return previous;
    return withUI(previous, { exportResult: payload });
  }

  function reducePreferenceResult(previous, payload) {
    var pending = copy(previous.ui.preferencePending);
    var name = Object.keys(pending).filter(function (key) { return pending[key].requestId === payload.request_id; })[0];
    var item;
    var changes;
    if (!name) return previous;
    item = pending[name];
    delete pending[name];
    changes = { preferencePending: pending };
    preferences.replace(payload.preferences, pending);
    if (payload.status !== "completed") {
      preferences.set(item.key, item.previous, item.extra);
      changes.notice = { message: payload.message || "The display preference could not be saved.", tone: "error" };
    }
    return withUI(previous, changes);
  }

  function reduceNotice(previous, payload) {
    if (payload.session !== previous.session) return previous;
    return withUI(previous, { notice: { message: payload.message, tone: payload.tone || "info" } });
  }

  function reduceFailure(previous, payload) {
    return withUI(previous, { notice: { message: payload.message || "The panel request failed.", tone: "error" } });
  }

  var MAX_VIEW_RESULTS = 8;
  function recentResults(previous, payload) {
    var kept = copy(previous), ids = Object.keys(kept);
    kept[payload.request_id] = payload;
    ids.slice(0, Math.max(0, ids.length + 1 - MAX_VIEW_RESULTS)).forEach(function (id) { delete kept[id]; });
    return kept;
  }

  function receive(envelope) {
    var handler = envelope && HANDLERS[envelope.type];
    if (!handler) return;
    state = handler(state, envelope.payload || {});
    render();
  }

  function mount(entry) {
    var root = document.querySelector("[data-section='" + entry.name + "']");
    var pane;
    if (root) return root;
    pane = document.querySelector("[data-pane='" + entry.pane + "']");
    if (!pane) throw new Error("panel section \"" + entry.name + "\" names no pane \"" + entry.pane + "\"");
    root = ui.element("section");
    root.setAttribute("data-section", entry.name);
    pane.appendChild(root);
    return root;
  }

  /* One section's failure stays in that section: the shell, the notices and every other section still
     paint, so a refusal warning is never hidden by an unrelated error. */
  function renderSection(entry) {
    try {
      entry.render(mount(entry), state, send);
    } catch (error) {
      if (window.console) window.console.error("panel section \"" + entry.name + "\" failed to render", error);
    }
  }

  function render() {
    api.state = state;
    renderNotice();
    renderUnitToggle();
    applyTab();
    if (state.session !== null) sections.forEach(renderSection);
  }

  /* One floating notice above the panes, so a late message never reflows the page. Warnings and errors stay
     until dismissed; information fades on the next interaction. */
  function renderNotice() {
    var layer = document.querySelector("[data-notice-layer]");
    var current = state.ui.notice;
    if (!layer) return;
    if (!notice) {
      notice = ui.floatingNotice(document.body);
      layer.appendChild(notice);
    }
    if (current === shownNotice) return;
    shownNotice = current;
    if (!current) { notice.clear(); return; }
    notice.show(current.message, { tone: current.tone, persistent: current.tone !== "info" });
  }

  function applyTab() {
    var name = state.ui.activeTab;
    Array.prototype.forEach.call(document.querySelectorAll("[data-pane]"), function (pane) {
      pane.hidden = pane.getAttribute("data-pane") !== name;
    });
    Array.prototype.forEach.call(document.querySelectorAll("[data-tab]"), function (tab) {
      var current = tab.getAttribute("data-tab") === name;
      tab.setAttribute("aria-pressed", String(current));
      // A tab row narrower than its tabs scrolls; the current tab stays in view.
      if (current && tab.scrollIntoView) tab.scrollIntoView({ block: "nearest", inline: "nearest" });
    });
  }

  function showTab(name) {
    if (!document.querySelector("[data-pane='" + name + "']")) return;
    if (name !== state.ui.activeTab) {
      var refusing = Object.keys(navigationGuards).filter(function (key) {
        return navigationGuards[key].guard(name);
      })[0];
      if (refusing) {
        var entry = navigationGuards[refusing];
        notify(entry.guard(name), "warning");
        if (entry.refused) entry.refused();
        return;
      }
    }
    state = withUI(state, { activeTab: name });
    render();
  }

  /* `options.pane` names the tab the section belongs to (default "overview"). `options.order` places
     it within that pane, low first; sections that do not ask are placed after those that do, in the
     order they registered. A pane holds the screen's work surface first and its secondary controls
     after it, and load order is decided by the module graph, so a section that cares says so. */
  function section(name, renderFunction, options) {
    var entry = { name: name, render: renderFunction, pane: (options && options.pane) || "overview",
      order: (options && options.order) !== undefined ? options.order : DEFAULT_ORDER,
      registered: sections.length };
    if (!document.querySelector("[data-section='" + name + "']") &&
        !document.querySelector("[data-pane='" + entry.pane + "']")) {
      throw new Error("panel section \"" + name + "\" names no pane \"" + entry.pane + "\"");
    }
    sections.push(entry);
    sections.sort(function (left, right) {
      return left.order - right.order || left.registered - right.registered;
    });
    if (state.session !== null) sections.forEach(renderSection);
  }

  function preferenceValue(key, extra) {
    var current = preferences.current();
    if (key === "unit_system") return current.unitSystem;
    return preferences.dimensionFormat(extra.scope, extra.system);
  }

  /* Applies a display preference at once and asks the host to remember it; a refusal restores the previous
     value. `extra` is `{ scope, system }` for a dimension format. */
  function setPreference(key, value, extra) {
    var details = extra || {};
    var name = key === "dimension_format" ? key + "." + details.scope + "." + details.system : key;
    var pending = copy(state.ui.preferencePending);
    var requestId = "preferences:" + String(preferenceSequence += 1);
    var payload = { request_id: requestId, key: key, value: value };
    if (key === "dimension_format") {
      payload.scope = details.scope;
      payload.system = details.system;
    }
    pending[name] = { requestId: requestId, key: key, value: value, extra: details,
      previous: preferenceValue(key, details) };
    state = withUI(state, { preferencePending: pending });
    preferences.set(key, value, details);
    render();
    send("preferences.set", payload);
    return requestId;
  }

  var renderedUnitSystem = null;
  function renderUnitToggle() {
    var system = preferences.current().unitSystem;
    if (system === renderedUnitSystem) return;
    renderedUnitSystem = system;
    Array.prototype.forEach.call(document.querySelectorAll("[data-unit-system]"), function (button) {
      button.setAttribute("aria-pressed", String(button.getAttribute("data-unit-system") === system));
    });
  }

  /* The one route to the host. An action names the shown session and, unless the caller gives one, the
     revision this page last rendered. */
  function send(type, payload) {
    var message = copy(payload);
    if (type === "action.invoke" && message.expected_revision === undefined) message.expected_revision = state.revision;
    if (window.sketchup && window.sketchup.ph_composer_message) {
      window.sketchup.ph_composer_message(JSON.stringify({ type: type, payload: message }));
    }
  }

  /* A notice raised by the page itself, such as a refused navigation. It never reaches the host. */
  function notify(message, tone) {
    state = withUI(state, { notice: { message: message, tone: tone || "info" } });
    render();
  }

  /* Sent once the page has started, so the first snapshot has somewhere to render. */
  function ready() { send("panel.ready", {}); }

  /* A presentation-only change: a section that owns local view state (a selection, a filter, an open
     row) repaints every section from the state already in hand. It never reaches the host. */
  function repaint() { render(); }

  api = { receive: receive, section: section, ready: ready, state: state, showTab: showTab, send: send,
    setPreference: setPreference, repaint: repaint, notify: notify,
    // `guard(tab)` answers why the tab may not change, or null; `refused`, when given, runs after a
    // refusal is shown, so a section can point the user at the work that holds the tab.
    navigationGuard: function (name, guard, refused) { navigationGuards[name] = { guard: guard, refused: refused }; }
  };
  Array.prototype.forEach.call(document.querySelectorAll("[data-tab]"), function (tab) {
    tab.addEventListener("click", function () { showTab(tab.getAttribute("data-tab")); });
  });
  Array.prototype.forEach.call(document.querySelectorAll("[data-unit-system]"), function (button) {
    button.addEventListener("click", function () {
      var system = button.getAttribute("data-unit-system");
      if (preferences.current().unitSystem !== system) setPreference("unit_system", system);
    });
  });
  return api;
});
