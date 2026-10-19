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
   with `matches(result, id)`.

   A `run` request still unanswered after RECOVERY_MS is unconfirmed: the channel stays pending, so the
   work is never sent twice, and every `onUnconfirmed` listener hears of it once; the panel keeps
   that request's way out on screen until it settles. For an action, `checkStatus` asks the host what
   became of that request id (`action.status`) and waits once more; the answer arrives as the request's
   own result. Any other channel can only stop waiting with `reset`. */
PhComposerUI.define("request", [], function () {
  "use strict";
  var sequence = 0;
  /* Longer than any interactive edit should take; the host answers in order, so a long operation delays
     this warning rather than the answer. A starting default, not a measured bound. */
  var RECOVERY_MS = 20000;
  var listeners = [];
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
    this.pending = null; this.action = null; this.handlers = null; this.timer = null; this.unconfirmed = false;
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
    var id = this.nextId(handlers && handlers.label);
    this.pending = id;
    this.dispatch(id, action, params);
    // A transport that answers at once has already settled it.
    if (this.pending === id) this.watch();
    return id;
  };
  /* Starts the recovery timer for the pending request; a page without timers never warns. */
  Channel.prototype.watch = function () {
    var self = this, id = this.pending;
    this.stopWatching();
    if (!window.setTimeout) return;
    this.timer = window.setTimeout(function () {
      self.timer = null;
      if (self.pending !== id) return;
      self.unconfirmed = true;
      listeners.slice().forEach(function (listener) { listener(self); });
    }, RECOVERY_MS);
  };
  Channel.prototype.stopWatching = function () {
    if (this.timer !== null && window.clearTimeout) window.clearTimeout(this.timer);
    this.timer = null;
  };
  /* Asks the host for the pending action's outcome without sending the action again, and waits once more.
     False when there is nothing to ask about or the channel carries no action. */
  Channel.prototype.checkStatus = function () {
    var id = this.pending;
    if (!id || this.message !== "action.invoke") return false;
    this.transport("action.status", { request_id: id, session: this.session });
    if (this.pending === id) this.watch();
    return true;
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
  Channel.prototype.reset = function () {
    this.stopWatching();
    this.pending = null; this.action = null; this.handlers = null; this.unconfirmed = false;
  };

  return {
    channel: function (session, send, label, message) { return new Channel(session, send, label, message); },
    RECOVERY_MS: RECOVERY_MS,
    /* `listener(channel)` hears of each unconfirmed request; the returned function removes it. */
    onUnconfirmed: function (listener) {
      listeners.push(listener);
      return function () {
        var index = listeners.indexOf(listener);
        if (index >= 0) listeners.splice(index, 1);
      };
    }
  };
});
