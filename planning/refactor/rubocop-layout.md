# Enable RuboCop's Layout department

DATE: 2026-10-01
STATUS: Merged to main 2026-10-02 (PR #32); dual-Ruby `make ci` passes. No host gate (no behaviour
change)
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Decision

The Phase 2 review ([R11](../features/phase-02-envelope/refactor/R11-readability-and-lint.md)) found
mechanically wrapped lines and two continuation styles in Ruby, all passing lint because
`.rubocop.yml` enables five cops and no `Layout` cop. Offered a minimal layout set, Ed chose the full
`Layout` department on 2026-10-01, with two conditions:

1. It runs **after** PR #15 merges, so formatting never mixes with feature changes in one diff.
2. It is **its own pull request**, executed once the other refactor work from the review (R01 to R10
   and the behavioural items of R11) is finished, so it does not create merge conflicts for them.

This widens the rule set that `.rubocop.yml`'s header calls "a deliberately small rule set" where
"widening the list is a separate decision". This is that decision. Update the header comment to say
so.

## Scope

- Enable `Layout` as a department in `.rubocop.yml`. Keep `Layout/LineLength` at 120
  (`context/CODING_STANDARDS.md`, "Line and size limits"). Keep every other department off unless Ed
  widens the list again.
- Choose and record the enforced styles where a cop offers more than one, before running
  auto-correct. At least: hash and argument alignment, first-argument and first-hash-element
  indentation, multiline method-call and operation indentation, `Layout/HashAlignment` for the
  hash-rocket style this codebase uses (`:key => value`), and end alignment. Pick the style closest to
  the Phase 0 and Phase 1 code so the transplanted files move least.
- Run `rubocop -a` (safe auto-correct only) over `src/`, `tests/` and `tools/`, then fix what remains
  by hand. This includes the Phase 0 and Phase 1 files carried from the predecessor.
- Hand-repair the lines R11 item 1 lists if auto-correct leaves them awkward: break at an argument
  boundary, never mid-expression.
- Update `context/CODING_STANDARDS.md`: the paragraph that describes the lint rule sets, and "Line and
  size limits".

## Out of scope

No behaviour change, no renames, no method extraction. R11's behavioural items (5 to 9) and its
readability items that need judgment (3 and 4) belong to the review refactor, not to this pass.

## Rules for the pull request

- Formatting only. A reviewer should be able to confirm with `git diff -w` that nothing but
  whitespace and line breaks moved, except the hand repairs, which are listed in the description.
- One commit for `.rubocop.yml` and the standards text, one for the auto-correct, one for hand
  repairs. Add the auto-correct commit's hash to a `.git-blame-ignore-revs` file so `git blame` skips
  it.
- Ruby 2.7 remains the floor. Auto-correct must not introduce syntax newer than 2.7; run the suite on
  2.7.2 and 3.2.2.
- No golden or fixture changes. If one changes, the pass altered behaviour: stop and find out why.

## Verification

`make ci` on both Rubies. `make lint` reports no offence with the widened configuration and no
`rubocop:disable` comment added to pass it. Coverage and test counts unchanged. No host gate: no
shipping behaviour changes. The installed RBZ file list is unchanged; its bytes change, so the RBZ
hash is re-recorded.

## Sequencing

PR #15 merged on 2026-10-01. Blocked on: the Phase 2 review refactor packet closed or its remaining items explicitly
deferred. Should land before Phase 3's first stage opens a long-lived branch, or immediately after
that phase merges, never in the middle of one.

## Outcome

Implemented 2026-10-02 on `refactor/rubocop-layout`; merged as PR #32. `.rubocop.yml` enables the whole `Layout`
department, including the four cops RuboCop 1.50 still marks pending. `context/CODING_STANDARDS.md`
describes the result for a reader.

**Styles.** Each cop with a choice took the style with the fewest offences against the code as it
stood, measured before any change:

| Cop | Style | Offences |
| --- | --- | --- |
| HashAlignment | key, rockets and colons | 928 |
| ArgumentAlignment | with_first_argument | 495 |
| ArrayAlignment | with_first_element | 53 |
| FirstHashElementIndentation | consistent | 20, against 208 for the default |
| FirstArrayElementIndentation | consistent | 5 |
| FirstArgumentIndentation | consistent | 0 |
| MultilineMethodCallIndentation | aligned | 56 |
| MultilineOperationIndentation | aligned | 34 |
| EndAlignment | keyword | 1 |

`HashAlignment` keeps its default `EnforcedLastArgumentHashStyle: always_inspect`.
`ignore_implicit` would have moved fewer lines, but then no cop checks the keys of a trailing hash
argument without braces, and those were the lines R11 item 2 was about.

**Commits.**

1. `.rubocop.yml` and the standards text.
2. `rubocop -a` (safe auto-correct only).
3. Hand repairs of the 373 lines the realignment pushed past 120 columns. Two scripted repairs did
   most of it:
   - a call whose trailing hash started mid-line starts its first key on its own line under the
     first argument;
   - a line holding several elements breaks before the first one crossing column 120, and a
     concatenated string literal is rewrapped at word boundaries.

   The rest were done by hand at argument boundaries, including the column-0 continuations R11
   item 1 listed. One ternary became the equivalent `if`/`else`.
4. **A deviation from "no method extraction", decided by Ed on 2026-10-02.** The new layout pushed
   six methods past `Metrics/MethodLength` 40, and none could be compacted under 120 columns. Ed
   chose to split them rather than disable or loosen the gate. Each splits along its seam and
   registers in the same order:
   - Windows `declare_product` and `declare_type`;
   - Zones `install_faces`;
   - Library `install`;
   - `feature_composition_test.rb` `install_entity_retargeter`;
   - the Assemblies walkthrough's `run`.
5. Enabling the four pending cops; one cop's auto-correct and one line break.

**Verification.** Commits 2, 3 and 5 change no meaning. Every changed Ruby file parses to the same
tree as before the pass once adjacent string-literal parts are joined, so every string value is
unchanged. The check is a scratch script; it is not committed. `make ci` passes on Ruby 3.2.2 and
2.7.2, with the same test counts (1,380 Ruby runs) and no golden or fixture change; `rbz-check`
passes. Commits 2, 3 and 5 are listed in `.git-blame-ignore-revs`.

**Follow-up.** `make lint-ruby` prints a `rubocop-ast` deprecation trace (`EnsureNode#body`, from
`Layout/IndentationWidth`): the locked `rubocop-ast` is newer than RuboCop 1.50.2 expects. It is
noise, not an offence. Upgrading RuboCop is a separate change; recorded in `planning/STATUS.md`.

