# Readiness review

DATE: 2026-09-18
STATUS: Scoped. Product decisions resolved; implementation design supplied in CONTRACTS.md.
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft; origin exists, issue not created)

## Conclusion

The Phase 0 planning packet is ready for handoff after implementation authorization. Ed resolved
the product choices below; [CONTRACTS.md](CONTRACTS.md) supplies the interface design and lifecycle
matrix. P0-A checks that design against the frozen source before implementation. A wholesale copy
would miss D10 and D11 even if it loaded successfully.

Documentation review only. No source transplant, runtime test or host experiment was performed.

## Decision record and implementation ownership

| Item | Evidence and consequence | Recommended next step |
| --- | --- | --- |
| Source baseline | Confirmed by Ed on 2026-09-18: `f358ebf51532046da1fa16f0ee7462df84e1ddaa` | Inventory and transplant against this frozen SHA, never moving main. Review any newer fix separately before inclusion |
| Units scope | Confirmed by Ed on 2026-09-18; Q1/Q4 resolved | Carry I1 through I15. Phase 0 ports shared infrastructure; F3 belongs to Assemblies, F4 to Window Types and F1 to Spaces if measurements justify it |
| New unit quantities | Deferral to owning features confirmed by Ed on 2026-09-18; quantity choices remain open | Resolve Q2/Q3 and the proposed rows with their features. They do not block the shared parser and field control |
| Public operations | Ed confirmed ordinary edits/batches succeed completely in one native Undo step or have no effect. Failures produce clear warnings confirming no change; stale requests write nothing | CONTRACTS C2 through C4 specify context, results, revisions, atomicity and bounded retries; P0-D implements and verifies them |
| Record metadata | Copy and unknown-data policies confirmed by Ed on 2026-09-18 in EXTENSIBILITY | CONTRACTS C5 defines the lifecycle matrix, reference declarations and synthetic export mappings; real mappings remain with their features |
| Registration | Feature schemas and compatibility checks are required | CONTRACTS C1 specifies declaration shapes and diagnostics; P0-D/F prove them with a synthetic feature |
| Translation dependencies | Confirmed by Ed on 2026-09-18: declared typed dependencies, generic ordering and explicit failures without substitution | CONTRACTS C6 specifies ordering and failure propagation; P0-F proves this with synthetic sections |
| Empty Export behavior | Confirmed by Ed on 2026-09-18: the Phase 0 user workflow writes no files | Test destination opening/cancellation without runtime boot. Use separate synthetic development probes for runtime and artifact handling; user-facing HBJSON/report output arrives in Phase 1 |
| External adapter scope | Confirmed by Ed on 2026-09-18: Phase 0 owns shared programming contracts and a synthetic client with the panel closed | Discovery, reads, validated writes, read-back, stale-request rejection and native Undo belong here. Transport, packaging and connection/access controls belong to a separate delivery packet; its milestone remains unscheduled. No adapter or user connection claim in Phase 0 |

The design work named in the last column is now specified in CONTRACTS C1 through C6. These are
implementation defaults, not additional product decisions or implemented APIs. Escalate a choice
to Ed when it changes product behavior or scope; ordinary API naming needs no interview round.

## Evidence gates inside Phase 0

| Gate | What is still needed | What it blocks |
| --- | --- | --- |
| PHX in Pyodide | Pinned PHX/runtime/dependency versions; actual synthetic HBJSON-to-METr conversion in Pyodide; dependency/license inventory and measured installed payload | Selecting and shipping the embedded METr route; not the empty foundation |
| Overlay fill | Alpha, depth, visibility, hit behavior and representative-size timing on the proving host | Filled Colour-by/preview commitments; a failure has the outline-only fallback recorded in DECISIONS |
| Window component | Glue/cut, selection, rewrite, anchor, no-scale, native Undo/Redo and reopen evidence | Window placement representation, not the empty foundation |
| Edge identity | Attribute and reference survival across split, weld, move, push-pull, window cut, Undo/Redo and reopen | Edge-owned assignments for thermal bridges, piping and ducting |

PHX issue #157 was OPEN on 2026-09-18. Its acceptance covers the optional Excel dependency split
and ordinary installs. Closing it alone does not prove Pyodide execution or the payload budget.
No PHX code was inspected in this review, and issue status is not proof that a fix is absent.

The three host experiments can share one prepared synthetic session through the predecessor
bridge, with the required fresh-process start and isolated/reset models between experiments.
An unavailable host produces a pending gate, never a passing result inferred from offline tests.

The [investigation plan](phases/phase-01-investigations.md) sets measurement cases and proposed
screening criteria. Verify the frozen manifest budget before running. Record measured numbers;
do not invent a threshold after seeing results.

## Settled or nonblocking items

- Development namespace is already settled in TECH_STACK: `PhComposer`, `ph_composer` dictionaries
  and `ph_composer.rbz`. D5 fixes the MVP license boundary. Final public naming is a launch gate.
- Thermal bridges, equipment, piping and ducting interviews belong before those features' plans.
  They need not delay foundation design. Validation/export interview work gates Phase 1 planning.
- SketchUp 2023 host proof, Windows support and public distribution remain separate gates.
  The foundation still requires Ruby 2.7.2/3.2.2 offline checks and the current macOS host gate.
- The checkout has `origin=https://github.com/bldgtyp/ph-composer.git`, with issues enabled and no
  open issues returned during the 2026-09-18 review. Ed confirmed this development home in D8.
  A future organization move remains open and requires an explicit decision. Issue creation
  remains separate from this local planning work.

## Document corrections to carry into detailed planning

The Units packet now consistently carries fifteen inherited decisions and the confirmed shared
infrastructure scope. Detailed planning must allocate its acceptance checks to the delivery owners.

Keep the roadmap's successful METr milestone distinct from the accepted failure route in DECISIONS.
If the PHX spike fails, record the HBJSON-only disposition and revise the Phase 1 exit before
claiming it satisfied. A documented negative spike result can close an investigation without
proving the capability it tested.

## Authorities

- [Foundation scope](../foundation-transplant.md)
- [Units PRD](../../features/units/PRD.md) and [status](../../features/units/STATUS.md)
- [Decisions](../../DECISIONS.md)
- [Contributor architecture](../../../context/EXTENSIBILITY.md)
- [Agent interface](../../../context/AGENT_INTERFACE.md)
- [Technical context](../../../context/TECH_STACK.md)
- [PHX issue #157](https://github.com/PH-Tools/PHX/issues/157)
