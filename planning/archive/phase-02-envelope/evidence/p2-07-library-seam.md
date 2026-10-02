# P2-07 evidence: library seam and file provider

DATE: 2026-10-01
STATUS: Implemented in source. Focused dual-Ruby checks and bounded coordination review pass; integrated and native gates open.

The neutral foundation registers providers and kind adapters, keeps immutable catalogs in session
memory, resolves local copies and calls the record owner's callbacks within one guarded proposal.
The file provider reads one file or immediate JSON files in a folder. Paths remain in private
SketchUp defaults and provider instances. No provider configuration enters the Model.

Focused coordination, callback, resolver, setup and admission tests pass on Ruby 2.7.2 and 3.2.2:
30 tests and 171 assertions. They cover preview/apply digest stability and retries, atomic public
copy plus assignment, complete replacement guards, preserved unavailable extension payloads,
stale generations and retained last-good catalogs. Unknown kinds remain unavailable while supported
Materials still load. Incoming fingerprints compare against stored attribution, independent of
local edits; incompatible fingerprint versions make the comparison unavailable.

The independent bounded coordination review established three defects, all corrected and rechecked:

- Name matching now uses the record engine's strip/downcase rule. Case differences still require
  explicit semantic review instead of offering a copy that local uniqueness would refuse.
- Resolver reads receive no mutable proposal and a read-only projected engine. Attempts to stage a
  write poison the actual proposal, including when a callback rescues its own error.
- Successful private setup changes invalidate affected provider catalogs across open sessions.
  Removal and re-addition cannot revive an old generation or copy timestamp.

The parser/provider/catalog/setup checks include the exact 32 MiB per-file, 64 MiB aggregate and
20,000 raw-row boundaries and one above. These are offline limit checks. The budget still needs
measurement in the actual native process. A reusable provider contract test is available for
P2-09's outside provider.

Public transport schemas describe metadata, pages and resolution candidates. Registered kind
schemas validate the dynamic snapshot fields. The provider metadata query remains
`ph_composer.library.providers`; its snapshot section is `ph_composer.library.provider_catalogs`
because declaration identifiers are globally unique. File-provider registration uses exclusive
`kinds: ["*"]` to serve all registered wire kinds without naming features in the foundation.

A copy's attribution timestamp belongs to its first reviewed gesture at the current session
revision. Preview and apply share it. It stays outside semantic fingerprints and is written only
with the committed local record. Session memory bounds retained gesture timestamps to 128.

The owner now declares a separate report-only Material attribution section. Its allowlist contains
local id/name and provider/library/record identifiers, including unused copies. It omits transport
configuration and raw source snapshots and contributes no Honeybee geometry or material values.
Focused Ruby report proof passes one test / 19 assertions; typed Python projection proof passes six
cases, Ruff and mypy. This new section still needs integrated runtime and native export proof.

## Resume

Registration/Material review and the public file-format page and dual-Ruby public-API walkthrough
are complete. Refresh
manifests after the sidebar integration freezes, generate and inspect API fixtures, commit a
coherent checkpoint and run required integrated gates on both Rubies. Install that exact package.
Then measure a bounded catalog and prove panel-closed copy/assignment, native Undo/Redo,
save/reopen and editing a local copy after the provider disappears. No acceptance award is claimed.

A separate ownership/registration/Material adapter/report review passed 31 tests and 299 assertions
on both Rubies, plus 63 affected Python cases and mypy. It reproduced an invalid-color row that
entered the catalog but failed during copy. The Material mapper now runs its owner's pure semantic
validation, and shared admission excludes intentionally invalid rows with structured warnings
before publication. Public regression proof verifies that no copy action is offered. General
adapter failures still fail refresh and preserve the last-good catalog. A stale factory comment
was corrected to the accepted zero-argument contract. Closure passes 29 tests / 177 assertions on both Rubies.

The extraction golden's only addition is an empty report-only attribution section; the prior JSON
is exactly unchanged after removing that field. Full Python passes 134 cases after updating the
normal and synthetic composition declarations. The broader Ruby probe exposed expected composition
assertions, stale manifests/API reference and a native setup menu leaking into viewport context
menus. Composition assertions and the Extensions-only setup availability are corrected; refreshed
manifest and final integrated verification are pending the sidebar source freeze.

Integrated dual-Ruby gates, coverage, runtime/browser checks and exact installed checkpoint are
recorded in [P2-08 evidence](p2-08-library-sidebar.md#integrated-checkpoint). Native proof remains open.

## Current-host proof

The exact installed `146076e` checkpoint passes the panel-closed native walkthrough, stable
preview/apply digest, sequence retry and exact native Undo/Redo. Copy plus assignment creates a
Material and sets an Assembly Segment in one operation; one native Undo restores both inventories
exactly and one Redo restores both final inventories. Private proof: `library-native-roundtrip.json`.

A 20,000-row synthetic catalog loaded in 2,720 ms. Two files exactly 32 MiB each, 64 MiB aggregate,
with 20,000 total rows loaded in 2,779 ms without warnings or truncation. A one-row public page
reports total 20,000. Exact-and-one-above refusal boundaries remain covered offline. This measures
load, not panel rendering performance or a different host's budget.

Fresh-process reopen with no provider configured retains the first copied Material exactly. A
subsequent public conductivity edit to 0.045 W/mK succeeds with both temporary budget providers
removed. The combined copied/assigned/edited catalog is saved and fresh-process provider-free
reopen is exact, as recorded in P2-08 evidence. No source provider is required to edit local records.

The fresh native `146076e` process (PID 91277, bridge 50967) also completes the actual Pyodide
export from the synthetic two-Zone reference Model with an unused copied Material. The report
contains exactly the five allowed attribution fields and no configured path or raw snapshot.
The unused copy appears in the report and is absent from the seven Honeybee energy Materials;
the output retains two Rooms, twelve Faces and one Surface pair. Private evidence:
`library-source-report-before.json`, `library-source-report-status.json`,
`library-source-report-proof.json` and the generated HTML report. All recorded proof checks pass.
Final structured native case attestation remains open.

## Current native session/revision guards

Normal installed `8a43bec`, SketchUp PID 33871, panel closed: the shipped file provider loads
the synthetic `tools/examples/library/materials.json` and public preview succeeds. Copy with
an older expected revision refuses `revision.stale`, effect none. Pairing the active session's
caller handle with the other open Model's session refuses `session.unknown`, effect none.
Both complete Materials/Assemblies inventories and their revisions remain exactly unchanged.
The development helper only configures the existing shipped provider; it introduces no provider
implementation or runtime patch. Setup begins empty and is restored empty in ensure.
Private `p214-p217-library-guards.json` retains list/load/preview, both refusals and two-Model
readbacks; `p217-e07-baseline.json` was captured before this batch. Other E07 assertions retain
their original native/offline provenance in the E17 matrix; this does not relabel them as a
new full current-build walkthrough or close the case.
