# P0-B: four technical investigations

DATE: 2026-09-18
STATUS: Scoped. Not executed; spike execution needs Ed's scheduling and an available host.
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft)

## Entry and boundaries

Requires explicit spike execution scope. The window/overlay spikes were deferred; this document
does not reactivate them. PHX changes require that repository's instructions and separate scope.
Read the host-machine workflow before using the existing predecessor bridge. Use synthetic Models.

Record the exact proving host build, OS, Ruby, renderer and bridge version. Prepare one fresh
host process, then reset to an isolated synthetic model for each experiment. Reopen where required.
The host may load the frozen predecessor; do not edit its source or follow moving main.

## B1: PHX inside Pyodide

Read current PHX #157 status and inspect the actual selected PHX revision. Its issue closure alone
does not satisfy this spike. Pin the runtime and every wheel; start from the predecessor's pinned
runtime, not an unreviewed upgrade.

Use a synthetic two-Room HBJSON with explicit simple constructions and stable ids. Record its
generator and hash. First prove the reference native Python conversion in an isolated project
environment; then load the same input and dependencies in actual Pyodide through the established
runtime/browser probe. Native Python success alone does not pass.

Check PHX/METr imports with the Excel extras absent, successful conversion, output parsing,
Room identities/counts and representative geometry/construction values against the reference.
Record load order, errors, cold/warm timings, installed bytes, wheel licenses and transitive
dependencies. Keep source content synthetic. No production exporter lands in PH-Composer.

Read the source manifest budget before running. If the added stack exceeds it, report both byte
totals and leave payload acceptance open; do not raise the limit silently. A browser runtime
incompatibility requires a scoped compatibility proposal, not an automatic dependency upgrade.
METr application import is a later consumer gate; JSON conversion must not be described as that gate.

## B2: overlay fill

Use generated scenes of 100, 1,000 and 10,000 triangles, including concave faces, holes, overlapping
faces, reversed normals and nested transformed instances. Compare disabled overlay, outlines and
filled overlay on the same camera path. Capture alpha, front/back depth, hidden geometry,
selection, orbit and picking behavior. Confirm model materials and saved attributes are unchanged.

Run five repeated camera paths after warm-up and record median/p95 draw time plus host interaction
observations. Planning screening target: at 1,000 triangles, p95 added overlay draw cost no more
than 16 ms, with no input-blocking stall over 100 ms attributable to it. The 10,000 case measures
headroom. These are proposed engineering screening criteria, not a product performance promise;
freeze them before the experiment or document a reasoned revision before measuring.

Require visually correct occlusion and usable native picking as well as timing. Failure selects
the decision register's outline-only fallback and records which filled modes remain unavailable.

## B3: window component

Generate a minimal flat cutting component in a synthetic Zone-like group. Test direct, nested,
repeated and mirrored placements. Record glue target, cut outline, click/selection behavior,
anchor position, transformation and no-scale mask behavior before/after a definition rewrite.
Use native Undo/Redo and save/reopen, verifying exact values as well as screenshots.

Measure the host Face's loops and area before placement, after placement, after resizing and after
explode. Split the host face with an adjacency-like geometry operation and observe attached units.
Inspect resulting topology, orphaned instances and gross-versus-net area consequences. This is
a representation experiment, not implementation of Solve adjacencies or Window placement.

A no-scale hint is not evidence that arbitrary programmatic scaling is impossible. Distinguish
native tool restrictions from transforms the future feature must detect. If flat geometry cannot
meet the PRD, document the more-geometry alternative for the Window packet before implementation.

## B4: edge identity

Tag edges with synthetic type ids, assignment ids and namespaced payloads. Include connected runs,
loose lines in groups, nested and repeated components. Split, Weld, move, cut/paste, push-pull an
adjacent face and cut the face with the window component. Undo/Redo each operation; save/reopen.

For every result, record edge persistent ids, occurrence paths, endpoints, lengths, full synthetic
attributes and the actual target of each reference. Distinguish id replacement from attribute loss
and from duplicated logical assignments. Count alone proves nothing about correct references.
Record whether a scan can diagnose loss without an observer. A repair is a proposal, not host fact.

## Exit and evidence

Create four reports under `evidence/`: `spike-phx.md`, `spike-overlay.md`,
`spike-window.md`, `spike-edge.md`. Each names expected and observed results, reproducible
inputs, limitations and affected feature decisions. Update the owning packets, roadmap and status.

A16 through A19 require results and dispositions. If the host or required runtime is unavailable,
mark that investigation Blocked and name the missing prerequisite. Other foundation work may
continue. Stop any experiment that risks a user's modified Model; never discard it for a clean run.

