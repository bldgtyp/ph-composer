# Library contracts acceptance

DATE: 2026-10-13
STATUS: Planned cases; none run. LC-A01 to LC-A08 are LC-01; LC-A09 to LC-A13 and LC-A20 are LC-02; LC-A14 to LC-A19 are LC-03; the rest are LC-04.
ISSUE: none (local planning draft)
BASELINE: `cfe01a6aad99a0e09d5ecf0de5659c606d7ba4f9`

This matrix gates [PLAN.md](PLAN.md). F05 baseline evidence establishes sorting failure, not a
completed adopter workflow; RF-04 is optional reuse, not a proven data defect. Use synthetic values
and namespaced metadata only. Record SHA, selected Ruby, fixtures/build hashes, exact commands and
observations. Future tests cite accepted durable contracts rather than planning identifiers.

## Synthetic adopter fixture

Create one outside catalog kind whose required id and authored designation map to nonempty
display_label, with no wire or mapped `name`. Include optional/null authored label inputs, equal
labels with distinct ids, mixed case/whitespace labels, two libraries/providers, shared external
typed references and a local assignment target. Projection failures and bad registration use
separate fixtures. Provide a current installed payload and an unavailable opaque local namespace
on existing local records; arbitrary user_data strings intentionally resemble object ids.

For every refused mutation compare full records/metadata/provenance, actual incoming references,
assignments and native state at all affected targets, revision and Undo boundary. A preserved row
count is not proof that assignment references still resolve. Export fixture values are invented;
private provider paths/errors never appear in public diagnostics or artifacts.

## Declaration, identity and label admission

| Case | Stimulus | Required observation | Evidence owner |
| --- | --- | --- | --- |
| LC-A01 | Register name-free kind with explicit projection; built-ins project name | Both use same contract without neutral-service feature branch; no callback invocation/Model mutation at registration | Registry suites |
| LC-A02 | Wire id absent/optional/null/wrong type/empty schema allowance; projection missing/noncallable | Actionable registration diagnostic names adapter/property; whole batch unpublished | Library registration suites |
| LC-A03 | Valid file and outside-provider rows with same semantic input | Same normalized values, identity and display_label; caller/provider-supplied wrapper cannot override projection | File/provider/admission suites |
| LC-A04 | Optional/null designation can or cannot yield label through owner's declared mapping | Valid mapped output admitted; invalid/empty label row omitted with code/identity warning; no silent id or to_s fallback | Admission suites |
| LC-A05 | Projection returns nil/number/object/array/invalid encoding/whitespace, or raises | Controlled row invalidity; no leaked exception/path text or crash; unaffected admitted rows remain usable | Admission suites |
| LC-A06 | Snapshot id differs from record_id, duplicate identity, unsupported version/kind, over budget | Existing identity/budget/unavailable policy preserved; no partial duplicate library inventory | File/provider suites |
| LC-A07 | Mutable inputs and returned row; retained adapter schema builders changed after install | Published declarations stable under registration contract; row/batch detached; projection receives no mutable Model data | Registration/provider suites |
| LC-A08 | Reload, folder merge, same folded label with distinct case/id/library | Deterministic tie-break order; every unique id retained; candidate order stable | File/catalog suites |

## Resolution, copy and replacement

