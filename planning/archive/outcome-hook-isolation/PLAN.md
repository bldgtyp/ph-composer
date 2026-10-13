# Outcome presentation hook isolation plan

DATE: 2026-10-13
STATUS: Complete; merged to main 2026-10-13 in [PR #102](https://github.com/bldgtyp/ph-composer/pull/102), delivery group 1. Stage ledger in [STATUS.md](STATUS.md).
ISSUE: [#100](https://github.com/bldgtyp/ph-composer/issues/100)
BASELINE: `cfe01a6aad99a0e09d5ecf0de5659c606d7ba4f9`
FINDING: [JS-02](../../code-review/sections/05-javascript.md#js-02-an-optional-outcome-translator-can-strand-an-unrelated-requesting-view)
DEPENDS ON: nothing. Lands on its own.

## Verified at the baseline

| Where | What it does now | Consequence |
| --- | --- | --- |
| `html/panel.js`, `outcomeText(translate)` | Pushes the bare callback onto `translators` | No owner, no disposer, no argument check |
| `html/panel.js`, `outcomeWords(payload)` | Calls each translator directly and returns the first truthy value | A throw propagates; a non-string truthy value becomes the notice |
| `html/panel.js`, `reduceActionResult(previous, payload)` | Builds `changes = { actionResult: payload }` first, checks the session, then calls `outcomeWords` while building the notice | The correlated result is already in `changes` when the hook runs; the throw loses it because the reducer never returns |
| `html/panel.js`, `receive(envelope)` | `state = handler(state, payload); render();` | A throwing reducer leaves `state` as it was and skips `render`, so no section runs and `request.Channel#consume` never sees the result |
| `html/request.js`, `Channel.prototype.consume(state)` | Reads `state.ui.actionResult` and matches request id and session | Nothing to match; the owner's `busy()` stays true |
| `html/panel.js`, `renderSection(entry)` | Wraps each section's render in `try` and logs one failure | The isolation principle already exists for sections; the hook is the one unguarded contributor call |
| `html/features/zones/overview.js`, the one `panel.outcomeText` call | Checks `screen.session` and `screen.zoneCells.owns(result.request_id)` before answering | The only shipped translator; it already behaves as the contract below requires |
| `context/TECH_STACK.md`, "Panel" | One sentence documents `panel.outcomeText(translate)` | Needs the owner argument, the disposer and the failure rule after implementation |

The review probe in `../../code-review/evidence/javascript_probes.cjs` reproduces the stranded channel. No shipped
translator throws; this is a contributor failure boundary.

## Target design

Keep the one-argument form working. Add an optional owner for diagnostics, return a disposer, isolate
each call, and validate the return. ES2020, script style, as the rest of `panel.js`.

```js
/* A view may restate a refused or failed outcome of its own request in its users' words; the host's
   message and code stay the contract. Each translator answers text or null for a detached
   { request_id, session, outcome }. A translator that throws or answers something other than a
   string is skipped and logged under its owner; it never stops the result being recorded. */
var translators = [];
function outcomeText(translate, options) {
  var owner = options && options.owner;
  if (typeof translate !== "function") throw new Error("panel.outcomeText needs a function");
  if (owner !== undefined && (typeof owner !== "string" || !owner)) {
    throw new Error("panel.outcomeText owner must be a nonempty string");
  }
  var entry = { translate: translate, owner: owner || "anonymous" };
  translators.push(entry);
  return function dispose() {
    var index = translators.indexOf(entry);
    if (index >= 0) translators.splice(index, 1);
  };
}
function outcomeWords(payload) {
  var current = translators.slice();
  for (var index = 0; index < current.length; index += 1) {
    var text;
    try { text = current[index].translate(JSON.parse(JSON.stringify(payload))); }
    catch (error) { hookFailed(current[index], "threw", error); continue; }
    if (text === null || text === undefined || text === "") continue;
    if (typeof text !== "string") { hookFailed(current[index], "answered " + typeof text); continue; }
    return text;
  }
  return null;
}
function hookFailed(entry, what, error) {
  try { console.error("panel.outcomeText " + entry.owner + " " + what, error || ""); } catch (ignored) { /* no console */ }
}
```

Rules this encodes:

- Correlation is independent of wording. `reduceActionResult` already stores the result before the
  hook runs; with the hook unable to throw, the reducer always returns and `render` runs.
- Each translator gets its own detached copy of the payload, so one cannot edit what the next sees or
  what the state retains.
- Null, undefined and empty string decline. Any other non-string, a Promise included, is logged and
  skipped. First valid string wins; later translators are not called.
- Fallback stays `outcome.message`, then the existing generic sentence. Tone stays warning for
  refused and error for failed. Completed outcomes still never reach a translator.
- `translators.slice()` makes disposal during a call safe; a disposed entry is skipped from the next
  outcome on. A failing translator stays registered: transient failure does not silence its later
  valid answers.
- Disposal is idempotent and removes only its own entry.

The Zones registration becomes `panel.outcomeText(function (result) { ... }, { owner: "ph_composer.zones" })`.
Its body does not change.

Not done here: no catch around the whole reducer, no catch around `receive`, no async translators, no
priority routing, no change to the single `actionResult` slot, no new host message.

## Stages

### OH-01: isolate the hook and prove settlement

State: Scoped.

Files: `src/ph_composer/html/panel.js`; tests in `tests/panel_app_test.js`.

1. Replace `outcomeText` and `outcomeWords` with the design above. Keep them where they are in the
   file; `api.outcomeText` stays the published name.
2. Add tests to `tests/panel_app_test.js`, using its existing panel fixture, a real
   `request.channel(session, send, "probe")` and `panel.receive({ type: "action.result", ... })` with
   a refused outcome, one test per behaviour:
   - a throwing first translator and a second that answers text: `receive` returns, the state holds the
     result under its request id, the notice shows the second text, the channel consumes once and is idle;
   - every translator throws or declines, host message present: notice shows the host message as a
     warning;
   - host message absent: the existing generic sentence shows;
   - null, undefined, empty string, a number and a Promise as returns (one parameterised test): the
     declines fall through and the invalid returns are skipped without becoming the notice;
   - first valid text, later translator counts its calls: the later one is not called;
   - translator mutates its input: the retained `state.ui.actionResult` and the next translator's input
     are unchanged;
   - completed outcome: no translator called;
   - another session's result: no translator called, state unchanged;
   - disposer called twice, and one of three disposed: remaining order preserved, disposed one not
     called;
   - console `error` throws or `console` is absent in the test context: the result still settles;
   - registration with a non-function, and with an empty owner: throws at registration, nothing inserted.
3. Where `tests/support/` lacks a refused action-result fixture, add one small helper there rather
   than inlining the envelope in every test.
4. Run:

   ```sh
   node tools/js_test_guard.js node --test --test-timeout=60000 tests/panel_app_test.js tests/request_test.js
   pnpm exec eslint src/ph_composer/html/panel.js
   make runtime-manifest && make runtime-check
   ```

   The runtime manifest hashes every file under `html/`; refresh it in the same commit.

Exit: all listed tests pass; the baseline probe's stranded-channel assertion no longer holds.

### OH-02: name the Zones owner and record the contract

State: Scoped.

Files: `src/ph_composer/html/features/zones/overview.js`; `tests/overview_panel_test.js`;
`context/TECH_STACK.md` "Panel"; `context/EXTENSIBILITY.md` where UI-kit contribution is described.

1. Pass `{ owner: "ph_composer.zones" }` to the existing registration. No change to its body.
2. Extend `tests/overview_panel_test.js` with one test: a refused Zone write still shows the Zone
   screen's restated text, and a refusal for a request the screen does not own leaves the host
   message in place.
3. Update the `panel.outcomeText` sentence in `context/TECH_STACK.md` to name the owner option, the
   disposer, the string-or-null return and the isolation rule. Add the same contract in one paragraph
   where `context/EXTENSIBILITY.md` lists what a feature's panel module may register.
4. Run the OH-01 commands plus `make runtime-manifest`, then `make ci`.

Exit: tests pass; the canon describes the implemented hook and nothing more.

## Decisions

The coding agent decides: the diagnostic wording, the helper's name, and whether the detached copy
helper reuses an existing `copy` in `panel.js` (it must deep copy; `copy` there is shallow).

Nothing needs Ed. Changing the notice policy, async translators or the single result slot would.

## Verification profile

Standard: focused JavaScript tests, Chromium 88 lint through `eslint`, runtime manifest refresh, one
bounded review, `make ci`. No Ruby change, so no native transaction gate. The
[acceptance rows](ACCEPTANCE.md) map one to one onto the OH-01 and OH-02 tests.
