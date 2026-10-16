/* The Spaces view's row actions (P3a-07 step 9): Locate every row; Open or Close a Space; Enter a Volume;
 * Delete a Space and Remove a Volume, each after a confirmation naming what goes; Move a Space to another
 * Zone; and the repair a row's finding names (Restore position, Make independent).
 *
 * Every Model change carries the revision the row was painted from, so a row from a stale snapshot refuses
 * rather than acting on what has changed. Context commands are view commands (they move the edit context and
 * the selection, never a record); entering a protected Volume unprotects it first and opens it only once that
 * has completed. The open row is the one on the snapshot's edit path, never the selection or the expansion.
 */
PhComposerUI.define("features/spaces/actions", ["panel", "request", "workspace"], function (panel, requests, ui) {
  "use strict";
  var PREFIX = "ph_composer.spaces";

  function copy(value) { return JSON.parse(JSON.stringify(value)); }

  function startsWith(path, prefix) {
    return path.length >= prefix.length && prefix.every(function (id, index) { return path[index] === id; });
  }

  function SpaceActions(host) {
    var self = this;
    this.host = host;
    this.editPath = [];
    this.zones = [];
    // A change carries the revision its row was read at: the current one, or the one a confirmation opened at.
    this.edits = requests.channel(host.session, function (type, payload) {
      var revision = self.pinned !== undefined ? self.pinned : self.host.revision;
      send(type, Object.assign({}, payload, { expected_revision: revision }));
    }, "spaces-actions");
    this.context = requests.channel(host.session, function (type, payload) { send(type, payload); },
      "spaces-context", "view.invoke");
    function send(type, payload) { self.host.send(type, payload); }
  }

  /* What a snapshot says: the edit path, the Zones a Space may move to, and the outcomes this view awaits. */
  SpaceActions.prototype.consume = function (state, zones) {
    this.editPath = state.edit_path || [];
    this.zones = zones || [];
    var self = this;
    [this.edits, this.context].forEach(function (channel) {
      var outcome = channel.consume(state);
      if (!outcome) return;
      if (outcome.status !== "completed") {
        self.entering = null;
        self.closing = null;
        self.host.refuse(outcome.message || "The Spaces command was not applied. Nothing was written.");
      } else if (channel === self.context && self.closing) {
        // Close leaves the innermost context; a Space closes through any Volume of it that is open.
        var path = outcome.value && outcome.value.path || [];
        if (startsWith(path, self.closing)) self.context.run(PREFIX + ".context.close", {});
        else self.closing = null;
      } else if (channel === self.edits && self.entering) {
        // Unprotected: now the Volume may be opened.
        var volume = self.entering;
        self.entering = null;
        self.context.run(PREFIX + ".context.open", { reference: volume });
      }
    });
  };

  /* Whether a row is open in the edit context: a Space or Volume on the path the snapshot reports. */
  SpaceActions.prototype.open = function (row) {
    var target = row.record.volume || (row.record.segment ? null : row.record.space);
    return Boolean(target) && startsWith(this.editPath, target.reference.entity_path);
  };

  SpaceActions.prototype.busy = function () { return this.edits.busy() || this.context.busy(); };

  /* What names a row's record to the user even when it has no name: "Living", or "Space 101", or
     "Volume 1 of Living". */
  function describe(record) {
    var space = record.space;
    var spaceName = space ? space.values.name || "Space " + space.values.number : "";
    if (record.volume) {
      return (record.volume.values.display_name || "Volume " + record.volume.values.number) + " of " + spaceName;
    }
    if (record.segment) return record.segment.values.display_name || "Floor Segment of " + spaceName;
    return spaceName;
  }

  function repairs(record) {
    return (record.findings || []).map(function (finding) { return finding.repair; }).filter(Boolean);
  }

  /* A row's actions, Locate first, the destructive ones last. */
  SpaceActions.prototype.actions = function (row) {
    var record = row.record, target = record.segment || record.volume || record.space, items = [];
    if (!target) return items;
    var busy = this.busy(), name = record.volume || record.segment ? record.name || describe(record) :
      describe(record);
    items.push({ id: "spaces.locate", icon: "locate", label: "Locate " + name, disabled: busy });
    var fixes = repairs(target);
    if (record.volume && fixes.indexOf("restore_position") >= 0) {
      items.push({ id: "spaces.restore", icon: "repair", label: "Restore the position of " + name, disabled: busy });
    }
    if (fixes.indexOf("make_independent") >= 0) {
      items.push({ id: "spaces.independent", icon: "repair", label: "Make " + name + " independent", disabled: busy });
    }
    if (record.space && !record.volume && !record.segment) {
      var open = this.open(row);
      items.push(open ? { id: "spaces.close", icon: "close", label: "Close " + name, disabled: busy } :
        { id: "spaces.open", icon: "enter", label: "Open " + name, disabled: busy });
      if (this.zones.length > 1 || !record.space.zone && this.zones.length) {
        items.push({ id: "spaces.move", icon: "assign", label: "Move " + name + " to another Zone", disabled: busy });
      }
      items.push({ id: "spaces.delete", icon: "delete", label: "Delete " + name, disabled: busy });
    }
    if (record.volume && !record.segment) {
      if (!this.open(row)) items.push({ id: "spaces.enter", icon: "enter", label: "Enter " + name, disabled: busy });
      items.push({ id: "spaces.remove_volume", icon: "delete", label: "Remove " + name, disabled: busy });
    }
    return items;
  };

  // The actions that change records or the edit context's protection; a held cell draft must not be lost to one.
  var CHANGES = { "spaces.enter": true, "spaces.restore": true, "spaces.independent": true, "spaces.delete": true,
    "spaces.remove_volume": true, "spaces.move": true };

  /* Runs one of this view's actions; false for an action it does not own. */
  SpaceActions.prototype.run = function (row, item) {
    var record = row.record, target = record.segment || record.volume || record.space;
    if (item.id.indexOf("spaces.") !== 0 || !target) return false;
    if (this.busy()) return true;
    var held = CHANGES[item.id] && this.host.draftReason();
    if (held) { this.host.refuse(held); return true; }
    var reference = copy(target.reference), self = this;
    switch (item.id) {
      case "spaces.locate": this.context.run(PREFIX + ".locate", { reference: reference }); break;
      case "spaces.open": this.context.run(PREFIX + ".context.open", { reference: reference }); break;
      case "spaces.close":
        this.closing = copy(reference.entity_path);
        this.context.run(PREFIX + ".context.close", {});
        break;
      case "spaces.enter":
        // A protected Volume is unlocked first; consume opens it once that completes.
        if (record.volume.protected) {
          this.entering = reference;
          this.edits.run(PREFIX + ".volumes.unprotect", { volume: reference });
        } else this.context.run(PREFIX + ".context.open", { reference: reference });
        break;
      case "spaces.restore": this.edits.run(PREFIX + ".volumes.restore_position", { volume: reference }); break;
      case "spaces.independent": this.edits.run(PREFIX + ".make_independent", { reference: reference }); break;
      case "spaces.delete":
        this.askFirst("Delete " + describe(record), "The Space, its Volumes and their Floor Segments are erased. " +
          "One Undo brings them back.", "Delete", function (revision) {
          self.runAt(revision, PREFIX + ".delete", { space: reference });
        });
        break;
      case "spaces.remove_volume":
        this.askFirst("Remove " + describe(record), "The Volume's records go and its Faces stay loose in the " +
          "Space. One Undo brings them back.", "Remove", function (revision) {
          self.runAt(revision, PREFIX + ".volumes.remove", { volume: reference });
        });
        break;
      case "spaces.move": this.pickZone(record, reference); break;
      default: return false;
    }
    return true;
  };

  /* Sends a change as of the revision a confirmation opened at, so one reviewed against older rows refuses. */
  SpaceActions.prototype.runAt = function (revision, name, params) {
    this.pinned = revision;
    try { this.edits.run(name, params); } finally { this.pinned = undefined; }
  };

  /* A confirmation in the shared dialog, naming exactly what goes; Cancel changes nothing. What it confirms
     is as of the revision it opened at. */
  SpaceActions.prototype.askFirst = function (title, consequence, commit, run) {
    var dialog = this.dialog || (this.dialog = ui.formDialog("", function () { dialog.closeModal(); }));
    if (!dialog.parentNode) document.body.appendChild(dialog);
    var cancel = ui.button("Cancel", function () { dialog.closeModal(); });
    var self = this, revision = this.host.revision;
    dialog.replaceChildren(ui.element("h2", "", title), ui.element("p", "", consequence),
      ui.actionRow(cancel, ui.button(commit, function () {
        dialog.closeModal();
        if (!self.host.disposed && !self.busy()) { run(revision); panel.repaint(); }
      })));
    dialog.openModal();
    cancel.focus();
  };

  /* Move to Zone: the Zones the Space may move to, chosen in the shared dialog. */
  SpaceActions.prototype.pickZone = function (record, reference) {
    var current = record.space.zone && JSON.stringify(record.space.zone.zone_path);
    var choices = this.zones.filter(function (zone) { return JSON.stringify(zone.zone_path) !== current; });
    var dialog = this.dialog || (this.dialog = ui.formDialog("", function () { dialog.closeModal(); }));
    if (!dialog.parentNode) document.body.appendChild(dialog);
    var select = ui.element("select");
    select.setAttribute("aria-label", "Zone to move " + describe(record) + " to");
    choices.forEach(function (zone, index) { select.appendChild(ui.option(String(index), zone.name || "Zone")); });
    var cancel = ui.button("Cancel", function () { dialog.closeModal(); }), self = this;
    var revision = this.host.revision;
    dialog.replaceChildren(ui.element("h2", "", "Move " + describe(record) + " to another Zone"),
      ui.element("p", "", "The Space moves where it stands, with its Volumes and Floor Segments; its number and " +
        "values are kept. Close any open Space or Volume first."), select,
      ui.actionRow(cancel, ui.button("Move", function () {
        var zone = choices[Number(select.value)];
        dialog.closeModal();
        if (!zone || self.host.disposed || self.busy()) return;
        self.runAt(revision, PREFIX + ".move_to_zone", { space: reference,
          zone: { zone_id: zone.zone_id, zone_path: copy(zone.zone_path) } });
        panel.repaint();
      })));
    dialog.openModal();
    select.focus();
  };

  SpaceActions.prototype.dispose = function () {
    this.edits.reset();
    this.context.reset();
    if (this.dialog) {
      this.dialog.closeModal();
      if (this.dialog.parentNode) this.dialog.parentNode.removeChild(this.dialog);
    }
  };

  return SpaceActions;
});
