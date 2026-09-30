# P1-D evidence: Face and Zone extension-reference targets

DATE: 2026-09-29
STATUS: Implemented and current-host verified; independent review pending because the chat's agent-thread limit refused both start and resume attempts. P1-D remains open for that gate.
ISSUE: none (local implementation packet)

## Scope and correction

Source base `860c150`, with the correction in this evidence record's implementation commit.
SketchUp Pro 26.1.188 / Ruby 3.2.2 / macOS 26.6.2. Every fixture is synthetic and gitignored
under `_private/host/`. Native controls use computer use; setup and public preview/invoke/readback
use the established development bridge, with the panel closed.

The installed previous build refused a contributor extension declaring Face or Zone UUID
references with `registration.missing_dependency`. Its catalog-only resolver could not validate
new entity identities during copy or split repair. Reference preservation was therefore not
established for those targets.

Features now register a read-only `Records::ReferenceTarget` through the public Registry.
Providers enumerate typed record occurrences; validators remain feature-owned. Catalog CRUD
does not become an entity-writing interface. Discovery and description expose target metadata.
The built-in targets are `ph_composer.zones.zone` and `ph_composer.face_assignment.face`.
Face enumeration includes orphan records and repeated placements so lookup cannot hide UUID
ambiguity. Core names no feature.

`Engine#resolve_reference` checks the declared target kind and resolves exactly one validated,
detached entry. A typed `ReferencePlan` projects the exact occurrences a proposal replaces.
Collection copies remap included references to new counterparts; outside references and literal
metadata remain unchanged. Split repair preserves incoming references on the proved/chosen
keeper, while new pieces' declared self references follow their new UUIDs.

Incoming checks cover catalog and entity-owned records, including declarations in readable
unavailable envelopes. If a solver cut retains no original Face, an incoming reference prevents
removal of its identity. Opaque or invalid data that cannot establish safe removal also refuses.
The native operation aborts rather than choosing a replacement by geometry.

Two associated corrections landed: repaired Faces' returned affected references now carry the
new Zone UUID; catalog duplication also respects target kind when another object uses the same
ID string. A declared failure discovered during a native operation retains its actionable reason
in the message and `detail.cause`, without changing rollback certainty or exposing unexpected
exception details.

## Native cases

| Case | Actual readback and rollback evidence |
| --- | --- |
| Copied Zone | Saved native clipboard-copy fixture, made independent in the earlier accepted run. Zone plus six member records carry self, cross-Face, many-Face, owner-Zone, outside Face/Zone and shared catalog references. After explicit repair, all seven copied payloads match the declared remap exactly; literal metadata, outside Zone/Face records and incoming catalog data remain exact. All 166 declared targets resolve to the actual intended identities and paths. Every returned affected Face reference resolves. |
| Native Line split | Existing native split fixture carries two copies of `fac_1cf12d368913`. Explicit choice retains it on path `[48906]`; path `[48952]` receives a new UUID. All 63 declared targets resolve; Zone, outside Face and catalog incoming references still name the keeper. New-piece self references remap, metadata stays literal, and outside records remain exact. |
| Coordinated Solve | Three stacked Zones, 18 Faces before / 19 after. Three pairs produce six current reciprocal Surface endpoints. All 76 declared Face/Zone/catalog targets resolve, including new-piece self references. Repeat Solve is `completed / none` with an exact fingerprint. |
| Catalog copy | A registered outside target deliberately shares the original catalog ID string. Public duplicate remaps its catalog self reference to the new record while keeping the other-kind reference on the original. Both resolve to the correct typed targets. Native Undo/Redo restore exact fingerprints. |
| Identity loss | A development-only injection recreates the two actual native split Faces after the cut, with new persistent IDs. It does not claim spontaneous host behavior. The unchanged incoming catalog reference to `fac_c48e0b42c4fe` triggers `reference.in_use`; the public result is `failed / operation.failed / rolled_back`, exposes that cause, and restores the full saved fingerprint exactly. The recreated IDs were `[48910 → 48982]` and `[48981 → 48983]`. All overrides are restored immediately. |

Post-write failure injections counted three actual Face writes for copy and Solve, and two for
split repair. Each returned `failed / operation.failed / rolled_back` and restored the complete
fingerprint, including records, stamps, geometry, transforms, dictionary values, materials and
`modified: false`. These are not failures in the offline stub's snapshot mechanism.

Copy, split and Solve each have exact native Undo/Redo and fresh-process reopen checks. Reopen
matches every fingerprint field except the expected modified-flag reset after saving; each Model
is unmodified. Actual reference targets are re-resolved rather than inferred from string counts.
Development extensions are registered again after restart; no fixture feature ships in the RBZ.

Fixtures use `p1d-entity-reference-{copy,split,solve,catalog}-{before,after}.skp` and
`p1d-entity-reference-no-survivor-before.skp`. Private helpers are
`p1d-entity-references.rb`, `p1d-catalog-reference-kind.rb`, and
`p1d-no-survivor-reference.rb`; corresponding JSON fingerprints and target checks stay private.

## Deterministic gates and review

Full `make ci`: 578 Ruby tests / 2,570 assertions; 180 JavaScript tests; 84 Python tests;
9 hostkit tests / 30 assertions. Ruby 2.7.2 passes the same full Ruby suite. RuboCop inspects
172 files with no offenses. `make coverage`: Ruby 96.8% (5,790 lines / 91 files), JavaScript
98.2%, Python 97.46%. Manifest, packaged inventory and RBZ checks pass. Installed inventory:
144 files, 5,422,503 compressed bytes / 19,904,298 installed bytes. No panel or Python assets changed.

Local coherent-diff review traced registration, typed lookup, catalog copy/delete, entity copy,
split keeper and solver identity-loss paths. It corrected the cross-kind catalog remap and removed
unreachable catalog-only resolution handling and unused reference helpers. The returned-reference
defect was reproduced and rechecked on the installed host. The required independent review did
not run: spawning a reviewer and resuming the earlier independent reviewer both returned
`agent thread limit reached`. Implementation-author investigation is not counted as that review.

## Remaining gate

A06's named current-host cases now have evidence. Before closing P1-D, a fresh review session must
review this coherent implementation against the architecture rubric and the stronger `simplify`
lane, including the final domain-failure reporting change. Keep P1-D open until that review and
any required corrections are complete. P1-E's HBJSON/report workflow and P1-F remain pending;
SketchUp 2023 and Windows acceptance remain separate gates.
