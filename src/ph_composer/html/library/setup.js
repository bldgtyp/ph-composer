/* Machine-level library setup. Native pickers own addresses; this dialog only sees provider ids and labels.
   It leads with the first task, adding a library, and keeps agent access folded away beneath it. */
PhComposerUI.define("library/setup", ["library/locations", "request", "snapshot", "workspace"],
  function (Locations, request, snapshot, ui) {
  "use strict";
  var PREFIX = "ph_composer.library.providers", SECTION = "ph_composer.library.provider_catalogs",
    SETUP_SECTION = "ph_composer.library.provider_setup", el = ui.element;
  /* The two ways to add a library, each one native picker. The choice is shown at once while there is no
     library yet, because adding one is then the whole job; afterwards it waits behind "Add a library…". */
  var ROUTES = [
    { verb: "add_file", label: "Library file…", detail: "One library file, such as one exported from PH-Composer." },
    { verb: "add_folder", label: "Library folder…", detail: "A folder of library files, read together." }];
  function Setup(session, send, changed) {
    var self = this;
    this.changed = changed; this.providers = []; this.enabled = false; this.unreadable = false;
    this.choosing = false; this.added = null;
    this.requests = request.channel(session, send, "library-setup", "setup.invoke");
    this.root = ui.formDialog("library-setup", function () { self.close(); });
    this.root.appendChild(el("h2", "", "Libraries"));
    this.intro = el("p", "muted", "Add a library to copy its Materials and window products into this file. " +
      "Libraries stay on this computer; nothing is shared.");
    this.root.appendChild(this.intro);
    this.list = el("div", "library-setup-list"); this.root.appendChild(this.list);
    this.unreadableNotice = el("div", "library-setup-unreadable");
    this.unreadableNotice.appendChild(el("p", "", "The library setup stored on this machine cannot be read. " +
      "Reset it to add libraries again; the libraries it held must be added again."));
    this.reset = ui.button("Reset library setup", function () { self.run("reset", {}); });
    this.unreadableNotice.appendChild(this.reset); this.root.appendChild(this.unreadableNotice);
    this.routes = el("div", "library-setup-routes"); this.routes.setAttribute("role", "group");
    this.routes.setAttribute("aria-label", "Add a library");
    this.routeButtons = ROUTES.map(function (route) {
      var choice = ui.button("", function () { self.run(route.verb, {}); });
      choice.className = "library-setup-route";
      choice.appendChild(el("strong", "", route.label)); choice.appendChild(el("small", "muted", route.detail));
      choice.setAttribute("aria-label", "Add a " + route.label.toLowerCase());
      self.routes.appendChild(choice);
      return choice;
    });
    this.file = this.routeButtons[0]; this.folder = this.routeButtons[1];
    this.root.appendChild(this.routes);
    this.error = el("p", "cell-error"); this.error.setAttribute("role", "status"); this.root.appendChild(this.error);
    // Agent access is a separate job: what an agent may open by id. Folded away until someone needs it.
    this.agentAccess = el("details", "library-agent-access");
    var summary = el("summary", "", "Agent access");
    this.agentAccess.appendChild(summary);
    // Close waits for a pending approval too, so a location request repaints this dialog as well.
    this.locations = new Locations(session, send, function () { self.paint(); changed(); });
    this.agentAccess.appendChild(this.locations.root);
    this.root.appendChild(this.agentAccess);
    this.add = ui.button("Add a library…", function () { self.choosing = !self.choosing; self.paint(); });
    this.add.setAttribute("aria-expanded", "false");
    // Every change here applies at once, so the dialog ends with Done, never a Cancel that would undo nothing.
    this.cancel = ui.button("Done", function () { self.close(); });
    this.cancel.setAttribute("aria-label", "Done");
    var footer = ui.element("div", "phc-dialog-actions library-setup-adds");
    footer.appendChild(this.add); footer.appendChild(this.cancel);
    this.root.appendChild(footer);
  }
  Setup.prototype.refresh = function (state) {
    if (this.disposed) return;
    var providers = state.session === this.requests.session && snapshot.value(state, SECTION);
    this.enabled = Boolean(providers); this.providers = providers || [];
    var setupState = this.enabled && snapshot.value(state, SETUP_SECTION);
    this.unreadable = Boolean(setupState) && setupState.state === "unreadable";
    if (!this.enabled) { this.requests.reset(); this.root.closeModal(); }
    var outcome = this.requests.consume(state);
    if (outcome) this.settle(outcome);
    this.locations.refresh(state);
    this.paint();
  };
  /* A finished request: an added library is named, marked in the list and the choice folds away, so the
     result and the next step (Done) are plain. A cancelled picker changes nothing. */
  Setup.prototype.settle = function (outcome) {
    var before = this.pendingIds || [];
    this.pendingIds = null;
    this.error.className = "cell-error";
    if (outcome.status === "cancelled") { this.error.textContent = ""; return; }
    if (outcome.status !== "completed") { this.error.textContent = outcome.message; return; }
    var added = (Array.isArray(outcome.value) ? outcome.value : []).filter(function (row) {
      return before.indexOf(row.id) < 0;
    })[0];
    this.added = added ? added.id : null;
    if (added) this.choosing = false;
    this.error.className = "library-setup-success";
    this.error.textContent = added ? "Added " + added.label + ". Choose it under the library list in the " +
      "Library sidebar to copy its records into this file." : "";
  };
  Setup.prototype.paint = function () {
    var self = this, busy = this.requests.busy(), empty = !this.providers.length;
    this.list.replaceChildren();
    this.providers.forEach(function (provider) {
      var row = el("div", "library-setup-row" + (provider.id === self.added ? " is-added" : ""));
      row.appendChild(el("span", "", provider.label));
      if (provider.provider_kind === "ph_composer.library.file") {
        var remove = ui.iconButton("Remove " + provider.label, "delete", function () {
          self.run("remove", { provider_id: provider.id });
        });
        remove.classList.add("library-setup-remove"); remove.disabled = busy || !self.enabled;
        row.appendChild(remove);
      } else row.appendChild(el("small", "muted", "Added by another tool"));
      self.list.appendChild(row);
    });
    this.intro.hidden = !empty || this.unreadable;
    this.unreadableNotice.hidden = !this.unreadable; this.reset.disabled = busy || !this.enabled;
    var blocked = busy || !this.enabled || this.unreadable;
    this.routes.hidden = this.unreadable || !(empty || this.choosing);
    this.routeButtons.forEach(function (button) { button.disabled = blocked; });
    // One primary: adding while there is nothing to use, Done once there is.
    this.add.hidden = empty || this.unreadable;
    this.add.disabled = blocked;
    this.add.setAttribute("aria-expanded", String(!this.routes.hidden));
    this.cancel.classList.toggle("primary", !empty);
    this.cancel.disabled = busy || this.locations.busy();
  };
  Setup.prototype.open = function () {
    if (this.disposed || !this.enabled || this.requests.busy()) return;
    this.error.textContent = ""; this.added = null; this.choosing = false;
    this.paint(); this.root.openModal();
    // The first thing to do takes the focus, not the dialog's close control.
    (this.routes.hidden ? this.cancel : this.file).focus();
    this.changed();
  };
  Setup.prototype.run = function (verb, params) {
    if (this.disposed || !this.enabled || this.requests.busy()) return false;
    this.pendingIds = this.providers.map(function (row) { return row.id; });
    this.requests.run(PREFIX + "." + verb, params);
    this.error.className = "cell-error library-setup-waiting";
    this.error.textContent = /^add_/.test(verb) ? "Choose the library in the window that opened…" :
      "Waiting for library setup…";
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
