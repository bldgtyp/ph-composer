# Production support: status

DATE: 2026-10-19
STATUS: In progress
AUTHOR: Ed May, BLDGTYP, with Codex and Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/245

## Current state

Ed accepted the review direction and a six-stage plan on 2026-10-19. A second review the same
day revised the packet to five stages and ten acceptance rows (DECISIONS, PS-D10); Ed accepted
the revision on 2026-10-19. No stage is implemented. Completion is required before public beta or
broader distribution. PS-02 is wanted before the Phase 3 internal candidate. Developer tooling
has a separate packet and ledger.

## Stage ledger

| Stage | Scope | State | Evidence still required |
| --- | --- | --- | --- |
| PS-02a | F06: checked preference writes; unreadable stored maps refused | Implemented on branch `fix/production-support-ps-02a` | Done offline: probe F06 as `test_a_write_the_host_refuses_is_reported_as_not_saved`, plus unreadable-map refusal, unrecognized-entry preservation and Colour-by-stays-on tests; rule in TECH_STACK "Units". Remaining: A06 native persistence/restart read-back (PS-05) |
| PS-02b | F04: request recovery timer and Check status for a lost reply | Scoped | Probe F04 as a test, contract update, native committed/lost-reply case |
| PS-02c | F05: Ruby-side runtime deadline before and after ready | Scoped | Probe F05 as a test, contract update, native asynchronous faults |
| PS-01 | Failure context, correlation and build identity in the log | Scoped | Confirmed fields and privacy tests, package identity, native incident |
| PS-03 | Help & Diagnostics and the support report | Scoped | Screen sketches, byte-equal preview/copy/save, negative privacy, native menu, fallback and keyboard evidence |
| PS-04 | Shipped help, bug template, maintainer procedure | Scoped | Packaged help, verified destination, template, walkthrough |
| PS-05 | Integrated acceptance | Scoped | Installed-build native receipt, normal-build restoration, full gates |

## Next action

Ed authorized the whole packet through pr-loop on 2026-10-19, one PR per stage with PS-02 split
into three, merged on green CI after each Codex review. PS-03 builds from its recorded sketches
without a separate stop. Product changes outside the accepted local-support direction return to Ed.
Native rows stay open until PS-05; this loop does not satisfy them.

## Verification

[REVIEW](REVIEW.md) records the source audit and focused checks from the preceding review.
These are baseline evidence, not passes for this feature. The packet's local Markdown targets
were checked with the acceptance_run links command after the revision; no code or native
acceptance ran for this documentation-only change.

## Ledger

| Date | Event |
| --- | --- |
| 2026-10-19 | Review direction accepted; local planning packet created with six stages and A01 to A16. Implementation remains unauthorized. |
| 2026-10-19 | Added the developer-tooling companion assessment and updated roadmap/master/unscheduled indexes. Documentation checks passed; no shipping-code change. |
| 2026-10-19 | Ed accepted all recommended steps/phases. Moved developer tooling into its own feature packet, defined shared ownership/dependencies and prepared both plans for separate implementation chats. No implementation started. |
| 2026-10-19 | Second review (Claude): kept the direction, cut the plan to five stages and ten rows, put the correctness fixes first and deferred Run checks, incident grouping and the JSON report (PS-D10). |
| 2026-10-19 | Ed accepted the five-stage revision (PS-D10). Implementation remains unauthorized. |
| 2026-10-19 | Ed authorized implementation through pr-loop with merge on green. Issue #245 created. PS-02a (F06) implemented on branch. |
