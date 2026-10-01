# Phase 2 acceptance register

DATE: 2026-09-30
STATUS: Scoped. No row has evidence.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

The owning PRDs supply the detailed cases. This register supplies the closure gates. Record a
source-controlled evidence summary per stage under `evidence/` with commit, build, fixtures,
checks, exact host versions and remaining limits. Keep SKP files and captures in `_private/`.
Ids use the prefix E so they do not collide with Phase 1's A and R rows in the case ledger.

| ID | Owner, stage | Required evidence | State |
| --- | --- | --- | --- |
| E01 | Shared, P2-01 | CONTRACTS section 7 answered from code; architecture review recorded; the subtabs module, `record_edits` and `inventory_grid` pass their tests and preview checks; the real panel loads with Zones / Faces and Export unchanged | Open |
| E02 | Assemblies, P2-02 | Schema round trips for Material and Assembly; the membrane, steel stud and one-spacing-per-Layer rules; thermal values equal the predecessor's reference cases; `user_data` and understood local-only extension payloads survive edit, Duplicate, Undo/Redo and reopen; unavailable payloads survive edit and refuse Duplicate when copy rules are missing; a panel-closed script builds a three-layer Assembly through registered actions only | Open |
| E03 | Assemblies, P2-03 | Both inventories on the host: create, in-place edit with stale-value refusal, duplicate, guarded delete, Material replace; filter, group and order never change the Model; unit switch keeps drafts | Open |
| E04 | Assemblies, P2-04 | The Builder on the host: every toolbar gesture is one Undo step; partial Assemblies save and reopen; both U-values shown, withheld and never zero when inputs are missing; the ventilated cladding flag changes only the displayed exterior film | Open |
| E05 | Zones and assemblies, P2-05 | Assign by selection, by right-click, by table and by paint, each one Undo step; hint fill and explicit-value precedence; the 250 ceiling and one above; delete with replacement across direct, nested and repeated-definition Faces, one Undo restoring the record and every `assembly_id`; a stale expected value and an unreachable Face each refuse the whole command; usage counts and area; the assembly Colour-by mode; paired Faces naming different Assemblies warn | Open |
| E06 | Assemblies and export, P2-06 | The normal packaged RBZ exports the reference model with no development provider present; the exact HBJSON reloads; single, mixed, steel stud and membrane layers read back with their identifiers, division grid and `ph_composer` block; one Material at two thicknesses is two materials; a Face naming an absent id, an incomplete assigned Assembly and an unused incomplete Assembly each produce the PRD's outcome; the metadata guard passes | Open |
| E07 | Library, P2-07 | The provider contract against a synthetic multi-kind file and folder; envelope refusals, row tolerance, duplicate ids across folder files, budget overflow and failed refresh each have a distinct outcome; resolver outcomes including ambiguity; copy plus assign rolls back together; panel closed: list, preview, apply, read back, stale revision, wrong session, duplicate retry | Open |
| E08 | Library, P2-08 | On the host: add a library file, copy and assign by drag, Add to this file, Undo removes copy and assignment together, In this file, same-name source review with all three answers, a second provider with identity-scoped state, reopen on a machine with no providers and edit the copy | Open |
| E09 | Library, P2-09 | Export model library, read back, update the same file and export a new one: semantic fields, local ids, retained and fresh library UUIDs, subsequent reuse; selected scope and hidden rows; a failed write keeps the prior file; synthetic secret, address and path fields are filtered; the example provider registers from outside and passes the shared provider contract tests | Open |
| E10 | Windows, P2-10 | Schema round trips for four kinds; grid operations; thermal values equal the predecessor's proof fixture; guarded delete with replacement; the settings primitive with Zones' settings unchanged on reopen; a panel-closed script creates products and a type | Open |
| E11 | Windows, P2-11 | The Builder, Installs and U-Values on the host; one Save for an Installs session; incomplete elements visible and never counted as zero | Open |
| E12 | Windows and zones, P2-12 | Fresh process: place by explicit Face reference on a wall and a flat roof; panes face out; glue verified geometrically; resize a used type with three anchors in play in one Undo step; Swap type; Re-host; scale, mirror, edit inside, Make unique, cross-Model paste, explode and Restore unit each produce the PRD's finding or repair; a copy gets its id at the next mutation; pane Faces are not Zone Faces; Solve reports a Face with glued units; the Phase 1 cases the ledger screens are repeated | Open |
| E13 | Windows, P2-13 | Place tool: hover outline, sill height and edge offset entry, refusals with reasons, Escape, tool stays active; Schedule with unhosted and differing units; the Window Type Colour-by mode | Open |
| E14 | Windows and export, P2-14 | The normal RBZ exports the reference model; one Aperture per glazed element on a gross parent Face; psi-install on each frame side and none on the Aperture; one window construction per distinct combination; a g-value 0 unit exports with the disclosed exception; every blocking row of the PRD blocks; net opaque area agrees with hand calculation | Open |
| E15 | Windows and library, P2-15 | Each of the three kinds copies from a library file; assigning a Frame or Glazing by drag copies and assigns in one Undo step; adding the kinds changed no file in `library/` | Pass: [E15 evidence](evidence/p2-15-window-library-kinds.md) |
| E16 | Library, P2-16 | Each sign-in method; a static file host as a server; late responses after removal do nothing; no credential or address in the panel, a log, the SKP or an export. In scope only if D2-8 keeps it | Open, conditional || Deferred to Phase 5 by D2-8 |
| E17 | Integration, P2-17 | Both offline Ruby gates, coverage, browser and runtime checks; packaged inventory and footprint against the 22 MB target and 24 MB ceiling; fresh-process authoring to export of the reference model with nested edit paths, two Models, Undo/Redo and reopen | Open |

## Synthetic reference model

Extend the Phase 1 reference: adjacent 5 x 4 x 3 m and 4 x 4 x 3 m boxes, one shared 12 m2 wall,
36 m2 of floor and of roof, 78 m2 of external wall.

- **Assemblies.** A wall with four Layers: cladding, a membrane, a steel stud Layer of studs and
  cavity insulation with one spacing, and an interior board. A roof with a mixed wood Layer. A
  single-Layer floor. One partition Assembly for the shared wall, the same on both sides. One
  unused incomplete Assembly. One Material used at two thicknesses.
- **Windows.** Two Window Types and four units: a one-element fixed unit, a three-element mulled
  unit with one Empty panel, the same type Move-copied, and a unit on the flat roof. One type
  carries a g-value 0 element as the opaque-door case.
- **Library.** A synthetic multi-kind library file with Materials, Frames, Glazings and
  Psi-Install Types, one row sharing a name with a local record and differing in value, and a
  second file reusing a record id under a different library id.

Hand-calculate the expected U-values, the glazed area per host Face and the net opaque areas
before the stages that assert them, and keep the calculation beside the fixture. Compare actual
identifiers and reference targets after save, reopen and HBJSON reload; matching counts alone do
not prove a round trip.

## Completion boundary

E01 to E15 and E17 close Phase 2. E16 closes with it only if D2-8 keeps the connection in scope.
Every "Through PHX" check in the three PRDs is excluded and stays open in
[metr-export](../unscheduled/metr-export/README.md). SketchUp 2023 and Windows remain their own
gates. Spaces-dependent and thermal-bridge-dependent cases stay with Phase 3.
