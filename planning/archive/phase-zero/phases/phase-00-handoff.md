# P0-A: verify the implementation handoff

DATE: 2026-09-18
STATUS: Complete 2026-09-18. Evidence: [evidence/phase-00-handoff.md](../evidence/phase-00-handoff.md).
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft)

## Entry and scope

Read [PLAN](../PLAN.md), [CONTRACTS](../CONTRACTS.md), [source inventory](../SOURCE_INVENTORY.md)
and the repository architecture skill. The interviews are resolved; do not restart them.
This stage verifies the design against the implementation checkout before copying code.

## Work

1. Record target branch, dirty-work ownership and authorized stage range. Preserve the current
   planning changes; isolate code work if another owner is using the checkout.
2. Resolve the frozen predecessor SHA and compare the inventory with its tree. Complete an
   explicit source-to-target disposition for any file reached transitively but not yet listed.
   A dependency on a deferred feature must be extracted as generic support or left out.
3. Turn C1 through C6 into synthetic contract fixtures and test case definitions. Verify the
   proposed Ruby entrypoints and operation context can work with no HtmlDialog. Pin failure
   codes and revision/retry boundaries before implementing callers.
4. Trace the synthetic feature end to end on paper: registration, query, atomic write, snapshot,
   read-back, duplicate and export contribution. Identify owners and affected files.
5. Record any necessary implementation-level refinement in CONTRACTS. Escalate only a conflict
   with accepted product behavior, licensing or scope.

## Exit and evidence

Produce `evidence/phase-00-handoff.md`: baseline SHA, disposition completion, contract fixture map,
design-trace findings and authorized next stage. A01's inventory portion is satisfied only when
the actual source closure is accounted for. No runtime behavior is proved here.

Stop if the frozen commit cannot be read, another owner's edits would be overwritten, or a
required contract contradicts an authority. A missing host does not block this stage.
No predecessor rewrite, dependency upgrade or repository transfer is part of this work.