| Case | Stimulus | Required observation |
| --- | --- | --- |
| LC-A09 | Source identity unchanged while label renamed | Exact source identity governs first; no duplicate create solely from label change; semantic change still reviewed |
| LC-A10 | One equal label/equal mapped row; unequal semantic values; multiple equal labels; duplicate source | Reuse/review/ambiguous/create policy matches plan; label never substitutes for semantic equality or identity |
| LC-A10b | Equal display labels with distinct ids; create/keep/replace on built-in and permissive adopter | No implicit authored name/designation rename; owner uniqueness policy remains authoritative, explicit choice resolves ambiguity |
| LC-A11 | Name-free copy preview in Ruby and shared UI | Neutral label shown in rows/title/candidate selector and sorting/search; no undefined or raw name assumption; UI renders Ruby resolution |
| LC-A12 | Panel-closed public create/keep/replace/assign for outside kind | Same supported callbacks/proposal contract as built-ins; local id/source/read-back correct; no dictionary knowledge required |
| LC-A13 | Stale generation/provider removed, ambiguous selection, changed expected_values, owner callback refuses/raises | No Model write; sanitized actionable refusal; proposal poisoned even if caller rescues; prior staged work not committed |
| LC-A14 | Replace Material ordinary values versus library values with trusted source | Same normal validation/normalization/name uniqueness/changed-field result; only deliberate source provenance differs |
| LC-A15 | Ordinary Material API attempts source through values; malformed callback source | Editable allowlist remains closed; schema refusal; no private provenance bypass |
| LC-A16 | Material library replace beside user_data/current/unavailable extension_data and inbound references | Local identity, all metadata and existing Assembly/Segment references retained; source updates only when supplied |
| LC-A17 | Copy+assignment joins outer feature proposal after earlier staged record | Projected read sees staged values, owner-scoped writes enforced, one final write per record; one root transaction |
| LC-A18 | Assignment fails at last target or first callback; valid earlier copy/replacement | Whole copy/assignment refuses, no partial local record/reference write; existing target metadata/classification preserved |
| LC-A19 | Existing Material membrane/name/domain constraints through replacement | Owner command still decides validity; no second business pipeline, geometry/domain bypass or changed refusal policy |
| LC-A20 | New label property versus provider/source/fingerprint variations | Label wrapper absent from fingerprint/source snapshot; declared authored semantic label participates only if owner declares it |

## Serialization, unavailable data and native lifecycle

| Case | Stimulus | Required observation | Evidence owner |
| --- | --- | --- | --- |
| LC-A21 | Local -> reverse wire -> normalize/map -> semantic compare, both built-in and name-free kind | Declared values/fingerprint equal; wire id preserved; normalized label recomputed; invalid/lossy reverse mapping refuses | Library export suites |
| LC-A22 | Export then import/copy into fresh synthetic Model with typed shared-definition refs | Actual refs resolve to intended kinds/records, deliberate remapping verified; no identity-string/count shortcut | Integrated fixture |
| LC-A23 | Local namespaced user_data/unavailable envelope on library export | Model keeps exact data, file deliberately omits with declared omission; no arbitrary metadata/provenance/private path leakage | Export/privacy suites |
| LC-A24 | Unsupported/unavailable provider while local record remains | Local edit/read/save works independently; restoring provider reloads explicit generation; no forced synchronization | Coordinator/provider suites |
| LC-A25 | Future explicit duplicate route with maintained and unavailable copy rules | Literal metadata independent; typed internal refs remap, external refs stay shared; unsafe unavailable rule refuses all | Existing engine/copy suites |
| LC-A26 | Native copy/replace+assign Undo/Redo and intervening unrelated transaction | Exactly one action boundary restores/reapplies record/source and actual assignment references; later transaction unaffected | Native library gate |
| LC-A27 | Save/close/reopen fresh host after copy/replacement with provider absent | Local identity/value/reference/provenance/metadata intact; display label derives from local owner projection; no provider dependency | Native library gate |
| LC-A28 | Private path/error content in provider diagnostics, unexpected mapped/wire/label wrapper fields | Sanitized diagnostics and explicit wire allowlist; arbitrary text/opaque objects never admitted to artifact | Privacy/admission/export suites |

## Required gates

Run focused Ruby library/Material/record/reference suites and shared-library JavaScript cases while
editing. Use both Ruby 2.7-compatible and current selected runtimes for the public outside-kind
example; regenerate API/reference through its fixture owner. Refresh shipped panel manifest if
changed. Run `make lint-ruby` before a future commit, `make coverage` separately and one required
`make ci` after coherent integration. Supply coverage/complexity measurements and the adapter
walkthrough to one stronger independent architecture review; resolve material findings.

Native proof uses the established bridge plus native controls and synthetic fixture, with panel
closed scripting, copy/replace/assignment, all-or-none refusal, Undo/Redo and fresh save/reopen.
Capture exact host/model session, source/build hashes and native observations. It does not close
SketchUp 2023, Windows, public distribution or certification gates. Documentation-only planning
review needs link/source/contract consistency, not runtime gates; no future case is marked passed
in this planning request.
