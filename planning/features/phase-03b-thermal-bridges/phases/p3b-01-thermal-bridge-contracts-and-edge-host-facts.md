# P3b-01: thermal-bridge contracts and edge host facts

DATE: 2026-10-03
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Entry and scope

Requires Ed's authorization. The interview is complete: Ed answered every question in
[thermal-bridges DECISIONS](../DECISIONS.md) on 2026-10-03, and the PRD and
`context/UBIQUITOUS_LANGUAGE.md` were amended the same day. Owns what must be true before any file
exists under `features/thermal_bridges/`: the bindings confirmed against code, the host facts B4
left open, and the citation lint for the new ids. No feature code and no screen.

Behavior owner: the [thermal-bridges PRD](../PRD.md). Names:
[thermal-bridges CONTRACTS](../CONTRACTS.md) sections 5 and 7. Host method:
`.agents/skills/ph-composer-native-acceptance/SKILL.md`.

Paths are relative to `src/ph_composer/`.

## Steps

1. **Check the interview fold.** The PRD, DECISIONS "Ed's answers" and the glossary were updated
   in planning on 2026-10-03. Confirm the PRD, CONTRACTS and the stage documents agree with every
   answer, D3b-20's change from the recommendation included, and correct any drift.
2. **Answer CONTRACTS section 7.** Each of the seven questions gets a focused test or a read of
   the code, written into CONTRACTS as section 8, "P3b-01 contract answers". Question 1 settles
   D3b-02: if a reference target's records need an id, switch the assignment to `tbe_` with the
   Window unit copy rule and update section 2. Correct every table the answers change. Run the
   architecture review on the corrected CONTRACTS and record its outcome.
3. **Close B4's open host cases.** Extend `tools/spikes/edge/edge_spike.rb` (development-only, it
   may cite planning) with five steps on a tagged edge inside a Zone-like Group, each followed by
   Undo, Redo, and a capture of persistent ids, endpoints and dictionaries: native Divide (the
   context-menu command, driven by a human or native control); native Weld (the menu command);
   a push-pull that removes the tagged edge; `Entities#intersect_with` of a crossing face; and
   erasing the crossing edge of a split so SketchUp heals two tagged collinear halves. Save, quit,
   relaunch and compare. For the heal, record which dictionary survives when the halves carry the
   same record, and when they carry different records.
4. **Fold the host facts.** Add the results to `context/SKETCHUP_HOST_BEHAVIOR.md`, "Components,
   glue and edge attributes", with the consequence column. If a case loses a tag or merges two
   different records silently, stop and record the consequence for D3b-01 in DECISIONS before
   P3b-03 starts.
5. **Citation lint (H17).** Extend `PLANNING_IDS` in `Makefile` so a numbered Phase 3 stage
   (`P3b-01`), an acceptance id (`T01`, and `S01` if P3a-01 has not already) and a finding id
   (`F3`) in `src/` or `tests/` fail `make lint-citations`. Check the pattern against the whole
   current tree first: a new id must not match an existing legitimate token.
6. **Ledger cases.** Add T01 to `planning/native-acceptance/cases.json` with the spike and context
   paths it depends on.

## Source

| PH-Composer file | Disposition |
| --- | --- |
| `tools/spikes/edge/edge_spike.rb` | Extend with the five cases; keep its scan and registry code unchanged so earlier B4 results stay reproducible |
| `features/zones/declarations/faces.rb`, `features/zones/faces/reference_targets.rb`, `features/windows/units/` reference target | Read for question 1 |
| `Makefile` `PLANNING_IDS` | Extend |

## Tests (write first)

1. A planted `P3b-01`, `T01` and `F3` in a scratch file under `tests/` fail `make lint-citations`;
   the current tree passes.
2. Whatever focused tests answer section 7's questions, kept only where they prove a contract a
   later stage relies on (for example: `EntityStore` round-trips a record on a stub Edge).

## Host gate

Fresh process, a synthetic Model with one tagged edge per case, the five B4 cases with Undo, Redo,
save and fresh-process reopen, read through the bridge. Native Divide and native Weld need native
controls or one precise human action each; follow `context/NATIVE_CONTROL_CAPABILITIES.md`.

## Out of scope

Any file under `features/thermal_bridges/`. Every Zones, Windows, Colour-by and export change.

## Done when

- T01 has evidence in `../evidence/p3b-01-edge-host-facts.md`, with the architecture review
  recorded.
- The PRD carries Ed's answers; CONTRACTS section 8 answers all seven questions; every table
  agrees with the code.
- `context/SKETCHUP_HOST_BEHAVIOR.md` holds the five results; `make ci` passes on both Rubies.
