# Contributor example keyboard and lifecycle acceptance

DATE: 2026-10-13
STATUS: Planned cases; none run. CE01 to CE07 are CE-01, CE08 to CE13 are CE-02, CE14 and CE15 are CE-03.
PLAN: [Contract and stages](PLAN.md)

Use the synthetic foundation feature and actual public kit. Full key-event propagation must
exercise ancestor capture and the UnitField target behavior. Directly calling the form submit
listener proves only that submit works and is insufficient for CE01/CE02; use `dom.dispatch` from
`tests/support/dom_stub.js`.

| ID | Case | Required observation | Gate |
| --- | --- | --- | --- |
| CE01 | New part, valid label, Length `3 ft`, Enter at Length | One create sends `length_mm: 914.4`; one new part exists after success; dialog closes; no double field/form send | DOM event test and native controls |
| CE02 | Same draft through Create, Enter at label, Enter at Length | Each route reaches the same validation/send path and produces equivalent payload; each independent action sends once | DOM event tests |
| CE03 | Invalid/blank/zero/disallowed Length or empty trimmed label | No create; draft/message visible; user can correct or Cancel; no implicit submit after parse failure | Parameterized event/form test |
| CE04 | Display-unit switch during typed draft, explicit suffix and regional number | Draft keeps starting profile; admitted stored number matches existing unit rules; no rounded display feedback into storage | Existing unit/example cases extended |
| CE05 | Pending create, repeated Enter/Create and attempted Cancel | One request in flight; no duplicate create; pending controls follow existing contract | Deferred-result event test |
| CE06 | Refused/failed create, correction, retry or Cancel | Original result settles once; message remains; retry/Cancel recover; no false completed close | Panel/example test |
| CE07 | Escape in edited Length, then Escape idle; blur/repaint | First Escape restores field, second closes idle dialog; blur/repaint never creates; Cancel writes nothing and returns focus appropriately | DOM and scoped native observation |
| CE08 | Switch Models while form closed, open, invalid or pending | Old form permanently retired before new one is used; old request handlers reset; new session owns new form/fields | Parameterized session fixture |
| CE09 | Hold old Length input; switch session; change unit preferences | Old disconnected input is not repainted by preferences; active input updates normally | Instrumented old-input preference test |
| CE10 | Retain old show/submit/run and Enter/submit/blur/header callbacks | Every route sends zero requests and opens no old/new-session form through the stale callback; host refusal is not substituted for client retirement | Retained-reference event tests |
| CE11 | Dispose twice and later old outcome arrives | No exception/re-subscription/reactivation; active channel and fields unchanged; old completion callback does not run | Lifecycle/channel test |
| CE12 | Repeat several Model switches and then create in active Model | No accumulated live old form field subscribers; active Enter/create works once in active session | Repeated-switch fixture and same-process native check |
| CE13 | Same live form withdrawn then intentionally reopened | Withdrawal stays reusable; valid current form still accepts normal submit; disposal is separately permanent | Example form test |
| CE14 | Row edit/removal and ordinary snapshot repaint | Existing row draft, starting unit and guarded blur behavior still pass; example form fix does not change inline cell semantics | Existing example/unit/request suites |
| CE15 | Contributor README procedure and package inventory | Walkthrough uses public kit entrypoints only and names Enter/disposal ownership; no example path enters RBZ | Focused docs review and normal packaging check |

Finish implementation with focused event/unit/request/example tests, relevant coverage and
available metrics, one bounded coherent review, Chromium 88 syntax/API lint and final `make ci`.
Use existing generators only for assets actually changed. Native observation is scoped to valid
and invalid Length Enter, Cancel/focus and same-process Model switching with synthetic fixtures.
Record host/build/fixture identity, real control route, public read-back and expected create count.
Current-host success does not close the pending support-floor or public distribution gates.

No source tests, browser, native acceptance, build, package or manifest run is part of this
planning-only delivery. Historical Phase 0 evidence remains historical evidence.
