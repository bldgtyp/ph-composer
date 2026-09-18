# Development

**DATE:** 2026-09-18 | **STATUS:** Partly implemented. The commands below exist unless marked
"not yet". The extension is an empty shell; tooling for the panel and the Python runtime arrives
with those parts.

The development loop needs no installed dependencies beyond Ruby, Node and `uv`. Ruby source stays
compatible with Ruby 2.7 inside the SketchUp 2023 support floor. The proving host is SketchUp
2026.1 with Ruby 3.2.2. Build tools run through `uv`; they never install packages into system
Python.

## Prerequisites

- Ruby 2.7.2 and 3.2.2 through rbenv (see "Ruby versions").
- Node 22 and pnpm, for the JavaScript suite and eslint.
- `uv`, which provides Python 3.11 for the tools and their tests.

## Offline loop

```sh
make ci
```

`ci` runs, in order: `syntax` (every `.rb` under `src`, `tests` and `tools`), `lint`, `test`,
`fixtures-check`, `hostkit-test`, `python-check` (mypy over the tools and their tests), `rbz` and
`rbz-check`. It ends by printing the checks that are not yet part of the gate:

- Not yet: the JavaScript suite and the generated panel script list, which arrive with the panel.
- Not yet: `runtime-pin-check`, `runtime-check` and the installed-size gate, which arrive with the
  Python runtime and its manifest.

A passing `make ci` is therefore not the full foundation gate until that list is empty.

`test` loads the real extension code against a stub SketchUp API and runs the Ruby and Python
suites in one pass. JavaScript tests, once they exist, are discovered by the glob
`tests/*_test.js` and run under `node --test`. The stubs say in comments what they support and
what they refuse to pretend to support; see `tests/support/.index.md`.

## Lint

```sh
make lint
```

Three rule sets, each a developer tool rather than something the extension needs. `make test`
stays dependency free, so rubocop and eslint each print a named skip line when absent. CI
installs both. A local skip is not gate evidence.

- `lint-ruby` runs rubocop from the `Gemfile`, with gems in `vendor/bundle` so adding a linter
  cannot change what the suite's `require` resolves. Install with `bundle install` using the
  bundler of the Ruby you test with.
- `lint-js` runs eslint from `package.json` at `ecmaVersion: 2020`, the floor host's Chromium 88
  level, with post-88 runtime APIs refused. Install with `pnpm install`; the repository keeps
  pnpm's one-day minimum release age and refuses non-registry subdependencies.
- `lint-python` runs ruff over `tools/` and `tests/python`, lint and format check.

The line ceiling is 120 characters in every language. What the linters cannot express is in
[`context/CODING_STANDARDS.md`](../context/CODING_STANDARDS.md).

## Ruby versions

The suite runs on Ruby 2.7 to 3.2 and refuses anything outside that span, because both ends are
real. A loop on one version alone cannot see Ruby 3 keyword separation in either direction.

```sh
brew install rbenv ruby-build
rbenv install 2.7.2
rbenv install 3.2.2
make ci                                        # 3.2.2, from .ruby-version
make ci RUBY=$(rbenv prefix 2.7.2)/bin/ruby    # the floor
```

GitHub Actions runs `make ci` on both, one matrix job per version, on every pull request and
every push to `main`.

## Fixtures and coverage

Generated goldens are regenerated with `make fixtures`, which prints every file it changed; every
other run compares them. Each golden has exactly one owning test, listed in `FIXTURE_OWNERS` in
the Makefile. There are no goldens yet. Hand-authored inputs live apart from goldens and nothing
regenerates them.

`make coverage` measures Ruby line coverage of the extension folder against a 93% minimum. It sits
outside `make ci`; run it before a phase gate. JavaScript (94%) and Python (92%) coverage join
when their shipped code lands. Thresholds ratchet upward only.

## Build, install and reload

```sh
make rbz       # dist/ph_composer.rbz, install through Extension Manager
make install   # replace only this extension's loader and folder in the Plugins directory
```

The archive holds the loader and the `ph_composer/` folder and nothing else. `make rbz` and
`make rbz-check` refuse development material (host kit, examples, fixtures, tests, the private
corpus), file types the extension does not ship, blocking browser dialogs in panel code, and any
line naming the retired designPH integration or the predecessor's namespace. A documentary
citation that must name the predecessor is admitted one exact line at a time through
`tools/rbz/shipping_allowlist.json`, with a reason.

Restart SketchUp after replacing the loader. For every phase gate, quit all SketchUp processes
and relaunch after `make install`. Installation is preparation, not host validation.

## Driving SketchUp from a terminal

This section concerns development tooling. The separate supported interface for users' agents is
planned in [AGENT_ACCESS.md](AGENT_ACCESS.md); development `eval` is not its public API.

Host work defaults to the development bridge, not to a person at the Ruby Console.
`make bridge-install` places the bridge in the SketchUp Plugins folder, never in the RBZ, and
`make bridge-uninstall` removes it. `launch` always opens a document, because the bridge did not
start while SketchUp waited at its Welcome screen
([host evidence](../planning/refactor/phase-zero/evidence/phase-02-bootstrap.md)):

```sh
uv run tools/hostkit/host_bridge.py launch _private/host/run.skp --fresh-from _private/host/blank.skp
uv run tools/hostkit/host_bridge.py state
uv run tools/hostkit/host_bridge.py quit
```

`launch` quits any running SketchUp, opens the Model as the only document and loads the helpers.
From there `eval`, `state`, `save`, `shot`, `key`, `console` and `quit` cover the fresh-process
loop. `tools/hostkit/.index.md` lists what each does. The measured host facts the bridge depends
on are in [`context/SKETCHUP_HOST_BEHAVIOR.md`](../context/SKETCHUP_HOST_BEHAVIOR.md).

## Not yet available

These arrive with the parts they verify. Until then no command exists and none may be cited as a
passing check.

- **Runtime verification.** The runtime manifest pins the Pyodide release, versions, licenses,
  hashes, MIME types, asset allowlist and size budget. `uv run tools/runtime/vendor.py --check`
  and `uv run tools/runtime/browser_check.py` arrive with the runtime.
- **Panel tooling.** `make panel-manifest`, which generates the panel's script list, and
  `make ui-preview` and `make ui-checks`, which serve the panel with synthetic snapshots, arrive
  with the panel. Neither preview replaces the SketchUp walkthrough a host gate requires.
- **Library provider testing.** A local fixture server for connection providers arrives with the
  library provider contract.
