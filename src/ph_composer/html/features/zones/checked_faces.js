/* The Faces checked in the Zones / Faces table: the set a bulk assignment acts on.
 *
 * The set belongs to the panel. It can span Zones, and checking a row never changes SketchUp's selection,
 * because SketchUp's selection holds only entities in the open edit context, so a mirrored set could not
 * span Zones (context/SKETCHUP_HOST_BEHAVIOR.md). The sync runs one way: when SketchUp's selection changes,
 * the set is replaced by the Faces now selected there, and an empty selection clears it.
 *
 * A Face is keyed by its occurrence (its Zone's path and its own), not its record id: a Face gains a record
 * when it is first classified, which must not uncheck it.
 */
PhComposerUI.define("features/zones/checked_faces", [], function () {
  "use strict";

  function key(reference) {
    return JSON.stringify([reference.zone_path || [], reference.entity_path || []]);
  }

  /* The Faces a row stands for: a Face row its Face, a Zone row every Face under it, a summary row the
     unclassified Faces it heads. "Show all" stands for none. */
  function facesOf(row) {
    if (row.record.face) return [row.record.face];
    if (row.record.more) return [];
    return row.record.every || row.record.faces || [];
  }

  function CheckedFaces() {
    this.keys = Object.create(null);
    this.anchor = null;
    this.synced = undefined;
  }

  CheckedFaces.prototype.has = function (face) { return Boolean(this.keys[key(face.reference)]); };

  /* true, false or "mixed" for a row with Faces under it; null for one with none, which has no box. */
  CheckedFaces.prototype.state = function (row) { return this.stateOf(facesOf(row)); };

  CheckedFaces.prototype.stateOf = function (faces) {
    if (!faces.length) return null;
    var count = faces.filter(this.has, this).length;
    return count === 0 ? false : count === faces.length ? true : "mixed";
  };

  CheckedFaces.prototype.set = function (faces, checked) {
    faces.forEach(function (face) {
      if (checked) this.keys[key(face.reference)] = true;
      else delete this.keys[key(face.reference)];
    }, this);
  };

  /* A click checks the row's Faces, or unchecks them when they all are. Shift-click applies the same to every
     row between the last box clicked and this one, in the order the table shows them. */
  CheckedFaces.prototype.toggle = function (row, event, shown) {
    var checked = this.state(row) !== true;
    var keys = shown.map(function (entry) { return entry.key; });
    var from = event && event.shiftKey && this.anchor ? keys.indexOf(this.anchor) : -1;
    var to = keys.indexOf(row.key);
    if (from >= 0 && to >= 0) {
      shown.slice(Math.min(from, to), Math.max(from, to) + 1).forEach(function (entry) {
        this.set(facesOf(entry), checked);
      }, this);
    } else this.set(facesOf(row), checked);
    this.anchor = row.key;
  };

  /* The header box checks every Face the table shows, or unchecks them when they all are. */
  CheckedFaces.prototype.toggleAll = function (faces) {
    this.set(faces, this.stateOf(faces) !== true);
    this.anchor = null;
  };

  CheckedFaces.prototype.replace = function (references) {
    this.keys = Object.create(null);
    references.forEach(function (reference) { this.keys[key(reference)] = true; }, this);
    this.anchor = null;
  };

  CheckedFaces.prototype.clear = function () { this.replace([]); };

  /* The checked Faces among `faces`, so a Face the Model no longer has is never counted or assigned. */
  CheckedFaces.prototype.among = function (faces) { return faces.filter(this.has, this); };

  /* Replaces the set when SketchUp's selection differs from the last one seen, whatever order the host lists
     it in. Answers whether it did. */
  CheckedFaces.prototype.sync = function (targets) {
    var references = targets.map(function (target) { return target.reference || {}; });
    var signature = references.map(key).sort().join("|");
    if (signature === this.synced) return false;
    this.synced = signature;
    this.replace(references);
    return true;
  };

  CheckedFaces.facesOf = facesOf;
  return CheckedFaces;
});
