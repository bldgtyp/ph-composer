# Cleanup during follow-up work

The review found stale or incomplete guidance, but did not establish that a shipping API can be
deleted safely. Cleanup belongs with the refactor that replaces its use. Preserve data compatibility
and identify consumers before removing a public name.

| Surface | Current evidence | Cleanup owner and action |
| --- | --- | --- |
| `context/AGENT_INTERFACE.md` feature inventory | Phase 2 inventory stops before Spaces; broad capture/context requirements coexist with implemented-contract prose | W2/W5: add Spaces operations and limitations; mark each context/capture guarantee as implemented or proposed |
| `docs/API_QUICKSTART.md` | Tested prepared-selection/Assembly example, predates Spaces | W2/W4: retain the useful example; add a root-start Spaces recipe after the missing operations exist |
| `docs/AGENT_ACCESS.md` | Correctly states no external connection; date and available-feature summary predate Spaces | W2/W4: update feature coverage; replace unavailable-client section only when exact-client acceptance exists |
| `tools/examples/authoring/spaces_walkthrough.rb` | Geometry traversal/context changes surround public operations | W2: retain native fixture setup, identify it explicitly, and add a public-only client segment; avoid claiming fully semantic parity from this script |
| `tools/hostkit/.index.md` | Still says predecessor Spaces gate commands stay behind until owning stages; Spaces is now implemented | W2/tooling docs: replace that current-routing sentence with present walkthrough and acceptance pointers |
| Repository architecture/native skills | Development review and host acceptance, not model-operation recipes for users | W4: keep these internal; make a separate operating guide rather than adding end-user connection steps to them |
| 47,774-line generated API reference | Current and verified against registration; expensive to consume wholesale | W4: preserve generation, add concise discovery/task recipes and optional per-owner outputs/index if actual clients need them; never hand-edit the generated file |
| Archived review/feature packets | Earlier general review is resolved; Spaces closure contains historical narrative and recorded follow-ups | Keep as evidence. Route current work through the active packet/status; do not delete history or reopen old findings from stale text |
| Provider `refresh` alias and old grid commands cited in prior review | Prior review records their replacement; current registry uses the newer names | No new deletion inferred. Do not reimplement already-completed cleanup |
| Future adapter configuration/schema copies | No end-user adapter exists yet | W4: generate one mapping from registry; remove temporary spike wrappers/configs when selected implementation supersedes them |

## Components to preserve

Keep the development eval bridge for development/native acceptance, excluded from normal client
installation and the RBZ. Keep the asset server limited to runtime assets. Neither is a stale
agent connection to rename or expose.

Keep complete `.all` projections while the panel's snapshot sections consume them. The agent reads
can become smaller without deleting the panel contract. Likewise, keep proposal participants internal;
their discovery presence is useful contributor metadata and does not make them callable MCP tools.

Keep native menu/tool entrypoints for complete hand authoring. Shared public operations should serve
both clients; replacing pointer tools with agent-only APIs would violate the product boundary.

## Removal checks

For any actual removal, identify registration, panel/native/script consumers, generated references,
fixtures and compatibility promises. Replace calls in the owning slice and test old persisted data.
Apply a documented deprecation/version policy to public operations. Delete dead code only after
references and affected workflows are checked; a search count alone does not prove it is unused.
