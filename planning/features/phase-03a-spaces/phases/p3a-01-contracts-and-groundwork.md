# P3a-01: contracts and groundwork

DATE: 2026-10-03
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Entry and scope

Requires the entry gates in [STATUS](../STATUS.md) and D3a-1. Owns what must be true before any
file exists under `features/spaces/`: the bindings confirmed against code, the Zones rule that
keeps Floor Segment faces out of the Zone's Faces, the Ruby unit rows, and the two export-run
items the first Spaces section would otherwise meet. No Spaces code and no screen.

Behavior owners: [face-assignment](../../../archive/face-assignment/PRD.md) and
[zones-and-adjacency](../../../archive/phase-01-zones-and-adjacency/PRD.md) for the Face walk;
[validation and export](../../cross-phase/validation-and-export/STATUS.md), "Owed from the Phase 2
review", for items 1 and 2. Names: [CONTRACTS](../CONTRACTS.md) sections 5 and 7.

Paths are relative to `src/ph_composer/`.

## Steps

1. **Reproduce the findings this stage acts on.** Before changing anything, write the failing
   test for each: a plain Group holding one Face inside a Zone is returned by
   `ph_composer.zones.faces.list` (F8); two contributors that read each other's sections register
   without refusal (F21); a Zone whose Faces are all omitted builds a Room with no Faces and the
   diagnostic model fails to reload (F21). A finding that does not reproduce is corrected in
   [DECISIONS](../DECISIONS.md) Part 1 and its step is dropped.
2. **Answer CONTRACTS section 7.** Each of the seven questions gets a focused test or a read of
   the code, and its answer is written into CONTRACTS as section 8, "P3a-01 contract answers", in
   the shape Phase 2 used. Correct any table the answers change. Run the architecture review on
   the corrected CONTRACTS and record its outcome in the evidence file.
3. **The nested-container rule (H1, D3a-1).** In `features/zones/zone/occurrences.rb`, a Group
   inside a Zone that carries a readable Zone stamp is a nested authoring container:
   `walk_faces` does not descend into it, and a path that runs through one resolves to no Zone
   Face. Apply the same rule in `export/geometry_snapshot.rb`'s Face capture and wherever
   `features/zones/adjacency/` gathers candidate Faces. The rule reads `STAMP_STORE`, which Zones
   owns, and names nothing else. A Group stamped for a different Zone than its parent is still a
   container; the mismatch is Spaces' finding, not Zones'.
4. **What the rule must not change.** A classified Face keeps its stamp and is still a Zone Face:
   the rule applies to Groups only. A Zone Group nested in a Zone keeps its existing treatment.
   Cutting components keep D2-5's.
5. **Ruby units (H2).** Reuse the standalone `volume` (m3) and `airflow` (m3/h) groundwork
   merged through PR #84, tracked by the [units receipt](../../cross-phase/units/STATUS.md).
   The existing agreement and formatting tests cover the quantity ids, factors and rounding in `html/unit_tables.js`; do not add a second table
   or duplicate test.
6. **Section-read cycle refusal (H3).** In `shell/registry_validation.rb`, refuse at registration
   a cycle among declared contributor section reads, with a `registration.` code and every
   section on the cycle named in the diagnostic. Follow the existing feature-cycle check.
7. **Empty Room (H4).** Decide in code review, against `context/CONTRACTS.md`, "Translation
   sections and artifacts", between refusing the Zone with a declared blocking finding and
   omitting the Room with a declared disclosure, and implement the one that keeps the diagnostic
   model loadable. Record the choice in validation-and-export's STATUS. The owed item says
   "refuse or omit the empty Room with a declared code"; either satisfies it.
8. **Context.** Fold the container rule into `context/TECH_STACK.md` beside the cutting-instance
   rules and into `context/CONTRACTS.md`, "Geometry records and occurrence references". Fold the
   cycle refusal into `context/CONTRACTS.md`, registration.

## Source

No predecessor source. The predecessor had no Zones and no export sections of this shape.

## Tests (write first)

1. The three reproductions in step 1, turned into the passing tests of steps 3, 6 and 7.
2. A stamped Group inside a Zone: its Faces are absent from the Face list, from Suggest's
   candidates, from the Shift-click flood, from Solve's candidates and from the export snapshot.
   An unstamped Group's Faces are still present.
3. A stamped Group nested two deep and one under a rotated wrapper are both skipped.
4. A mutable Face path through a stamped Group refuses with a target code and writes nothing.
5. Volume and airflow convert both ways and agree with the panel table to the stored precision.
6. A two-section cycle and a three-section cycle each refuse; an acyclic chain registers.
7. The all-omitted Zone produces the chosen outcome and the diagnostic model reloads.
8. Every existing Zones, Colour-by and export test passes unchanged.

## Host gate

Fresh process on the Phase 2 reference model. Draw a Group with one Face inside Zone A and write
a Zone stamp on it through the bridge. Confirm the Zones / Faces table, Suggest classification,
the Shift-click flood and Solve all ignore the Face, and that export preflight is unchanged from
the baseline. Remove the stamp and confirm the Face returns as unclassified. Repeat the Phase 1
and Phase 2 cases that `acceptance_ledger.py status --changed` screens for the files in step 3.

## Out of scope

Any file under `features/spaces/`. The edit-context writer and deferred work (P3a-03). The
Colour-by extension (P3a-05). R05 items 3 and 4 (P3a-10).

## Done when

- S01 has evidence in `evidence/p3a-01-groundwork.md`, with the architecture review recorded.
- CONTRACTS section 8 answers all seven questions; every table agrees with the code.
- `make ci` passes on both Rubies.
- validation-and-export's STATUS records items 1 and 2 as delivered; the units STATUS records
  the two Ruby rows.
