# Windows orchestration acceptance

DATE: 2026-10-13
STATUS: Planned checks; none run.
PLAN: [PLAN.md](PLAN.md)

| Case | Scenario | Required result | Evidence |
| --- | --- | --- | --- |
| W01 | Grid, thermal and outline rules from explicit records | Same derived values; no Model lookup | Pure Ruby, existing suites |
| W02 | Product and Type create, update, duplicate, delete, grid proposals | Record changes and declared references only; no step added; Model holds record dictionaries only | `window_records_operations_test.rb` |
| W03 | Frame create with an ordinary, a duplicated and a locked copied Unit | Existing refusal and repair policy; `identity_repaired` reported; no partial write | `window_authoring_test.rb`, walkthrough |
| W04 | Installs save or Library copy running several Windows operations | One `IdentityStep` per proposal; no duplicate step; correct final record | `window_authoring_test.rb`, `windows_walkthrough_test.rb` |
| W05 | Used Type resize with two anchored Units on two hosts | One `TypeChangeStep`, both hosts, anchors fixed | Offline and native |
| W06 | Oversize or overlapping proposed geometry | Whole edit refused; Types, Units and metadata unchanged | Offline and native |
| W07 | Name-only Type edit | No `TypeChangeStep`; `unit_count` still reported | Offline |
| W08 | Make Unique, Type edit, Reset to Type | Detached definition untouched until Reset | Native |
| W09 | Product or Type delete with retarget; compound failure after retarget | Complete final references or whole refusal | Offline round trip, native |
| W10 | Target changes after preview; apply fails after earlier work | Stale guard refuses, or the outer abort restores all; unknown reported truthfully | Fault tests, native |
| W11 | Undo, Redo, save and reopen, HBJSON read-back | Records, anchors, metadata and Aperture associations coherent | Native, synthetic export |
| W12 | Source boundary | `products/operations.rb` and `types/operations.rb` contain no `Units::`; a script runs a product create with the panel closed | Source check test, public walkthrough |

Record host and version, Model session, build and fixture hashes and the native observations.
Compatibility and support-floor acceptance stay separate.
