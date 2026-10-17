# W2: complete semantic Zones/Spaces access

DATE: 2026-10-17
STATUS: Scoped; planning only. No implementation authorized. Rewritten 2026-10-17 to accepted D3a1-03, 04, 10 and 13.
ISSUE: none (local planning draft)
FINDINGS: A06/A07/A08/A09, Spaces A10/A13
STAGES: P3a1-03 through P3a1-05

This workstream supplies the missing public steps in the Spaces journey and runs it through the
live read-only connection V2 delivered. It reshapes `spaces.list` in place, adds scoped child,
finding and candidate reads, types the edit shapes, and gives the foundation the two navigation
commands a client needs to start at the Model root.

## Stages

| Stage | Order | Deliverable | Acceptance |
| --- | --- | --- | --- |
| [03](../phases/p3a1-03-spaces-totals-and-pages.md) | V4 | Totals before filtering; `spaces.list` as summaries with `fields`; `volumes.list`, `floor_segments.list`, `findings.list`; `spaces.all` whole | C03 |
| [04](../phases/p3a1-04-space-candidates-and-edit-shapes.md) | V4 | `candidate_faces.list` scoped to a Space or Volume; typed `values` and `expected_values` | C04 |
| [05](../phases/p3a1-05-context-and-spaces-recipe.md) | V4 | `ph_composer.context.open` and `.root` as foundation view commands with declared lock side effects; the public-only recipe | C05 |

The stage files own implementation steps. Shared policy/data are in [CONTRACTS](../CONTRACTS.md),
product choices in [DECISIONS](../DECISIONS.md), evidence in [ACCEPTANCE](../ACCEPTANCE.md), and
progress only in [STATUS](../STATUS.md).

## Ownership and architecture

Spaces owns candidate geometry inside stamped Space and Volume containers; Zones does not resume
walking their children and gains no navigation. The foundation owns edit-context navigation
(`shell/context_commands.rb`, beside the location commands), calling `EditContext` so every
registered boundary runs; Spaces keeps `context.open` and `context.close` as conveniences. Under
D3a1-13 navigation stays `view`: it writes no authored data and creates no Undo entry of its own, and
each command declares the Volume lock it may trigger in `side_effects`. Under D3a1-10 shapes change
freely under major 1 with one `MINOR` bump and one changelog line per change; no legacy twin is kept.

## Dependencies and handoff

03 consumes 02's `context` read and envelope schemas and the response budget V2 measured. 04 builds
on 03's paging. 05 composes the reads and actions with the foundation navigation. 06 to 11 do not
wait for this workstream; 12's guide does. Thermal bridges (P3b-03) reuses the same navigation step.

## Acceptance and failure boundaries

A summary is small even for one Space with 600 children. Whole-model totals stay whole-model under
filters. Candidate reads find unmarked existing geometry without stamping it. The root-start recipe
creates and edits a Space, exits and moves it, with one Undo step per action and no private host
call after setup, and its C05 matrix records the lock, path, revision and Undo effect of each
navigation for a `view`-only caller. Drawing, copying and solid picking remain host-required steps.

## Verification and cleanup

03 uses focused numerical and paging tests plus a measured native read; 04 and 05 use high assurance
for native geometry and context lifecycle. CL02, CL03 and CL04 rewrite `spaces_reads_test.rb`, split
the walkthrough into fixture setup and public client, and repair the hostkit routing sentence.

## Out of scope

No generic CAD engine, automatic read-time repair, Space schema migration, Zones-owned navigation,
or replacement of the native Mark floor and Create Space tools.
