# Development

**DATE:** 2026-09-18 | **STATUS:** Target state. None of these commands exist in this repository
yet. The tooling arrives with the transplant from the predecessor named in the founding brief, and
this page is rewritten against the real Makefile when it lands.

The development loop has no installed dependencies. Ruby source stays compatible with Ruby 2.7
inside the SketchUp 2023 support floor. The proving host is SketchUp 2026.1 with Ruby 3.2.2. Build
tools run through `uv`; they do not install packages into system Python.

## Offline loop

```sh
make ci
```

`ci` runs, in order: `syntax` (every `.rb` under `src`, `tests` and `tools`), `lint`, `test`,
`fixtures-check`, `hostkit-test`, `python-check` (mypy over the translation package, the
exporters and their tests), `runtime-pin-check`, `runtime-check`, `rbz` and `rbz-check`.

Editing a file the extension ships, including the panel JavaScript and the Python packages,
changes hashes that `vendor/manifest.json` records. Run
`uv run tools/runtime/vendor.py --refresh-manifest` and commit the result, or `runtime-check`
reports a mismatch and the Ruby runtime probe fails with it.

`test` loads the real extension code against a stub SketchUp API and runs the Ruby, JavaScript
and Python suites in one pass. The JavaScript files are discovered by glob and run under
`node --test`. The stubs say in comments what they support and what they refuse to pretend to
support.

## Lint

```sh
make lint
```

Three rule sets, each a developer tool rather than something the extension needs. `make test`
stays dependency-free, so each prints a named skip line when absent. CI installs all three.

- `lint-ruby` runs rubocop from the `Gemfile`, with gems in `vendor/bundle` so adding a linter
  cannot change what the suite's `require` resolves.
- `lint-js` runs eslint from `package.json` at `ecmaVersion: 2020`, the floor host's Chromium 88
  level, with post-88 runtime APIs refused.
- `lint-python` runs ruff over the Python packages, their tests and `tools/`.

What the linters cannot express is in [`context/CODING_STANDARDS.md`](../context/CODING_STANDARDS.md).

## Ruby versions

The suite runs on Ruby 2.7 to 3.2 and refuses anything outside that span, because both ends are
real. A loop on one version alone cannot see Ruby 3 keyword separation in either direction.

```sh
brew install rbenv ruby-build
rbenv install 2.7.2
rbenv install 3.2.2
make test                                       # 3.2.2, from .ruby-version
make test RUBY=$(rbenv prefix 2.7.2)/bin/ruby   # the floor
```

GitHub Actions runs `make ci` on both, one matrix job per version, on every pull request and
every push to `main`.

## Fixtures and coverage

Generated goldens are regenerated with `make fixtures`, which prints every file it changed; every
other run compares them. Each golden has exactly one owning test. Hand-authored inputs live apart
from goldens and nothing regenerates them.

`make coverage` runs Ruby, JavaScript and Python coverage with minimums the target enforces. It
sits outside `make ci`; run it before a phase gate. Thresholds ratchet upward only.

## Install and reload

```sh
make rbz       # dist/passive_builder.rbz, install through Extension Manager
make install   # replace only this extension's loader and folder in the Plugins directory
```

Restart SketchUp after replacing the loader. The composition root requires every file by
directory walk, so loading it again does not reload a changed file. For every phase gate, quit all
SketchUp processes and relaunch after `make install`. Installation is preparation, not host
validation.

## Driving SketchUp from a terminal

Host work defaults to the development bridge, not to a person at the Ruby Console.
`make bridge-install` places the bridge in the SketchUp Plugins folder, never in the RBZ.
`uv run tools/hostkit/host_bridge.py launch <model.skp> --fresh-from <accepted.skp>` quits any
running SketchUp cleanly, opens the Model as the only document and loads the helpers. From there
`eval`, `state`, `save`, `export`, `probe`, `shot`, `console`, `log` and `quit` cover the
fresh-process loop. The measured host facts the bridge depends on are in
[`context/SKETCHUP_HOST_BEHAVIOR.md`](../context/SKETCHUP_HOST_BEHAVIOR.md).

## Runtime verification

The runtime manifest is the source of truth for the Pyodide release, wheel order, versions,
licenses, source URLs, hashes, MIME types, asset allow-list and size budget. These checks do not
use the network:

```sh
uv run tools/runtime/vendor.py --check
uv run tools/runtime/browser_check.py
```

## Library provider against a local server

A library file works without any server. To exercise a connection provider's sign-in and
connection states locally, `make library-server` runs a fixture server on loopback with flags for
the deny, expiry and revoke paths, and `make library-reset` signs out and removes the loopback
Keychain entry. Only HTTPS addresses and loopback HTTP are accepted.

## Workspace UI verification

`make ui-preview` serves the same panel with a captured host channel and a stub in place of the
runtime, fed by synthetic snapshots. `make ui-checks` runs browser checks against it under
Playwright installed outside the repository. Neither replaces the SketchUp walkthrough a host gate
requires.
