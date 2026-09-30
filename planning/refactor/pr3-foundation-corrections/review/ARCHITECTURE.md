# Foundation architecture assessment

DATE: 2026-09-30
STATUS: Recommendations; no new product decision or implementation authorization
ISSUE: none (local review draft against PR #3)

## Keep the current layer boundaries

The SKP remains the authoring authority. Explicit proposals enter one native operation; callers
receive a structured result and verified rollback certainty. Detached export separates host access
from translation. Typed Python dependencies order translation without teaching the coordinator
about building features. Exporters consume HBJSON. These mechanisms match the founding brief.

The language count is justified by actual responsibilities. Language consolidation would move
complexity into host integration or duplicate the Honeybee model. There is no measured runtime
failure in this review that justifies replacing the stack.

| Alternative | Assessment and recommendation |
| --- | --- |
| Ruby host layer plus pure Ruby domain calculations | Keep. Explicit inputs let validation/geometry rules be tested without SketchUp; host reads and mutations remain separate |
| Move all domain logic to Python | Defer. Record/reference validation would need an asynchronous runtime for ordinary edits, and native proposal/Undo ownership still needs Ruby. Extract portable pure calculations only when another consumer needs them |
| Reimplement Honeybee translation in Ruby or JavaScript | Reject for this foundation. It adds an independent implementation of the canonical export model and reference rules |
| System-Python companion for translation | Do not adopt now. It changes the accepted installation/product boundary and requires its own process/distribution acceptance. Consider only for a concrete runtime limit |
| Pinned offline Pyodide translation | Keep the current route. Manifest, eight-wheel pins, native/Pyodide conformance and lazy startup have specific evidence. Future payload/cancellation costs remain measurable gates |
| Move the UI to TypeScript | Optional later improvement. Generated request/result types would help now without requiring a bundler/framework rewrite. Preserve Chromium 88 output and dependency safeguards |
| React or a general plugin framework | No demonstrated need. The registered UI kit already has discrete modules and shared controls. Fix draft ownership and schemas before changing presentation infrastructure |
| External database as the working model | Reject under current product scope. It replaces SKP portability and adds account/service dependencies |
| HBJSON as the live authoring datastore | Reject. HBJSON is the export boundary; native occurrence identity, repair state and partially authored records have different responsibilities |
| One local agent adapter over the application API | Keep as the later integration direction. Transport should translate schemas/envelopes and schedule host calls, with no feature-specific business logic |

These are comparisons against current source and accepted product constraints. They do not select
new runtime versions or claim untested platform behavior.

## Resolve authored-envelope ownership before more features depend on it

Zones declares no feature dependency. FaceAssignment declares Zones, yet Zones calls
FaceAssignment's record store/schema in copying, adjacency, split and export paths. The dependency
graph published by discovery therefore omits a real dependency. Adding the reciprocal `requires`
would create the cycle the registry correctly forbids. Load order in the composition root currently
makes the two modules available, but it does not make this a clean contributor boundary.

The primary problem is responsibility. Zone containment, Face identity, stamps, Surface endpoints
and safe copy/split transitions form one authoring domain. Today a contributor must learn both
features' internal stores and mutation steps to change any of them safely.

| Option | Cost and outcome |
| --- | --- |
| Retain two features and add public proposal participants | Smaller initial diff; can make selected cross-feature operations explicit. Both features still need a shared identity/reference owner, and callbacks can hide the actual dependency |
| One authored-envelope domain feature, with Zone, Face and adjacency submodules | Recommended. Gives the coupled lifecycle one owner while retaining small files and separate UI views. Materials, windows and importers depend on a public envelope query/proposal interface |
| A third shared record/domain package beneath both features | Viable if genuinely independent Zone and Face installations are required. Currently adds registration and composition work without an identified separate consumer |

Recommend one cohesive envelope domain registration with explicit public submodules. Keep Zone
and Face as product/domain concepts; do not flatten them into a generic entity class. Keep schemas,
occurrence resolution and pure pair validation separate from SketchUp write steps. Public queries
and mutations remain named operations. This choice needs Ed's acceptance before implementing the
larger move. The concrete correctness fixes can proceed independently once authorized.

There are no users or deployed files to justify compatibility shims. If action IDs, modules or
schema shapes change during this correction, update examples, tests and declarations coherently.
Do not write migrations or duplicate APIs to preserve an internal iteration. Still preserve
arbitrary user metadata, extension references and native Undo as product invariants; those are
correctness requirements even before users exist. Keep the SketchUp 2023/Ruby 2.7/Chromium 88
policy unless Ed explicitly changes the supported-host target. It is separate from legacy data/API
compatibility.

## Declare schema and references once

Catalog `RecordKind` has values and references. Entity `ReferenceTarget` has inventory/validation
but no public values schema or core reference declarations. That split is useful for storage
ownership, but incomplete for discovery and integrity. M3 demonstrates the consequence: generic
incoming-reference checks skip `attached_zone_id` in an entity-owned Face record.

Introduce a shared descriptive contract for values, identity, occurrence references and outgoing
core references; compose it with either catalog storage or entity-owned inventory. Do not give
the generic engine authority to create or delete native geometry. Reuse descriptors in discovery,
validation and generated client types. Represent occurrence keys as typed values internally where
that prevents root-path/relative-path confusion; serialize them plainly at the public boundary.
Avoid replacing domain records with arbitrary key/value bags.

Keep request revision, proposal digest and expected record values distinct. They protect different
facts. Retain bounded idempotency outcomes and truthful unknown rollback results. Give the native
cut step its request's catalog/reference guard explicitly; `adjacency_steps.rb:79` obtains
`Registry.current.catalog` during apply instead of using its prepared operation dependency.
No mis-removal through a mismatched catalog was reproduced; this is a directly evidenced hidden
dependency requiring a targeted test, not a confirmed current data-loss case.

## Refactor responsibilities where the measurements support it

Normal lint passes, including method/class limits. The two feature `install.rb` files are 531 and
592 physical lines because modules hold both declarations and operational policy. Class-only
length limits do not flag those modules. Length alone is insufficient, but the mixed responsibilities
are concrete. Separate declarative contracts/registration from operation handlers and inventory
projection while preserving a readable entrypoint per domain owner.

| Unit | Measured review signal | Useful change |
| --- | --- | --- |
| `Zones::Overlap.partition`, line 166 | Cyclomatic 20; ABC 55.76 | Keep pure geometry local; separate polygon validation from region construction if it reduces retained context |
| `PartitionAndPairStep#cut_partition`, line 228 | Cyclomatic 18; ABC 64.76 | Separate native splitting from post-cut identity/reference projection; preserve one transaction owner |
| `Adjacency.state`, line 317 | Cyclomatic 17 | Centralize reciprocal-pair validity rules shared with retirement/snapshot checks; live resolution stays separate |
| `SplitIdentityRepair.keeper_path`, line 179 | Cyclomatic 17 | Name and isolate endpoint proof versus explicit keeper selection; preserve conservative ambiguity refusal |
| `Registry::Validation#check_export_contributors`, line 171 | Cyclomatic 17 | Separate preflight ownership, schema and result-field ownership checks |
| `Export::Workflow.start`, line 13 | Cyclomatic 17 | Separate reviewed repairs from destination consent and task startup without splitting transaction policy across clients |
| `FaceGeometry.world_normal`, line 118 | ABC 90.39 | Matrix arithmetic explains much of the score; retain readable math unless a smaller pure transform helper helps actual callers |
| `ColourBy` hatch clipping | Cyclomatic 11 | Share proven edge-intersection math if useful; preserve measured holes/concavity/performance evidence |

Metrics are advisory at default exploratory thresholds. They do not establish 324 defects or
justify mechanical helper extraction. Long cohesive recovery/geometry procedures can be easier
to audit than a chain of tiny callbacks. No repository thresholds were changed.

## Removal and deferred code

No confirmed dead shipping module was found. Public seams, test resets, synthetic examples and
empty exporter composition have documented purposes and current tests. `library/` is a target
layout entry, not an implemented unused package. Development spikes and host walkthroughs never
ship and preserve the evidence for host assumptions; lack of a production caller is expected.
Deleting them based on occurrence counts would discard evidence without reducing the RBZ.

One small removal candidate is the unused `revision` parameter on `Zones::Repair.restore_plan`.
Remove it and update its callers during the affected refactor. Beyond that, require an actual
unreachable call path or an explicit retired contract before deleting modules. No legacy adapter
or designPH integration was found to reintroduce or remove from shipping code.

## Documentation and development skills

The repository-local architecture rubric is useful and correctly distinguishes reproduced defects
from hypotheses and host gates. Retain it. The UI skill's draft/navigation rule directly applies
to U1. Its linked `references/patterns.md:5` still says transplanted file names will match the
predecessor, and names absent Assembly/Library/Window modules as current reference points. Its
last section says Face assignment has no accepted pattern despite current Overview/Classify
acceptance. Update the reference to actual local paths and label future/predecessor-only patterns.
Do not weaken shared skills to make the current implementation comply.

Other directly observed stale passages:

- `context/TECH_STACK.md:14` says the shipping build registers no building features.
- `docs/PRD.md`, Current capability and release boundary, describes P1-C through P1-F as future work.
- `docs/DEVELOPMENT.md`, Fixtures and coverage, says there are no goldens although the Phase 1
  extraction has an owning fixture test. Its earlier Colour-by paragraph says remaining questions
  are open despite the later acceptance continuation.
- `context/AGENT_INTERFACE.md`, final entity-reference paragraph, still names a pending independent
  review gate that the current acceptance register says passed.
- `planning/.instructions.md` depends on a `planning-conventions` skill that is not in this session's
  catalog or the searched standard skill directories. Restore a resolvable reference or place the
  needed packet convention locally. No issue was created solely to repair that unavailable workflow.

These are consistency follow-ups. This review does not silently change product policy or historical
evidence. Link the review from current status while retaining the original named-case acceptance.
