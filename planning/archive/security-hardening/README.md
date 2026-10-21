# Security hardening

DATE: 2026-10-21
STATUS: Complete. SH-01 to SH-04 merged to main on 2026-10-21 (#293, #294, #299, #300); SH-05 deferred. Archived.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#292](https://github.com/bldgtyp/ph-composer/issues/292)
BASELINE: `main` at `0a41c0b7` (the review packet's commit; source unchanged since `9e52821`)
SOURCE: [the security and privacy review](../security-review-2026-10/README.md), findings F01 to F11

The implementation program for the eleven findings of the October 2026 security and privacy
review. The review found no high-confidence vulnerability; every stage here is hardening, release
hygiene or documentation, and each is one reviewable pull request.

## Read in this order

1. [STATUS.md](STATUS.md): the stage ledger, which stage is next, and the program's close.
2. [PLAN.md](PLAN.md): what the source does at the baseline, the stage order and dependencies, and
   the decisions table that separates what the coding agent decides from what goes to Ed.
3. The stage documents under [phases/](phases/), one per stage, each self-contained:
   [SH-01 release gates](phases/sh-01-release-gates.md),
   [SH-02 token setup and agent docs](phases/sh-02-token-setup-and-docs.md),
   [SH-03 panel and report hardening](phases/sh-03-panel-and-report-hardening.md),
   [SH-04 repository hygiene and context fold](phases/sh-04-repository-hygiene-and-context.md),
   [SH-05 listener binding](phases/sh-05-listener-binding.md) (deferred).
4. [ACCEPTANCE.md](ACCEPTANCE.md): the observable checks by stage, with stable case ids.

## Handing a stage to a coding agent

Give the agent this folder. It reads `STATUS.md`, then `PLAN.md`, then the first stage document
whose state is `Scoped`, and implements that stage alone. Each stage names its files, its tests,
the gate command and the acceptance rows it must satisfy. A stage that needs Ed (an account
setting, a contact address, a native host run) says so in its decisions table; the agent does the
rest and leaves that item in the pull request description.

The stage documents name files and methods, not line numbers, so a later head can be re-found.
Planning points at code; code never cites planning (`make lint-citations`).

Branch from `main`, run `make ci && git commit -s`, open the PR, and record the outcome in
`STATUS.md`. Squash merges are the repository's default.
