# P3a-02: Space records and operations

DATE: 2026-10-03
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Entry and scope

Requires P3a-01 and D3a-2. Owns the `ph_composer.spaces` feature without any screen, tool or
automatic behavior: the three entity-owned records, the scan and index, the metrics, the findings
on what the scan sees, and the registered operations. A script can create and edit Spaces when
this stage closes. Nothing reacts to native edits yet, nothing is locked, and nothing is exported.

Behavior owner: [Spaces PRD](../PRD.md), sections "Where a Space sits", Records, "Creating
Spaces, Volumes and Floor Segments" less Mark floor's tool and Move Space to Zone, iCFA, Volume
less the preview and Height from solid, Airflows less the balance view, and Validation rows.
Names: [CONTRACTS](../CONTRACTS.md) sections 1, 2, 3 and 6.

Paths are relative to `src/ph_composer/`. Predecessor paths are relative to
`../ph-navigator-sketchup/src/ph_navigator_sketchup/` at `f358ebf`.

## Steps

1. **Feature skeleton.** `features/spaces/install.rb` with one `install(registry)`, the feature
   id, contract version and `requires: ["ph_composer.zones"]`. Add `Spaces` to `FEATURES` in
   `extension.rb` after `Windows`. Add a dependency-direction test that fails if any file under
   `features/zones/`, `features/assemblies/` or `features/windows/` names Spaces, and if any file
   under `features/spaces/` names Windows or Assemblies.
2. **Record schemas.** `space/schema.rb`, `volume/schema.rb`, `floor/schema.rb`: the three stores
   and values schemas of CONTRACTS section 2, each with its `ReferenceTarget`. Airflow fields are
   optional numbers, never null. `icfa_factor` and `net_area_factor` are floats in 0 to 1. Port
   the field set from `features/spaces/attrs.rb`; drop `entity_type`, `color`, `floor_level` and
   the model flag.
3. **Occurrences and scan.** `scan/occurrences.rb` walks from a Zone occurrence to its Space
   Groups, their Volume Groups and each Volume's marked Faces, yielding entity, record, transform
   accumulated once from the root, and the persistent-id path. Port `scan.rb`, `entries.rb` and
   `transforms.rb`. The scan reads Floor Segment records; nothing reads a designPH dictionary.
   A Space Group at the model root, with no Zone above it, is scanned too and carries
   `space.outside_zone`.
4. **Index.** Port `index.rb`: lookups by id and by path, valid for one read phase, as
   `Zones::Index` is.
5. **Metrics.** `scan/metrics.rb`, pure: per Floor Segment the projected horizontal area in m2
   (`floor/projection.rb`: project the face's world loop onto the horizontal plane at its mean z;
   F17), iCFA as area times `icfa_factor`, net area as area times `net_area_factor`; per Volume
   net volume as net area times height; sums per Space, Zone, Building-Segment and Model. The
   any-set rule (Q21) lives here as one function: a Space is `inheriting` or `user_specified`,
   and for a user-specified Space an absent rate is zero. No rounding beyond what
   `core/units.rb` already defines for the quantity.
6. **Findings.** `scan/findings.rb`, pure, from a scan to the rows of CONTRACTS section 6 that
   need no reconciler: outside Zone, empty Space, empty Volume, height missing, duplicate number
   in a Zone, floor projected. Map each remaining predecessor code in `validation.rb` (`RULES`,
   lines 31-85) to a code, a new code, or "cannot occur", and write the mapping into CONTRACTS.
   Each finding carries its condition; whether it blocks is the table's.
7. **Create.** `space/operations.rb` and `steps.rb`: `create_preview` returns, for explicit Face
   references and a Zone reference, which Faces are accepted and which are left out with a reason
   (not in the Zone's context, already a Floor Segment, already a Zone Face with a classification,
   inside shared storage, wrong entity). `create` groups the accepted Faces into a new Volume
   Group inside a new Space Group in the Zone's entities, writes the three record kinds and the
   Zone stamp on the Space Group, numbers the Space with the next free number in the Zone, and
   takes the height from the Space default per Q7. Adapt `preview.rb` and
   `operations/creation.rb`; the designPH acceptance test is replaced by the list above. The
   operation takes explicit references and reads no `active_path`.
8. **Volumes and floors.** `volumes.create`, `volumes.update`, `volumes.remove`, `floors.mark`,
   `floors.unmark`, `floors.update`, as proposal handlers. `floors.mark` on an already marked
   Face updates its factor. Adapt `operations/editing.rb`.
