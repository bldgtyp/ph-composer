# Phase 4: mechanical

DATE: 2026-10-21
STATUS: Requested. Not planned in detail; packets re-baselined against `main` at `420c783a` on 2026-10-21.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Roadmap items 4.1 to 4.6 from [ROADMAP.md](../../ROADMAP.md). No coordinating packet yet: per
[planning/.instructions.md](../../.instructions.md) this directory gains `PLAN.md`, `CONTRACTS.md`,
`DECISIONS.md`, `ACCEPTANCE.md` and `phases/` when the phase is planned in detail, after the
interviews. The three PRDs were drafted on 2026-09-18, before Phase 0 merged, and were re-read
against the current code on 2026-10-21; each PRD opens with a table of what `main` supplies.

| Packet | Roadmap | State | Can start after |
| --- | --- | --- | --- |
| [equipment](equipment/README.md) | 4.1, 4.3, 4.5, 4.6 | Scoped: shared shape and Ventilators interviewed 2026-10-21, families 2 to 7 not | The hot water family interview. No Phase 3b dependency |
| [hot-water-piping](hot-water-piping/README.md) | 4.4 | Requested, PRD drafted, re-baselined | Equipment family 2 and Phase 3b's P3b-03, P3b-04, P3b-06, P3b-07, P3b-08 |
| [erv-ducting](erv-ducting/README.md) | 4.2 | Requested, PRD drafted, re-baselined | Equipment family 1 and the same Phase 3b stages, without P3b-04 |

## What the current app supplies

Phases 0 to 3a and 3a1 are merged and archived; Phase 3b (thermal bridges) is scoped and
interviewed, with no stage authorized. For this phase that means:

- The record engine, inventory tables, in-place drafts, subtabs nav, Colour-by with derived
  geometry and readouts, Zone views, the export contributors and the Room-attaching translation
  section all exist. Equipment ports nothing: it registers against them.
- The export snapshot carries Edge entries (G-02, PR #119). Everything else piping and ducting
  draw on for edges is a Phase 3b stage: edge records and assignment, the chain rule, the stroke
  weight, the edge tool, the edge contributor. Phase 3b's P3b-09 hands this phase the edge tagging
  rules in `context/` and two deferred items, the registry question (D3b-01) and moving the run
  builder to `core/`.
- The Systems primary tab D4 confirmed does not exist; the first Phase 4 screen adds it.
- The pinned honeybee-ph wheel (1.33.65) ships `honeybee_phhvac`, but the translation's stack
  seam does not list it; the first mechanical section adds it.
- PHX is not in the pinned runtime and METr export is deferred
  ([metr-export](../unscheduled/metr-export/README.md)). Every acceptance in this phase reloads
  the exact HBJSON in the pinned stack with a section `conformance` check; every METr row is a
  metr-export row. The roadmap's "METr needs no hand entry before its first run" is met through
  that packet, not here.

## Order

Equipment first, its shared shape settled on 2026-10-21 and its families interviewed one at a time, Ventilators and hot water before the rest so
the two drawn packets have something to export into. Piping before ducting, since ducting reuses
piping's draw and assign answers. Piping is not planned in detail before Phase 3b's P3b-04 has merged, since it reuses the
chain rule; ducting follows piping and needs P3b-03 and P3b-06 to P3b-08 only.
