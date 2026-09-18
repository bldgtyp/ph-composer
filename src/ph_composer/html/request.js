/* The one way a panel view sends a registered action and recognises its result.

   The panel keeps a single correlated result slot (`state.ui.actionResult`, set by panel.js only for the
   Model session it shows). A channel mints each request id (`<session>:<label>:<n>`, unique across the
   panel), sends `action.invoke`, and matches the slot against its own id and session. The request id is
   presentation only: the host gives the panel's mutations their own sequence numbers (CONTRACTS.md C4).

   A result is `{ request_id, session, outcome }`, where `outcome` is the public operation outcome
   (`status`, `code`, `message`, `effect`, `revision`, `value`, ...).

   Two shapes: `run` is single flight (refuses while a request is pending, and `consume` settles it once);
   `send` never refuses and returns the id, for callers that keep several requests in flight, which match
   with `matches(result, id)`. */
PhComposerUI.define("request", [], function () {
  "use strict";
  var sequence = 0;

  function Channel(session, send, label) {
    this.session = session; this.transport = send; this.label = label;
    this.pending = null; this.action = null; this.handlers = null;
  }
  Channel.prototype.send = function (action, params, label) {
    var id = this.session + ":" + (label || this.label) + ":" + (++sequence);
    this.transport("action.invoke", { request_id: id, session: this.session, name: action, params: params || {} });
    return id;
  };
  /* Sends unless a request is pending; returns the new id, or false when busy. `handlers.label` overrides the
     channel label; `onDone(outcome)` and `onFail(outcome)` run from consume. */
  Channel.prototype.run = function (action, params, handlers) {
    if (this.pending) return false;
    this.handlers = handlers || null; this.action = action;
    this.pending = this.send(action, params, handlers && handlers.label);
    return this.pending;
  };
  Channel.prototype.busy = function () { return Boolean(this.pending); };
  Channel.prototype.matches = function (result, id) {
    var expected = arguments.length > 1 ? id : this.pending;
    return Boolean(expected && result && result.request_id === expected && result.session === this.session);
  };
  /* The pending request's outcome, if this state carries its result: clears pending, runs the handler, and
     returns the outcome so the caller can use it for the rest of the render. Null otherwise. */
  Channel.prototype.consume = function (state) {
    var result = state && state.ui && state.ui.actionResult, handlers = this.handlers, outcome;
    if (!this.matches(result)) return null;
    outcome = result.outcome;
    this.reset();
    if (handlers && outcome.status === "completed" && handlers.onDone) handlers.onDone(outcome);
    if (handlers && outcome.status !== "completed" && handlers.onFail) handlers.onFail(outcome);
    return outcome;
  };
  /* Forgets the pending request: its result, if it still arrives, is ignored. */
  Channel.prototype.reset = function () { this.pending = null; this.action = null; this.handlers = null; };

  return { channel: function (session, send, label) { return new Channel(session, send, label); } };
});
