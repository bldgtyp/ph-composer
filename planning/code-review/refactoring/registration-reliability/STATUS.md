# Registration reliability status

DATE: 2026-10-13
STATUS: Implemented on branch `refactor/group-2-foundation-contracts`, with the other delivery group 2 packet, one PR.
ISSUE: [#103](https://github.com/bldgtyp/ph-composer/issues/103)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| RR-01 | Store and dictionary admission in validation; `publish` split into pure `prepare` and raise-free `commit`; reentrancy guard | Implemented on branch | `StoreValidation` (five methods by presence, getter once, prefix); `prepare` and `commit`; reentrant `install` and `reset` refused. Six tests in `tests/registry_test.rb` (RR-A09, A10, A13, A14, A17 and the F01 probe inverted) |
| RR-02 | `VALUE_MEMBERS` ownership at publish; `Fields.detached` at construction for kinds, descriptors, targets and extensions; rewrite the one live-map test | Implemented on branch | `Registry::VALUE_MEMBERS` and `own`; `Fields.detached`; record classes detach at construction; the live-map test counts `HandlerRequest#query` instead. Seven tests in `tests/registry_ownership_test.rb` (RR-A18 to A25, A27, A28); six fail on the RR-01 code |
| RR-03 | Outside walkthrough with a custom store; CONTRACTS and EXTENSIBILITY registration text; dual-Ruby `make ci`; native smoke | Implemented on branch | `ExampleWalkthrough.registration` and its test (RR-A41, A42); CONTRACTS "Registration" and EXTENSIBILITY; native smoke pending |

Reviewed against source on 2026-10-13. Four technical defaults from the first draft were dropped
(reference swap with restoration, subscription tokens, frozen maps, cyclic-container diagnostics);
the reasons are in the plan's "Decisions and deviations" and in [DECISIONS.md](../DECISIONS.md). Ed accepted them on 2026-10-13.

Deviation: the stage table in PLAN.md put the store check in `Validation#check_record_kinds`; it is a
sibling `StoreValidation` class, because `Validation` would otherwise pass the class-length limit.
`Registry.reset` refuses while an install runs, as the plan asked. Full Ruby suite passes on 3.2.2 and
2.7.2; `make coverage` 97.0 % Ruby lines.
