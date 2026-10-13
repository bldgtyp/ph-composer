"use strict";
/* Action-result payloads as the host sends them, for tests that need a refusal or failure envelope. */
function result(requestId, session, outcome) {
  return { request_id: requestId, session: session, outcome: outcome };
}
function refused(requestId, session, message) {
  var outcome = { status: "refused", code: "validation.failed" };
  if (message !== undefined) outcome.message = message;
  return result(requestId, session, outcome);
}
function failed(requestId, session, message) {
  return result(requestId, session, { status: "failed", code: "operation.failed", message: message });
}
function completed(requestId, session) { return result(requestId, session, { status: "completed", value: {} }); }
module.exports = { refused: refused, failed: failed, completed: completed };
