# The Ruby suite errors without a UTF-8 locale

DATE: 2026-10-03
STATUS: Requested. Reproduced 2026-10-03; not fixed.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

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
