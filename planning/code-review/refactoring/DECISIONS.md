# Refactoring decisions

DATE: 2026-10-13
STATUS: Direction and the four 2026-10-13 deviations accepted by Ed. Implementation authorized on 2026-10-13.
ISSUE: none (local planning draft)

## Accepted on 2026-10-13

| Id | Accepted direction | Reason and limit |
| --- | --- | --- |
| C1 | Typed participants with params, result, refusals and examples, and explicit composition edges | Replace raw callbacks with a contributor contract; only the outer action owns approval, sequencing and Undo |
| C2 | Owner-scoped proposal and engine access, protected prior contributions and failure poisoning | Prevent cross-owner corruption; trusted native callbacks still need explicit scopes and tests |
| W1 | Preserve the broad next-Windows-mutation copied-id repair during the structural refactor | Isolate layering changes from user-visible repair timing; the copied-Zone route adds a path without removing the fallback |
| Z1 | Reusable definitions stay independent of host context; placed uses compose above both | Type validity and placement suitability are different checks |
| Z2 | Parent containment does not make Zone the implementation owner of every child | Registered child owners supply their own steps and copy rules |
| Z3 | Apply the pattern to Spaces and future equipment relationships | Reuse ownership and coordination, not a universal copy algorithm |

See [ZONE_CHILD_PATTERN](ZONE_CHILD_PATTERN.md) and the [Windows rationale](../WINDOWS_BOUNDARY.md).

## Deviations recorded 2026-10-13

The plans were reviewed against the baseline source after the direction was accepted. Four
technical defaults from the first drafts changed mechanism, not direction. Ed accepted all four on
2026-10-13 after a walkthrough; each plan's "Decisions and deviations" section carries the detail.

| Packet | First default | Now | Why |
| --- | --- | --- | --- |
| Registration | Prepare three framework-owned references, swap atomically, restore on internal failure; stable subscription tokens; frozen public maps | Validate everything in staging (store protocol and dictionary name included), then a `commit` that only assigns and appends; subscriptions and their array-closing disposers unchanged; maps stay live Hashes | After validation nothing in `commit` can raise, so there is nothing to restore. The per-kind subscriber array is never replaced, so the disposer is already stable. Readers index maps on each use, so live maps give additive visibility without a facade |
| Composition | A `ProposalScope` facade over the root proposal | The projected engine's existing write-time guard plus a postcondition that prior writes, steps and findings are unchanged; `ProjectedEngine#projected` derives nested delegation from the root | The guard exists in `ProjectedEngine#writable!`; the facade would duplicate `ChangeSet` and `Proposal` for one check. Also: the Zones `retire_pairs` participant becomes a direct same-feature call |
| Entity customization | Pre-image with explicit presence bits for legacy absence; a preparation helper returning candidates and findings; new steps per owner | `expected_metadata` is the two maps as read; `Metadata.updated` returns a record or raises; `UpdateZoneStep` and `ClassifyStep` are reused, one new `UpdateUnitStep` | Reads already report absence as `{}` and the updater never adds a key it was not asked to write; the existing steps already carry full before and after records |
| Zone-child lifecycle | A gesture-provenance lifecycle with invalidation; a transition registry with schemas; a foundation late-materialization protocol | Inherit the Zone repair's accepted join and Undo notice; a string transition plus a contributor declaration mirroring retargeters; logical binding inside the child step as `MakeIndependentStep` does | No new risk beyond what D-1 accepted for Zones; one mechanism to learn; the parent already solved the binding shape |

Smaller choices recorded in the plans and not needing confirmation: `install_topology` lives in a
Type row's `display`; Zone totals are two numbers beside `face_count`; the library label is an
adapter projection (the mandatory-name alternative is documented); Colour-by lines are per-segment
entries with a `member` key for counting.

## Technical defaults carried into the plans

| Area | Default | Limit |
| --- | --- | --- |
| Registration | Store protocol and prefix validated in staging; `VALUE_MEMBERS` ownership at publish; detachment at construction for kinds, descriptors, targets and extensions | Behaviour objects retained by identity, never copied or frozen; no rollback of a throwing install's own side effects |
| Composition | `participants:` edge on operations; `request.participate`; three new foundation codes | No nested dispatch; memo semantics unchanged |
| Entity customization | Whole-map `user_data` replacement, installed payload replacement, `expected_metadata` pre-image, one step per owner, `entity_projections:` claims | No generic dictionary writer, no arbitrary metadata export |
| Panel facts | Ruby publishes topology facts and occurrence totals; JS formats and stages | Existing copy and Save policies unchanged; read cost measured |
| Library | Adapter `display_label`; wire `id` required; `Materials::Operations.update(source:)` | Identity and fingerprints unchanged |
| Child copy | `transition_contributor`; `request.contribute_transition`; child steps answer `restore` and bind logically | Measured host behaviour from ZC-01 governs |
| Drawing | Edge entries with vertex and face ids; `LineEntry` per segment | No scene graph; cost measured before cache changes |
| Purity | `FaceGeometry.build` plus `FaceCapture.call` | No package extraction |

## Conditional decisions still needing Ed

| Id | Trigger | Recommended course |
| --- | --- | --- |
| D-01 | ZC-01 shows copied Units cannot be re-resolved after `make_unique` on the host | Decline automatic child repair with an accurate notice; keep explicit Make independent; confirm before product behaviour changes |
| D-02 | Later work proposes narrowing the broad Windows repair trigger | Revisit separately with copy, export and recovery traces; keep the trigger in these plans |
| D-03 | The thermal-bridge interview wants whole-run filtering as visible behaviour | Confirm there; per-segment is the shared default |
| D-04 | Equipment or other children need copies of shared systems crossing Zones | Settle in that product packet; never infer deep copy from containment |
| D-05 | EC-03's `entity_projections:` declaration shape | Confirm after EC-03's offline tests, before EC-04 |
| D-06 | Library label policy | Adapter projection is the default; the mandatory-name alternative rewrites LC-01 and LC-02 together |

Canonical contracts stay unchanged until a stage lands; each stage's last task folds the verified
contract into `context/`.
