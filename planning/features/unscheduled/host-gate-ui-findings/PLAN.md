# UI findings from the R11 host gate: implementation plan

DATE: 2026-10-02
STATUS: Implemented on branch `feat/host-gate-ui-findings` 2026-10-02, all five items; `make ci` passes on
Ruby 2.7.2 and 3.2.2. In review. The host look (Verification) is owed, including item 3's Save-sheet cases.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/37

Read [README.md](README.md) for the five findings. Each item below gives the traced cause, the change,
its tests and its open questions. Root causes were read from `main` at 6e3f5b0; none was reproduced
offline yet, and the first step of each item is a failing test.

Load `.agents/skills/ph-composer-ui-polish/SKILL.md` before starting. One branch, one commit per
item, `make ci` and `make ui-checks` at the end, one short host look (Verification).

## Decision

Decided 2026-10-02 by Ed, as recommended, together with agent-authorized-file-access D6.

**D1 (item 3). Is the macOS Save sheet enough consent to replace the file it names?**
Recommendation: yes. A second question appears only for a companion file the sheet did not name: the
Export report beside an HBJSON, when the report exists and the `.hbjson` does not. When the `.hbjson`
exists, the sheet's consent covers the pair, because the report is documented as the HBJSON's
companion and is always written with it. Other platforms keep today's message box until the Windows
packet checks `UI.savepanel` there. This is the same rule as
[agent-authorized-file-access PLAN.md](../agent-authorized-file-access/PLAN.md) D6; whichever packet
lands first owns it, and the other reuses it.

Alternative: keep asking whenever the companion exists, even when the sheet already asked about the
`.hbjson`. Safer for the report, at the cost of the double question for HBJSON only.

## Item 1. A disabled primary button looks active

**Cause.** `actionRow` (`html/overlay.js:256`) marks its second button `primary phc-action-apply`.
`overlay.css:217` styles `.phc-workspace .phc-dialog-actions .primary` with the accent fill. The
disabled rule `.phc-workspace .primary:disabled` (`base.css:142`) has the same specificity (0,3,0),
and `overlay.css` loads after `base.css` (`index.html:7-8`), so the accent fill wins. The same holds
for `.phc-dialog-actions .phc-action-delete` (`overlay.css:218`): a disabled destructive button stays
red. Every `actionRow` in the app is affected, not only the Libraries dialog.

**Change.** In `overlay.css`, directly after the hover rule at line 256, add one disabled rule for the
dialog action row that covers both `.primary` and `.phc-action-delete`, using the same values as
`base.css:142`. Its specificity (0,4,0) wins regardless of load order. The `✓` and trash glyphs follow
`currentColor` and grey out with it. No JavaScript change.

**Tests.**
- `tools/ui-preview/fixtures.js` has no `ph_composer.library.provider_setup` section today; add one
  the check can set to `unreadable` (the dialog reads it, `html/library/setup.js:31`).
- `tools/ui-preview/library_checks.cjs`: open the Libraries dialog with the fixture's setup state set
  `unreadable`; assert "Add library file…" is disabled and its computed background is not the accent
  color, and that it matches "Add library folder…".
- Same file or `preview_checks.cjs`: a disabled destructive dialog button computes a non-red
  background (pick any form dialog the preview can disable, such as a Delete confirm while its
  request is pending).
- `tests/css_selectors_test.js` needs no change; the rule uses existing class names.

**Follow-up, not in scope.** "Add library file…" carries the apply `✓` because `actionRow` treats it as
the confirming action, though it opens a picker. Record in the Verification notes for Ed; changing
the Libraries dialog's action layout is a separate polish decision.

## Item 2. The export form shows internal codes

**Cause.** `html/library/export.js:73-79` prints `kind.kind` (the wire kind, e.g. `materials`),
`omission.record_kind` (e.g. `ph_composer.windows.frame`), the reason code and raw field keys. One
line is written per omitted record, so a Model with several Frames repeats the same line.
`ExportProjection` (`library/export_projection.rb:22,31,35`) emits three reason codes:
`unsupported_kind`, `fields_not_in_wire_schema` and `origin_identity_unavailable`.

**Change.**
- Server, `library/export_projection.rb` `summary` and `export_registration.rb` `summary_fields`:
  add `record_kind_label` to each `kinds` row and each omission, from the registered record kind's
  `label` (the glossary owner). The stored codes stay the data contract. `make fixtures` regenerates
  `docs/API_REFERENCE.md`; describe the new field.
