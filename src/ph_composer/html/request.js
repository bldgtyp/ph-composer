/* The one way a panel view sends a registered action and recognises its result.

   The panel keeps a single correlated result slot (`state.ui.actionResult`, set by panel.js only for the
   Model session it shows). A channel mints each request id (`<session>:<label>:<n>`, unique across the
   panel), sends `action.invoke`, and matches the slot against its own id and session. The request id is
   presentation only: the host gives the panel's mutations their own sequence numbers
   (context/CONTRACTS.md, "Retries").

   A result is `{ request_id, session, outcome }`, where `outcome` is the public operation outcome
   (`status`, `code`, `message`, `effect`, `revision`, `value`, ...).

   A channel carries one host message. The default is `action.invoke`, whose result lands in the single
   `state.ui.actionResult` slot; `view.invoke` is the viewport-state channel (selection, camera, the
   active Colour-by mode), whose results land in `state.ui.viewResults` keyed by request id. Several
   views send viewport commands independently, so one slot would let the second answer strand the first
   in a pending state it could never settle out of. Read-only `query.invoke` results use the same keyed
   correlation in `state.ui.queryResults` and never republish a snapshot or open a Model operation.
   `setup.invoke` carries session- and machine-state commands, such as adding a library on this machine,
   keyed in `state.ui.setupResults` for the same reason as viewport commands.

   Two shapes: `run` is single flight (refuses while a request is pending, and `consume` settles it once);
   `send` never refuses and returns the id, for callers that keep several requests in flight, which match
   with `matches(result, id)`. */
PhComposerUI.define("request", [], function () {
  "use strict";
  var sequence = 0;
  var SLOTS = { "action.invoke": { slot: "actionResult", keyed: false },
    "view.invoke": { slot: "viewResults", keyed: true }, "query.invoke": { slot: "queryResults", keyed: true },
    "setup.invoke": { slot: "setupResults", keyed: true },
    "file_export.invoke": { slot: "fileExportResults", keyed: true } };

  function Channel(session, send, label, message) {
    this.session = session; this.transport = send; this.label = label;
    this.message = message || "action.invoke";
    var carried = SLOTS[this.message];
    if (!carried) throw new Error("request channel does not carry \"" + this.message + "\"");
    this.slot = carried.slot; this.keyed = carried.keyed;
    this.pending = null; this.action = null; this.handlers = null;
  }
  Channel.prototype.nextId = function (label) {
    return this.session + ":" + (label || this.label) + ":" + (++sequence);
  };
  Channel.prototype.dispatch = function (id, action, params) {
    this.transport(this.message, { request_id: id, session: this.session, name: action, params: params || {} });
    return id;
  };
  Channel.prototype.send = function (action, params, label) {
    return this.dispatch(this.nextId(label), action, params);
  };
  /* Sends unless a request is pending; returns the new id, or false when busy. `handlers.label` overrides the
     channel label; `onDone(outcome)` and `onFail(outcome)` run from consume. The request is pending before it
     leaves, so a host that answers at once is still recognised. */
  Channel.prototype.run = function (action, params, handlers) {
    if (this.pending) return false;
    this.handlers = handlers || null; this.action = action;
    this.pending = this.nextId(handlers && handlers.label);
    return this.dispatch(this.pending, action, params);
  };
  Channel.prototype.busy = function () { return Boolean(this.pending); };
  Channel.prototype.matches = function (result, id) {
    var expected = arguments.length > 1 ? id : this.pending;
    return Boolean(expected && result && result.request_id === expected && result.session === this.session);
  };
  /* The pending request's outcome, if this state carries its result: clears pending, runs the handler, and
     returns the outcome so the caller can use it for the rest of the render. Null otherwise. */
  Channel.prototype.consume = function (state) {
    var held = state && state.ui && state.ui[this.slot];
    var result = this.keyed ? (held && this.pending && held[this.pending]) : held;
    var handlers = this.handlers, outcome;
    if (!this.matches(result)) return null;
    outcome = result.outcome;
    this.reset();
    if (handlers && outcome.status === "completed" && handlers.onDone) handlers.onDone(outcome);
    if (handlers && outcome.status !== "completed" && handlers.onFail) handlers.onFail(outcome);
    return outcome;
  };
  /* Forgets the pending request: its result, if it still arrives, is ignored. */
  Channel.prototype.reset = function () { this.pending = null; this.action = null; this.handlers = null; };

  return {
    channel: function (session, send, label, message) { return new Channel(session, send, label, message); }
  };
});
