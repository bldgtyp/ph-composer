# Workflow coverage

Baseline: `60982fc73af6841f0c2bc5f55136dd21cad20930`, 2026-10-17. This matrix assesses the
implemented application operations. External access remains unavailable for every row until
A01 to A03 are addressed. An explicit-path operation is not fully accessible if the client has
no public way to discover the path or satisfy its context precondition.

## Runtime inventory

| Owner | Queries | Actions | Views | Setup | File exports |
| --- | ---: | ---: | ---: | ---: | ---: |
| Records | 1 | 0 | 0 | 0 | 0 |
| Assemblies | 5 | 21 | 0 | 0 | 0 |
| Zones and Faces | 20 | 26 | 7 | 0 | 0 |
| Windows | 14 | 39 | 3 | 0 | 0 |
| Spaces | 10 | 15 | 8 | 0 | 0 |
| Colour-by | 1 | 0 | 5 | 0 | 0 |
| Library | 5 | 1 | 0 | 5 | 1 |
| Approved locations | 1 | 0 | 0 | 6 | 0 |
| **Total** | **57** | **102** | **23** | **11** | **1** |

There are also two internal proposal participants and five export task methods. Participants are
discoverable composition contracts, not externally callable actions. The counts and serialized
sizes are retained in [inventory.json](evidence/inventory.json). They were collected from live
registration in the offline stub, not by counting source occurrences.

## Subsystem review

| Workflow | Available public affordance | Assessment / follow-up |
| --- | --- | --- |
| Discover installed capabilities | `discover`, `describe`, record kinds and reference targets | Strong registry-derived schemas, units, examples and refusals. Add context/grant metadata, A10 |
| Read/update Zone values and managed choices | `zones.list`, `update`, `update_field`, options queries/actions | Explicit references, field projections and expected-value guards |
| Make a Zone from existing entities | `zones.make`, `list.make_zone` | Explicit parent/IDs supported. Selection convenience needs a prepared host selection; no generic untagged entity inventory |
| Classify, suggest, reverse or assign an Assembly | Face list/host_context and named actions | Semantic operations shared with tools; no adapter domain logic needed |
| Solve and retire adjacency | `solve_adjacency`, `retire_adjacency` | Public scope/preview/action contract. Keep native split/identity acceptance separate |
| Split/copy repair, Make Independent, Restore | Named Zone/Face repair actions | Public refs and structured refusals; native geometry copy initiation is a host workflow |
| First Space from loose Zone Faces | `spaces.create_preview`, `spaces.create` | Public action, missing Zone context entry, A08 |
| New Volume from loose Space-root Faces | `spaces.volumes.create`, context commands | Missing candidate Face discovery, A09 |
| Mark/unmark floor | `spaces.floors.mark`, `unmark` | Explicit paths work. Unmarked internal targets cannot be read, A09 |
| Space/Volume/Floor fields and metrics | `spaces.list`, `update`, `batch_update` | Ruby owns metrics and guarded writes. Correct aggregates/bounds and improve editable schemas, A06/A07/A10 |
| Height, weighting and airflow defaults/overrides | Space edits, `settings.update` | Public operations; agents need no copied calculation rules |
| Height from solid | Selected-solid read, explicit solid preview/action | Known solid paths work; unfamiliar solid discovery/picking remains a host step |
| Protect/open/close/restore a Volume | `unprotect`, `context.open`, `context.close`, `restore_position`, `locate` | Public protection behavior; root exit gap, A08 |
| Move Space to another Zone | `move_to_zone` | Explicit refs and Zone stamping participant; closed-context precondition requires A08 |
| Copied Space/Volume/Floor identity | Findings plus `make_independent`, Zone transition hooks | Public repair and ownership-aware composition. Native copying itself is not an API operation |
| Metadata and extensions | Entity metadata actions, catalog CRUD, kind/target descriptors | Shared validation/reference machinery. Do not interpret user metadata as instructions |
| Material and Assembly authoring | CRUD plus Layer/Layer-Segment actions | Broad semantic parity for Builder gestures, with metrics/findings in reads |
| Window products and Type design | CRUD, grid edits, batch `installs.save` | Strong explicit operations; existing authoring coordinator retains domain ownership |
| Window placement/repair | Unit `place`, `remove`, `rehost`, `swap_type`, reset/restore/flipped Type and identity repair | Explicit host Face, anchor and SI offsets. Findings name repairs with params |
| Optional libraries | Provider/catalog/in-file reads, preview/copy and assignment participant | Provider-independent, declared schemas and bounded catalog pages |
| Machine library setup and file export | `setup`, `export_file`, approved location IDs | Correct separate grants and native location ownership. Named connection/revocation work remains A02/A14 |
| Colour-by and labels | State, activation, legend select/isolate/filter, readout and Spaces label commands | Semantic controls exist. Generic camera/capture is separate work, A12 |
| Validate/export | Preflight, explicit repairs, task start/status/cancel/latest | Useful detached tasks and destination-state checks. Add artifact retrieval and revocation policy, A11/A14 |
| Generic geometry drawing/transform/copy | No general application operation | Explicitly document host-required scope. Add bounded geometry operations only for selected real workflows |
| Save/open/close SKP, Undo/Redo | Development host/native controls | Do not expose lifecycle or history control incidentally through eval. Define scope and user-work protection before adding supported commands |

## Strong paths worth preserving

- [API quickstart](../../../docs/API_QUICKSTART.md) and its
  [executable client test](../../../tests/api_client_test.rb) use public discovery/read/preview/write/read-back,
  stale refusal, retry, Assembly assignment and export task cancellation.
- [Windows placement walkthrough](../../../tools/examples/authoring/windows_placement_walkthrough.rb)
  demonstrates the explicit-reference counterpart to pointer placement. That is a useful pattern for
  the Spaces candidate and context work.
- [Spaces walkthrough](../../../tools/examples/authoring/spaces_walkthrough.rb) covers public domain
  operations after native geometry/context setup. Label its native setup clearly; retain its fixture
  utility while adding a strictly public client scenario.
- [Separate library provider example](../../../docs/LIBRARY_PROVIDER_EXAMPLE.md) exercises an outside
  contributor. Use an equivalent outside-feature test to prove the MCP adapter remains generic.
- [Spaces export](../../../src/ph_composer/features/spaces/export.rb#L34) declares a contributor and
  preflight, and [Python composition](../../../src/ph_composer/python/ph_composer_translation/composition.py#L19)
  attaches it through the existing section contract. Agents should consume this canonical output.

## Verification limits by layer

Dispatch, registration, session/retry and selected feature paths received source review and focused
offline suites. The export task, approved-location and API-reference suites passed. Python composition
and snapshot/privacy boundaries were inspected for access design; this was not a fresh certification
or numerical-translation audit. JavaScript was inspected only where it establishes private panel
context or workflow coupling; there was no visual UI review or browser run.

[Spaces acceptance](../phase-03a-spaces/ACCEPTANCE.md) and its
[status ledger](../phase-03a-spaces/STATUS.md) remain the feature evidence, including their
recorded follow-ups. This review adds no new native-host acceptance and makes no SketchUp 2023,
Windows, METr or public-distribution claim.
