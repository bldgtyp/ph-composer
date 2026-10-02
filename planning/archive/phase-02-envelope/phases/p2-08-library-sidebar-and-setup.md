# P2-08: library sidebar and setup

DATE: 2026-09-30
STATUS: Implemented on branch; named acceptance passes with qualified retained evidence; Phase 2 integration remains open.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Entry and scope

Requires P2-07 and P2-04. Owns the panel side of the library seam: provider sources in the
sidebar, the source selector, copy by drag and by keyboard, the source review, Library badges,
and provider setup.

Behavior owner: [libraries PRD](../../libraries/PRD.md), "Carried over unchanged" and "Changed by
the pivot". Screen rulings: [ui-baseline](../../../ui-baseline/README.md) sections 3, 5 and 6.
The predecessor's interaction detail is in
`../ph-navigator-sketchup/planning/archive/shared-material-library/phases/`. Load the UI polish
skill first.

Predecessor paths are relative to `../ph-navigator-sketchup/src/ph_navigator_sketchup/` at
`f358ebf`.

## Steps

1. **Source selector.** Extend the sidebar from P2-04 with the selector from
   `html/library_sidebar.js`: In this file, then every configured provider that serves the
   current kind, by label. One source is shown at a time; there is no merged view. The heading
   names the provider. The word "organization" appears nowhere.
2. **Store.** Port `html/library_store.js`: pulled rows by provider, kind and generation,
   in-flight requests, and the state wording. States in this stage: library file open, loading,
   no results, failed with the last good catalog still shown and its age.
3. **Rows and details.** A record with a local copy shows In this file, muted, and using it
   takes the local copy. The details bubble separates copied properties from source-only
   information and names the library and the manufacturer separately. Opening it never copies.
4. **Copy routes.** Drag onto a Layer-Segment copies and assigns in one Undo step. Add to this
   file copies without assigning. Select then apply is the keyboard route. All three call the
   `copy` action from P2-07 with the generation the row was painted from.
5. **Source review.** Port `html/library_conflict.js` as the blocking comparison: Cancel, Use
   local copy, Use library copy, with the differing fields shown through `units.js`. Several
   same-name local matches, and several exact source matches, show the candidates and require an
   explicit choice. The panel submits the same explicit choice a script would.
6. **Badges.** In the Materials table add the Library badge with the provider's name on hover,
   and the quiet "source changed" mark while that provider is loaded and the record's source
   fingerprint differs. The mark opens the source review on request. Nothing updates on its own.
7. **Setup.** "Library setup..." opens a Libraries surface listing configured providers by label
   with Remove, and "Add library file..." and "Add library folder...". Adding opens a native
   file or folder dialog from Ruby, so no path crosses the panel boundary. The label is the
   library name from the envelope, or the folder's own name when it holds several. Nothing is
   listed on first run.
8. **Sidebar state.** Expansion, search and scroll survive an assignment and a refresh.
9. **Preview and manifests.** Port `tools/ui-preview/library_sidebar_checks.cjs`; add fixtures;
   regenerate both manifests.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `html/library_sidebar.js`, `library_rows.js` (the provider parts) | part of 479 | Port |
| `html/library_store.js`, `library_conflict.js` | 148 | Port |
| `tests/library_sidebar_test.js` | 727 | Port the remaining cases |
| `tools/ui-preview/library_sidebar_checks.cjs` | 143 | Port |

## Tests (write first)

1. The selector lists only providers serving the current kind and never shows a path.
2. A drop sends one `copy` with the assignment target and the generation; a stale generation
   refusal repaints and keeps the sidebar state.
3. Each source review answer sends the matching explicit choice; Cancel sends nothing.
4. The badge and the "source changed" mark follow the fingerprint and the loaded state.
5. Opening the sidebar, the details bubble or the setup surface sends no action.
6. No snapshot, message or DOM node carries a path (assert against the fixture).

## Host gate

Fresh process, real panel: add a library file through the native dialog; copy and assign by
drag; Add to this file; one Undo removes copy and assignment together; reuse through In this
file; trigger the source review and take each answer; configure a second file and confirm
identity-scoped In this file state; remove a provider while its catalog is shown; reopen the SKP
with no provider configured and edit a copy.

## Out of scope

Export model library to file, the starter library, the example provider (P2-09). Connection
states and sign-in (P2-16). The window kinds (P2-15).

## Done when

- E08 has evidence in `evidence/p2-08-library-sidebar.md`, with the UI polish review recorded.
- `make ci` and `make ui-checks` pass.

## Current evidence

See [source and review evidence](../evidence/p2-08-library-sidebar.md). The native host gate remains open.

Current consolidation and provenance: [P2-17](../evidence/p2-17-acceptance.md#register-consolidation-at-f4f6576).
