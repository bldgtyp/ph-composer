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
