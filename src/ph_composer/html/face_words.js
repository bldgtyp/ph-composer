/* The words any screen shows for honeybee's face types and boundary conditions. honeybee's own strings
 * are the contract; these are what a user reads (context/UBIQUITOUS_LANGUAGE.md, ui-polish "Words on
 * screen"). One place in the kit, so the faces table, the Classify palette and the Window schedule
 * cannot disagree, and a feature that shows a face type need not reach into Zones.
 */
PhComposerUI.define("face_words", [], function () {
  "use strict";

  var FACE_TYPES = { Wall: "Wall", RoofCeiling: "Roof or ceiling", Floor: "Floor",
    AirBoundary: "Air boundary" };
  var BOUNDARIES = { Outdoors: "Outdoors", Ground: "Ground", Adiabatic: "To neighbour",
    Surface: "Surface", AttachedZone: "Attached zone" };
  // Boundary conditions a chip cannot set on its own, and why. The Classify palette leaves them out
  // and says why once, in its help; a Face that already holds one shows it read only.
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
