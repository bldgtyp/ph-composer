# P1-D native split identity recovery

DATE: 2026-09-29
STATUS: Implemented and current-host verified on the implementation branch. A06 remains open for
Face/Zone extension-reference targets and one-to-many pairing.

## Accepted policy and implementation

Ed accepted [P1-Q5](../DECISIONS.md#p1-q5-native-split-identity-frontier): keep one old Face identity
through stored original endpoint-path proof, or explicit selection when proof is absent. Geometry
does not choose the keeper. Other pieces receive new identities. Invalid Surface links retire
within an explicit mutation scope; supported payloads survive and unsafe data refuses before writes.

The public action is `ph_composer.zones.repair_split_face`. Its inputs are `zone`, `face_id`,
`zones` and optional `retaining_entity_path`. Preview returns the retaining path and basis,
before/after piece references and retired endpoints. Missing proof returns `identity.choice_required`
with candidate paths. The native Extensions → PH-Composer → Repair → Repair split Face identities
client uses the same preview/action contract and asks for confirmation. Selection supplies the
choice only when proof is absent. Model switching during confirmation cancels the client write.

The action checks the entire duplicate set, unique mutable Zone occurrences, stamps, common
Surface envelope, reciprocal counterpart and scope. Installed extension copy rules validate every
piece before writing. Ordinary Face resolution remains strict about duplicate identities. One
operation owns all writes and rollback. The [public walkthrough](../../../tools/examples/authoring/split_identity_walkthrough.rb)
uses the reviewed preview's revision and digest; it does not refresh the revision before invocation.

## Fresh installed SketchUp evidence

SketchUp 26.1.188, embedded Ruby 3.2.2, macOS. `make install` installed the new Ruby action/menu;
fresh processes 2573, 2934, 3093, 3264, 3595 and 4504 exercised the cases below. Fixture geometry was
split with SketchUp's native Line tool before installation. All fixtures and full dictionary,
material, geometry and reference snapshots remain gitignored under `_private/host/`.

| Case | Observed result |
| --- | --- |
| Paired Surface split, two 6 m² pieces against one 12 m² counterpart | Preview kept `fac_c8e930f1a41f` on stored original path `[48909]`; piece `[49014]` received a new ID. Both copied envelopes and the reciprocal counterpart `[48937]` retired. No Surface endpoints remained. |
| Choice conflicts with proof | Choosing `[49014]` refused `identity.choice_conflicts`; exact full fingerprint unchanged, including modified state. |
| Counterpart outside mutation scope | Refused `scope.incomplete`, naming the counterpart Zone; exact full fingerprint unchanged. |
| Failure after second Face write | Development-only injected failure returned `operation.failed`, `effect: rolled_back`; all dictionaries, geometry, records, materials and modified state matched exactly. |
| Paired split Undo/Redo and fresh reopen | Native Cmd-Z restored the full pre-repair data and saved modified state; Cmd-Shift-Z restored the result. Save/fresh reopen matched all captured data exactly. |
| Solve after identity recovery | Reported `adjacency.multiple_neighbours`, proposed no pairs and changed no data. Identity recovery does not solve a one-to-many overlap. |
| Unavailable payload on native Surface split | Preview and invocation refused `copy.rule_missing` for `unavailable.fixture` before writes; exact full fingerprint unchanged. |
| Non-Surface split without historical endpoint proof | Refused `identity.choice_required` with both actual paths `[48910]` and `[48916]`; read/preview changed no data. |
| Native menu Cancel | Confirmation showed the selected keeper, one new identity and affected Zone. No cancelled invocation; full fingerprint including modified state was exactly unchanged against the baseline taken in that edit context. Opening the native edit context had already marked the Model modified. |
| Native menu explicit choice | Selecting the newer native piece `[48916]` and confirming kept `fac_0b1748efa842` there; original native piece `[48910]` received a new ID. Both remained Wall/Outdoors with exact original stamps, user data and registered extension payloads. |
| Supported reference meaning | Both extension `external_id` values still resolve to the same live Attached-zone record `atz_avRVD0HdMXSY`. Literal UUID strings in user data and undeclared marker fields remain unchanged; they are not treated as references. |
| Choice Undo/Redo and fresh reopen | Native Undo restored the duplicate records exactly; Redo restored the repaired result exactly. Save/fresh reopen retained all captured data and the same live referenced record. |

Record comparison also confirms unchanged loop geometry, paths, stamps, face types and supported
payloads across all 13 Faces in the paired fixture and all seven Faces in the choice fixture.
The choice fixture's development-only extension registers through the public registry; it adds no
shipping feature or privileged core branch.

## Offline gates and review

Final `make ci`, `make coverage` and the Ruby 2.7.2 full suite pass: 537 Ruby tests / 2,326
assertions, 174 JavaScript tests, 84 Python tests and nine hostkit tests / 30 assertions.
Coverage is Ruby 96.7%, JavaScript 98.2%, Python 97.46%. Ruby lint/syntax, fixture, manifest,
runtime-pin and RBZ checks pass. No panel or Python payload changed.

One independent architecture/simplify review found a stale-preview defect in the development
walkthrough: it refreshed the revision before invoking. The correction uses the preview revision,
handles refused previews explicitly and has regression coverage. The reviewer confirmed the fix
and found no remaining actionable source defect. The review model was GPT-6 Sol, the available
fallback for the skill's unavailable Terra model. Native acceptance is recorded separately above.

## Remaining boundary

This closes the native duplicated-Face identity recovery slice, not A06 as a whole. Face/Zone UUID
extension-reference targets are not yet registrable. One-to-many pairing remains reported without
geometry cuts or pairs. The subsequent [atomic Attached-zone continuation](p1-d-attached-zone-atomic.md)
completes A07's named current-host cases. A08's isolated GPU timing remains open. SketchUp 2023,
Windows, distribution and certification claims are outside this run.
