# P2-17: acceptance and handoff

DATE: 2026-09-30
STATUS: In progress. All implementation delivered; named acceptance consolidated; held-Classify and handoff remain.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Entry and scope

Current continuation: [acceptance consolidation](../evidence/p2-17-acceptance.md).

Requires every stage in scope to read `Implemented on branch` or `Merged to main`. Owns the
integrated run, the closure of the acceptance register and the document handoff. No new behavior.

## Steps

1. **Offline gates.** `make ci` on Ruby 2.7.2 and 3.2.2, coverage, `make ui-checks`,
   `make runtime-check` and `make runtime-browser-check`, `make rbz-check` with the package
   inventory, and the installed footprint against the 22 MB target and 24 MB ceiling.
2. **Ledger.** `uv run tools/hostkit/acceptance_ledger.py validate`, then a `status` screen over
   everything Phase 2 changed. Every Phase 1 case it reports is repeated or its reuse is
   justified in the evidence.
3. **Integrated native run.** Fresh process, the installed normal RBZ, the reference model built
   from an empty file by hand and by script: Zones, classification, Assemblies built and
   assigned, a library file configured and records copied, Window Types built and units placed,
   export, exact HBJSON reload. Include a nested edit path, two Models open, Undo and Redo across
   feature boundaries, save and reopen, and a host restart with a staged export.
4. **Close the register.** Each row of [ACCEPTANCE](../ACCEPTANCE.md) gets its evidence link and
   state. A row that cannot pass stays open with its reason; it is not waived by an offline test.
5. **Packets.** Update each feature packet's STATUS and PLAN with what was delivered and what
   remains. A packet that is `Complete` is archived flat by slug under `planning/archive/` with a
   row in the archive README. Face assignment is complete when assembly assignment and its
   export rows pass.
6. **Context and docs.** Run the docs pass. `context/` carries every durable rule the phase
   settled. `docs/PRODUCT.md`, `docs/PRD.md`, the format and protocol pages and the generated API
   reference describe what exists. `AGENTS.md`'s repository map lists the new folders.
7. **Roadmap.** Update the State column for 2.1 to 2.5 and the ledger. Route Phase 3: carry the
   derived-geometry Colour-by extension (D2-6, confirmed 2026-09-30) and anything this phase deferred into the Spaces
   and thermal-bridges packets.
8. **Hands-on pass.** Offer Ed a hands-on session on the installed build and record its findings
   as a follow-ups packet, the way the Phase 1 UX follow-ups were handled.

## Done when

- E17 has evidence in `evidence/p2-17-acceptance.md` and every in-scope row is `Pass`.
- The planning index, the roadmap and the archive agree with each other.
- Nothing is described as released, supported on SketchUp 2023 or Windows, or certifiable.

Current normal-package export, exact full public-value reopen and staged-artifact recovery pass.
E02–E04/E06–E15 pass with original/current provenance. E01/E05/E17 retain held-Classify and
final handoff; see [consolidation](../evidence/p2-17-acceptance.md#register-consolidation-at-f4f6576).
