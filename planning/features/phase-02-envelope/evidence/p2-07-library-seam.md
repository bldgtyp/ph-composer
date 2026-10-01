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
