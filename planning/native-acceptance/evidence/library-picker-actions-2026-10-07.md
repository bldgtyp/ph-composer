# Libraries picker action acceptance

DATE: 2026-10-07
STATUS: GH43 passed on the current macOS host
ISSUE: [#43](https://github.com/bldgtyp/ph-composer/issues/43)

The current dialog already uses equal Library file / Library folder routes with no apply glyph.
This replaces the older action-row layout that prompted the issue. Done closes a dialog whose
changes apply immediately. No additional screen implementation was needed.

| Assertion | Observed outcome |
| --- | --- |
| Readable setup | Native Library > Library setup > Add a library showed equal unfilled file/folder route cards, no check marks, and Done. The file route opened the native Add library file picker; native Cancel returned without a Model write. |
| Unreadable setup | A private process-only override of the setup reader returned an unreadable empty store. Native pixels showed Reset library setup and Done, with both picker routes absent. Reset was not clicked; real preferences were never overwritten. |
| Normal restoration | Fresh process with the normal RBZ and no fault helper restored readable setup and the original provider. Native pixels confirmed its dialog. Preferences fingerprint matched before/after; Model remained unmodified, with a new session. |

Host: SketchUp 26.1.188 / Ruby 3.2.2; native `cua_repl` controls and separate bridge readbacks.
Source: `main@727c2ba`; shipping bytes match the offline-verified #42 source.
Installed RBZ SHA-256: `551290344ae971f4abebd8235aa2f45e2ce8a3d930ac7105c7354f11dfa80dfb`.
All 390 packaged files match, with no mismatches or extras.

Private fixture, immutable baseline, helper, PNGs, readbacks and observation receipt are in
`_private/host/issue-sweep/issue43/`. The baseline was captured before expanding the picker routes;
the unreadable override is explicitly synthetic and was removed by restart. The normal fixture
remains open and unmodified. No unrelated Model was open at intake.
Nine setup tests, focused consistency review and independent architecture/UI/provenance review
passed with no findings. Prior unchanged full offline gates
are reused; the issue PR still runs the required dual-Ruby CI. No human action was needed.
This is current-host acceptance, not SketchUp 2023, Windows or public-release evidence.
