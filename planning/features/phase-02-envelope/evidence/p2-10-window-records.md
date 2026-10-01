# P2-10 evidence: Window records and calculations

DATE: 2026-10-01
STATUS: Implemented in source and independently reviewed. Focused dual-Ruby checks pass; integrated and native gates open.

Windows owns version-1 Frame, Glazing, Psi-Install Type and Window Type catalog kinds. The products
and Types contain no Zone or Face references. Registered product references cover Glazing, all four
Frame sides and perimeter installs. The Model settings reference target participates in incoming
reference checks and guarded Psi-Install deletion/replacement.

The focused source gate passes 27 tests / 616 assertions on Ruby 2.7.2 and 3.2.2. Rubocop passes on
24 owned files. Thirty-six public operation declarations cover record authoring, nine grid
operations, model defaults and atomic Installs sessions. Thermal calculations retain missing values
and use a synthetic hand-calculation fixture. A staged-product name collision refuses the complete
Installs proposal.

The public walkthrough builds product definitions and a Type through seven guarded commits.
It has offline proof; native execution, exact Undo/Redo and fresh save/reopen remain required.
No placed unit, aperture export, provider adapter or Window UI is implemented by this stage.

Model defaults initialize `default_psi_install_id` to null and `default_install_depth_m` to 0.0 m.
A missing Type depth override inherits that explicit Model value. Initial dimensions follow the
predecessor's SI 1.0 by 1.5 m and IP 1.016 by 1.524 m.

The core ModelSettings promotion preserves Zones' existing storage and effective-value guards.
Generic Records::AuthoringFields replaces the implementation behind an exact Assemblies alias.
Their affected compatibility checks pass 37 tests / 306 assertions on both Rubies. These focused
checks do not claim that the current source is installed or fully gated.

Independent review found no confirmed defect in the coherent backend. It traced product replacement
through nested references and the Model default, rollback, grid coverage, staged Installs, stale
settings and unavailable extension preservation. The reviewer independently repeated all 27 tests
and 616 assertions on both Rubies. Native Undo/Redo and save/reopen remain explicit gates.

Integrated dual-Ruby gates, coverage, runtime/browser checks and exact installed checkpoint are
recorded in [P2-08 evidence](p2-08-library-sidebar.md#integrated-checkpoint). Native proof remains open.

## Current-host record proof

Fresh SketchUp 2026, installed `146076e`, panel closed: the public walkthrough commits all seven
synthetic gestures and reads complete U_w 0.78704 and U_effective 0.8803733333 W/m²K. Seven native
Undo steps restore the exact empty inventories; seven Redo steps restore all four final inventories
and computed results. Save and fresh-process reopen preserve them exactly. Private proof:
`windows-walkthrough.json`, `windows-native-roundtrip.json`, `library-windows-reopen-proof.json`.
The saved Phase 1 Zone-settings compatibility check remains open before E10 is closed.

The saved mainline Phase 1 fixture `pr3-handoff.skp` (archived proof identifies build `b2dd8b2`)
opens unmodified under this checkpoint. It has no authored Zone-settings dictionary; the public
read returns the preserved effective defaults (Suggest true, Roof 60 degrees, Floor 130 degrees)
without creating one or dirtying the Model. Private `mainline-settings-compat.json` records both
raw absence and the public result. Non-default settings/preimage behavior is covered by the
focused shared-primitive tests. This is current-host compatibility evidence, not a 2023/Windows claim.
