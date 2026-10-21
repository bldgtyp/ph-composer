# 03 Shell: dispatch, the panel and the native dialogs

Files: `src/ph_composer/shell/{api,dispatch,request_checks,handler_request,operation_context,panel,panel_messages,preferences,support_dialog,support_report,native_approval,commands,snapshot,context_commands,capture_command,record_queries,pages}.rb`,
`agent_access/dialog.rb`, `core/diagnostics.rb`.

## The public interface and dispatch

`API.connect` issues a 128-bit caller handle on the session's `CallerRegistry` with a frozen copy
of the requested capabilities. `OperationContext` carries the handle, the session id and the API
major; `Dispatch#resolve` looks the handle up in the session on every call, so a serialized or
edited context grants nothing, a revoked handle is refused with `access.revoked`, and a closed
session with `session.unknown`.

Every path checks, in order: context shape and API major, session, caller and revocation,
operation existence, capability, params as plain JSON (`JsonValue.problems`) and against the
operation's schema, busy state, declared precondition, then the handler, then the result against
its declared schema. A mutation additionally digests the request so a retry under the same sequence
with a different payload is `request.sequence_conflict`, and runs inside `session.exclusive` with
one native operation.

Handlers receive a frozen `HandlerRequest` whose params are a frozen deep copy. Nested reads go
through `request.query`, which re-validates params and results and refuses cycles and undeclared
dependencies, never through the public dispatcher.

## The panel transport

`Panel#build_dialog` registers one callback bound to the dialog instance; `receive` ignores a message
from a dialog that is no longer the current one. `PanelMessages.parse` accepts only the declared
types and, for each, only the declared keys; anything else is `Malformed` and answered with
`panel.failure`. Outbound messages are built by `PanelMessages.script`, which refuses undeclared
types and keys and serializes with `JSON.generate` into a fixed `PhComposerUI.get("panel").receive(...)`
call. `JSON.generate` does not escape U+2028/2029, which is fine in a JavaScript string literal on
the Chromium 88 floor.

The panel connects with `read view model_write setup export` and never `capture`. It acts only on
the session it shows; a payload naming another session is refused `session.inactive`.

`run_development_script` reads a file into `execute_script`. The only caller is
`add_development_script`, reached from `tools/examples`; the shipping build never calls it.

## Preferences

`Preferences.set` accepts four keys. Values are enumerated (`SI`/`IP`, the format lists) or must
match `Registry::ID_PATTERN` (dotted lowercase). Stored maps are strict base64 JSON under a 4 KiB
cap and 32 scopes; an unreadable map refuses a change rather than overwriting it. The only subprocess
in the shipping tree is `Open3.capture3("/usr/bin/defaults", "read", "-g", "AppleLocale")` with
fixed arguments and an absolute path; it is wrapped in `rescue StandardError`.

## Native approval

`NativeApproval::Granted` is the one carrier of a user-chosen path. Its `to_h` returns only
`replace`, and `inspect`/`to_s` the class name, so an accidental serialization or log line cannot
leak it. `admit` strips `location` from params before the handler sees them. `save_destination` asks
to replace on non-macOS platforms and trusts the macOS Save sheet's own question, which
`confirm_replace` documents.

## Help & Diagnostics

The support dialog's inbound messages are key-allowlisted. `support.save` writes through a
`.partial-<random>` file renamed into place, to a path from `UI.savepanel`. `open_url` opens three
fixed URLs (help page as `file://`, online help with the build's commit, the issue template) and the
log folder. `SupportReport` rebuilds every log line through `Diagnostics.sanitized`, which keeps only
allowlisted fields whose values match their regex and at most 20 extension-relative frames; the
header states what is omitted.

## Diagnostics

`Diagnostics.log` accepts only `ALLOWED_FIELDS`; named fields must match a regex (`event`,
`operation`, `code` and so on are dotted names; `session`, `request`, `run_id`, `incident` have
exact forms); any free-text field is passed through `redact`, which replaces anything matching the
absolute-path patterns (`/x`, two-segment paths after punctuation, drive letters, UNC, `~/`,
`file://`). Exceptions are recorded by class and by frames inside the extension folder only; a
frame's method name is kept only when it is a word in the extension's own source for that file. A
field a caller sends that is not allowed is dropped and recorded as `diagnostics_field_dropped`
with the key only when it looks like a name. The log rotates at 512 KiB and prunes at seven days.

The design holds: a Model name or a client's folder cannot reach the log through any logged field.
Two tests pin the redaction patterns.

## Context and capture commands

`ph_composer.context.read` answers the Model path (accepted by design), the edit path, the camera
and the selection in bounded pages. `ph_composer.view.capture` needs its own grant, writes
`cap_<random>.png` under `Dir.tmpdir/ph_composer/captures/<session id>/`, caps the image at
4096 px a side and 2 MiB, deletes a partial on failure or a view change, and prunes only `cap_*.png`
in that folder. The returned path is the agent's to read.

## Native menus

`Commands` builds menus from registered declarations; handlers run with the current session and a
`UserError` becomes a notice. Menu-driven setup commands (`LocationCommands`, `SetupCommands`) go
through `NativeApproval` with a `read setup` context, so they open a native picker and never take a
path from anywhere else.
