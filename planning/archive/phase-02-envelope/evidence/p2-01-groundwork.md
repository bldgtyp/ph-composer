# P2-01 groundwork: implementation and verification record

DATE: 2026-10-01
STATUS: In progress on `codex/phase-02-envelope`; required native regression screen remains open.
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Delivered on the working branch

Nested catalog references, schema validation of reference declarations, handler-scoped cross-feature
queries, and reference retargeters joining one proposal are implemented and tested. The shared
Subtabs, RecordEdits and InventoryGrid ports are implemented. No feature tab is enabled here.
The six binding questions have answers in CONTRACTS. Foundation rules are folded into context.

The independent architecture review found a native-select integration defect: the grid called a
text selection API on selects and overrode their disabled state. Combined tests reproduced it;
the correction and a browser-discovered options-before-value initialization defect are fixed.
The same reviewer checked the changed source and found no remaining material issue. Unchanged
Ruby groundwork retains the original review. Native popup arrow behavior is outside headless
browser proof; unprevented key routing and real option changes were checked.

## Offline evidence

Before the final select correction, full `make ci` passed on Ruby 3.2.2 and 2.7.2:
732 Ruby tests, 3,740 assertions; Python 96 tests; hostkit checks passed. Coverage passed:
Ruby 96.6%, JavaScript 97.3%, Python 94%. These results cover the initial coherent groundwork,
not the later duplicate-transform hook or final select changes. Refresh final gates at integration.

Final select changes: 24 focused JavaScript tests, scoped ESLint and real Chrome preview checks
at 1280 and 360 pixels passed. Private browser evidence is in the temporary
`ph-composer-groundwork-Ic5M3y` directory. Panel and runtime manifests were refreshed afterward.

P2-02 exposed a needed generic duplicate hook. `propose_duplicate` now optionally transforms
only detached authored values after identity/reference/extension remapping, followed by normal
schema and reference validation. Record identity and metadata stay engine-owned. Focused engine
checks pass on both Rubies: 33 tests, 98 assertions. The independent review reproduced a
callback exception leaving earlier duplicates staged when the caller rescued the error. The
duplication operation now poisons the proposal on ordinary exceptions; a public-action test
confirms a rescued second-record failure writes nothing. The reviewer closed that finding.
Composition checks pass on both Rubies: 14 tests, 60 assertions. Integrated gates remain open.

## Native observations

Host: SketchUp 26.1.188, Ruby 3.2.2, macOS. Initial installed RBZ SHA-256:
`554ef3d09fea5b875b83a1a832710a4609c0851e03f0e1c537a5d72658139a27`.
Every installed ZIP member matched. This build predates the final select correction and duplicate
hook. Normal composition contained Zones only; no synthetic product provider was installed.

- Zones/Faces panel and Export were opened through native controls. Empty export refused for
  lack of a Zone; this is a bounded observation, not the complete panel gate.
- Public authoring operations built two adjacent Zones and classified twelve Faces. Solve produced
  exactly one reciprocal pair. Repeat Solve made no change. Tolerance boundary probes passed.
- Moving one Zone marked both Surface records stale; retiring the pair cleared both sides. Native
  Undo restored both stale references; native Redo cleared both. Restoring geometry and solving
  produced the current pair again.
- Save and fresh-process reopen preserved the complete Faces query, including actual references
  and values, exactly. Private comparison file: `_private/host/envelope/faces-before-reopen.json`.
- R01: native Edit > Copy and Paste In Place produced two placements sharing one definition.
  Classify and Reverse preview/invoke all refused `target.shared_definition`; revision and stored
  Face records remained unchanged. The keyboard shortcut attempt did not create a copy and was
  discarded before the valid native-menu observation.
- R02: repeated in an isolated blank fixture. Classify and Reverse crossing a nested Zone
  refused `target.wrong_hierarchy`; the inner stamp retained its own Zone id and revision stayed
  unchanged. An ordinary nested Group remained readable/editable. Its existing Wall/Outdoors
  defaults made the requested edit a valid no-op. The development walkthrough now accounts for
  no-op revision behavior instead of assuming every successful edit commits.
- R03 exploded-Zone variant: native Explode left two Garage references outside a Zone. Both
  delete replacement modes refused `reference.in_use`, named two Faces, and preserved records
  and revision. Native Undo restored the Zone and native Redo restored the orphan references.
  Public Restore Zone and delete then committed, reassigning both Faces and removing the Garage.
  The moved-Face variant also refused both replacement modes, named the one root Face, and
  preserved both assignments and the definition after native Cut and Paste In Place.
- R04: partial overlaps with one and then two AttachedZone sides produced a reciprocal current
  Surface pair without attached-zone ids. The 6 m2 remainder(s) retained their AttachedZone ids.
  Repeated Solve was a no-op in both variants.
- R06 panel-closed API quickstart committed Make Zone, Classify and update; the exact values
  matched readback, stale revision refused without writing, and retry returned the same outcome.

No complete E01 or Phase 1 case is attested from these supporting observations alone.

## Resume and remaining gates

Current private host fixture: `_private/host/envelope/e01-regression.skp`, freshly opened from the
blank template for isolated R02 and further regression checks. The earlier adjacency model remains
at `_private/host/envelope/e01.skp`. Reinstall the final coherent build and reopen a fresh process
before final native attestation. Run the changed-path ledger screen and satisfy its reported cases.

The held Classify gesture across Model/edit-path change requires button-down/button-up control
that the native automation API does not expose separately. Retain that manual check for Ed's final
batch. Other native checks remain autonomous work until a concrete limitation is established.

P2-02 implementation is underway while manual attestations remain open, following Ed's instruction
to defer manual work. No preceding stage is represented as complete and no failed gate is bypassed.
No commit, push, stage PR or merge has been made.
