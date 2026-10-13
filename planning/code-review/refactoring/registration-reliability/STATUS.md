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
| RR-03 | Outside walkthrough with a custom store; CONTRACTS and EXTENSIBILITY registration text; dual-Ruby `make ci`; native smoke | Implemented on branch | `ExampleWalkthrough.registration` and its test (RR-A41, A42); CONTRACTS "Registration" and EXTENSIBILITY; native smoke passed (receipt below) |

Reviewed against source on 2026-10-13. Four technical defaults from the first draft were dropped
(reference swap with restoration, subscription tokens, frozen maps, cyclic-container diagnostics);
the reasons are in the plan's "Decisions and deviations" and in [DECISIONS.md](../DECISIONS.md). Ed accepted them on 2026-10-13.

Deviation: the stage table in PLAN.md put the store check in `Validation#check_record_kinds`; it is a
sibling `StoreValidation` class, because `Validation` would otherwise pass the class-length limit.
`Registry.reset` refuses while an install runs, as the plan asked. Full Ruby suite passes on 3.2.2 and
2.7.2; `make coverage` 97.0 % Ruby lines.

## Native smoke receipt, 2026-10-13

Host SketchUp 26.1.188 (Ruby 3.2.2), current host, not the support floor. Source `2c8afbe`; installed
with `make install`, RBZ sha256 prefix `388cd8c84d799d4e`. Fresh launch through the development
bridge onto a copy of `_private/host/blank-template.skp`, panel closed. Development eval arranged one
edge and changed the selection; registration went through `load.rb` and `Registry.install`.

| Observation | Result |
| --- | --- |
| Built-ins composed at launch | 7 features, 17 subscriptions |
| `load.rb` (outside example and kit) | both installed, 18 subscriptions |
| One selection change | kit subscriber counted 1 |
| `load.rb` again (guarded) | 18 subscriptions, count unchanged |
| Next selection change | count 2: delivered once |
| Unguarded `Registry.install([ExampleKit])` | `registration.duplicate_id`; 18 subscriptions |
| `ExampleWalkthrough.registration` on the host | passed; 18 subscriptions |
| Selection change after both | count 3 |