9. **Update, batch and delete.** `update` with `expected_values`; an airflow key present with a
   number sets it, present with the clear marker removes it, absent leaves it. `batch_update`
   validates every target and writes all or none in one Undo step. `delete` removes the Space
   Group. Adapt `operations/editing.rb` (`update_space`, `batch_update`, `delete_space`,
   the draft-stale check).
10. **Height default (Q7).** `settings.get` and `settings.update` on the Model settings
    primitive; a height edit records the last value entered; a new Space's default height is that
    value, else 2.5 m.
11. **Reads.** `list` and the `spaces` snapshot section return canonical SI values, references,
    states and findings. Ruby formats no unit-bearing text. Adapt `snapshot.rb` and `names.rb`.
12. **Walkthrough and reference.** `tools/examples/authoring/spaces_walkthrough.rb`: panel
    closed, discover, create a Space from three Faces in a Zone, add a second Volume, mark one
    Face as Does not count, set a height and two airflows, clear one, read back, recover from a
    stale edit. Regenerate `docs/API_REFERENCE.md` with `make fixtures`.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `features/spaces/attrs.rb`, `names.rb`, `entries.rb`, `transforms.rb`, `index.rb` | 387 | Port onto `EntityStore`; add the Zone stamp, airflows and `user_data` |
| `features/spaces/identifiers.rb` | 18 | Drop (D3a-2) |
| `features/spaces/designph.rb` | 47 | Drop |
| `features/spaces/scan.rb`, `metrics.rb`, `snapshot.rb`, `findings_index.rb` | 297 | Adapt; projected area and the any-set rule are new |
| `features/spaces/validation.rb` | 179 | Adapt; every designPH rule goes |
| `features/spaces/preview.rb`, `operations/creation.rb`, `operations/editing.rb` | 469 | Adapt to proposal handlers and explicit references |
| `features/spaces/actions.rb`, `spaces.rb` | 251 | Replace with declarations and `install` |
| `tests/attrs_test.rb`, `index_test.rb`, `names_test.rb`, `transforms_test.rb`, `scan_test.rb`, `metrics_test.rb`, `snapshot_test.rb`, `validation_test.rb`, `space_creation_test.rb`, `space_editing_test.rb`, `space_preview_test.rb`, `support/space_fixtures.rb` | about 1,300 | Port with the code; `designph_stub.rb` is not ported |

## Tests (write first)

1. Schema round trip for each record; an unknown key is unreadable; airflow absent, 0 and a
   value are three distinct stored states.
2. `create` under a rotated wrapper Zone: areas, world positions and paths are correct; the
   stamp matches the Zone; one Undo step.
3. `create_preview` names each left-out Face with its reason and writes nothing.
4. A multi-Volume Space with two heights: net volume is the sum.
5. A sloped Face: area is the projected area and `space.floor_projected` is raised.
6. The any-set rule: all unset inherits; one set makes the other two read zero in metrics;
   clearing the last returns to inheriting.
7. Stale `expected_values` refuses with nothing written. A batch with one bad target writes none.
8. `user_data` and an unavailable extension payload survive every edit in this stage.
9. Every finding in step 6 from a minimal fixture; the reference model's hand-calculated totals
   in [ACCEPTANCE](../ACCEPTANCE.md).
10. Every registered operation has schemas and a validating example.
11. The walkthrough runs as written and names no feature module.
12. The dependency-direction test of step 1.

## Host gate

Fresh process, panel closed: run the walkthrough through the bridge, then native Undo and Redo
across each step, save, reopen in a fresh process and read the records back. Confirm with the
Zones / Faces table that no Floor Segment appears as a Zone Face (P3a-01's rule, now with a real
Space). Two Models with the same synthetic ids stay isolated. Record what a native copy and a cut
and paste of a Space Group do to its dictionaries; the result feeds P3a-04.

## Out of scope

Locking, edit contexts, the reconciler, recovery of moved Volumes (P3a-03). Copies and Move Space
to Zone (P3a-04). Any screen or tool (P3a-06, P3a-07). The balance read (P3a-08). Export (P3a-10).

## Done when

- S02 has evidence in `evidence/p3a-02-space-records.md`.
- `make ci` passes on both Rubies; the generated API reference is current.
- CONTRACTS records the finding-code mapping; the Spaces STATUS records the delivered scope.
