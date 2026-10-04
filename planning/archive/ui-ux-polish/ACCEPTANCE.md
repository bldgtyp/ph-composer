# UI and UX polish: acceptance

DATE: 2026-10-04
STATUS: Complete. Offline gates and browser checks passed; Ed checked the branch build in SketchUp 2026 on 2026-10-04; merged through PR #71.
ISSUE: none (local planning draft)

## Planning checkpoint

- All 22 requests retain owner-item mapping, evidence, intended behavior and acceptance checks.
- Reported bugs remain unverified until reproduced; screenshot observations are not host acceptance.
- Every request maps to a proposed PR; dependencies and open decisions are explicit.
- Local references resolve; planning index and ledger agree; no screenshot pixels or model data tracked.
- Commit contains only this packet and its index changes, with DCO sign-off.

## Verification profile

Ordinary presentation changes use focused behavioral/browser checks, one coherent review and
repository-required gates. Strengthen to high assurance for Assembly topology/resize/delete,
authorization, model transactions or public contracts: check references and affected round trips,
Undo/Redo, refusal behavior and the required native/fresh-process evidence. Never update a golden
only to remove a failure. No code or host gates are needed for this documentation-only checkpoint.

For implementation: refresh the vendor manifest when packaged assets change; run `make ui-checks`
and `make ci` for the coherent affected slice. Capture wide and narrow layouts using synthetic
fixtures in preview, then native SketchUp for affected real interactions. Define exact host state,
fixture/build identity and assertion observations using the native-acceptance skill. Preview,
installation and bridge execution alone do not close a native gate. Keep raw captures private.

## PR acceptance matrix

| PR | Required evidence beyond the request-level checks |
| --- | --- |
| P1 | Zones/Faces, Assemblies and other affected table consumers; multi-Zone groups, hover/focus/selection/invalid/pending, long labels, range editing, sticky columns and narrow widths; palette matches viewport semantics |
| P2 | Success timing and newer-message replacement; persistent warnings/errors/tool instructions; hover/focus; representative read-only, staged, immediate-action and destructive dialogs; X/Escape/Cancel/commit/focus return |
| P3 | No sources to usable library; file and folder routes, picker cancel, approvals, load failure, duplicate source and unavailable source; both Builders' fold/search/detail/copy/assignment flows |
| P4 | Empty and populated Zones, Colour-by/filter/reset, Classify start/change/stop, authoring toolbar; table width and scroll held while disclosed surfaces open; drafts, narrow widths and native viewport state |
| P5 | Source-referenced parity matrix; insertion on each applicable edge, dimensions and resize on both axes, delete/split/merge/flip/copy/material affordances where present; SI/IP, invalid input, zoom stability, refusal, references and native Undo/Redo |
| P6 | View/zoom versus editing groups, contextual settings, shared chips, tooltips and active state; representative selected/unselected states and narrow layout; preserved Escape/focus/commands |
| P7 | Reproduced fixture, scope diagnosis, each supported ordering and reverse direction; hierarchy and selection preserved; no claimed fix if sorting was functioning within its intended scope |

Check desktop-scale and narrow panels, including 1280, 900, 420 and 280 CSS-pixel widths where
applicable. Horizontal scrolling may be intentional; controls must remain reachable and overlays
must not obscure the active operation. Record actual dimensions rather than generic "responsive".

## Closure

Each PR ledger records implemented, offline-verified, host-verified and merged separately.
Accepted reusable rules are reflected in the skill/patterns. Design System synchronization is
verified from merged main; if inaccessible, record the outstanding sync and reason rather than
claiming completion. This packet makes no Windows, SketchUp 2023 or certification/release claim.
