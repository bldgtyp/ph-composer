# 07. Contributor tasks and refactoring frontiers

This is a cost assessment and set of candidate workstreams, not implementation authorization or
a detailed refactoring plan. The user explicitly permits architectural change at this early stage;
there is no need to maintain a legacy public API simply because version 1 exists in current source.
Existing acceptance decisions, authored fixtures and host behavior still need deliberate treatment.

Detailed [refactoring packets](../../archive/code-review-refactoring/README.md) now cover these candidates. This section
retains the review's design priorities; the [packet ledger](../../archive/code-review-refactoring/STATUS.md) owns current
planning state and the [Zone-child pattern](../../archive/code-review-refactoring/ZONE_CHILD_PATTERN.md) records accepted direction.

## Concrete contributor tasks

| Task | Current supported path | Remaining obstacle / decision |
| --- | --- | --- |
| Add a pure calculation to an existing feature | Explicit values in owning Ruby domain module; expose a query field; JS formats it | Keep calculations out of panel rules; JS-01/05 show current exceptions |
| Add a Model-local definition with a simple editor | Feature install, RecordKind, named actions/query/snapshot, feature-owned JS module; composition entry and generated manifests | F01/02 publication stability; repair example lifecycle JS-03/04 |
| Attach a firm's review status to an Assembly | Existing catalog update's user_data; custom structured payload through an owner-supported action | Catalog engine has the primitives; public generic structured-update scope should be deliberate |
| Attach a firm's review status to a Face or placed Unit | Public occurrence read/reference discovery exists | RF-01 lacks supported entity metadata writes; RF-03 lacks status; F07 lacks cooperating required-payload export |
| Add a vendor/private library provider | Registered provider factory, immutable rows and reusable provider contract tests | Separate provider example exists; actual outside native installation is still unproved. F05 neutral display-label contract |
| Add a new library kind | Own catalog kind, map/reverse/fingerprint/local callbacks, optional inventory UI | Common wire label/identity shape must be enforced or projected. Reuse owner operation rather than a second persistence path |
| Add usage information to another screen | Table contribution with current snapshot and own action | Good dependency inversion example: Zones supplies Assembly usage; owner inventory imports no geometry feature |
| Add a composed importer/firm workflow | Own action proposes changes; use participants and reference retargeters | F04 uniform participant invocation; there is no complete shipped file-model importer example or generic multi-action batch promise |
| Add an Edge assignment feature | Feature-owned tagging/run rules and reference reads | F06 export capture and overlay primitive contracts require extension; settle with the owning planned feature |
| Add a translated entity under a Room or Face | Ruby export contributor plus explicit Python Section requires/Attachment | Runtime build inclusion and manifests are composition work; independent hot-loading is not currently promised |
| Add an output exporter | HBJSON plus options; synthetic exporter contract | Native format selection/delivery and actual exporter remain deferred; don't advertise the test seam as independently installable product functionality |

## Candidate workstreams, in recommended order

1. **Registration and callback reliability.** F01/F02/F04/JS-02 address contracts that every new
   contribution relies on. Define owned immutable declarations and guarded composition. These have
   synthetic, deterministic acceptance checks and limited product decision cost.
2. **Company metadata on authored geometry.** RF-01/RF-03/F07 form one coherent capability: update,
   inspect, preserve, copy and deliberately export namespaced data on Zone/Face/Unit records. Design
   the successful and unavailable-extension flows together. F08 fixes a false export promise and can
   be a small separate correction.
3. **Domain and orchestration ownership.** RF-02 separates Windows definition use cases from native
   Unit participation while respecting the currently accepted and advertised repair policy. JS-01 publishes
   canonical topology facts to the detached installation draft. Settle JS-05's aggregation policy.
4. **Next-feature host geometry contracts.** F06 supports Edge occurrences and derived primitives.
   Resolve it in the existing Spaces/thermal-bridge design frontier, with representative performance
   and native evidence rather than building a speculative general scene graph.
5. **Contributor examples and library contract completion.** JS-03/04 make the worked example a safe
   template; F05 formalizes common row identity/label behavior. RF-04 consolidates Material replacement.
   Add a short contributor router and one lifecycle example without copying canonical contracts.
6. **Portable foundation packaging, when justified.** F03 and the shell/export adapter coupling can
   inform extraction for an actual adopter. Improve visible purity boundaries now; defer independent
   package releases, loader design and dependency injection machinery until their cost has a user.

The small example corrections need not wait for major refactoring. This order prioritizes design
dependencies; it is not a requirement to bundle every item into one PR or interrupt other authorized
work. No findings here are marked resolved or accepted for implementation.

## Architectural checks worth carrying into those plans

- A complete outside contribution should register, read, preview, invoke and read back without
  changing shell/session/export/kit internals. Allowed composition edits must be named explicitly.
- Pure value/rule tests should load without SketchUp. Native adapters and action coordinators should
  have their own stub/native checks rather than polluting calculation fixtures.
- A dependency check should inspect sanctioned feature crossings, not only private constant names.
  The current Zone-store and frontend graph tests are useful but cannot detect every Ruby internal
  dependency, as RF-02 demonstrates.
- Read and contribution callbacks must not mutate published contracts or a later contributor's
  snapshot. Choose freeze versus detached copies explicitly; mutable proposal builders remain mutable.
- Native mutations, cancellation/refusal recovery, metadata/reference round trips and runtime assets
  keep their high-assurance gates. Test coverage and green CI do not prove extensibility for a new
  contribution kind until its example and applicable host gate pass.

## Scope exclusions

No generic marketplace, hot loader, untrusted Ruby sandbox, full ORM, global business event bus,
company account service or independently versioned package tree is recommended. The current
explicit composition model is adequate for this stage. The review identifies concrete contribution
friction, and the next plans can remove it within the existing modular application.
