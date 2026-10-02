/* Library decisions stay in the detached Installs session. Save resolves the trusted catalog in Ruby. */
PhComposerUI.define("features/windows/library_stage", ["library/copy", "features/windows/editor_shared", "workspace"],
  function (Copy, shared, ui) {
    "use strict";
    function StagedCopy(session, send, adapter, changed, stage) {
      Copy.call(this, session, send, adapter, changed); this.stage = stage;
      this.root.insertBefore(ui.element("p", "muted", "This choice is staged until Save Installs."), this.explanation);
    }
    StagedCopy.prototype = Object.create(Copy.prototype); StagedCopy.prototype.constructor = StagedCopy;
    StagedCopy.prototype.run = function (row, choice, candidate) {
      if (this.disposed || this.enabled === false || this.busy()) return false;
      var library = row.library, copy = { provider_id: library.provider_id, kind: library.kind,
        generation: library.generation, library_id: library.library_id, record_id: library.record_id, choice: choice };
      if (candidate) copy.local_id = candidate.id;
      if (choice === "use_library") copy.expected_values = shared.clone(candidate.expected_values);
      var values = choice === "keep_local" ? candidate.expected_values : row.values;
      if (!this.stage(shared.clone(copy), shared.clone(values))) return false;
      this.held = null; this.root.closeModal(); this.error.textContent = ""; this.changed(); return true;
    };
    return StagedCopy;
  });
