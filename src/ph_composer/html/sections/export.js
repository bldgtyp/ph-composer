/* Export uses public preflight, native destination selection and Model-owned task handles.
   Closing this page stops polling; the host task continues and can be retrieved when reopened. */
PhComposerUI.define("sections/export", ["panel", "workspace"], function (panel, ui) {
  "use strict";
  var element = ui.element;
  var sequence = 0, session = null, revision = null, last = null, seen = null, timer = null;
  var pending = {}, checks = null, selected = {}, task = null, message = "", findings = [], retrieved = false;
  var stages = { queued: "Preparing export…", reading: "Reading Model…", translating: "Translating Model…",
    checking: "Checking export…", writing: "Writing HBJSON and report…" };
  var CHANNELS = { start: "export.start", preflight: "export.preflight", status: "export.status",
    cancel: "export.cancel", latest: "export.latest" };

  function active() { return task && !task.outcome; }
  function waiting(operation) {
    return Object.keys(pending).some(function (id) { return pending[id] === operation; });
  }
  function request(operation, payload) {
    var id = "export:" + String(sequence += 1);
    pending[id] = operation;
    last.send(CHANNELS[operation], Object.assign({ request_id: id, session: session }, payload || {}));
  }
  function repaint() { panel.repaint(); }
  function choose() {
    if (active() || waiting("start") || waiting("preflight") || !checks ||
        checks.findings.some(function (f) { return f.blocks_export; })) return;
    request("start", { repairs: Object.keys(selected).filter(function (id) { return selected[id]; }) });
    repaint();
  }
  function cancel() {
    if (!active() || !task.cancellable || waiting("cancel")) return;
    request("cancel", { task_id: task.task_id });
    repaint();
  }
  function poll() {
    if (timer || !active() || waiting("status") || waiting("cancel")) return;
    var current = session;
    timer = window.setTimeout(function () {
      timer = null;
      if (current === session && active()) request("status", { task_id: task.task_id });
    }, 200);
  }
  function accept(result) {
    if (!result || result === seen || result.session !== session) return;
    seen = result;
    var operation = pending[result.request_id];
    if (!operation) return;
    delete pending[result.request_id];
    var outcome = result.outcome || {};
    if (operation === "preflight") {
      checks = outcome.status === "completed" ? outcome.value : {
        findings: [{ message: outcome.message, blocks_export: true }], repairs: [] };
      checks.repairs.forEach(function (repair) {
        if (!Object.prototype.hasOwnProperty.call(selected, repair.id)) selected[repair.id] = repair.checked === true;
      });
      if (outcome.status !== "completed") { message = outcome.message; findings = outcome.findings || []; }
    } else if (outcome.status === "completed") {
      var next = outcome.value;
      if (!(task && task.outcome && next && next.task_id === task.task_id && !next.outcome)) task = next;
      if (task && task.outcome) {
        message = task.outcome.message;
        findings = task.outcome.findings || [];
        if (task.outcome.value && task.outcome.value.result) findings = task.outcome.value.result.findings;
      } else message = "";
    } else {
      message = outcome.message || "The export request could not complete.";
      findings = outcome.findings || [];
      if (operation === "status") task = null;
    }
  }
  function findingList(rows) {
    var list = element("ul", "phc-export-findings");
    rows.forEach(function (finding) {
      var row = element("li", "", finding.message);
      if (finding.locate) row.appendChild(ui.button("Locate", function () {
        last.send("view.invoke", { request_id: "export-locate:" + String(sequence += 1), session: session,
          name: finding.locate.name, params: finding.locate.params });
      }));
      list.appendChild(row);
    });
    return list;
  }
  function paint(root) {
    var heading = element("div", "phc-heading");
    heading.appendChild(element("h1", "", "Export"));
    var actions = element("div", "phc-export-actions");
    var blocked = !checks || checks.findings.some(function (finding) { return finding.blocks_export; });
    actions.appendChild(ui.button(waiting("start") ? "Choosing destination…" : "Choose destination…", choose,
      Boolean(active() || waiting("start") || waiting("preflight") || blocked)));
    if (active()) actions.appendChild(ui.button(waiting("cancel") ? "Cancelling…" : "Cancel export", cancel,
      !task.cancellable || waiting("cancel")));
    var status = element("p", "phc-export-status", active() ? stages[task.stage] || "Export running…" : message);
    status.setAttribute("role", "status");
    root.replaceChildren(heading, element("p", "", "Export creates an HBJSON model and an HTML Export report."));
    if (!checks) root.appendChild(element("p", "", "Checking the Model…"));
    if (checks) {
      checks.repairs.forEach(function (repair) {
        var label = element("label", "phc-export-repair"), input = element("input");
        input.type = "checkbox"; input.checked = Boolean(selected[repair.id]);
        input.disabled = Boolean(active() || waiting("start"));
        input.addEventListener("change", function () { selected[repair.id] = input.checked; });
        label.appendChild(input); label.appendChild(element("span", "", repair.label)); root.appendChild(label);
      });
      if (!active() && !task && checks.findings.length) root.appendChild(findingList(checks.findings));
    }
    root.appendChild(actions); root.appendChild(status);
    if (task && task.outcome && task.outcome.value && task.outcome.value.result) {
      var canonical = task.outcome.value.result.canonical_model;
      if (canonical) root.appendChild(element("p", "", String(canonical.rooms) + " Rooms · " +
        String(canonical.faces) + " Faces · " + String(canonical.surface_pairs) + " Surface pairs"));
      (task.outcome.value.artifacts || []).forEach(function (path) {
        root.appendChild(element("p", "", path.split(/[\\/]/).pop()));
      });
    }
    if (findings.length) root.appendChild(findingList(findings));
  }
  function render(root, state, send) {
    last = { root: root, state: state, send: send };
    if (state.session !== session) {
      window.clearTimeout(timer); timer = null; session = state.session; revision = null; seen = null;
      pending = {}; checks = null; selected = {}; task = null; message = ""; findings = []; retrieved = false;
    }
    accept(state.ui.exportResult);
    if (state.ui.activeTab === "export") {
      if (revision !== state.revision && !active() && !waiting("start") && !waiting("preflight")) {
        revision = state.revision; request("preflight");
      }
      if (!retrieved) { retrieved = true; request("latest"); }
    }
    poll();
    ui.memoPaint(root, "export", [session, Boolean(waiting("start")), Boolean(waiting("cancel")),
      checks, task, message, findings], function () { paint(root); });
  }
  panel.navigationGuard("export", function () {
    return active() || waiting("start") ?
      "Export is running. Cancel it or wait for it to finish before changing tabs." : null;
  });
  window.addEventListener("beforeunload", function () { window.clearTimeout(timer); });
  panel.section("export", render, { pane: "export" });
});
