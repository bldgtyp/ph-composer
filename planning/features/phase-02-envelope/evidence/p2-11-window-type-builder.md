# P2-11 evidence: Window Type Builder

DATE: 2026-10-01
STATUS: Source implemented; focused and browser checks pass. Independent review closed; native acceptance in progress.

The panel now has Window Types and U-Values peer tabs, the type list and dimensioned element
drawing, guarded grid commands, element product cards and an Installs session with local staging.
Shared internal edges are unpaintable. Save sends one registered action; Cancel sends none.
Library contains Frame, Glazing and Psi-Install Type inventories and model defaults. The type
depth override clears through the existing null patch. In this file product selection is active;
provider sources await P2-15. Place remains disabled pending its owning stage.

Thermal headlines and audit rows consume Ruby projections. The browser fixture supplies synthetic
canonical results and performs no UI calculation. Dimension edits use the shared unit field and
retain typed drafts across unit changes. Navigation and withdrawn snapshots guard pending edits.

The focused suite passes 56 JavaScript tests with clean scoped ESLint. The Window browser script
passes 1280, 900, 420 and 280 pixel widths, including drawing selection, Installs local staging
and Save, audit, product creation, defaults and overflow. Logs are `/tmp/phc-p211-focused.log`,
`/tmp/phc-p211-lint.log` and `/tmp/phc-p211-browser.log`. These prove browser behavior only.

The independent UI review reproduced and closed two draft defects. A rail rename input was
discarded on refresh while its navigation guard remained active; keyed drafts now survive and
withdraw explicitly when the target disappears. An Element name draft could disappear when
changing types; it now guards navigation and dismissal until Apply or Cancel. Focused regressions
and independent direct probes pass. The immediate-response export form also retains refusal text
and an enabled Cancel. The combined Window/export browser script passes all four widths.

Both Ruby full shipping gates pass on `d812540`; all seven browser scripts and Chromium 88
pass. Tests-only checkpoint `7afe894` closes JavaScript coverage at 94.8%, with 33 focused
Window/CSS cases and clean scoped ESLint. Ruby coverage is 96.5%; Python is 94.98%.

Installed `7afe894` is byte-exact, fresh SketchUp 26.1.188 / Ruby 3.2.2, PID 3593, bridge
55228, session `83a48fca-0d70-4fca-b0fc-0225c9112e5d`. Fixture `p209-p211-native.skp`
started unmodified at root edit path, with one Window Type and one of each Window product.
The E11 ledger baseline was captured before gestures. Native creation and inline rename each
restore the complete public Window Type inventory through one Undo and one Redo. Private
`e11-create-rename-proof.json` records four exact comparisons, all true. An explicit-unit band
edit `1200 mm` visibly commits as 1.2 m. Remaining Builder gestures and their Undo checks are
still in progress. No E11 acceptance is awarded.


## Native Builder workflow on installed 7afe894

The real panel built a 2.2 m by 1.5 m type with three columns, two Glazed elements and one
Empty. Gestures covered two insertions, Empty confirmation, keyboard multi-selection, merge,
split, explicit-unit band edit, four Frame assignments, Glazing, Fixed operation, eyedropper
paste, repeat paste, horizontal flip, perimeter Installs staging and Save, thermal audit,
Window Type duplication and Frame duplication/replacement. The replacement rewrote all 24
Frame references across three types. Repeat paste made no second commit. Staging Installs
changed neither inventory nor revision; shared internal edges remained zero and unpaintable.
The audit displayed U-w 0.805 and installed U 0.906, Glazed gross area 2.55 m² and Empty wall
area 0.75 m². These are Ruby projections displayed by the real panel.

Eighteen subsequent native Undo gestures and eighteen Redo gestures were observed through a
tools-only ModelObserver that recorded the public product and Window Type inventories after
each native transaction. `e11-native-journal-proof.json` has 38 exact comparisons, all true,
including replacement and its references. Creation/rename had already passed their own four
exact comparisons. The fixture is saved as `p209-p211-native.skp`; fresh reopen is still pending.

This workflow exposed a form visibility defect: Duplicate/Delete hid numeric UnitField spans
but left their labels. Backend quantities copied correctly. The owned-label correction and a
reproducing regression pass eight inventory tests and scoped ESLint. It must be packaged and
rechecked natively before E11 closure. No structured E11 award is made from this partial run.
