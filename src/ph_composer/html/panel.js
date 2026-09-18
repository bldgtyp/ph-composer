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
  var state = initialState();
  var preferenceSequence = 0;
  var notice = null;
  var shownNotice = null;
  var api;

  var HANDLERS = {
    "panel.snapshot": reduceSnapshot,
    "action.result": reduceActionResult,
    "preferences.result": reducePreferenceResult,
    "panel.notice": reduceNotice,
    "panel.failure": reduceFailure
  };

  function initialState() {
    return { session: null, revision: null, sections: {},
      ui: { activeTab: "overview", actionResult: null, notice: null, preferencePending: {} } };
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
      next.ui.notice = null;
    }
    preferences.replace(next.preferences, next.ui.preferencePending);
    return next;
  }

  /* The owning view reads the outcome; a refusal or failure also stays on screen as a warning until the
     user dismisses it (CONTRACTS.md C2: the client shows the message). */
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
      tab.setAttribute("aria-pressed", String(tab.getAttribute("data-tab") === name));
    });
  }

  function showTab(name) {
    if (!document.querySelector("[data-pane='" + name + "']")) return;
    state = withUI(state, { activeTab: name });
    applyTab();
    api.state = state;
  }

  /* `options.pane` names the tab the section belongs to (default "overview"). */
  function section(name, renderFunction, options) {
    var entry = { name: name, render: renderFunction, pane: (options && options.pane) || "overview" };
    if (!document.querySelector("[data-section='" + name + "']") &&
        !document.querySelector("[data-pane='" + entry.pane + "']")) {
      throw new Error("panel section \"" + name + "\" names no pane \"" + entry.pane + "\"");
    }
    sections.push(entry);
    if (state.session !== null) renderSection(entry);
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

  /* Sent once the page has started, so the first snapshot has somewhere to render. */
  function ready() { send("panel.ready", {}); }

  api = { receive: receive, section: section, ready: ready, state: state, showTab: showTab, send: send,
    setPreference: setPreference };
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
