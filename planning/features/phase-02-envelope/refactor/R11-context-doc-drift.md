# R11: `context/` did not absorb what Phase 2 settled

DATE: 2026-10-01
STATUS: Requested
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; review of PR #15, issue #14)
CLASS: Evidenced. Documentation only; no code or host gate.
PRIORITY: 3. Cheap, and the other packets cite these files.

## Governing rule

`planning/.instructions.md`: "Plans are provisional; `context/` is canonical. When a plan lands, fold
the outcome into the relevant `context/` doc." `AGENTS.md`: "Keep context, planning and status
documents synchronized with verified work."

## Observed

1. `context/EXTENSIBILITY.md:73-76` still says "The Assemblies is implemented as a definition feature",
   "Windows remains future work" and the table-contribution primitive's "first inventory integration
   is in progress in P2-05". The header STATUS line stops at Phase 1.
2. `context/EXTENSIBILITY.md`, "Organization and dependencies", says of the three-layer rule "Ed set
   this on 2026-10-01, ahead of its implementation". It is implemented in Ruby. R01 records where the
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
5. The code table in `context/CONTRACTS.md` is behind by at least 48 codes (R06 item 7).
6. `context/AGENT_INTERFACE.md` gained one paragraph. It does not list Phase 2's programmatic reads
   and writes or the dialog-only limits (R05 item I). `docs/API_QUICKSTART.md` has no Phase 2 workflow.
7. `context/EXTENSIBILITY.md`, "View commands", defines a view command as viewport state only. Five
   library operations registered as view commands change session or machine state (R05 item B).
8. `context/UBIQUITOUS_LANGUAGE.md` changed by two lines. "Anchor" is absent. "Window unit" has one
   mention. Check that Frame, Glazing, Psi-Install Type, Window Type, Element, Layer, Layer-Segment,
   Provider, Catalog, Library kind and Source each have an entry that matches the code's use.
9. The archived Phase 2 `CONTRACTS.md` section 4 states "Every arrow above points down a layer". The
   `ZoneSection` to Apertures row does not. The archive is a historical record; correct the claim in
   `context/` when R01 is decided, not in the archive.
10. `panel.section`, `ui.contributeTable` and `library.registerSurface` are three panel contribution
    seams. The first two are documented; `registerSurface` is not (R09).

## Proposed correction

One documentation pass, using the `docs-pass` skill, that:

- rewrites the stale paragraphs in items 1 and 2;
- adds the Window Unit storage rows, reference shape and identity rules to `CONTRACTS.md`;
- adds a "Library providers and catalogs" mechanics section to `CONTRACTS.md` and trims the archive
  pointer;
- brings the code table up to date (or replaces it with the generated index from R06);
- adds the per-feature agent paragraph and the quickstart workflow;
- completes the glossary entries.

`docs/` and `context/UBIQUITOUS_LANGUAGE.md` are externally readable: client-facing register, no em
dashes or en dashes.

## Verification

Focused consistency review only. `make lint-citations` still passes. Every `context/` section name
cited in a `src/` comment still exists (`grep -rn "context/CONTRACTS.md, \"" src`).
