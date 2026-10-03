# UI findings from the R11 host gate

DATE: 2026-10-02
STATUS: Complete. Merged to main 2026-10-02 (PR #40, merge commit `58b347c`); host check passed 2026-10-02
([PLAN.md](PLAN.md), "Implementation record"). Archived. Five small UI findings from the R11 carried host gate; none failed a check.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/37

Observed in real SketchUp on 2026-10-02
([evidence](../../native-acceptance/evidence/r11-host-gate-2026-10-02.md)). Each is small. Work
them with the UI polish skill, together or alongside the next Library or Window Types screen change.

1. **A disabled primary button looks active.** In the Libraries dialog with an unreadable setup,
   "Add library file…" refused clicks but kept the primary teal fill and check icon, while the
   secondary "Add library folder…" greyed out. The fix belongs in the UI kit's primary/apply button
   styles, so every disabled primary button reads as disabled.
2. **The export form shows internal codes.** The Export library form lists omissions as
   `ph_composer.windows.frame: fields_not_in_wire_schema (source)` and
   `ph_composer.windows.window_type: unsupported_kind`. Show the kind's label and a plain reason
   ("Frames: provenance is not exported", "Window Types are not library records").
3. **Export over an existing file asks twice.** macOS's Save dialog asks "already exists. Do you want
   to replace it?", then `NativeApproval` asks "Replace the existing file?". The second question
   repeats the first. Decide whether the native sheet is sufficient consent on macOS; the HBJSON export
   shares the same path.
4. **The menu's library add says only "Done."** Adding a library folder from Extensions →
   PH-Composer → Libraries showed "Done." in the panel. Name what was added ("Added library r11").
5. **The uses bubble counts one element but lists four rows.** A Frame used on all four sides of one
   element shows "1 element uses" above four "R11 type / Element / side" rows. Count what is listed,
   or group the sides under the element.

## Verification

Focused panel tests for 1, 2, 4 and 5; `make ui-checks`; a short host look at the dialogs. Item 3
needs a host check of the Save dialog on macOS.
