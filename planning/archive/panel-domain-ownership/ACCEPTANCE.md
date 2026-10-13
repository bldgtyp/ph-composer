# Panel domain ownership acceptance

DATE: 2026-10-13
STATUS: Offline cases run and passing at merge (PR #108); native receipts in STATUS.md. Current host only, not the support floor.
BASELINE: `cfe01a6aad99a0e09d5ecf0de5659c606d7ba4f9`
PLAN: [Contract and stages](PLAN.md)

Fixtures are synthetic. Review probes establish the baseline ownership findings, not acceptance
of the proposed contract. Expected numbers come from independently specified fixture geometry
or the canonical Ruby operations, not from copying the new projection's output.

| ID | Case | Observable result | Evidence |
| --- | --- | --- | --- |
| PD01 | Perimeter, fully shared, partly shared, merged spans and Empty elements | Published edge classifications match `Grid.classify`; only current glazed/perimeter edges permit paint; Empty has no paintable edge | Ruby projection and JS consumer fixtures |
| PD02 | Null row/column dimensions and incomplete products | Eligibility remains available; thermal incompleteness is reported separately; no extra domain fallback in JS | Ruby read and `window_editor_test.js` |
| PD03 | Same layout, reordered arrays, different Type/element IDs and names | Ruby `copy_key` and slots match; copied assignments reach correct target IDs; source/target names and IDs remain their own | Ruby `Installs.copy` versus staged UI submission |
| PD04 | Different dimensions, null versus numeric dimensions, kind or merged span | Copy keys differ exactly where current Ruby copy policy differs; incompatible targets are not offered | Parameterized Ruby/UI fixtures |
| PD05 | Unknown edge or missing/malformed topology/slot | Paint/copy sends no request and changes no staged assignments; read-unavailable reason visible | JS failure fixtures |
| PD06 | Valid slot/key with partly shared source | No claim that compatibility guarantees valid Save; canonical current partial/shared validation still refuses final invalid records | Existing Installs/save refusal tests |
| PD07 | Paint, Apply, edit/create/import product and copy within one session | Facts remain attached to unchanged topology; one Save carries all final assignments/products with authored expected values; derived fields absent from write params | JS payload and Ruby save tests |
| PD08 | External edit changes a staged target's topology/settings | Original draft/facts remain coherent and visible; stale Save refuses with no partial writes; Cancel still available after settlement | Deterministic interleaving plus scoped native observation |
| PD09 | Cancel, withdrawn Type or Model switch | Cancel writes nothing; old derived facts never cross sessions; retained callbacks do not stage/send into a replacement session | Existing lifecycle tests extended |
| PD10 | Query Type with panel closed | Discover/describe/result schema and snapshot row agree for new fields; read changes neither dictionaries, revision, selection nor Undo | Public API walkthrough and schema tests |
| PD11 | Zone with recorded complete/incomplete and unclassified Faces | Total includes all Faces; unclassified subtotal includes only Faces with no record; explicit expected sums returned in square metres | Zone read fixture with known geometry |
| PD12 | Zone with zero Faces | Both totals are numeric zero, not null or an unavailable placeholder | Public read and UI formatting |
| PD13 | Shared Zone record ID on two occurrence paths, nested Zone, scaled/mirrored instances | Separate path-qualified totals use each transform and existing membership; no identity merging or double inclusion of nested membership | Occurrence/geometry fixtures plus native synthetic Model |
| PD14 | Face filter, collapsed summary, more than 50 unclassified Faces, Zone paging/path filter | Quantities remain full-occurrence totals; visible subset/expansion/page boundaries do not change them | Overview and public paged read tests |
| PD15 | Whole `.list` and `.all`; authored `fields` projection | Whole rows carry `face_area_m2` and `unclassified_face_area_m2` beside `face_count`; Type rows carry `display.install_topology`; `fields` keeps its authored-value meaning | Public schemas/reference fixtures |
| PD16 | Classify/unclassify or change geometry; Undo/Redo | Next revision updates subtotal/total appropriately; UI displays public values and restores correct totals with Undo/Redo | Offline refreshed snapshots and scoped native check |
| PD17 | Unreadable record/geometry or failed summary read | No invented zero, omitted-Face success or stale-current total; structured read failure and existing unavailable UI shown | Fault-injected read and panel fixtures |
| PD18 | SI/IP and display precision change, Area ordering | Display converts/rounds published SI values only; numeric sort uses unrounded public total; stable path/selection identity retained | `overview_panel_test.js` |
| PD19 | Representative larger synthetic Zone inventory | Record traversal and area capture counts/read time recorded; no cross-revision native-object cache or per-target whole-Model traversal introduced | Focused count/cost observation, no unsupported speed claim |
| PD20 | Dependency and packaging boundary | No Python/honeybee in UI; no feature-specific shell/session code; old eligibility/Area domain algorithms absent; asset/API manifests current | Static scope review and normal generators |
| PD21 | Snapshot revision advances or an optional focused read completes after replacement/cancellation | Facts remain bound to their originating session/revision/Type/draft generation; stale completion does not replace any active values/facts pair | Controlled result-order fixture if focused reads are introduced |

Final implementation evidence consists of focused checks, relevant coverage/available complexity
results, one coherent architecture review and supported-Ruby `make ci`. Chromium 88 lint is a
compatibility gate. The native observations exercise incomplete Type painting, compatible copy,
Save/Cancel/stale refusal and transformed Area with real controls and public read-back. Record
host/version, fixture/build identity and actual assertions. A current-host pass does not establish
the pending SketchUp 2023 floor proof, Windows support, release or certification acceptance.

No source tests, manifest refresh, benchmark or native run is part of this planning-only delivery.
