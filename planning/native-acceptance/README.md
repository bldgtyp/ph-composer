# Native acceptance ledger

DATE: 2026-09-30
STATUS: Development tooling implemented. Historical Phase 1 acceptance remains with its packet.
ISSUE: none (local tooling work)

[`cases.json`](cases.json) holds case identities, owning authorities, deferred scope and conservative
source dependency patterns. [`results.jsonl`](results.jsonl) is an append-only result index. Initially
it contains 15 historical evidence pointers, not reconstructed host runs. Detailed case requirements
and closure remain in [the owning acceptance register](../archive/phase-01-faces-and-zones/ACCEPTANCE.md). Add finer case IDs
when a gate needs independent reruns; a partial subcase does not close its parent.

The Phase 1 packet is archived and stays unchanged. A rerun after that records its synthetic summary
under [`evidence/`](evidence/) and, when another agent runs it, its procedure as a handoff beside
this file, such as the [R06 rerun](R06-RERUN-HANDOFF.md) of 2026-09-30.

## Resume and screen affected checks

```sh
uv run tools/hostkit/acceptance_ledger.py validate
uv run tools/hostkit/acceptance_ledger.py status --changed src/ph_composer/colour_by/service.rb
uv run tools/hostkit/acceptance_ledger.py snapshot A12 --output _private/host/a12-baseline.json
```

`--changed` is repeatable and takes repository-relative paths, including deleted/renamed paths.
Supply both sides of a rename. This is a dependency screen, not automatic acceptance. Check newly
added feature dependencies and change the catalog when its coverage is incomplete. Source
fingerprints include tracked and nonignored new files matching the case, with names and contents.
Only affected cases need targeted repeats; the packet's required final gates still apply.

| Change or condition | Checks to reconsider |
| --- | --- |
| Geometry, identity, records, operations or observer/session contracts | Dependent authoring/reference/export cases; relevant rollback, native Undo/Redo and reopen |
| Colour-by drawing/cache or visibility | A08 native pixels/occlusion/invalidation and affected timing; authoring if picking changes |
| Panel/tool keyboard, navigation or focus | A04/A07/A09 and export panel/lifecycle cases affected by the control |
| Translation, exporter, report, privacy or artifact commit | A10 to A14 and A16 as matched by dependency paths; canonical reload/reference/accounting/recovery |
| Runtime wheels, manifest, packaging or environment | Runtime/payload/parity and installed-build cases; platform proof is specific to that environment |
| Bridge/control helper or fixture/assertion recipe | Native cases depending on it; a helper change can change what the test actually establishes |
| Host/Ruby/OS/graphics/controller, fixture hash, installed RBZ or composition changes | Review corresponding native conditions even if source fingerprint is unchanged. A new session alone is not evidence of new product behavior |
| Documentation-only narrative/status edits | Focused consistency/link review; no automatic code/host rerun. Changed contracts or acceptance criteria require dependency review |

Historical evidence is preserved unless relevant changes or a changed claim make it insufficient.
The tool cannot prove the current environment from source hashes; a source-unchanged result is not
an automatic current-host pass. Unmapped changes require review of the catalog rather than silence.

## Record a new observed run

Capture a baseline before the action. Fill a copy with `evidence_kind: "observed"`, the observed
`outcome` (`pass`, `fail`, `blocked`, `unknown`), and `assertions`, each containing `status` and a
concrete `observation`. Add existing repository-relative `evidence` paths and a `control` route
(`bridge`, `native`, `human`, `combined`). A native/mixed result also needs `host` fields:
`sketchup`, `ruby`, `session_id`, `fixture_id`, `fixture_sha256`, `rbz_sha256`, `composition`
(`normal` or `synthetic`). Include optional `os` and `graphics` when they govern the claim.

The host tuple and hashes must be obtained from the actual tested host, fixture and installed RBZ;
`git HEAD`, a built RBZ and a fixture name alone cannot prove the installed build. Snapshotting
source is read-only and performs no host interaction or acceptance case. Record observed timestamps
and assertions, not inferred outcomes. The result is an attestation, not a test runner.

```sh
uv run tools/hostkit/acceptance_ledger.py record --input _private/host/a12-observed-summary.json
```

Only synthetic, publication-safe summaries belong in tracked results. Store raw Models, captures,
traces and artifacts in gitignored `_private/`. Review the summary before recording; arbitrary
free text still needs human/agent judgment. Passing new records require a matching source baseline,
existing evidence and all assertions passing. Native-interaction cases refuse a bridge-only result.
Deferred cases require a separate scope decision and catalog update before new observed acceptance.

## Restoration and check reuse

Keep one independent reviewer for the coherent task. Record deterministic checks at exact build
checkpoints and the reason for rerun; do not turn every case into a new review/full-suite cycle.
The ledger reports observations, not merge/release readiness. Normal-build restoration after
private providers, faults or runtime delays is an additional observed case, with its own readback.
Use the [project skill](../../.agents/skills/ph-composer-native-acceptance/SKILL.md) and
[control reference](../../context/NATIVE_CONTROL_CAPABILITIES.md) for the native procedure.
