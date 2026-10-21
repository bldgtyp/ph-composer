# The Ruby suite errors without a UTF-8 locale

DATE: 2026-10-03
STATUS: Implemented on branch `fix/ci-needs-utf8-locale`. Reproduced 2026-10-03 and again 2026-10-21.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#290](https://github.com/bldgtyp/ph-composer/issues/290)

## Defect

With `LANG` and `LC_ALL` unset, five Ruby tests raise `ArgumentError: invalid byte sequence in
US-ASCII`. `make ci` then fails on a machine or shell with no locale, though nothing is wrong with
the code under test. It was noted in the library-product-tab-headers packet and again in the UI and
UX refinement packet, both now archived.

## Evidence

`env -u LANG -u LC_ALL ruby -Itests tests/all_tests.rb` on `main@e93e88d`, Ruby 3.2.2:
1408 runs, 0 failures, 5 errors.

| Test | Raises at |
| --- | --- |
| `ReadContextTest#test_features_neither_build_read_requests_nor_reach_global_registry_state` | `tests/read_context_test.rb:38`, `match?` |
| `PanelMessagesTest#test_every_message_the_page_sends_is_one_ruby_accepts` | `tests/panel_messages_test.rb:12`, `scan` |
| `GeometrySnapshotTest#test_no_code_outside_the_zones_feature_names_its_private_stores` | `tests/geometry_snapshot_test.rb:36`, `match?` |
| `OutcomeCodesTest#test_every_code_literal_in_feature_library_and_translation_source_is_listed_or_declared` | `tests/outcome_codes_test.rb:52`, `scan` |
| `OutcomeCodesTest#test_the_window_schedule_labels_only_declared_codes` | `tests/outcome_codes_test.rb:62` |

With `LANG=en_US.UTF-8` the same command passes.

## Root cause

Each test reads source files with `File.read` and no encoding. Ruby then takes the external
encoding from the locale, which is US-ASCII when none is set, and the source files hold UTF-8
characters.

## Proposed correction

Either of these, not both:

- `export LANG ?= en_US.UTF-8` near the top of the `Makefile`, so every recipe gets a locale. One
  line, but a direct `ruby -Itests ...` run outside make still errors.
- Read with `encoding: "UTF-8"` in the five tests (or one shared helper in `tests/`). The suite
  then passes under any locale. This is the better fix.

## Regression test

The reproduction command above is the check: it must report 0 errors.

## Recheck 2026-10-21

On `main@bfee7cf`, Ruby 3.2.2, `env -u LANG -u LC_ALL -u LC_CTYPE ruby -Itests tests/all_tests.rb`:
2107 runs, 0 failures, 10 errors. The five above, plus five source-scanning tests added since:

| Test | Raises at |
| --- | --- |
| `AgentAccessTokensTest#test_the_page_sends_and_handles_exactly_the_declared_messages` | `tests/agent_access_tokens_test.rb:244`, `scan` |
| `OutcomeCodesTest#test_every_raised_literal_code_can_be_declared_as_an_operation_refusal` | `tests/outcome_codes_test.rb:63`, `scan` |
| `SpacesWalkthroughTest#test_the_walkthrough_names_no_feature_module` | `tests/spaces_walkthrough_test.rb:58` |
| `SpacesWalkthroughTest#test_the_client_moves_the_edit_path_only_through_the_public_commands` | `tests/spaces_walkthrough_test.rb:63` |
| `SupportDialogTest#test_the_page_sends_exactly_the_messages_the_dialog_accepts` | `tests/support_dialog_test.rb:300`, `scan` |

## Correction

`tests/test_helper.rb` sets `Encoding.default_external = Encoding::UTF_8` before anything else
loads, and `tests/parallel_tests.rb`, the runner `make test` uses, sets it too: it reads every test
file and each shard's output before any test loads the helper. This is the shared-helper form of the second option: one line covers every read, so the next
source-scanning test cannot reintroduce the defect, where per-read `encoding:` arguments would have
grown from five sites to ten and on. The `Makefile` is unchanged. CI runs on GitHub's Ubuntu image,
whose locale is already UTF-8, so CI behaviour does not change.

## Verification

`env -u LANG -u LC_ALL -u LC_CTYPE ruby -Itests tests/all_tests.rb` on the branch: 2107 runs,
0 failures, 0 errors on both Ruby 2.7.2 and 3.2.2. A single file run alone
(`tests/outcome_codes_test.rb`) and the parallel runner also pass with no locale, and
`env -u LANG -u LC_ALL make ci` passes.
