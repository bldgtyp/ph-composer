# Packet 7: Library

DATE: 2026-10-03
STATUS: Implemented; pull request open
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Covers findings L1, L2, L3 and K11 and ruling D5 in [FINDINGS.md](../FINDINGS.md). The decisions
taken are listed for Ed's verification pass.

## Outcome

The Library tab's sidebar earns its width, a provider's record says how it gets into the file, a
record form says what it is waiting for, and New Assembly makes an Assembly. No command, payload,
guard or Undo step changes.

## What is there today, re-measured on main

| Finding | On main today |
| --- | --- |
| L1 the sidebar repeats the table | True on every Library tab that has one (Materials, Frames, Glazings, Psi-Install Types). With "In this file" chosen it lists the records of the table beside it |
| L2 nothing says how to copy a provider's record in | True. A provider row opens a card whose last button is "Add to file"; the row gives no hint of that |
| L3 New Material opens with Create disabled and no sign of why | True. Only a name is required. The reason appears only if the form is submitted, which a disabled button prevents |
| D5 New Assembly opens a form | True: name, Type, Exterior and Notes, though the Builder edits all four |
| K11 "Add library file…" carries a check mark; a provider that is not a file has no state | True |

## Design

**Sidebar beside a table (L1).** A sidebar that stands beside the table of the same records takes
a `besideTable` option. With "In this file" chosen it shows one line in place of the list:
"These records are in the table. Choose a library above to copy records from it." Its search and
count are hidden with the list. With a library chosen it works as it does now. Sidebars in the two
Builders and the Installs editor do not set the option: there the local list is the palette.

**Provider rows (L2).** A row from a library ends in a small plus glyph and its tooltip reads "Add
<name> to this file". The click still opens the record's card, where "Add to file" stays the
commit; the card is where a duplicate is reviewed.

**Required fields (L3).** A shared `forms.required(control)` marks a control's label with a muted
"required" and sets `aria-required`. The record forms use it on Name. While a form's Create is
disabled, its status line says why ("Enter a name."), where today it is blank.

**New Assembly (D5).** "+ New Assembly" creates "Assembly 1" (the first free number) through the
same create action and opens it in the Builder with its title selected for renaming. The form and
its dialog go. A refusal shows in the panel's notice like any refused edit.

**Library setup (K11).** "Add library file…" and "Add library folder…" lose the check mark. A
provider that is not a file or folder reads "Added by an extension" where a file has Remove.

## Decisions taken

| Id | Question | Decision |
| --- | --- | --- |
| P7-Q1 | Collapse the sidebar on the Library tab instead of showing a line of text? | No. Collapsed, nothing says a library can be chosen there. The line says it and keeps the source select in view. |
| P7-Q2 | Copy a provider's record in with one click on the row? | No. The card shows what will be copied and whether the file already has it; skipping it hides a duplicate. The row only says where the click leads. |
| P7-Q3 | Should New Material also act at once? | No. D5: a Material is only numbers, and a Material with no conductivity makes every Assembly using it incomplete. It keeps its form. |

## Files

`src/ph_composer/html/library/`: `sidebar.js`, `rows.js`, `setup.js`, `library.css`.
`src/ph_composer/html/inventory_forms.js`. `src/ph_composer/html/features/assemblies/`:
`section.js`, `form.js`, `material_form.js`, `materials.js`.
`src/ph_composer/html/features/windows/inventory.js`,
`src/ph_composer/html/features/zones/attached_zone_fields.js`. The ui-polish skill states the D5
split. Then the manifests.

## Tests and gates

- Sidebar: the hint replaces the list beside a table and not elsewhere; a provider row carries the
  glyph and tooltip.
- Forms: the required mark and the reason line.
- Assemblies: New Assembly sends one create with the first free name and opens the Builder on the
  new record.
- `make ci`, `make ui-checks`, one Sonnet diff review, a host check through the development bridge.

## Not in this packet

Empty states and one vocabulary for "not finished" (packet 8).

## Outcome, 2026-10-03

Implemented on `feat/ui-library`. `make ci` and `make ui-checks` pass.

What differs from the plan above:

- The required mark is `RecordForm.required(label, control)` in `record_form.js`, re-exported by
  `inventory_forms.js`, since the record forms depend on the first and not the second.
- The Psi-Install Types tab keeps its local list. There the list also sets the Model default, so
  it is not a repeat of the table.
- With no library set up, the line beside a table says to add one with Library setup; "Choose a
  library above" would point at a select with one entry.
- A provider that is not a file or folder reads "Added by another tool". "Extension" in the
  glossary means PH-Composer itself.
- New Assembly opens the record the create's outcome names, not the first record that was not there
  before, so a record added by something else in the same moment is never opened by mistake.

One Sonnet diff review ran against the architecture and ui-polish rubrics. Applied: the wrong
record opening when another record arrives during the create, the dead end with no library set up,
a refusal left on screen while the user edits the Material form, an unparsable entry shown in the
hint tone, two owners for the required mark, the unreachable Psi default route, the ambiguous
"extension". Not taken: returning focus to New Assembly after a refused create.
