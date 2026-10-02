# R01: `context/` did not absorb what Phase 2 settled

DATE: 2026-10-01
STATUS: Implemented on branch `refactor/r01-context-doc-drift`, 2026-10-01. Documentation only.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; review of PR #15, issue #14)
CLASS: Evidenced. Documentation only; no code or host gate.
ORDER: 1 of 11. See the packet README, Sequencing.

## Governing rule

`planning/.instructions.md`: "Plans are provisional; `context/` is canonical. When a plan lands, fold
the outcome into the relevant `context/` doc." `AGENTS.md`: "Keep context, planning and status
documents synchronized with verified work."

## Observed

1. `context/EXTENSIBILITY.md:73-76` still says "The Assemblies is implemented as a definition feature",
   "Windows remains future work" and the table-contribution primitive's "first inventory integration
   is in progress in P2-05". The header STATUS line stops at Phase 1.
2. `context/EXTENSIBILITY.md`, "Organization and dependencies", says of the three-layer rule "Ed set
   this on 2026-10-01, ahead of its implementation". It is implemented in Ruby. R05 records where the
   export side departs from it.
3. `context/CONTRACTS.md`, "Geometry records and occurrence references", lists Zone, stamp, Face and
   Attached zone storage. It has no row for `ph_composer.window_unit`, `ph_composer.window_definition`,
   `ph_composer.window_pane`, the `ph_composer.window_definitions` index or
   `ph_composer.windows_settings`. The Unit occurrence reference `{ unit_id, entity_path }`, the
   copied-identity rule and the primary-definition index are described only in the archived Phase 2
   packet (`planning/archive/phase-02-envelope/CONTRACTS.md` section 2).
4. `context/CONTRACTS.md` has no section for the library provider and kind adapter mechanics that
   code cites by name (catalog generations, admission budgets, fingerprint versions, callback write
   ownership). `EXTENSIBILITY.md` and `TECH_STACK.md` cover the contributor view; the binding rules
   (limits, codes, refusal order) are in the archive.
5. The code table in `context/CONTRACTS.md` is behind by at least 48 codes (R04 item 7).
6. `context/AGENT_INTERFACE.md` gained one paragraph. It does not list Phase 2's programmatic reads
   and writes or the dialog-only limits (R03 item I). `docs/API_QUICKSTART.md` has no Phase 2 workflow.
7. `context/EXTENSIBILITY.md`, "View commands", defines a view command as viewport state only. Five
   library operations registered as view commands change session or machine state (R03 item B).
8. `context/UBIQUITOUS_LANGUAGE.md` changed by two lines. "Anchor" is absent. "Window unit" has one
   mention. Check that Frame, Glazing, Psi-Install Type, Window Type, Element, Layer, Layer-Segment,
   Provider, Catalog, Library kind and Source each have an entry that matches the code's use.
9. The archived Phase 2 `CONTRACTS.md` section 4 states "Every arrow above points down a layer". The
   `ZoneSection` to Apertures row does not. The archive is a historical record; correct the claim in
   `context/` when R05 is decided, not in the archive.
10. `panel.section`, `ui.contributeTable` and `library.registerSurface` are three panel contribution
    seams. The first two are documented; `registerSurface` is not (R10).

## Proposed correction

One documentation pass, using the `docs-pass` skill, that:

- rewrites the stale paragraphs in items 1 and 2;
- adds the Window Unit storage rows, reference shape and identity rules to `CONTRACTS.md`;
- adds a "Library providers and catalogs" mechanics section to `CONTRACTS.md` and trims the archive
  pointer;
- brings the code table up to date (or replaces it with the generated index from R04);
- adds the per-feature agent paragraph and the quickstart workflow;
- completes the glossary entries.

`docs/` and `context/UBIQUITOUS_LANGUAGE.md` are externally readable: client-facing register, no em
dashes or en dashes.

## Verification

Focused consistency review only. `make lint-citations` still passes. Every `context/` section name
cited in a `src/` comment still exists (`grep -rn "context/CONTRACTS.md, \"" src`).

## Outcome

Implemented 2026-10-01 on `refactor/r01-context-doc-drift`.

| Item | Disposition |
| --- | --- |
| 1, 2 | `EXTENSIBILITY.md`: STATUS through Phase 2; the three-layer paragraph says the Ruby features follow the rule and names the export-side departure (R05); the stale Assemblies/Windows/P2-05 paragraph is replaced by what Phase 2 built |
| 3 | `CONTRACTS.md`, "Geometry records and occurrence references": rows for `ph_composer.window_unit`, `.window_definition`, `.window_pane` and the `ph_composer.window_definitions` index; the Unit reference shape; the copied-identity and primary-definition rules. "Model settings" names `ph_composer.windows_settings` |
| 4 | New `CONTRACTS.md` section "Library providers and catalogs": limits, admission order, catalog notes, generations, copy refusal order, callback write ownership. Cross-cites `TECH_STACK.md` and `EXTENSIBILITY.md` rather than restating them |
| 5 | Code table: Library row (29 outcome codes raised from `library/`), an Identity and scope row, `geometry.failed`, `geometry.split_failed`, and `operation.proposal_required` plus the three `operation.query_*`/`dependency_missing` codes. The table is stated to hold foundation, library and shared-noun codes; feature-noun codes (`window.*`, `construction.*` and the rest) stay out, as Zones' always have. Library catalog notes are listed in the new section, not the table. `request.stale_revision` is left out: it is the R04 defect, to become `revision.stale` |
| 6 | `AGENT_INTERFACE.md`: per-feature reads and writes for Assemblies, Face assignment, Windows and Library, with the two dialog-only Library limits and the implicit Unit identity repair. The quickstart's stale export sentence is corrected. **Deferred to R03 item I:** the Phase 2 quickstart workflow, because `tests/api_client_test.rb` runs the quickstart as written and extending that test is R03's |
| 7 | `EXTENSIBILITY.md`, "View commands": the five library commands are recorded as a known deviation pending R03's `setup` verb; the contract is not widened |
| 8 | Glossary: Library kind, Catalog, Catalog generation, Element and Primary definition added. "Window anchor" already covers Anchor. Frame, Glazing, Psi-Install Type, Window Type, Layer, Layer-Segment, Library provider and Definition source were checked and left as they are |
| 9 | Left for R05, as the finding says |
| 10 | `library.registerSurface` documented beside `panel.section` and `ui.contributeTable` in `EXTENSIBILITY.md`; the worked example and the Materials/Attached zones move stay with R10 |

Verification: one source-checked consistency review (four wording corrections applied); `make lint-citations` passes, and every `CONTRACTS.md` and `EXTENSIBILITY.md` section
name cited from `src/` or `tests/` still exists.
