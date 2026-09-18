# Decision register

DATE: 2026-09-18
STATUS: D1-D11 confirmed 2026-09-18. No implementation authorization.
AUTHOR: Ed May, BLDGTYP, with Codex review

This register collects only choices that change the product boundary, architecture, roadmap or
public posture. Feature-local interview questions remain in their owning PRDs. Confirmed decisions
are folded into their owners. No program decision in this register remains open.

## Program decisions

| ID | Status | Decision | Consequence | Owner |
| --- | --- | --- | --- | --- |
| D1 | Confirmed | Phase 3 is the first internal envelope-model release candidate; Phase 4 is the complete MVP. Trial notes must state that Phase 3 still needs downstream mechanical entry | Fixes the sequence without delaying the first end-to-end trial for mechanical breadth; public release still needs Gate A | [ROADMAP.md](ROADMAP.md) |
| D2 | Confirmed | If HBJSON succeeds and an optional METr exporter fails, commit the canonical HBJSON/report pair, record the exporter failure in both report and panel, and leave any prior METr file untouched | Keeps HBJSON independently useful and the exporter seam honest | [validation-and-export](features/validation-and-export/PRD.md) |
| D3 | Confirmed | The MVP supports linear thermal bridges only. Point thermal bridges and chi-values are wholly outside MVP; never encode one as a fake 1 m linear bridge | Limits the public promise to what the canonical artifact can represent correctly | [thermal-bridges](features/thermal-bridges/PRD.md) |
| D4 | Confirmed | The primary tab is **Systems**, with Equipment, ERV ducting and Hot-water piping as peer subtabs and one work surface at a time | Avoids primary-tab sprawl and keeps drawn distribution systems distinct from equipment | [UI baseline](ui-baseline/README.md) |
| D5 | Confirmed | Keep the repository and UI kit AGPL for MVP. Closed systems connect through HBJSON, a library file or HTTPS. In-process closed-source embedding is unsupported; revisit a separate package only for a real adopter | Preserves the useful integration boundaries without a premature package and license split | [LICENSING.md](../docs/LICENSING.md) |
| D6 | Confirmed | **Export model library to file** opens an explicit choice dialog, defaults to all supported kinds, offers selected records only when a selection exists, and never derives scope from filters or hidden rows | Makes the complete export the safe default without confusing table state with data scope | [libraries](features/libraries/PRD.md) |
| D7 | Confirmed | Ship and distribute no climate datasets. Permit manual entry/paste and user-owned climate files. Permit public EPW use by sending the user to the Ladybug EPW Map to obtain a file, then convert the selected local hourly EPW with honeybee-ph `Site.from_epw()`. Store a model-owned snapshot with provenance; never imply certification approval | Reuses the existing converter, keeps the core offline after import, and avoids a bundled catalog or redistribution claim | [climate-data](features/climate-data/PRD.md) |
| D8 | Confirmed for development | Keep the current PassiveBuilder name and PH-Tools repository home during development. The public name and long-term organization remain deliberate launch decisions; move later if needed | Avoids premature repository churn without treating the current name or organization as final | [FOUNDING_BRIEF.md](FOUNDING_BRIEF.md) |
| D9 | Confirmed | EPW-derived monthly data may be used for preliminary demand work and overlays. A climate-bearing METr export remains blocked until the user supplies authorized peak-load values by manual entry, paste or a user-owned dataset. Never synthesize peak loads | Preserves useful EPW-derived monthly data without disguising it as a complete or certification-ready climate | [climate-data](features/climate-data/PRD.md) |
| D10 | Confirmed | Contributor comprehension and extensibility govern architecture and coding standards. Built-in features use public contracts; provide scripting, namespaced metadata and registered extension data. Apply a repository-local architecture skill within the existing implementation review | Records accepted direction without implementing APIs; exact scripting, lifecycle and registration contracts remain design work. Size metrics guide review rather than force fragmentation | [EXTENSIBILITY.md](../context/EXTENSIBILITY.md), [CODING_STANDARDS.md](../context/CODING_STANDARDS.md) |
| D11 | Confirmed priority | Users' agents must be able to inspect, view and write through a clear public interface designed into the foundation. PassiveBuilder does not build an agent | Public operations support external clients as well as UI and scripts. MCP is a recommended adapter, with transport and delivery choices still open; no implementation authorized | [AGENT_INTERFACE.md](../context/AGENT_INTERFACE.md) |

## Technical gates that need an answer, not a product preference

D11 confirms the agent-access priority and scope. Detailed interface requirements are recorded
in its authority; transport, adapter packaging and exact API choices remain proposed design work.

These gates may produce evidence that forces a later decision. They do not authorize implementation.

| Gate | Passing evidence | If it fails |
| --- | --- | --- |
| PHX in Pyodide | PHX imports without Excel-only dependencies; a synthetic HBJSON converts to METr JSON; wheel licenses and installed payload size are recorded | Keep HBJSON as the MVP artifact and defer the in-extension METr exporter. Do not add a hidden system-Python dependency |
| Window component | Glue, cut, selection, type rewrite, anchor preservation, no-scale behavior, Undo/Redo and reopen pass in a fresh SketchUp process | Reopen the chosen representation before planning Window placement |
| Edge identity | Thermal-bridge, pipe and duct assignments have documented survival or repair behavior across split, weld, cut, Undo/Redo and reopen | Replace edge-owned assignment with an explicit run record before planning the three edge features |
| Overlay fill | Alpha, depth, visibility, hit behavior and performance are acceptable at representative model size | Retain outline-only previews and postpone filled volume/window modes; do not block non-overlay authoring |
| Export consumer | The exact accepted HBJSON loads in pinned honeybee and converts through current PHX to METr with reconciled identities and values | Attribute the producer or consumer defect and narrow the claim. Never mutate correct HBJSON to satisfy a consumer bug |

## Feature interviews that can wait

Units, thermal bridges, each equipment family, piping, ducting and the three post-MVP packets still
have local interview tables. They need answers before their own PLAN.md files, but they do not
block the foundation or the walking-skeleton scope except where the roadmap says otherwise.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | Consolidated cross-cutting decisions found during the scoping review. |
| 2026-09-18 | Ed confirmed D1-D8. D7 now reuses honeybee-ph's EPW conversion and distributes no datasets. D8 is explicitly a development home, not a final public-name decision. Added D9 for the unresolved EPW peak-load boundary. |
| 2026-09-18 | Ed confirmed D9: EPW-derived monthly climate is valid for preliminary work; user-supplied peak-load cases are required before climate-bearing METr export. |
| 2026-09-18 | Ed accepted contributor-first architecture and requested durable context plus a project review skill. Recorded D10 and routed implementation review through AGENTS.md. No product code authorized or implemented. |
| 2026-09-18 | Ed established external-agent access as a foundation priority. Recorded D11, interface design requirements, the future user guide and review routing. Transport and adapter selection remain proposed. |
