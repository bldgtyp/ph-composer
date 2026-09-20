# Development

**DATE:** 2026-09-18 | **STATUS:** Partly implemented. The commands below exist unless marked
"not yet". The extension has its foundation, an empty panel, the Python runtime payload and the
export infrastructure, with no exporter yet.

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
`fixtures-check`, `panel-manifest-check`, `runtime-check` (the tree, the Pyodide pin, the gates
and the installed-size budget against `src/ph_composer/vendor/manifest.json`), `runtime-pin-check`
(shipped wheels against `pyproject.toml`), `hostkit-test`, `python-check` (mypy over the
translation package, the tools and their tests), `rbz` and `rbz-check`, which also refuses an
installed extension over the manifest's 24,000,000-byte ceiling.

`test` loads the real extension code against a stub SketchUp API and runs the Ruby and Python
suites in one pass. JavaScript tests are discovered by the glob `tests/*_test.js` and run under
`node --test` against a DOM double. The stubs say in comments what they support and what they
refuse to pretend to support; see `tests/support/.index.md`.

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
- `lint-python` runs ruff over `tools/`, `tests/python` and the translation package, lint and
  format check.

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

`make coverage` measures Ruby line coverage of the extension folder against a 93% minimum,
JavaScript line coverage of `html/` (the runtime page included) against 94%, and Python coverage of
the translation package against 92%. It sits outside `make ci`; run it before a phase gate.
Thresholds ratchet upward only.

`tests/fixtures/foundation/{extraction,result}.json` are hand-reviewed contract examples, not
generated goldens: the Ruby suite checks that the example feature collects to the extraction, and
the Python suite that its sections translate that to the result.

## The Python runtime

The runtime payload is the Pyodide core pinned in `tools/runtime/vendor.py`, plus the shipped
`html/` and `python/` files, each listed with its size and SHA-256 in the manifest. After editing
anything under `html/` or `python/`:

```sh
make panel-manifest      # when a panel module was added, renamed or re-declared
make runtime-manifest    # re-hashes html/ and python/; never adopts a changed Pyodide file
make ci
```

`uv run tools/runtime/vendor.py` without flags downloads the pinned Pyodide release, checks its
hash and rewrites the manifest. `make runtime-browser-check` boots the shipped runtime page in the
Chromium 88 snapshot (downloaded once with `uv run tools/runtime/browser_check.py
--download-chromium`) and checks isolation, single-flight boot, that no stack module loads, and the
manifest's cold-boot and round-trip ceilings. It launches a browser, so it is not part of `make
ci`, and a browser pass is not host evidence. On the host, `tools/hostkit/runtime_probe.rb` runs the
same probe and reports teardown (see `tools/hostkit/.index.md`).

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
([host evidence](../planning/archive/phase-zero/evidence/phase-02-bootstrap.md)):

```sh
uv run tools/hostkit/host_bridge.py launch _private/host/run.skp --fresh-from _private/host/blank.skp
uv run tools/hostkit/host_bridge.py state
uv run tools/hostkit/host_bridge.py quit
```

`launch` quits any running SketchUp, opens the Model as the only document and loads the helpers.
From there `eval`, `state`, `save`, `shot`, `key`, `console` and `quit` cover the fresh-process
loop. `tools/hostkit/.index.md` lists what each does. Every `eval` runs in one shared binding, so
a local variable assigned in one call survives into the next and keeps its object alive. Set such
locals to nil before checking that a closed Model's session was collected. The measured host facts
the bridge depends on are in [`context/SKETCHUP_HOST_BEHAVIOR.md`](../context/SKETCHUP_HOST_BEHAVIOR.md).

Phase-specific native probes live under [`tools/spikes/`](../tools/spikes/) and never ship. The
P1-A Zone geometry probe and its stepwise bridge commands are documented in
[`tools/spikes/geometry/README.md`](../tools/spikes/geometry/README.md); its accepted results are
in [`planning/phase-one/evidence/p1-a-geometry.md`](../planning/phase-one/evidence/p1-a-geometry.md).
The P1-B panel-closed Zone/Face walkthrough is in
[`tools/examples/authoring/`](../tools/examples/authoring/README.md); its accepted current-host
result is recorded in [`planning/phase-one/evidence/p1-b-authoring.md`](../planning/phase-one/evidence/p1-b-authoring.md).

## The panel

Each panel file is one `PhComposerUI.define(name, dependencies, factory)` call. After adding,
renaming or re-declaring a module, regenerate the pages' script lists:

```sh
make panel-manifest
```

`make ci` fails while `html/index.html` or the preview page is stale. After installing changed panel
assets, close and reopen the panel; an open panel keeps running the old page.

The preview is the real panel in a browser, with a stand-in host and synthetic Models. It does not
replace the SketchUp walkthrough a host gate requires.

```sh
make ui-preview                                  # http://127.0.0.1:8765/tools/ui-preview/
NODE_PATH=/path/to/scratch/node_modules make ui-checks
```

`ui-checks` needs Playwright from `NODE_PATH`, installed outside the repository, and prints a skip
line without it. `tools/ui-preview/.index.md` describes the page, its fixtures and the checks.

## The development example

`tools/examples/foundation/` is a complete feature built only from the public contracts, with a
script that drives it through `PhComposer::API` as two clients with the panel closed, and a
synthetic editor: a panel section for its parts that exercises the unit field and the record form.
Its README lists each file. It never ships. Loading it registers the feature and hands the editor
to the panel, which runs it the next time the panel opens. To run it in a host with the bridge:

```sh
uv run tools/hostkit/host_bridge.py eval \
  'load "/absolute/path/to/ph-composer/tools/examples/foundation/load.rb"; ExampleWalkthrough.run'
```

## Not yet available

These arrive with the parts they verify. Until then no command exists and none may be cited as a
passing check.

- **Library provider testing.** A local fixture server for connection providers arrives with the
  library provider contract.
