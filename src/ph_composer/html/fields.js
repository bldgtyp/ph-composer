/* Unit descriptors for stored fields: the quantity the units core formats and parses, and the unit the value
   is stored in. One frozen descriptor per stored unit; a screen adds its own label, dimension scope and blank
   or zero rules with `fields.with`. */
PhComposerUI.define("fields", [], function () {
  "use strict";
  function descriptor(quantity, unit) { return Object.freeze({ quantity: quantity, unit: unit }); }

  var LENGTH_M = descriptor("length", "m");
  var LENGTH_MM = descriptor("length_mm", "mm");
  /* A length stored in metres but shown and entered in millimetres (a narrow width in a metre record). */
  var WIDTH_M_AS_MM = descriptor("length_mm", "m");
  var AREA_M2 = descriptor("area", "m2");
  var VOLUME_M3 = descriptor("volume", "m3");
  var U_VALUE = descriptor("u_value", "w_m2k");
  var R_VALUE = descriptor("thermal_resistance", "m2k_w");
  var CONDUCTIVITY = descriptor("conductivity", "w_mk");
  var LINEAR_PSI = descriptor("linear_psi", "w_mk");
  var HEAT_LOSS = descriptor("heat_loss_rate", "w_k");
  var DENSITY = descriptor("density", "kg_m3");
  var SPECIFIC_HEAT = descriptor("specific_heat", "j_kgk");

  /* A copy of a descriptor with a screen's own settings (label, scope, allowBlank, allowZero). */
  function withSettings(base, settings) {
    return Object.assign({ quantity: base.quantity, unit: base.unit }, settings);
  }

  return { LENGTH_M: LENGTH_M, LENGTH_MM: LENGTH_MM, WIDTH_M_AS_MM: WIDTH_M_AS_MM, AREA_M2: AREA_M2,
    VOLUME_M3: VOLUME_M3, U_VALUE: U_VALUE, R_VALUE: R_VALUE, CONDUCTIVITY: CONDUCTIVITY, LINEAR_PSI: LINEAR_PSI,
    HEAT_LOSS: HEAT_LOSS, DENSITY: DENSITY, SPECIFIC_HEAT: SPECIFIC_HEAT, with: withSettings };
});
