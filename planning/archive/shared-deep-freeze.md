# One shared deep-freeze helper

DATE: 2026-10-02
STATUS: Complete on `codex/shared-deep-freeze`; archived 2026-10-07. Not merged or released.
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

## Execution receipt

- Scope: reviewed all ten call sites in `ModelSettings` and `Registry`; each already copied before
  freezing. Replaced them with `DeepCopy.frozen` and removed both private recursive helpers.
  The shared helper and `HandlerRequest` are unchanged. The Layout prerequisite merged through
  PR #32, with the tooling follow-up through PR #81.
- Identity: branch `codex/shared-deep-freeze`, based on `main@9202e5e`.
- Build: `dist/ph_composer.rbz`, 387 files / 7,568,869 bytes; SHA-256
  `69e825471fa1c9877f59bd129093bce327aafedb8d57ccc26a6d81f96b2a5b4e`.
- Verification: existing focused registry, settings and request tests pass on Ruby 2.7.2 and
  3.2.2, each with 43 tests and 285 assertions; `git diff --check` passes. No new test or host gate
  is required by this behavior-preserving packet.
- Quality: `make coverage` passes (Ruby 97.0%, JavaScript 96.3%, Python 95.59%); Ruby coverage
  runs 1,451 tests with 14,745 assertions and no failures, errors or skips. RuboCop passes all
  449 files, including method and class size limits. No dedicated complexity/CRAP tool is
  configured; the source diff removes 16 net lines and two recursive helpers.
- Review: one bounded independent review using the architecture rubric found no actionable
  findings. It covered all ten replacements, nested detachment/freezing, declaration publication
  and preservation of contributor callable state, including the existing library registration tests.
- Full gates: `make ci` passes on Ruby 3.2.2 and 2.7.2 on 2026-10-07. Each runs 1,451 Ruby
  tests / 14,745 assertions, 475 JavaScript tests and 191 Python tests, with no failures or skips;
  lint, fixtures, manifests, runtime checks, hostkit tests, typing and RBZ verification pass.
- Closeout: archived under the existing flat-file convention; status, R11 follow-up and Spaces
  dependency references updated. No public contract or behavior changed, so no context amendment
  is needed. No shipped panel or Python assets changed, so no runtime manifest refresh is needed.
- Pending acceptance: none within this packet. SketchUp compatibility-floor host proof, Windows,
  public distribution and certification remain separate repository gates.
- Delivery: signed-off work pushed to `origin/codex/shared-deep-freeze` on 2026-10-07;
  [PR #83](https://github.com/bldgtyp/ph-composer/pull/83) is open against `main` and attached to
  the Codex chat. GitHub's outage caused three failed pushes and one failed PR creation before
  retries succeeded. Remote CI had not reported checks at PR creation. Next: PR review and remote
  CI; merge has not been requested. Merge is needed before the Spaces shared-file dependency closes.