- View, `html/library/export.js`: map at the view edge.
  - Counts: "Materials: 4", "Frames: 2" from `record_kind_label`.
  - Omissions grouped by `record_kind` and `reason`, one line each, with a count when more than one
    record: "Frame (3): source attribution is not exported".
  - Reason sentences, one table in `export.js`:
    `unsupported_kind` → "not a library record; it stays in this Model",
    `fields_not_in_wire_schema` → "not exported: " plus field words, where `source` reads
    "source attribution" (the glossary term, `context/UBIQUITOUS_LANGUAGE.md`) and any other field
    reads "some fields" (the keys go in the line's tooltip, as the
    polish skill allows ids in tooltips),
    `origin_identity_unavailable` → "library origin is not exported".
  - An unknown code shows "not exported" with the code in the tooltip, so a contributor's new reason
    never breaks the form.
- The README's suggested wording "provenance" is replaced by the glossary's "Source attribution".

**Check first.** `export_projection.rb:30-31` reports `source` as an omitted field for every record
that has one, and lines 32-34 then export a library-sourced record's origin in `record_origins`. For
those records "source attribution is not exported" is false. Recommendation: the projection stops
reporting `source` as omitted when it recorded an origin for that record, so the sentence holds for
the rows that keep it (hand entry and derived records, whose attribution really is dropped). Confirm
against a library-copied Frame before choosing the wording.

**Tests.** `tests/library_export_form_test.js`: a preview with two Frame omissions of the same reason
and one Window Type omission renders two lines, neither containing `ph_composer.` or an underscore
code; an unknown reason renders "not exported". A Ruby test in `tests/library_export_test.rb`
asserts `record_kind_label` is present and comes from the registered kind.

## Item 3. Export over an existing file asks twice

**Cause.** `shell/native_approval.rb:79` (library export, after `UI.savepanel`) and
`export/workflow.rb:51` (HBJSON) each call `UI.messagebox` when the chosen path exists. On macOS the
Save sheet has already asked.

**Change (per D1).**
- One function, `NativeApproval.confirm_replace(path, companions: [])`, owns the rule. On macOS
  (`Sketchup.platform == :platform_osx`) it returns true without asking when only `path` exists, and
  asks once, naming the companion ("Replace the Export report beside it?"), when only a companion
  exists. Elsewhere it keeps the current question.
- `NativeApproval.save_destination` and `Export::Workflow.consent` both call it; HBJSON passes
  `ArtifactPair.report_path(destination)` as its companion.
- `replace` in the resulting consent is unchanged in meaning: true when anything will be replaced.

**Tests.** `tests/file_export_test.rb` and `tests/panel_test.rb` (which drives the HBJSON workflow's
dialogs through `tests/support/sketchup/ui.rb`): on a stubbed macOS platform an
existing destination calls `UI.messagebox` zero times and yields `replace: true`; a companion-only
case calls it once; a non-macOS stub keeps one call.

**Host check required.** In SketchUp on macOS: export a library over an existing file (one prompt,
the sheet's), export HBJSON over an existing pair (one prompt), and over a lone report (the sheet
does not ask, the companion question does).

## Item 4. The menu's library add says only "Done."

**Cause.** The setup command returns the provider list, and `Dispatch#answer` builds
`Outcome.completed` with its default message "Done." (`shell/outcome.rb:24`). The Libraries menu
shows that message (`library/setup_commands.rb:47`). The panel route does not, because the dialog
clears the message and repaints the list.

**Change.** In the menu block, read `Setup.providers` ids before calling `NativeApproval.setup`; on
completion find the added row in `outcome["value"]` and notify "Added library <label>." Keep the
outcome message for every other status. The change stays in the Library feature; no foundation
message hook is added for one caller.

Note: a folder's label falls back to the folder name (`setup_commands.rb:120,125`), so the notice can
show a folder name. That is the leak recorded as D4 in the
[agent-authorized-file-access plan](../agent-authorized-file-access/PLAN.md); this item does not
change labels.

**Tests.** `tests/library_setup_commands_test.rb`: the add menu item with a stubbed picker notifies
"Added library <label>." with tone info; a refusal still notifies its own message with tone warning;
cancel notifies nothing.

## Item 5. The uses bubble counts one element but lists four rows

**Cause.** `Graph.uses` (`features/windows/types/graph.rb:46`) emits one use per element side, named
`Type / Element / side`. `Snapshot#product` counts distinct `[type_id, element_id]` as
`element_use_count` (`features/windows/snapshot.rb:119`). The bubble (`html/features/windows/inventory.js:81`)
prints that count, as "1 element uses", above one row per side.

**Change.** Group in the view; the snapshot contract (one use per side, which navigation and delete
guards rely on) stays.
- `Inventory.prototype.uses` groups `record.uses` by `type_id` and `element_id`. One row per element:
  "R11 type / Element" with the sides beneath in glossary words ("Top, right, bottom, left"; check
  the labels the Window Types editor already shows for sides and reuse them). An inherited
  Psi-Install side keeps its "(default)" marker on that side.
