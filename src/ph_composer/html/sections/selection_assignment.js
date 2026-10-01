/* A native selection handoff owns a frozen set of Faces and revision until its modal closes. */
PhComposerUI.define("sections/selection_assignment",
  ["panel", "snapshot", "request", "sections/attached_zone_assignment", "sections/assembly_assignment"],
function (panel, snapshot, requests, assignment, assemblies) {
  "use strict";
  var SECTION = "ph_composer.zones.faces.selection_assignment";
  var CLOSE = "ph_composer.zones.faces.close_attached_assignment";

  function SelectionAssignment(session, send, guard) {
    this.session = session;
    this.send = send;
    this.guard = guard;
    this.closeRequest = requests.channel(session, send, "selection_assignment_close", "view.invoke");
    this.assembly = new assemblies.Picker(session, send, guard);
    this.root = this.assembly.root;
    this.form = null;
    this.token = null;
    this.waiting = null;
    this.tabAttempt = null;
  }

  SelectionAssignment.prototype.consume = function (state, records) {
    this.assembly.refresh(state);
    this.closeRequest.consume(state);
    if (this.form) { this.form.consume(state); return; }
    var pending = snapshot.value(state, SECTION);
    if (!pending || !pending.token || pending.token === this.token) return;
    var reason = this.guard();
    if (reason) {
      var fresh = this.waiting !== pending.token;
      this.waiting = pending.token;
      if (fresh) panel.notify(reason, "warning");
      return;
    }
    if (state.ui && state.ui.activeTab !== "overview") {
      if (this.tabAttempt === pending.token) return;
      this.tabAttempt = pending.token;
      panel.showTab("overview");
      // Retain the token during refusal's recursive repaint, then allow a later host update to retry.
      if (panel.state.ui.activeTab !== "overview") this.tabAttempt = null;
      return;
    }
    this.token = pending.token;
    this.waiting = null;
    var self = this;
    this.form = assignment.open(this.session, this.send, pending.revision, pending.faces, records, null, function () {
      self.form = null;
      self.closeRequest.run(CLOSE, { token: self.token });
      panel.repaint();
    });
  };

  SelectionAssignment.prototype.active = function () { return Boolean(this.form) || this.assembly.active(); };
  SelectionAssignment.prototype.dispose = function () {
    this.assembly.dispose();
    if (this.form) this.form.dispose();
    this.form = null;
    this.closeRequest.reset();
  };
  return SelectionAssignment;
});
