# Phase 2 envelope: review findings and refactor packet

DATE: 2026-10-01
STATUS: In progress. Review complete and Ed's eight decisions recorded on 2026-10-01. R01 is
merged (PR #16); R02 is merged (PR #17) with its host gate passed; R03 is merged (PR #18); R04 is merged (PR #19); R05 is merged (PR #20) with its host gate passed; R06 is merged (PR #21) with its host gate passed; R07 is merged (PR #22); R08 is merged (PR #25) with its host gate run; R09 is merged (PR #26); R10 and R11 are requested.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft). Reviews [PR #15](https://github.com/bldgtyp/ph-composer/pull/15), merged 2026-10-01 as `c687a73`, which closed [#14](https://github.com/bldgtyp/ph-composer/issues/14).

An independent whole-diff review of `codex/phase-02-envelope` at `7021eab` against `origin/main`
(`26a87a2`), using `.agents/skills/ph-composer-architecture-review/SKILL.md` as the rubric and
`context/CODING_STANDARDS.md`, `context/EXTENSIBILITY.md`, `context/AGENT_INTERFACE.md` and
`context/CONTRACTS.md` as the authorities. This packet records findings for later agents to scope
and implement. It changes no code and authorizes none.

## Read order

1. This file: scope, verdict, the ranked table, decisions Ed owes.
2. The finding file being worked. Each is self-contained: locations, the governing rule, what was
   observed, the consequence, the smallest adequate correction and its verification.
3. `planning/archive/phase-02-envelope/DECISIONS.md` and `CONTRACTS.md` for what Phase 2 already
   decided. Findings that revisit a recorded decision say so.

## Scope and method

Read in full: the diff to `core/`, `session/`, `shell/`, `export/`, `extension.rb` and
`features/zones/`; all of `features/assemblies/`, `features/windows/`, `library/`; the Python
translation package; the panel composition, shared kit modules and section entry files. About 19,000
lines of shipping source out of 75,966 added (32,150 of the additions are the generated
`docs/API_REFERENCE.md`).

Checked by measurement: the registered operation inventory through `API.discover` and `API.describe`;
cross-feature constant and registry reaches by grep; duplicated helpers by grep; five suspected
behaviours by scratch tests on Ruby 3.2.2 (not committed).

Not reviewed, or reviewed only by sampling:

- Test quality and coverage. The suite was not audited; counts in the PR body were not re-run.
- Visual and interaction quality of the screens (UI polish skill), CSS, and most of the larger panel
  files (`window_cards.js`, `window_editor.js`, `assembly_editor.js`, `inventory_grid.js`,
  `record_edits.js`) beyond grep checks for layering.
- `tools/`, the hostkit, vendor manifest, `starter-library/`, fixtures and goldens.
- Thermal formulas against the predecessor's reference cases.
- Any host behaviour. No SketchUp run. `make ci` was not re-run locally; both PR jobs (Ruby 2.7.2
  and 3.2.2) report pass on GitHub for `7021eab`.

## Verdict

The foundation held under three new features. `shell/`, `session/`, `core/`, `colour_by/` and the
Ruby side of `export/` name no feature. Handlers add steps to one proposal and never write. The
definition delete with retargeting, the library kind adapter seam, table contributions, nested
reference declarations and `request.query` are real contracts that built-in features use. No
thermal calculation leaked into JavaScript. Every one of the 90 new operations is discoverable and
reachable through the API with the panel closed; three of them open native dialogs when called
(R03 item A).

The problems cluster where a feature needed something the foundation did not yet offer and worked
around it locally. Four of those gaps (R02, R05, R06 and R07) will be hit again by Spaces and thermal bridges,
so they are worth closing as contracts before Phase 3 rather than after. The agent surface is broad
but uneven in three places that matter: operations that open native dialogs, a `view` grant that now
reaches machine configuration, and finding codes that differ by read.

No finding loses Model data. Two can lose per-machine library configuration (R03 item B, R11 item
9). Nothing here blocks merging PR #15 on correctness grounds. Ed decided on 2026-10-01 to merge it
as is and take every finding on its own branch (see Sequencing).

## Findings

Numbered in the order they are to be worked: R01 first, R11 last. Class follows the skill:
reproduced defect, evidenced contract violation, unverified risk, optional improvement.

| ID | Finding | Class | Size |
| --- | --- | --- | --- |
| [R01](R01-context-doc-drift.md) | `context/` not updated: stale Extensibility paragraphs, no Window Unit storage or library mechanics in Contracts, glossary gaps. **Merged 2026-10-01, PR #16** | Evidenced, docs only | Small |
| [R02](R02-handler-read-context.md) | Colour-by projections and menus get no read context; features use `API.connect` per call (caller registry grows, reproduced), `Registry.current`, and instance variables smuggled onto the request | Reproduced defect inside a contract gap. **Merged 2026-10-01, PR #17; host gate passed** | Medium |
| [R03](R03-agent-access.md) | Agent access: native dialogs inside public operations; `view` grant removes machine configuration (reproduced); implicit Unit identity repair; offset paging; 218 of 233 params undescribed; untyped `grid.element`; defaults depend on display preference (reproduced, a recorded port); agent docs not extended | Mixed, two reproduced. **Merged 2026-10-01, PR #18** | Medium, several small |
| [R04](R04-findings-and-codes.md) | Finding codes: no `noun.condition` form, two codes for one condition, codes derived from message text, Zones matching Assemblies' codes, `request.stale_revision` (reproduced), 48 codes missing from the table | Evidenced contract violation. **Merged 2026-10-02, PR #19**, with R09 item 5 | Medium, touches panel and report |
| [R05](R05-export-layering.md) | Export and translation layering runs upward: `ZoneSection` requires Apertures, Zones declares Window result fields, Windows calls a Zones module directly, shared conformance names Windows | Evidenced contract violation. **Merged 2026-10-02, PR #20; E06/E14 host readbacks pass** | Large, architecture |
| [R06](R06-entity-target-resolution.md) | No public way to resolve a Face reference to a live Face; Windows re-implements Zones' path resolution in six places and loads the whole Face table per Unit operation | Evidenced contract gap, one unverified performance risk. **Merged 2026-10-02, PR #21; host gate passed** | Medium, architecture |
| [R07](R07-operations-coupled-to-request.md) | Operations read `request.params`; reuse duplicates the request, pulls actions out of registration staging and replays handler blocks; partial engine stand-in built with `define_method` | Evidenced contract violation. **Merged 2026-10-02, PR #22** | Medium |
| [R08](R08-window-unit-steps.md) | Seven Unit steps each carry their own copy of the same guards and vector maths; planning lives in long constructors; one matcher swallows every error; R06's four placement follow-ups (batch locate, hover refusal, Place over-reading, a redundant Reset check); R04's Unit read and preflight disagreement and side-less Type findings; R05's unmeasured matcher cost. **Merged 2026-10-02, PR #25; host gate run** | Optional improvement, one silent-failure pattern | Medium |
| [R09](R09-definition-feature-pattern.md) | Definition features fork one generic path by kind, build kinds and actions from positional tables, and repeat schema builders six times; a library callback's `find` refuses with a different code (from R07); the provider factory reads `Registry.current` (from R02); optional `refuses:` on operations (from R04) | Optional improvement. **Merged 2026-10-02, PR #26**; `refuses:` left optional | Medium |
| [R10](R10-ui-kit-organization.md) | Library pane hard-codes Materials and Attached zones beside a surface seam only Windows uses; feature screens share a flat directory with the kit; its host gate carries R03's unrun library dialog, paging and grid checks. Item 5 resolved by R04 | One evidenced, rest optional | Small to medium |
| [R11](R11-readability-and-lint.md) | Mechanically wrapped lines, inconsistent continuation style, folded conditions; `Layout` cops are off; the frozen request's params are not frozen (from R07); a double menu test and unreadable-Type menu reads (from R02); approval dialog before dispatch checks and a one-page walkthrough (from R03); one shared id allocator and the `SchemaFields` alias (from R09). Formatting itself moves to a separate post-merge pull request | Optional improvement | Small |

R05's four export-run follow-ups, one of them a live defect (a Zone with every Face omitted builds
an empty Room that fails to reload), are not refactor items. They are recorded in
[validation and export](../../cross-phase/validation-and-export/STATUS.md), "Owed from the Phase 2
review", for Phase 3's first export section.