- The Model default row (`kind: "model_default"`) stays its own row.
- Heading: "Used by 1 element", "Used by 3 elements", plus "and the Model default" when that row is
  present. The trigger count stays `element_use_count`, now equal to the rows listed apart from the
  Model default.
- "Open type" on a grouped row navigates with the element's first side, as today.

**Tests.** `tests/window_inventory_test.js`: a Frame used on four sides of one element renders one
row with four sides and the heading "Used by 1 element"; two elements render two rows; a Psi-Install
Type that is also the Model default renders the extra row and heading clause; Open type navigates
with that element.

## Verification

- Focused tests above; `make ci`; `make ui-checks` with the updated library checks.
- `make ui-preview` captures at 1280 and 420 px: Libraries dialog with an unreadable setup (item 1),
  the Export library form with grouped omissions (item 2), a Frame uses bubble (item 5).
- Host look in SketchUp, through the `ph-composer-native-acceptance` skill: the same three screens,
  the menu add notice (item 4) and the three Save-dialog cases (item 3). Record the result in
  `planning/native-acceptance/evidence/` and link it here.
- Review: one Sonnet diff review with the architecture and UI polish rubrics.

## Implementation record

Implemented 2026-10-02 on `feat/host-gate-ui-findings`, one commit per item plus a manifest refresh.

| Item | Change | Tests |
| --- | --- | --- |
| 1 | One disabled rule for `.primary` and `.phc-action-delete` in the dialog action row (`overlay.css`) | `library_checks.cjs`: the preview host now publishes `ph_composer.library.provider_setup`; an unreadable setup disables "Add library file…", and its disabled fill differs from the enabled one in both the apply and destructive roles |
| 2 | `record_kind_label` on each `kinds` row and omission (`ExportProjection.summary(projection, registry)`); `export.js` groups omissions by kind and reason with glossary sentences; codes and field keys in the tooltip. A recorded origin no longer reports `source` as omitted | `library_export_test.rb`, `library_export_form_test.js`, `windows_checks.cjs` |
| 3 | `NativeApproval.confirm_replace(path, question, companions: {})`, per D1, used by the library export and `Export::Workflow.consent` | `file_export_test.rb`, `panel_test.rb` (macOS lone report, Windows pair), `library_export_test.rb` |
| 4 | The Libraries menu notifies "Added library <label>." on completion (`setup_commands.rb`) | `library_setup_commands_test.rb` |
| 5 | The uses bubble groups per-side uses by element, sides beneath, heading counts what it lists; a Model-default-only Type reads "Used as the Model default" | `window_inventory_test.js` |

Deviations from the text above, each the simpler choice:

- Item 2 counts read "Material: 2", "Frame: 2", not "Materials: 4". The registry holds singular labels
  only, and a pluralizing rule would mislabel a contributor's kind.
- Item 3's signature takes the whole-set question and a `{ path => question }` companion map, so each
  caller keeps its own wording; the macOS companion question reads "Replace the existing Export report
  beside this HBJSON?".
- Item 1's check compares disabled against enabled fills rather than against the secondary button:
  `base.css` gives a disabled primary its own grey, which the new rule reuses.

Verification run: `make ci` (Ruby 3.2.2 and `RUBY=$(rbenv prefix 2.7.2)/bin/ruby`), `make fixtures`
(API reference gains `record_kind_label`), `make runtime-manifest`. `make ui-checks`: every script passes
except an intermittent `windows_checks.cjs:46` failure ("Element 1 glazed" detached during
`scrollIntoViewIfNeeded`), which `main` shows at the same rate (3 of 20 runs) and is left as a follow-up. Preview captures: Libraries dialog with an unreadable setup, Export library
form with grouped omissions, Frame uses bubble at 1280 and 420 px.

Owed before acceptance: the host look through `ph-composer-native-acceptance` (items 1, 2, 4, 5), and
item 3's three Save-dialog cases on macOS, which need Ed at the host. Add a fourth: type the name
without `.hbjson` over an existing pair, to confirm the sheet checked the path SketchUp returns, since
macOS now asks nothing more when that path exists.

Review: one Sonnet diff review with both rubrics found no confirmed defects. Applied: the uses bubble
reads the side from `use.side` rather than parsing the name alone, and the origin reason reads "library
source attribution is not exported". Not applied: asking about the report when the pair exists (D1). Follow-up for Ed, not in scope:
"Add library file…" carries the apply ✓ although it opens a picker.
