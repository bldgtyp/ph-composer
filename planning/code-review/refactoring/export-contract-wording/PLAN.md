# Export contract wording plan

DATE: 2026-10-13
STATUS: Implemented on branch `refactor/export-wording-ew-01` (2026-10-13). Stage ledger in [STATUS.md](STATUS.md).
ISSUE: https://github.com/bldgtyp/ph-composer/issues/98
BASELINE: `cfe01a6aad99a0e09d5ecf0de5659c606d7ba4f9`
FINDING: [F08](../../sections/06-export.md#f08-some-operation-schemas-incorrectly-promise-verbatim-metadata-export)
DEPENDS ON: nothing. Lands on its own.

## What is wrong

Three declaration constants describe `user_data` as "exported verbatim". The export reader never
exports arbitrary `user_data`: `Export::RecordReader#omit_metadata` records
`export.metadata_omitted` for every record that carries any, for catalog and entity records alike.
The constants feed every create, update and place schema in their features, and the generated
`docs/API_REFERENCE.md` repeats the false sentence sixteen times.

The review plan named two constants. There are three.

| Constant | File | Used by |
| --- | --- | --- |
| `Zones::Faces::Registration::USER_DATA` | `src/ph_composer/features/zones/declarations/faces.rb` | Attached zone create and update params |
| `Assemblies::Shapes::USER_DATA` | `src/ph_composer/features/assemblies/declarations/shapes.rb` | `Shapes.create` and `Shapes.update` for Materials and Assemblies |
| `Windows::Shapes::USER_DATA` | `src/ph_composer/features/windows/declarations/shapes.rb` | `Shapes.create`, `Shapes.update` for products and Types, and Unit `place` |

Verified at the baseline with `grep -rn verbatim src docs context`. Nothing under `docs/` other than
the generated reference, and nothing under `context/`, repeats the promise. `context/CONTRACTS.md`
"Records and extension data" and `context/EXTENSIBILITY.md` "Metadata and structured extension
data" already state the correct policy; neither changes.

## The correction

Replace the description in all three constants with one sentence:

```ruby
USER_DATA = { "type" => "object",
              "description" => "Local JSON metadata kept with the record in the Model. Export needs an " \
                               "explicit mapping; arbitrary metadata is left out with a finding." }.freeze
```

Keep the type, the shape, the `optional` placement and every example unchanged. The three constants
stay separate: each feature's `Shapes` module extends `SchemaShapes` with its own constants by
design (`context/EXTENSIBILITY.md`, "Organization and dependencies"), so this is not an invitation
to hoist a shared constant into `core/schema_shapes.rb`.

## Stages

One stage. It is a shipping Ruby source change whose only observable effect is documentation.

### EW-01: correct the three descriptions and regenerate the reference

State: Implemented on branch `refactor/export-wording-ew-01`, 2026-10-13.

1. Edit the three constants above to the new sentence. Line wrap at the 120 column ceiling as the
   neighbours do.
2. Run `make fixtures`. `tests/api_reference_test.rb` owns `docs/API_REFERENCE.md`; the regenerated
   file must differ only in the sixteen description strings. Inspect the diff with
   `git diff --stat docs/API_REFERENCE.md` and `git diff docs/API_REFERENCE.md | grep '^[-+]' | grep -v description`
   which should print nothing but the diff headers.
3. Run the focused checks:

   ```sh
   make lint-ruby
   "$RUBY" -Itests -rapi_reference_test -rwindow_records_schema_test -rassembly_records_schema_test -e ''
   grep -rn "exported verbatim" src docs context tools   # must print nothing
   make fixtures-check
   ```

4. Commit the three source edits and the regenerated reference together. The commit message says
   the descriptions were wrong, not that export behaviour changed.

Exit: the grep prints nothing, `make fixtures-check` passes, and no test other than the reference
golden changed. If any schema test fails, a constant's shape changed by accident; revert and redo.

## Decisions

The coding agent decides the exact line wrapping. Nothing here needs Ed.

Not in scope: exporting `user_data`, any reader or serializer change, any quickstart edit (none
contradicts the policy), and any `context/` edit. If an implementation finds it must change
behaviour to make the wording true, stop: that belongs to
[entity customization](../entity-customization/PLAN.md).

## Verification profile

Documentation consistency only: the focused commands above and the final `make ci` on the coherent
head this lands with. No native gate. The [acceptance rows](ACCEPTANCE.md) are the checklist.
