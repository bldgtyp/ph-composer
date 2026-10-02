# One shared deep-freeze helper

DATE: 2026-10-02
STATUS: Requested. A follow-up from the Phase 2 review's R11, which added the third copy.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Observed

Three places freeze a JSON-shaped value and everything inside it, each with its own code:

- `ModelSettings#deep_freeze` (`src/ph_composer/core/model_settings.rb`), private;
- `Registry#deep_freeze` (`src/ph_composer/shell/registry.rb`), private, used for published
  declarations;
- `DeepCopy.frozen` (`src/ph_composer/core/deep_copy.rb`), added by R11 item 10 so each
  `HandlerRequest` holds a frozen copy of its params. It copies and freezes in one call.

The first two freeze in place, so each caller passes `deep_freeze(DeepCopy.call(value))`, which is
what `DeepCopy.frozen` does.

## Proposed correction

Replace both private methods with `DeepCopy.frozen`, and delete them. Check each call site first: a
caller that relies on freezing its own object in place, rather than a copy, keeps that behaviour or
says why it no longer needs it.

## Verification

`make ci` on both Rubies. No behaviour change, so no new test; the existing frozen-declaration and
settings tests (`registry_test.rb`, `model_settings_test.rb`, `handler_request_test.rb`) cover it.

## When to schedule

Any time after the RuboCop `Layout` pull request, so the two diffs do not conflict. Small; one branch.
