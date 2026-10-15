/* A synthetic Zone view: the shape an outside feature copies to add a view to the Zones tab through the
   public contract alone (context/EXTENSIBILITY.md, "Zone views"). It shows each Zone's gross and unclassified
   Face area as columns on the Zone row, with no rows beneath, no Zone cells, no checks and no tools: every
   hook it leaves out takes the host's default.

   It never ships. Load it into a running host as the synthetic editor is loaded
   (`PhComposer::Panel.add_development_script("<repo>/tools/examples/zones/example_zone_view.js")`);
   tools/ui-preview/index.html loads it after the kit starts. It is plain script, not a module: it reaches
   the kit through PhComposerUI.get. */
(function () {
  "use strict";

  var units = PhComposerUI.get("units");
  var AREA = PhComposerUI.get("fields").AREA_M2;

  function area(value, profile) {
    return units.format(value, AREA, profile, { showUnit: false });
  }

  PhComposerUI.get("table_views").register("ph_composer.zones", {
    id: "example.zones.areas", label: "Areas", order: 90,
    // Listed whenever the Zones read is, so it needs no section of its own.
    sections: ["ph_composer.zones.overview"],
    zoneFields: [],
    columns: function (vs, profile) {
      return [["gross_m2", units.header("Gross area", AREA, profile)],
        ["unclassified_m2", units.header("Unclassified area", AREA, profile)]];
    },
    value: function (vs, row, field, profile) {
      var zone = row.record.zone;
      if (field === "gross_m2") return area(zone.face_area_m2, profile);
      if (field === "unclassified_m2") return area(zone.unclassified_face_area_m2, profile);
      return "";
    }
  });
  // Loaded after the panel has painted, so it repaints to list the new view; a module registers before.
  PhComposerUI.get("panel").repaint();
}());
