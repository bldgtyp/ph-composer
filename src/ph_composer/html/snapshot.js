/* Reads the panel state a render receives: the host's snapshot plus panel.js's `ui` slot. One place knows
   the snapshot's shape, that a section may be absent, and that each section is the outcome of its
   registered query (a refused or failed section carries its message instead of a value).

   Snapshot: { product, version, session, revision, file_name, edit_path, preferences,
               sections: { name: outcome } } */
PhComposerUI.define("snapshot", ["units"], function (units) {
  "use strict";

  /* A section's outcome as the host sent it, or null when the snapshot has none. */
  function section(state, name) { return (((state || {}).sections || {})[name]) || null; }
  /* A section's value when its query completed, or null. */
  function value(state, name) {
    var outcome = section(state, name);
    return outcome && outcome.status === "completed" ? outcome.value : null;
  }
  /* The one correlated action result panel.js keeps for the shown Model session. */
  function actionResult(state) { return ((state || {}).ui || {}).actionResult; }

  /* The host may send a user-facing line twice: prose, and the same text as parts whose numbers the panel
     formats in the display units. The parts win; the prose is the fallback. */
  function message(item, fallback) { return units.formatParts(item.message_parts, item.message || fallback); }

  return { section: section, value: value, actionResult: actionResult, message: message };
});
