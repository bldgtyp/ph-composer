/* The words this feature's screens show for the values it stores. honeybee's own strings are the
 * contract; these are what a user reads (context/UBIQUITOUS_LANGUAGE.md, ui-polish "Words on
 * screen"). One place, so the faces table and the Classify palette cannot disagree.
 */
PhComposerUI.define("features/zones/face_words", [], function () {
  "use strict";

  var FACE_TYPES = { Wall: "Wall", RoofCeiling: "Roof or ceiling", Floor: "Floor",
    AirBoundary: "Air boundary" };
  var BOUNDARIES = { Outdoors: "Outdoors", Ground: "Ground", Adiabatic: "To neighbour",
    Surface: "Surface", AttachedZone: "Attached zone" };
  // Boundary conditions a chip cannot set on its own, and why. Shown rather than hidden, because a
  // user who looks for Surface and does not find it learns nothing (ui-polish: say why on the
  // control before the click).
  var UNCHOOSABLE = { Surface: "set by Solve adjacencies", AttachedZone: "choose a record below" };

  function label(table, value) {
    if (value === null || value === undefined || value === "") return "";
    return Object.prototype.hasOwnProperty.call(table, value) ? table[value] : String(value);
  }

  return {
    FACE_TYPES: FACE_TYPES, BOUNDARIES: BOUNDARIES, UNCHOOSABLE: UNCHOOSABLE,
    faceType: function (value) { return label(FACE_TYPES, value); },
    boundary: function (value) { return label(BOUNDARIES, value); }
  };
});
