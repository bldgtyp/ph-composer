# P0-E: panel kit and shared Units

DATE: 2026-09-18
STATUS: Complete 2026-09-18; archived after PR #1. At the last stage update: Implemented on branch 2026-09-18; host-verified on 26.1.188 except a same-process Model switch. Evidence: [evidence/phase-04-panel-units.md](../evidence/phase-04-panel-units.md).
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft)

## Entry and scope

Requires P0-D. Read the UI-polish skill/reference, the empty-shell portions of ui-baseline and
the Units PRD. Own shared HtmlDialog modules/styles and user preferences. Assembly, Window,
Library and Spaces screens remain excluded.

## Work

1. Transplant the module registry and generate its script list. Rename JS/CSS namespaces together.
   Missing/cyclic modules fail with diagnostics. Extract shared styles from deferred screens only
   where a shared component requires them.
2. Adapt panel transport to C2/C3. Correlation is a presentation concern; domain results originate
   outside the dialog. Close/reopen, late responses and model switches must not repaint another Model.
3. Mount empty Overview and Export sections. Keep the normal panel minimal. Diagnostics, runtime
   probes and the synthetic editor are development-only controls, excluded from normal shipping UI.
4. Port the six listed shared unit files, their `length_expression.js` dependency, existing
   quantity rows and applicable numerical vectors.
   Preserve I1 through I15; no new equipment/pipe/climate rows or F1/F3/F4 feature cleanup here.
5. Exercise text entry, invalid input, locale behavior and draft-unit preservation through the
   synthetic editor. Capture report-unit preferences in a synthetic report test, not a user export.
6. Reuse notices, accessible labels, focus handling, Escape and explicit Save/Cancel behavior.
   Failed operations give clear persistent warnings; a programmatic failure does not force panel open.

## Acceptance allocation and checks

Before declaring Units complete, map predecessor A1 through A15 to shared coverage or a named
later owner. Retain synthetic equivalents for parser/control behavior while deferring actual
Assembly/Window/Spaces walkthroughs. Link the allocation in the phase report.

Check known U/R/conductivity/psi/H vectors, architectural lengths, mixed suffix arithmetic,
regional grouping/decimals, wrong dimensions, nonfinite input, division by zero and whole-string
consumption. Switching or repainting must never write rounded display values back to storage.
Native restart restores preferences; switching units changes neither SKP dirtiness, Undo nor
SketchUp UnitsOptions. An unfinished draft keeps its starting unit until commit or Escape.

Run applicable Node/preview checks and a current-host walkthrough with refreshed panel assets.
Capture empty panes, synthetic editor focus/error states, model switch and narrow panel behavior.
Refresh the manifest after shipped assets change. Browser preview alone is not native acceptance.

## Exit and evidence

A10/A11 pass, with explicit feature-screen deferrals and UI review findings in
`evidence/phase-04-panel-units.md`. Reuse the architecture rubric in the same coherent review.
Stop if a shared component needs feature-specific business logic or if an active draft can be
silently reinterpreted. Do not port a whole builder to satisfy a generic control dependency.
