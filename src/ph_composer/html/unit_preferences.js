/* User-wide display preferences: the unit system, each registered dimension scope's remembered format per
   system, and the computer's regional number format. The numerical unit core remains stateless.

   A dimension scope is one editor's remembered length format (a graphical builder remembers mm in SI and
   feet and inches in IP separately). A screen names its scope, a dotted name under its feature's id; the
   snapshot carries every scope a format has been chosen for, and any other scope takes the system
   default. This store holds no scope vocabulary of its own. */
PhComposerUI.define("unit_preferences", ["units"], function (units) {
  "use strict";

  var SYSTEMS = ["SI", "IP"];
  var listeners = [];
  var numberFormats = {};
  var profile = fromSnapshot({});

  /* Intl derivation is the costly part of a profile; locale and decimal rarely change, so cache per pair. */
  function numberFormat(locale, decimal) {
    var key = String(locale || "en-US") + "|" + String(decimal || ".");
    if (!numberFormats[key]) numberFormats[key] = units.deriveNumberFormat(locale || "en-US", decimal || ".");
    return numberFormats[key];
  }

  function cloneFormats(formats) {
    var result = {};
    Object.keys(formats).forEach(function (scope) {
      result[scope] = { SI: formats[scope].SI, IP: formats[scope].IP };
    });
    return result;
  }

  function clone(value) {
    return {
      unitSystem: value.unitSystem,
      dimensionFormats: cloneFormats(value.dimensionFormats),
      numberFormat: { decimal: value.numberFormat.decimal, group: value.numberFormat.group,
        groupSizes: value.numberFormat.groupSizes.slice() }
    };
  }

  function fromSnapshot(snapshot) {
    var formats = snapshot.dimension_formats || {};
    var number = snapshot.number_format || {};
    var next = { unitSystem: snapshot.unit_system === "IP" ? "IP" : "SI", dimensionFormats: {},
      numberFormat: numberFormat(number.locale, number.decimal) };
    Object.keys(formats).forEach(function (scope) {
      next.dimensionFormats[scope] = {};
      SYSTEMS.forEach(function (system) {
        var stored = formats[scope] && formats[scope][system];
        next.dimensionFormats[scope][system] = typeof stored === "string" ? stored : units.dimensionDefaults[system];
      });
    });
    return next;
  }

  function apply(next, key, value, extra) {
    if (key === "unit_system") next.unitSystem = value;
    if (key === "dimension_format" && extra && extra.scope) {
      if (!next.dimensionFormats[extra.scope]) {
        next.dimensionFormats[extra.scope] = { SI: units.dimensionDefaults.SI, IP: units.dimensionDefaults.IP };
      }
      next.dimensionFormats[extra.scope][extra.system] = value;
    }
  }

  /* Snapshots arrive on every Model change; subscribers repaint only when the unit profile moved. */
  function same(a, b) {
    return a.unitSystem === b.unitSystem && a.numberFormat.decimal === b.numberFormat.decimal &&
      a.numberFormat.group === b.numberFormat.group &&
      a.numberFormat.groupSizes.join(",") === b.numberFormat.groupSizes.join(",") &&
      JSON.stringify(a.dimensionFormats) === JSON.stringify(b.dimensionFormats);
  }

  function commit(next) {
    var value;
    if (same(profile, next)) return;
    profile = next;
    value = clone(profile);
    listeners.slice().forEach(function (listener) { listener(value); });
  }

  /* A message without a preferences section keeps the current profile rather than resetting to defaults.
     `pending` holds choices the host has not confirmed yet; they stay applied over the snapshot. */
  function replace(snapshot, pending) {
    var next = snapshot ? fromSnapshot(snapshot) : clone(profile);
    Object.keys(pending || {}).forEach(function (name) {
      var item = pending[name];
      apply(next, item.key, item.value, item.extra);
    });
    commit(next);
  }

  function set(key, value, extra) {
    var next = clone(profile);
    apply(next, key, value, extra);
    commit(next);
  }

  /* The remembered format for one scope and system, or the system's default for a scope the host never
     declared. */
  function dimensionFormat(scope, system) {
    var formats = profile.dimensionFormats[scope];
    return formats ? formats[system] : units.dimensionDefaults[system];
  }

  units.preferences = {
    current: function () { return clone(profile); },
    /* The live profile for formatting in render loops; callers must not mutate it. */
    peek: function () { return profile; },
    dimensionFormat: dimensionFormat,
    subscribe: function (listener) {
      listeners.push(listener);
      return function () { listeners = listeners.filter(function (candidate) { return candidate !== listener; }); };
    },
    replace: replace,
    set: set
  };
  return units.preferences;
});
