# Operations publish the codes they refuse with

DATE: 2026-10-02
STATUS: Scoped 2026-10-02: [PLAN.md](PLAN.md); Ed decided D1 to D4 the same day. Moved out of the
Phase 2 review's R09 on 2026-10-02, which did not take it.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/39

## Why this packet exists

R04 made every feature declare its finding and refusal codes (`feature.code`). They appear only
under "Feature codes" in `docs/API_REFERENCE.md`. `API.describe` does not say which codes one
operation can answer, so an agent learns them by trying. R04 listed this as optional item 7, and
R09 carried it as optional item 8 ([R09](../../../archive/phase-02-envelope-review/R09-definition-feature-pattern.md),
"Observed" item 8 and "Proposed correction" step 6). R09 left it out because it changes the shell,
the registry and `API.describe`, which its per-kind split did not need.

## Required behavior

- A query or action registration may name `refuses:`, the declared codes it can answer.
- Registration refuses a `refuses:` entry that no feature in the batch declares, and a foundation
  code it does not own is named by its existing foundation id.
- `API.describe` publishes the list for each operation, and `docs/API_REFERENCE.md` shows it.
- Built-in features declare `refuses:` on their operations. Ed decided on 2026-10-02 to require
  it on every operation (PLAN.md D1).

## Verification

- `API.describe` of a Windows Type operation lists its refusal codes.
- A test refuses registering an operation that names an undeclared code.
- `make fixtures-check` changes `docs/API_REFERENCE.md` only by the added lists.

## When to schedule

Before an external agent adapter ships, or alongside the agent connection and access-grant work,
whichever comes first. It depends on nothing else.
