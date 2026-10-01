# Phase 0 implementation plan

DATE: 2026-09-18
STATUS: Complete 2026-09-18; archived after PR #1. At the last stage update: In progress. Implementation authorized 2026-09-18 on branch `phase-zero-foundation`.
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft)

## Outcome and authority

Deliver the empty PH-Composer extension, shared Units infrastructure and public contribution
contracts, with four recorded technical investigations. Building authoring, real HBJSON output
and an external-agent adapter remain outside this packet. The [foundation scope](../foundation-transplant.md)
owns the product boundary; [CONTRACTS.md](CONTRACTS.md) supplies the implementation design.

Ed has resolved the product choices recorded in [READINESS.md](READINESS.md). The API spellings,
bounds and file organization below are planning defaults within those choices. An implementer may
refine them with evidence and update the plan; a change to accepted behavior requires Ed's decision.
Nothing in this packet claims that the proposed APIs exist.

## Stage map

| Stage | Plan | Prerequisites | Result |
| --- | --- | --- | --- |
| P0-A | [00: handoff check](phases/phase-00-handoff.md) | Implementation scope granted | Baseline/disposition checked, contract examples pinned |
| P0-B | [01: investigations](phases/phase-01-investigations.md) | Spike execution authorized; required host/runtime available | Four reports and downstream dispositions |
| P0-C | [02: tooling/bootstrap](phases/phase-02-bootstrap.md) | P0-A | Empty extension and executable verification tooling |
| P0-D | [03: records/operations](phases/phase-03-operations.md) | P0-C | Synthetic record, public operations and lifecycle proof |
| P0-E | [04: panel/Units](phases/phase-04-panel-units.md) | P0-D | Empty panel and shared Units acceptance |
| P0-F | [05: runtime/export](phases/phase-05-runtime.md) | P0-D and P0-E | Runtime and synthetic translation/export contracts |
| P0-G | [06: integrated gate](phases/phase-06-acceptance.md) | P0-C through P0-F; P0-B reports | Evidence-backed foundation handoff |

P0-B is independent of P0-C through P0-F. A PHX dependency failure does not stop the empty
foundation. A blocked investigation prevents claiming all of roadmap Phase 0 complete. A
negative result can close an investigation only after the affected packet records the fallback;
it never proves the tested capability. In particular, revise the Phase 1 METr success criterion
if the PHX route fails, using DECISIONS' HBJSON-only fallback.

Stage numbers describe dependencies, not a requirement for seven agents or seven branches.
Prefer one coherent checkout unless ownership requires isolation. Preserve the existing planning
edits. No cross-repository implementation is implied by authorization to implement this foundation.

## Source and changes

The sole transplant baseline is
`f358ebf51532046da1fa16f0ee7462df84e1ddaa` in the sibling predecessor.
Read [SOURCE_INVENTORY.md](SOURCE_INVENTORY.md). Use a detached source view or `git show`, never
copy uncommitted predecessor files. New fixes need separate disposition.

Shipping target: `src/ph_composer/`, loader `src/ph_composer.rb`, Ruby module `PhComposer`,
dictionary prefix `ph_composer`, RBZ `ph_composer.rbz`. Rename the JS registry to
`PhComposerUI` and CSS prefix to `phc-` as local implementation defaults. Package name
`ph_composer_translation` owns Python translation; exporter registrations are distinct.

Development-only synthetic examples live under `tests/fixtures/foundation/` and
`tools/examples/foundation/`. The normal composition root registers no example. Host probes
load examples explicitly from the development tree. Packaging checks must prove their absence.

## Execution rules

1. Read this plan, current STATUS and the next stage. Reuse loaded context; do not repeat completed gates.
2. Complete the stage's work and focused tests, then its stated exit checks. A missing prerequisite
   remains pending. Do not stub a failed gate into success.
3. Record actual commands, exit codes, source SHA, installed version where relevant and evidence
   paths in a short phase report. Store public synthetic evidence under this packet's
   `evidence/`; logs/screenshots must contain no private project data or local secrets.
4. Update STATUS and affected authorities through docs-pass. Each stage report names outstanding
   limitations and the next stage. DCO-sign every commit if commits are requested.
5. Use the high-assurance profile for persistence, public APIs and host lifecycle. Run one
   architecture review per coherent consequential slice through the existing review ladder.
   Reuse that review at final acceptance when the relevant diff has not changed.

The commands in DEVELOPMENT are target-state until P0-C installs them. It is an error to cite
their existence as a passing test today. The final full gate requires all tooling installed;
a local lint skip is not final-gate evidence. Coverage is required; use available complexity
metrics as review evidence, not fabricated scores or automatic splitting rules.

Carry the frozen coverage minima: Ruby 93%, JavaScript 94%, Python 92%. Measure the retained
Phase 0 code, including failure paths; excluding whole modules to meet a percentage is prohibited.
The frozen runtime manifest targets 22,000,000 installed bytes and enforces a 24,000,000-byte
ceiling. Retain those limits for the foundation. PHX spike growth is a separate recorded decision
if it exceeds them. Keep Pyodide 0.24.1 and its pinned supporting assets; omit unused domain
wheels from the empty shell by explicit manifest disposition, not by changing their versions.
Retain the source manifest's timing thresholds for the corresponding runtime probes as listed
in SOURCE_INVENTORY. Record cold/warm samples on the proving host; do not silently widen limits.
Windows thresholds remain source evidence only until the separate Windows gate is in scope.

## Handoff instruction

After implementation is authorized, give the next agent this packet and the authorized stage range:

> Read planning/archive/phase-00-foundation/STATUS.md and PLAN.md, then execute the first incomplete
> stage within the authorized scope. Follow CONTRACTS.md and the frozen source inventory.
> Preserve unrelated work. Do not implement later features or an external adapter. Record
> verification and remaining gates, update the packet, and stop at an unavailable prerequisite
> or a material product decision. Do not infer authority for PHX changes, publication or release.

Before code work, apply the repository architecture skill. Before panel work, apply the UI-polish
skill and reference. Before host work, read the SketchUp section of
`/Users/em/.codex/references/machine-workflows.md`. No host process is launched by this planning pass.

## Completion

Use [ACCEPTANCE.md](ACCEPTANCE.md). Foundation verified, spikes answered, merged and released
are separate states. Phase 0 completion does not authorize Phase 1, Windows support, public
distribution, the SketchUp 2023 host claim or external-agent connection support.