## Sequencing

Decided by Ed on 2026-10-01.

**Governing criterion.** PH-Composer has no users, is not deployed and is not in use. Nothing here is
weighed against the state of a running product: there is no compatibility promise, no migration and
no deprecation path to protect. The one criterion for ordering and for how far a change goes is how
well later agents and contributors can read and extend the result. Renames, contract changes and
moved files are free now and should be done completely rather than staged.

**Order.** The findings are numbered in working order.

0. **Merge PR #15 as it stands.** Done 2026-10-01: merge commit `c687a73`, issue #14 closed. The
   accepted Phase 2 build is what landed on main; no review fix was added to that branch.
1. **One new branch and pull request per finding, R01 through R11 in number order**, each cut from
   main after the one before it merges. The finding file is the brief for its branch.

   | Step | Finding | Why here |
   | --- | --- | --- |
   | 1 | R01 `context/` documentation | Documentation only. Gives the later branches current authorities to cite |
   | 2 | R02 read context | Small, and removes the reproduced caller-registry growth |
   | 3 | R03 agent access | The `setup` verb and grant, the clean refusal for scripted callers, the named identity repair, descriptions |
   | 4 | R04 finding codes | The one rename pass. Takes R09's unit-bearing field renames with it |
   | 5 | R05 export layering | Architecture. Starts with a short design note against its recorded decisions |
   | 6 | R06 entity target resolution | Architecture. Design note first. Builds on R05's contracts |
   | 7 | R07 operations and the request | Architecture. Changes how handlers are written, so it follows R05 and R06 |
   | 8 | R08 Window Unit steps | Cleanup behind the existing tests; uses R06's `locate` |
   | 9 | R09 definition-feature pattern | Cleanup. Its field renames already went with R04 |
   | 10 | R10 UI kit organization | Cleanup |
   | 11 | R11 readability | Items 3 to 9 only. Its formatting items wait for the pull request below |

   R05, R06 and R07 land before Phase 3's first stage.
