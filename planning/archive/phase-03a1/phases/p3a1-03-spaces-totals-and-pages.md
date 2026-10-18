# P3a1-03: Correct totals and bounded Space reads

DATE: 2026-10-17
STATUS: Implemented on branch `feat/phase-03a1-p3a1-03`.
ISSUE: [#221](https://github.com/bldgtyp/ph-composer/issues/221)

## Entry and ownership

Workstream: W2. Order: V4. Depends on: P3a1-02 (the `context` read and view `side_effects` it adds, and the envelope schemas); the V2 client measurements that set the response budget.
Review findings: A06, A07. Acceptance: C03 in [ACCEPTANCE](../ACCEPTANCE.md).
Behavior: [PRD](../PRD.md). Proposed boundaries: [CONTRACTS](../CONTRACTS.md) section 2.
Decisions: [DECISIONS](../DECISIONS.md) D3a1-03, 10, 12. Delivery rules: [PLAN](../PLAN.md).

`spaces.list` has no production caller (consumer audit 2026-10-17: only `tests/spaces_reads_test.rb`
and the generated reference), so it is reshaped in place rather than kept beside a bounded twin.
`spaces.all` stays whole for the panel's snapshot section.

## Source and intended change surface

Existing files changed:

- [features/spaces/reads.rb](../../../../src/ph_composer/features/spaces/reads.rb): `totals` computed from every Space before `list` filters; `list` builds summary rows; three new scoped reads beside it, sharing `assemble`'s one scan and metric calculation
- [features/spaces/declarations/spaces.rb](../../../../src/ph_composer/features/spaces/declarations/spaces.rb): `list` params gain `fields`; its result loses embedded children, Zone collections and stray findings and gains counts; `volumes.list`, `floor_segments.list` and `findings.list` declared with their scoped params and paged results
- [features/spaces/scan/occurrences.rb](../../../../src/ph_composer/features/spaces/scan/occurrences.rb): unchanged unless a scoped read needs a container-only walk; measure before adding one
- [shell/pages.rb](../../../../src/ph_composer/shell/pages.rb): unchanged; every new read pages through it
- [shell/api.rb](../../../../src/ph_composer/shell/api.rb): `MINOR` bumped once for the reshape, with its line in the "API changes" table D3a1-10 adds to the generated reference
- [tests/spaces_reads_test.rb](../../../../tests/spaces_reads_test.rb): rewritten to the new shape; FX2 and FX3 fixtures from [tests/support/space_fixtures.rb](../../../../tests/support/space_fixtures.rb)

## The reshaped reads

| Read | Scope | Row | Params |
| --- | --- | --- | --- |
| `ph_composer.spaces.list` | The Model | A Space summary: occurrence reference, editable values, derived metrics, Zone and Building-Segment membership, Volume and Floor Segment counts, finding counts by code | `ids`, `fields`, `limit`, `cursor`; `totals` (model, per Zone, per Segment) computed before filtering and returned beside the page |
| `ph_composer.spaces.volumes.list` | One Space by reference | A Volume row as `all` returns it, without its segments | `space`, `fields`, `limit`, `cursor` |
| `ph_composer.spaces.floor_segments.list` | One Space or one Volume by reference | A Floor Segment row as `all` returns it, loops only when `fields` asks | `space` or `volume`, `fields`, `limit`, `cursor` |
| `ph_composer.spaces.findings.list` | The Model, or one Space | A finding row: code, reference, message | `space`, `codes`, `limit`, `cursor` |
| `ph_composer.spaces.all` | The Model | Unchanged, whole | Unchanged |

Pages: 100 default, 500 maximum, plus the 24 KB response budget (D3a1-12, lowered from 80 KB by the P3a1-06 receipt); a page that would exceed
the budget is cut at the last whole row that fits and says so in `next_cursor`, never inside a row.
Cursors bind session, read, scope, `fields`, filter and revision as every list does.

## Implementation steps

1. Compute whole-model, per-Zone and per-Segment totals from every Space before `ids` filtering;
   add FX2 regressions for `ids`, empty `ids`, `limit` and a cursor walk.
2. Reshape `list` rows to summaries with `fields` projection; a projected row actually omits what
   was not asked for.
3. Add the three scoped reads from the same scan and the same metric calculation; refuse a scope
   reference that does not resolve with the owner's `target.*` code.
4. Apply the page and byte budget through `Pages`; measure FX3 serialized sizes and native read
   cost and record them beside the D3a1-12 rows.
5. Bump `MINOR`, add the changelog line, regenerate the reference, rewrite `spaces_reads_test.rb`
   and the walkthrough calls that read `list`.
6. Keep `all` byte-identical for the panel; its snapshot section test proves it.

## Acceptance checks

- FX2 totals stay 34, 32 and 95.6 under `ids`, empty `ids`, `limit` and cursor; per-Zone and
  per-Segment totals have the same declared scope.
- FX3: `list` with `limit: 1` returns one summary under 24 KB with no embedded children or stray
  findings; 600 segments page through `floor_segments.list`; `fields` omits geometry and metadata.
- Cursors refuse or expire as declared for the wrong session, read, scope, projection or revision;
  long Unicode labels and large optional metadata respect the budget.
- `spaces.all` unchanged; derived values never writable.

## Native/client gate

Read-only FX3 timing and serialized size on the current host with the panel closed, through the
live V2 connection; dictionaries, camera, selection, edit path and Undo count unchanged.

## Cleanup and documentation

CL02: the generated reference and the walkthroughs read the reshaped `list`; nothing legacy remains
to label because nothing outside the test suite consumed it. Docs-pass items: [AGENT_INTERFACE](../../../../context/AGENT_INTERFACE.md)
"Focused reads" gains the Spaces reads; context [CONTRACTS](../../../../context/CONTRACTS.md) "Public
interface" gains the D3a1-10 minor-bump and changelog rule when 02 or this stage lands first.
Record affected context/docs, exact checks and evidence in [STATUS](../STATUS.md) through docs-pass.
Shipping source/tests cite durable context rather than this plan. Preserve unrelated dirty work.

## Done when

C03 passes offline and on the host, the measurements sit beside the D3a1-12 rows, the reference and
changelog are current, and the standard review passes.
Applicable full gates, review level, manifest handling and DCO/hook rules are in [PLAN](../PLAN.md).
A planning document or unexecuted check is not implementation evidence.

## Out of scope

Caching or index rewrites without measurements, persistence changes, candidate Faces (04) and any
change to `spaces.all`.
