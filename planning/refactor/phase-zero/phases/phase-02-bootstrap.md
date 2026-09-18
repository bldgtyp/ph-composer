# P0-C: tooling and empty extension

DATE: 2026-09-18
STATUS: Scoped. Implementation authorized 2026-09-18; not started.
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft)

## Entry and permitted changes

Requires P0-A. Own the loader/composition root, build/test configuration, development tooling,
packaging checks and their synthetic fixtures. Follow the source inventory. No feature folders
are transplanted wholesale. This stage can run while P0-B is pending.

## Work

1. Establish the PhComposer loader and explicit composition root with no product feature enabled.
   Rename namespace/dictionary/asset identifiers together. Keep the development bridge outside RBZ.
2. Port test helpers and host stubs with comments linking measured host differences. Remove old
   feature fixture dependencies. Establish Ruby 2.7.2/3.2.2 checks and Chromium 88 lint rules.
3. Port build, fixture, hostkit, type-check and manifest tooling in dependency order. Initially
   run applicable focused checks; label targets awaiting P0-D/F rather than silently passing them.
4. Define the shipping inventory and minimal manifest. Retain required attribution. Read LICENSING
   and DCO before copying third-party payloads. Reject private corpora and development examples.
5. Add namespace/designPH checks over shipping paths, dictionaries, actions and synthetic fixtures.
   Documentary source citations and upstream license notices need a narrow reviewed allowlist;
   broad suppression of a shipping namespace violation is prohibited.
6. Update DEVELOPMENT with actual commands and installed prerequisites. Keep local tests independent
   of lint dependencies; require those tools for final CI. Preserve pnpm minimum-age protections
   if package management is needed.

## Verification and exit

Focused syntax, loader/stub tests, packaging inventory and negative packaging tests pass.
Load the empty extension in the current host through the development workflow and record version.
A missing host leaves this exit pending even if tooling can support subsequent offline work.

Record source paths, target paths and any extracted dependency in `evidence/phase-02-bootstrap.md`.
A03/A04 are provisional until the final RBZ is checked again after shipping assets change.
Do not claim the full empty-foundation suite passes before its components exist.

Stop on licensed payload uncertainty, a source dependency that requires a deferred feature, or
a toolchain change that would abandon the compatibility floor. Do not install into system Python.

