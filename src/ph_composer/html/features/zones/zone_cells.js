/* A Zone's own fields, edited in place on its row of the Zones / Faces table: Name, Building-Segment, Level and
 * Ground depth. Face rows leave these columns blank.
 *
 * The shared inline record drafts do the editing (typing, Enter or leaving applies, Escape restores, a refusal
 * keeps the typed text until Escape). Each committed cell is one `ph_composer.zones.update` carrying that one
 * value and every value the row was painted from, so it is one operation and one Undo step, and a Zone that
 * changed underneath refuses rather than being overwritten.
 */
PhComposerUI.define("features/zones/zone_cells", ["record_edits", "fields", "units"],
function (RecordEdits, fields, units) {
  "use strict";
  var GROUND_DEPTH = fields.with(fields.LENGTH_MM, { label: "Ground depth", scope: "ph_composer.zones.ground_depth" });
  var COLUMNS = [["building_segment", "Building-Segment"], ["level", "Level"], ["ground_depth_mm", "Ground depth"]];
  var LABELS = { name: "name", building_segment: "Building-Segment", level: "Level", ground_depth_mm: "ground depth" };

  function copy(values) { return JSON.parse(JSON.stringify(values || {})); }

  function ZoneCells(session, send, notice) {
    this.edits = new RecordEdits(session, send, notice, {
      action: "ph_composer.zones.update", fields: ["name", "building_segment", "level", "ground_depth_mm"],
      recordLabel: "Zone", requiredFields: ["name"], navigateOnCommit: false,
      quantities: { ground_depth_mm: GROUND_DEPTH },
      eligible: function (row, field) { return Boolean(row.record.zone) && this.fields.indexOf(field) >= 0; },
      rawValue: function (row, field) { return row.record.zone.values[field]; },
      // A Level left empty is a Zone with no Level, which the Model stores as null.
      normalize: function (field, text) { return field === "level" && text === "" ? null : undefined; },
      label: function (row, field) { return row.record.name + " " + LABELS[field]; },
      send: function (cell) {
        var zone = cell.row.record.zone, values = {};
        values[cell.field] = cell.submitted;
        return { action: "ph_composer.zones.update",
          params: { reference: copy(zone.reference), values: values, expected_values: copy(zone.values) } };
      }
    });
  }

  /* The Zone columns the table shows after Name, with Ground depth's header carrying its display unit. */
  ZoneCells.columns = function (profile) {
    return COLUMNS.map(function (column) {
      return column[0] === "ground_depth_mm" ? [column[0], units.header(column[1], GROUND_DEPTH, profile)] : column;
    });
  };
  ZoneCells.GROUND_DEPTH = GROUND_DEPTH;
  ZoneCells.prototype.refresh = function (zoneRows, state) { this.edits.refresh(zoneRows, state); };
  /* Paints the cell's editor and answers true when it is a Zone field on a Zone row. */
  ZoneCells.prototype.render = function (td, row, field) { return this.edits.render(td, row, field); };
  ZoneCells.prototype.busy = function () { return Boolean(this.edits.pending || this.edits.queue.length); };
  ZoneCells.prototype.dispose = function () { this.edits.dispose(); };
  return ZoneCells;
});