2. **Last: the formatting-only pull request** in
   [planning/refactor/rubocop-layout.md](../../../refactor/rubocop-layout.md).

A branch that changes shipping Ruby, Python or panel assets ends with `make ci` on both Rubies and
the host gates its finding file names. Refresh the vendor manifest after panel or Python changes.

## Decisions before scoping

Ed answered all eight on 2026-10-01. The owning finding file holds the full record of each.

| # | Decision | Recommendation | Blocks | Ed's answer |
| --- | --- | --- | --- | --- |
| 1 | Model assembly: a foundation section with an attachment contract, or Zones stays the assembler? | Foundation section; Zones contributes Rooms and Faces | R05 | 2026-10-01: foundation section, as recommended. Principle: atomic independent entities, composed by higher-level entities |
| 2 | Namespace export result fields by section id? | Yes; makes cross-feature reads declarable | R05 | 2026-10-01: yes, as recommended. Cross-section reads are declared and checked at registration |
| 3 | May a live entity cross a feature boundary through a reference target's `locate`? | Yes, for read and glue only | R06 | 2026-10-01: yes, as recommended. `locate` on the reference target; read and glue only, record writes stay with the owner |
| 4 | Session and machine state commands: new verb and grant, or widen the documented `view` contract? | New verb and grant | R03 B | 2026-10-01: new verb and grant (working name `setup`), as recommended. `view` returns to viewport only |
| 5 | Library export and setup for scripted callers: design authorized paths now, or document as dialog-only and refuse scripted calls cleanly? | Refuse cleanly now; design with the access grant | R03 A | 2026-10-01: refuse cleanly now, as recommended, on condition the later agent work is recorded. Recorded in [agent-authorized-file-access](../../unscheduled/agent-authorized-file-access/README.md) |
| 6 | Rename finding codes and unit-bearing display fields now? | Yes, before any release | R04, R09 | 2026-10-01: yes, both, in one pass before any release, as recommended |
| 7 | Enable a minimal `Layout` cop set? | Yes | R11 | 2026-10-01: not as recommended. Ed chose the full `Layout` department, after PR #15 merges, on its own pull request once the other refactor work is done. Recorded in [planning/refactor/rubocop-layout.md](../../../refactor/rubocop-layout.md) |
| 8 | Merge PR #15 before or after the review findings? | Merge after R01 and the small reproduced defects; do R05, R06, R07 on a follow-up branch before Phase 3 | all | 2026-10-01: merge PR #15 now, as is. Every finding then lands on its own new branch. No fixes are added to the Phase 2 branch first |

## Evidence retained

The scratch probes are not in the repository. Their results, on this branch at `7021eab`, Ruby 3.2.2:

| Probe | Result |
| --- | --- |
| Five calls to `Zones::Faces::ColourModes.assembly_entries(model)` | `session.callers.count` 1 to 6 |
| `ph_composer.library.providers.remove` from a context with `capabilities: ["view"]` | `completed`; stored providers 1 to 0 |
| `ph_composer.windows.types.create`, same params, display system SI then IP | `columns_m, rows_m` `[[1.0],[1.5]]` then `[[1.016],[1.524]]` (recorded port; see R03 item H) |
| `ph_composer.library.export_file` with a stale `expected_revision` | `refused`, code `request.stale_revision` |
| `API.discover` and `API.describe` over the Phase 2 operations | 90 operations; 233 top-level params, 218 without a description; no Windows identity repair action |

An implementing agent should turn each probe into the focused test named in its finding file.
