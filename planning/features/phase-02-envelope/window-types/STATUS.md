# Window Types and placement: status

DATE: 2026-10-01
STATUS: Implementation in progress
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## State

Phase 2 implementation is authorized on `codex/phase-02-envelope`, issue #14. P2-10's product,
Window Type, grid, Installs and model-settings records are implemented in source and independently
reviewed. Focused tests pass on Ruby 2.7.2 and 3.2.2, 27 tests / 616 assertions. See
[record evidence](../evidence/p2-10-window-records.md). Installed `146076e` passes integrated gates,
seven public commits with exact native Undo/Redo and fresh-process inventory persistence.
Final structured E10 attestation remains open.

P2-11 screens are implemented in source. Focused checks and browser workflows at four widths pass;
independent review is closed; the native Builder workflow, exact Undo/Redo journals and fresh
persistence pass on installed `7afe894` plus targeted corrections on `74f7f05`. See
[Builder evidence](../evidence/p2-11-window-type-builder.md).

P2-12 and E12 are complete on the current host, including the actual native Move-copy observation,
cutting-component replay and Slice C operations. P2-13 Place, Schedule and Colour-by pass E13.
P2-14 Aperture export passes E14, including the canonical two-Zone reference, exact g-value
endpoints, all blocking rows, net-area read, pinned native comparison and clean native close/reopen.
P2-15 library adapters and native E15 pass. See [E12](../evidence/p2-12-window-unit.md),
[E13](../evidence/p2-13-place-tool.md), [E14](../evidence/p2-14-aperture-export.md) and
[E15](../evidence/p2-15-window-library-kinds.md).

## Next step

Consolidate E10/E11 observations and the remaining Phase 2 register through P2-17. The Window
implementation stages are delivered on branch. Held-Classify and the integrated final workflow
remain separate checks. Follow the owning [PLAN.md](PLAN.md) and stage entry gates.

## Blockers and remaining acceptance

The previous native Move-copy blocker is resolved by Ed's observed gesture and exact readback.
SketchUp 2023 and Windows gates remain separate from current-host evidence.

## Verification

See the linked source and host evidence. E12 to E15 pass; structured E10/E11 consolidation and
Phase 2 integration remain open.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Interview complete: 20 decisions. Notable: flat component per type, one face per glazed element, generated in code; no shading of any kind; install depth as an attribute, exported to METr's reveal depth; scaling refused by the definition; opaque doors as g-value 0; Frame segment renamed Frame; the whole type editor ports. |
| 2026-09-18 | Scoping review clarified that placement may precede face classification, but export blocks until the host face is a classified Outdoors face. |
| 2026-10-01 | D2-1 revised by Ed: definitions sit below Zones, and placed things above. See the [Phase 2 decisions](../DECISIONS.md). |
| 2026-09-30 | Phase 2 planning: PRD amended for what Phase 1 merged, PLAN.md added, the carried holed-Face blocker restated against B3. Packet moved under `features/phase-02-envelope/`. Nothing implemented. |
| 2026-09-18 | Architecture review run against `context/EXTENSIBILITY.md` and folded into the PRD, then removed. Q21: a unit id, and a copy gets its own at the feature's next mutation, a recorded exception to spaces Q20. Q22: Make unique is a detached-definition finding with Reset to type; Restore unit is a limited repair. Q23: g-value 0 is outside honeybee-schema's range and is disclosed. Q24: psi-install exports into the frame elements, no aperture install types, so PHX synthesizes no variant window types. Q25: seams restated against assemblies Q23 and spaces Q19 and Q22; no Zone stamp on the unit. Q26: the host Face exports gross, and the cut opening is measured in the spike. Also added: `user_data` on five records, a deterministic construction identifier, three validation rows, the Frame segment rename repaired. |

| 2026-10-01 | P2-10 source and independent review complete; integrated/native gates open. P2-12 host investigations started; native Move-copy remains a batched manual item. |
