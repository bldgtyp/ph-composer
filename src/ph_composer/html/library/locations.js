/* The approved locations on this machine, inside the Libraries dialog. Approving opens a native dialog on the host;
   this view only sees each location's id, label and state, never its path. */
PhComposerUI.define("library/locations", ["request", "snapshot", "workspace"], function (request, snapshot, ui) {
  "use strict";
  var PREFIX = "ph_composer.locations", SECTION = "ph_composer.locations.approved", el = ui.element;
  var KINDS = { save_file: "Export destination", open_file: "Library file", open_folder: "Library folder" };
  function day(iso) { return iso ? new Date(iso).toLocaleDateString() : ""; }
  function Locations(session, send, changed) {
    var self = this;
    this.changed = changed; this.rows = []; this.enabled = false; this.unreadable = false;
    this.renaming = null; this.renameInput = null; this.painting = false; this.revoking = null;
    this.requests = request.channel(session, send, "approved-locations", "setup.invoke");
    this.root = el("div", "library-locations"); this.root.setAttribute("role", "group");
    this.root.setAttribute("aria-label", "Approved locations");
    this.root.appendChild(el("h3", "", "Approved locations"));
    this.root.appendChild(el("p", "muted", "An agent working with PH-Composer can open these by id without asking " +
      "you again. Adding a library above needs no approval. Approvals stay on this computer, for this version " +
      "of SketchUp."));
    this.list = el("div", "library-locations-list"); this.root.appendChild(this.list);
    this.unreadableNotice = el("div", "library-setup-unreadable");
    this.unreadableNotice.appendChild(el("p", "", "The approved locations stored on this machine cannot be read. " +
      "Reset them to approve locations again."));
    this.reset = ui.button("Reset approved locations", function () { self.run("reset", {}); });
    this.unreadableNotice.appendChild(this.reset); this.root.appendChild(this.unreadableNotice);
    this.error = el("p", "cell-error"); this.error.setAttribute("role", "status"); this.root.appendChild(this.error);
    this.approvals = ["approve_destination", "approve_file", "approve_folder"].map(function (verb, index) {
      var label = ["Approve destination…", "Approve file…", "Approve folder…"][index];
      return ui.button(label, function () { self.run(verb, {}); });
    });
    var approvals = el("div", "library-setup-adds");
    this.approvals.forEach(function (button) { approvals.appendChild(button); });
    this.root.appendChild(approvals);
  }
  Locations.prototype.busy = function () { return this.requests.busy(); };
  Locations.prototype.refresh = function (state) {
    var listing = state.session === this.requests.session && snapshot.value(state, SECTION);
    this.enabled = Boolean(listing); this.rows = listing ? listing.locations : [];
    this.unreadable = Boolean(listing) && listing.state === "unreadable";
    if (!this.enabled) this.requests.reset();
    var outcome = this.requests.consume(state);
    if (outcome) this.error.textContent = ["completed", "cancelled"].includes(outcome.status) ? "" : outcome.message;
    this.paint();
  };
  Locations.prototype.row = function (location) {
    var self = this, busy = this.busy() || !this.enabled, row = el("div", "library-setup-row library-location-row");
    var text = el("div", "library-location-text");
    if (this.renaming === location.id) text.appendChild(this.renameInput);
    else text.appendChild(el("span", "", location.label));
    var facts = [KINDS[location.kind], "approved " + day(location.approved_at),
      location.last_used_at ? "last used " + day(location.last_used_at) : "not used yet"];
    var meta = el("small", "muted", facts.join(" · ")); text.appendChild(meta);
    if (!location.available) text.appendChild(el("small", "library-location-missing", "No longer there as approved"));
    row.appendChild(text);
    var actions = el("div", "library-location-actions");
    if (this.revoking === location.id) {
      var keep = ui.button("Keep", function () { self.revoking = null; self.paint(); });
      var confirm = ui.button("Revoke", function () { self.revoking = null; self.run("revoke", { id: location.id }); });
      confirm.className += " phc-action-delete"; confirm.setAttribute("aria-label", "Confirm revoke " + location.label);
      keep.disabled = confirm.disabled = busy;
      actions.appendChild(keep); actions.appendChild(confirm);
    } else {
      var rename = ui.button("Rename", function () { self.startRename(location); });
      var revoke = ui.button("Revoke", function () { self.revoking = location.id; self.paint(); });
      rename.setAttribute("aria-label", "Rename " + location.label);
      revoke.setAttribute("aria-label", "Revoke " + location.label);
      rename.disabled = revoke.disabled = busy;
      actions.appendChild(rename); actions.appendChild(revoke);
    }
    row.appendChild(actions);
    return row;
  };
  /* One field for the whole rename, kept across repaints so a snapshot refresh neither loses the draft nor, through
     the blur a browser fires while the list is rebuilt, submits it. Enter or leaving applies; Escape restores. */
  Locations.prototype.startRename = function (location) {
    var self = this, input = el("input");
    input.value = location.label; input.setAttribute("aria-label", "Location name");
    var finish = function (apply) {
      if (self.painting || self.renameInput !== input) return;
      self.renaming = null; self.renameInput = null;
      var label = input.value.trim();
      if (apply && label && label !== location.label) self.run("rename", { id: location.id, label: label });
      else self.paint();
    };
    input.addEventListener("keydown", function (event) {
      if (event.key === "Enter") { event.preventDefault(); finish(true); }
      if (event.key === "Escape") { event.preventDefault(); event.stopPropagation(); finish(false); }
    });
    input.addEventListener("blur", function () { finish(true); });
    this.renaming = location.id; this.renameInput = input; this.paint();
    input.focus(); input.select();
  };
  Locations.prototype.paint = function () {
    var self = this, input = this.renameInput, focused = Boolean(input) && document.activeElement === input;
    var caret = focused ? [input.selectionStart, input.selectionEnd] : null;
    if (input && !this.rows.some(function (location) { return location.id === self.renaming; })) {
      this.renaming = null; this.renameInput = input = null;
    }
    this.painting = true;
    this.list.replaceChildren();
    this.rows.forEach(function (location) { self.list.appendChild(self.row(location)); });
    this.painting = false;
    if (!this.rows.length && !this.unreadable) this.list.appendChild(el("p", "muted", "No approved locations."));
    this.unreadableNotice.hidden = !this.unreadable; this.reset.disabled = this.busy() || !this.enabled;
    this.approvals.forEach(function (button) { button.disabled = self.busy() || !self.enabled || self.unreadable; });
    if (input && caret) { input.focus(); input.setSelectionRange(caret[0], caret[1]); }
  };
  Locations.prototype.run = function (verb, params) {
    if (!this.enabled || this.busy()) return false;
    // Said before sending, so an answer that arrives at once is not overwritten by it.
    this.error.textContent = "Waiting for approved locations…"; this.requests.run(PREFIX + "." + verb, params);
    this.paint(); this.changed(); return true;
  };
  Locations.prototype.dispose = function () { this.enabled = false; this.requests.reset(); };
  return Locations;
});
