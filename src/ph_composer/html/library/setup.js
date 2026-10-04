/* Machine-level library setup. Native pickers own addresses; this dialog only sees provider ids and labels. */
PhComposerUI.define("library/setup", ["library/locations", "request", "snapshot", "workspace"],
  function (Locations, request, snapshot, ui) {
  "use strict";
  var PREFIX = "ph_composer.library.providers", SECTION = "ph_composer.library.provider_catalogs",
    SETUP_SECTION = "ph_composer.library.provider_setup", el = ui.element;
  function Setup(session, send, changed) {
    var self = this;
    this.changed = changed; this.providers = []; this.enabled = false; this.unreadable = false;
    this.requests = request.channel(session, send, "library-setup", "setup.invoke");
    this.root = ui.formDialog("library-setup", function () { self.close(); });
    this.root.appendChild(el("h2", "", "Libraries"));
    this.root.appendChild(el("p", "muted", "Configure library files or folders on this machine."));
    this.list = el("div", "library-setup-list"); this.root.appendChild(this.list);
    this.unreadableNotice = el("div", "library-setup-unreadable");
    this.unreadableNotice.appendChild(el("p", "", "The library setup stored on this machine cannot be read. " +
      "Reset it to add libraries again; the libraries it held must be added again."));
    this.reset = ui.button("Reset library setup", function () { self.run("reset", {}); });
    this.unreadableNotice.appendChild(this.reset); this.root.appendChild(this.unreadableNotice);
    this.error = el("p", "cell-error"); this.error.setAttribute("role", "status"); this.root.appendChild(this.error);
    // Close waits for a pending approval too, so a location request repaints this dialog as well.
    this.locations = new Locations(session, send, function () { self.paint(); changed(); });
    this.root.appendChild(this.locations.root);
    this.file = ui.button("Add library file…", function () { self.run("add_file", {}); });
    this.folder = ui.button("Add library folder…", function () { self.run("add_folder", {}); });
    this.cancel = ui.button("Close", function () { self.close(); });
    this.cancel.setAttribute("aria-label", "Close"); this.file.setAttribute("aria-label", "Add library file…");
    // Both open a native picker, so neither carries the check mark of an action that applies at once. Adding a
    // file is still the dialog's primary action.
    this.cancel.className += " phc-action-cancel"; this.file.className += " primary";
    var adds = ui.element("div", "phc-dialog-actions library-setup-adds");
    [this.cancel, this.folder, this.file].forEach(function (button) { adds.appendChild(button); });
    this.root.appendChild(adds);
  }
  Setup.prototype.refresh = function (state) {
    if (this.disposed) return;
    var providers = state.session === this.requests.session && snapshot.value(state, SECTION);
    this.enabled = Boolean(providers); this.providers = providers || [];
    var setupState = this.enabled && snapshot.value(state, SETUP_SECTION);
    this.unreadable = Boolean(setupState) && setupState.state === "unreadable";
    if (!this.enabled) { this.requests.reset(); this.root.closeModal(); }
    var outcome = this.requests.consume(state);
    if (outcome) this.error.textContent = ["completed", "cancelled"].includes(outcome.status) ? "" : outcome.message;
    this.locations.refresh(state);
    this.paint();
  };
  Setup.prototype.paint = function () {
    var self = this, busy = this.requests.busy();
    this.list.replaceChildren();
    this.providers.forEach(function (provider) {
      var row = el("div", "library-setup-row"); row.appendChild(el("span", "", provider.label));
      if (provider.provider_kind === "ph_composer.library.file") {
        var remove = ui.button("Remove", function () { self.run("remove", { provider_id: provider.id }); });
        remove.setAttribute("aria-label", "Remove " + provider.label); remove.disabled = busy || !self.enabled;
        row.appendChild(remove);
      } else row.appendChild(el("small", "muted", "Added by another tool"));
      self.list.appendChild(row);
    });
    if (!this.providers.length && !this.unreadable) this.list.appendChild(el("p", "muted", "No libraries configured."));
    this.unreadableNotice.hidden = !this.unreadable; this.reset.disabled = busy || !this.enabled;
    this.file.disabled = busy || !this.enabled || this.unreadable; this.folder.disabled = this.file.disabled;
    this.cancel.disabled = busy || this.locations.busy();
  };
  Setup.prototype.open = function () {
    if (this.disposed || !this.enabled || this.requests.busy()) return;
    this.error.textContent = ""; this.paint(); this.root.openModal(); this.changed();
  };
  Setup.prototype.run = function (verb, params) {
    if (this.disposed || !this.enabled || this.requests.busy()) return false;
    this.requests.run(PREFIX + "." + verb, params); this.error.textContent = "Waiting for library setup…";
    this.paint(); this.changed(); return true;
  };
  Setup.prototype.close = function () {
    if (this.requests.busy() || this.locations.busy()) return;
    this.root.closeModal(); this.changed();
  };
  Setup.prototype.dispose = function () {
    this.disposed = true; this.enabled = false; this.requests.reset(); this.locations.dispose(); this.root.closeModal();
  };
  return Setup;
});
