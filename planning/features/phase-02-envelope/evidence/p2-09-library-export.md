# P2-09 evidence: library export, starter and outside provider

DATE: 2026-10-01
STATUS: In implementation; focused starter proof recorded, export and outside-provider gates open.

The export command is being added as a generic registered FileExport under the existing export
grant. It carries no Model mutation sequence or Undo operation. The public interface accepts
explicit all/selected scope and new/update identity, while native save and review controls own
the destination. Reverse mappings publish local IDs and only declared wire properties. An
optional `record_origins` envelope section carries informational allowlisted source IDs and a
provider-kind label, never private setup or source snapshots. The reader ignores this section;
semantic fingerprints remain unchanged. Backend implementation is frozen: both Ruby versions pass
146 affected tests and 845 assertions, including actual file-provider load/copy into a fresh Model,
invalid update destination semantics, cancellation, stage ownership and destination preservation.
Scoped RuboCop passes twelve files. The independent backend/transport review is in progress.

The panel carries FileExport results in a separate session-correlated slot. Both Ruby versions
pass 29 panel tests and 93 assertions; 26 request/panel JavaScript tests pass. The explicit scope
and identity form is integrated and passes four focused lifecycle tests plus the affected inventory
suite. It defaults to all supported local definitions regardless of filters, offers selected
records from the actual grid selection, and rereads its preview when the Model revision changes.
Native dialog and integrated gates remain open.

## Starter data

`starter-library/materials.json` contains twelve generic records with authored notes and public
source links. Insulation conductivities are rounded SI conversions of nominal DOE guidance,
with aging and temperature limits stated. Gypsum values are rounded means from original NIST
room-temperature measurements. Unknown density, specific heat and emissivity remain null.
No licensed corpus or compiled ISO/ASHRAE table was used; source PDFs are not committed.

The actual registered Material adapter and file provider admit all twelve rows without warnings
or unavailable kinds. Ruby 2.7.2 and 3.2.2: 1 test, 92 assertions, no failures. The focused
archive suite passes 15 cases, including rejection of starter-library data under the extension.
The authored data has its separate CC0 notice and is excluded from the RBZ; licensing
documentation distinguishes it from the AGPL code. Full integrated gates are still pending.

## Resume

The local separate-extension example now passes four tests and 36 assertions on both Rubies.
These cover its shared immutable provider contract, an early-load subprocess with no core
namespace, duplicate and incompatible registration, unavailable kinds and public copy/read-back
with unchanged core composition. Its contributor walkthrough is documented. Native installation
succeeds in the fresh `146076e` process (PID 91277, bridge 50967): a separate
`SketchupExtension` loads from the Plugins directory and the panel-closed public walkthrough
commits and reads back its synthetic Material. Private proof: `example-provider-native-proof.json`.
No PH-Composer file was edited for registration. Final E09 provenance and the external repository
remain open.

The independent export review reproduced schema-valid semantic drift in a third-party reverse
mapper. Export now captures a detached mapped baseline before calling reverse and requires exact
mapped round-trip equality. The registered-adapter regression refuses before the save dialog and
preserves file, Model and revision. Both Ruby versions pass 43 affected tests and 377 assertions;
two changed files pass RuboCop. Independent drift and fresh-Model round-trip verification passes
on both Rubies, closing the finding. No other confirmed backend/transport/form finding remains.

The export form's five focused tests and actual selected-grid/filter regression pass. The combined
Window/export browser workflow passes all four widths, including the preview's explicit file-write
refusal and Cancel with no extra Model action. Log: `/tmp/phc-p209-window-export-browser.log`.

Complete export projection/write/round-trip tests and coherent independent review. Prepare the
separate-extension example under tools, prove load-order diagnostics and shared provider contract,
then integrate the explicit panel scope/identity choice and native export/read-back proof.
Ask Ed for the external repository creation only after the local example is reviewable, with the
other manual items at the end. No external repository has been created.


## Native export checkpoint on installed 7afe894

Fresh SketchUp 26.1.188 / Ruby 3.2.2, PID 3593, session
`83a48fca-0d70-4fca-b0fc-0225c9112e5d`, used the real export form, native Save panel
and final review to write four Materials from `p209-p211-native.skp`. The installed
FileProvider reads all four rows with no warnings or unavailable kinds. Explicit Update
retains UUID `29c576e0-9961-412c-b806-2561544c7292` and its library name. Cancelling
a subsequent native destination chooser leaves the Model unmodified at revision 61.
Private readback is `e09-all-readback.json`; all files remain in the private synthetic corpus.

The final native review exposed a blank unsupported-kind omission label. The correction
now names each omitted record kind and field names without field values. A regression
through the actual export callback passes with the file-export suite on Ruby 2.7.2 and
3.2.2 (20 tests, 138 assertions). Installation and native recheck remain pending. Selected
scope, fresh identity, subsequent reuse and complete E09 attestation remain open.


## Remaining native export observations

Installed `74f7f05` in fresh session `47ef05df-5c01-45f2-9f2b-8a35d288c96c` exports
a filtered, explicitly selected Material to `native-export-selected.json`: exactly one record,
retained local row id and new UUID `0d7bb8af-e15c-4578-892d-9c80abcfeb74`. The three hidden
records are absent. The corrected final review names both omitted kinds and field names.
Loading the earlier four-Material export through configured FileProvider returns no warnings;
public copy preview resolves the original local id, and Keep Local returns effect `none` at
the same revision. The temporary provider configuration is removed afterward.

A private, destination-specific rename fault was armed in the host. The real form, Save panel
and final consent run then report a write failure. Readback proves the prior file bytes exact,
no owned temporary files, unchanged revision and an unmodified Model. The original rename
method is restored immediately. Private proof is `e09-native-failure-74f7f05.json`.

The corrected outside provider from `4193311` is installed as its two separate Plugin paths,
registers its own SketchupExtension after core composition, and runs its public walkthrough
with no catalog warnings or unavailable kinds. It copies the synthetic insulation with correct
source attribution (`e09-outside-provider-74f7f05.json`). Native Undo removes that one copy
and returns the four-Material Model to unmodified. Only those two owned Plugin paths are
moved back into the private evidence folder. Fresh PID 12145 restores the normal six-feature
composition, no configured providers and an unmodified synthetic Model. No external
repository is created or published; that approval remains in Ed's final batch.
