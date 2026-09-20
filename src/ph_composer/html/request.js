/* The one way a panel view sends a registered action and recognises its result.

   The panel keeps a single correlated result slot (`state.ui.actionResult`, set by panel.js only for the
   Model session it shows). A channel mints each request id (`<session>:<label>:<n>`, unique across the
   panel), sends `action.invoke`, and matches the slot against its own id and session. The request id is
   presentation only: the host gives the panel's mutations their own sequence numbers (CONTRACTS.md C4).

   A result is `{ request_id, session, outcome }`, where `outcome` is the public operation outcome
   (`status`, `code`, `message`, `effect`, `revision`, `value`, ...).

   A channel carries one host message. The default is `action.invoke`, whose result lands in
   `state.ui.actionResult`; `view.invoke` is the viewport-state channel (selection, camera, the active
   Colour-by mode), whose result lands in `state.ui.viewResult`. Both settle the same way.

   Two shapes: `run` is single flight (refuses while a request is pending, and `consume` settles it once);
   `send` never refuses and returns the id, for callers that keep several requests in flight, which match
   with `matches(result, id)`. */
PhComposerUI.define("request", [], function () {
  "use strict";
  var sequence = 0;
  var SLOTS = { "action.invoke": "actionResult", "view.invoke": "viewResult" };

  function Channel(session, send, label, message) {
    this.session = session; this.transport = send; this.label = label;
    this.message = message || "action.invoke";
    this.slot = SLOTS[this.message];
    if (!this.slot) throw new Error("request channel does not carry \"" + this.message + "\"");
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
    var result = state && state.ui && state.ui[this.slot], handlers = this.handlers, outcome;
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
