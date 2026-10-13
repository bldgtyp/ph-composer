# Contributor example keyboard and lifecycle plan

DATE: 2026-10-13
STATUS: Complete; merged to main 2026-10-13 in [PR #102](https://github.com/bldgtyp/ph-composer/pull/102), delivery group 1. Stage ledger in [STATUS.md](STATUS.md).
ISSUE: [#101](https://github.com/bldgtyp/ph-composer/issues/101)
BASELINE: `cfe01a6aad99a0e09d5ecf0de5659c606d7ba4f9`
FINDINGS: [JS-03](../../code-review/sections/05-javascript.md#js-03-the-contributor-examples-length-enter-never-creates-the-part), [JS-04](../../code-review/sections/05-javascript.md#js-04-the-contributor-example-retires-its-form-without-disposing-its-field-or-callbacks)
DEPENDS ON: nothing. Lands on its own. The example is development only and never enters the RBZ.

## Verified at the baseline

| Where | What it does now | Consequence |
| --- | --- | --- |
| `tools/examples/foundation/editor.js`, `NewPartForm` | Builds a `UnitField` for Length inside the form; the comment says Enter and Create share one submit | No listener routes Enter to `submit`; the comment is false |
| `html/unit_field.js`, the input `keydown` listener | `event.preventDefault(); self.commit()` on Enter | The field commits its own draft and swallows the key; the form never submits |
| `tests/example_editor_test.js`, "New part saves a suffixed length" | Calls `form.listeners.submit(...)` directly | Proves submit works, not that Enter reaches it |
| `tests/example_editor_test.js`, `press(label, key)` | Fires `input.listeners.keydown(...)`, the node-only fan-out | Cannot exercise an ancestor capture listener |
| `tests/support/dom_stub.js`, `dispatch(target, event)` | Walks capture listeners top down, then bubbles; honours `stopPropagation` | The test route the fix needs already exists |
| `tools/examples/foundation/editor.js`, `resetFor` | Disposes row fields, calls `view.form.withdraw()`, then builds a new form | The old form's Length field keeps its `preferences.subscribe`; its submit listener and `run` route stay callable with the old session |
| `html/record_form.js`, `withdraw(message)` | Resets the channel, closes the surface, re-enables Cancel | Reusable by design; it does not dispose children or retire the form |
| `html/features/assemblies/editor.js`, dimension field wiring | Capture `keydown` on `entry.field.root` checks `event.target === entry.field.input`, prevents default and stops propagation, then commits through the owner | The established pattern, with the Chromium 88 note on why capture sits on an ancestor |
| `shell/panel.rb`, the active-session check | Refuses an action for an inactive session | The host already blocks the cross-Model write; the client should never send it |

## Target design

Example-local repair with the public kit only. No change to `record_form.js` or `unit_field.js`.

```js
var NewPartForm = RecordForm.extend(function (session, send, changed) {
  RecordForm.call(this, session, send, { /* unchanged spec */ });
  var self = this;
  /* ...label and Length rows as today... */
  // UnitField owns the Length draft and swallows Enter on the input. The form owns submit, so it
  // takes Enter while the event travels down to the input, as the Assembly builder does.
  this.onKeydown = function (event) {
    if (event.key !== "Enter" || event.target !== self.length.input) return;
    event.preventDefault();
    event.stopPropagation();
    self.submit();
  };
  this.form.addEventListener("keydown", this.onKeydown, true);
  this.retired = false;
  this.finish();
});
NewPartForm.prototype.submit = function () {
  if (this.retired || this.busy() || !this.root.isConnected) return;
  var parsed = this.length.commit();
  if (!parsed.ok) return;
  if (!this.label.value.trim()) { this.error.textContent = "Enter a label."; return; }
  this.run({ definition_label: "Example", parts: [{ label: this.label.value.trim(), length_mm: parsed.value }] });
};
NewPartForm.prototype.show = function () {
  if (this.retired) return;
  RecordForm.prototype.show.call(this);
};
/* Permanent: the Model this form belonged to is no longer shown. Withdraw forgets the request and
   closes; disposal also ends the Length field's preference subscription and the Enter route. */
NewPartForm.prototype.dispose = function () {
  if (this.retired) return;
  this.retired = true;
  this.withdraw();
  this.form.removeEventListener("keydown", this.onKeydown, true);
  this.length.dispose();
};
```

In `resetFor`, replace `if (view.form) view.form.withdraw();` with `if (view.form) view.form.dispose();`
and retire the old form before `view.session` is reassigned. Build the "New part" button in
`paintHeader` with a captured form, `var form = view.form;` then `form.show()`, so a retained old
header cannot open a later Model's form.

What stays as it is: suffix parsing and SI storage in `UnitField`, the invalid draft and its
message, single flight through `RecordForm.run`, Cancel, the two-layer Escape (field draft first,
then dialog), `commitOnBlur` on row fields only, and the host's session guard.

## Stages

### CE-01: Enter reaches the one submit path

State: Scoped.

Files: `tools/examples/foundation/editor.js`; `tests/example_editor_test.js`.

1. Add `onKeydown`, the capture registration and the availability guard in `submit` as above.
2. In `tests/example_editor_test.js`, add a `dispatch(label, event)` helper beside `press` that calls
   `dom.dispatch(input(label), { type: "keydown", key: key, ... })` so the event travels the real
   capture and bubble path. Check that the stub's event object supports `preventDefault` and
   `stopPropagation`; `dom_stub.js` documents both. Leave `press` for the row-field tests it serves.
3. Tests, one each:
   - Length `3 ft`, Enter at Length: one `create_parts` invoke with `length_mm: 914.4`, the form closes
     on the completed result, one new part row appears;
   - Create button, Enter at Length and Enter at Label produce equal params and one invoke each;
   - blank label, zero, negative and unparsable Length: no invoke, the message stays, Cancel still
     closes;
   - Enter while a create is pending: no second invoke; the pending result settles once.
4. Fix the stale comment above `NewPartForm`.
5. Run `node tools/js_test_guard.js node --test --test-timeout=60000 tests/example_editor_test.js tests/unit_field_test.js`
   and `pnpm exec eslint tools/examples/foundation/editor.js tests/example_editor_test.js`.

Exit: the four tests pass; the existing example tests still pass unchanged.

### CE-02: retire the old form on a Model switch

State: Scoped.

Files: `tools/examples/foundation/editor.js`; `tests/example_editor_test.js`.

1. Add `retired`, `show` guard and `dispose` as above; call `dispose` in `resetFor`; capture the form
   in the header button.
2. Tests, using the existing `e.host.session = "preview-session-b"` route plus a snapshot publish:
   - hold the old Length input, switch sessions, change the unit system: the old input is not repainted,
     the new one is;
   - hold the old form's `submit`, `run`, `show` and `onKeydown`, switch sessions, call each: zero
     invokes, no dialog opens;
   - switch while the old form is open and pending, then let the old result arrive: no exception, no
     settlement on the new form, the new form creates once;
   - `dispose` twice: no error, no second unsubscribe;
   - `withdraw` on the live form then `show` again: still usable (withdraw stays reusable).
3. Confirm `dom_stub.js` `removeEventListener` honours the capture flag used at registration; if it
   does not, extend the stub in `tests/support/dom_stub.js` and add a stub test beside the existing
   `tests/dom_stub_test.js` cases. Record it as a stub deviation if the behaviour differs from the host.

Exit: the five tests pass; `tests/dom_stub_test.js` passes.

### CE-03: document the pattern

State: Scoped.

Files: `tools/examples/foundation/README.md`; `docs/DEVELOPMENT.md` and `context/EXTENSIBILITY.md`
only where they point at the example.

1. In the README, add one short section: field commit versus form submit, who owns Enter, `withdraw`
   versus `dispose`, and that a form disposes the children it built. Point at the Assembly builder as
   the shipping precedent.
2. Where `docs/DEVELOPMENT.md` or `context/EXTENSIBILITY.md` says the example demonstrates the kit,
   make sure the sentence does not promise more than CE-01 and CE-02 built.
3. `make ci`. The example is outside `html/`, so no runtime manifest refresh; `make rbz-check`
   confirms it stays out of the package.

Exit: `make ci` passes; a reader of the README can trace Enter, invalid input, Cancel, pending and
retirement without opening the kit source.

## Decisions

The coding agent decides method names, the test helper's name, and whether to store `onKeydown` on
the instance or in a closure (it must be removable at disposal).

Escalate to Ed only if the kit must change: for example if `RecordForm` cannot express the
retirement without a base-class hook. Nothing found so far requires that.

Not in scope: a generic kit disposal API, making every `UnitField` Enter submit its form, retaining
drafts across Models, any shipping form.

## Verification profile

Standard: focused tests through real event dispatch, `eslint`, `make ci`, one bounded review. A
native observation of Enter in the real HtmlDialog and a same-process Model switch is useful if a
panel run is already scheduled; it is not a gate this packet adds. See [ACCEPTANCE.md](ACCEPTANCE.md).
