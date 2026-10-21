# 09 Development tooling, the build and the supply chain

Files: `tools/rbz/build.py`, `tools/runtime/vendor.py`, `tools/hostkit/*`, `tools/ui-preview/*`,
`tools/githooks/staged_checks.py`, `.githooks/*`, `.github/workflows/ci.yml`, `Makefile`,
`package.json`, `.npmrc`, `pyproject.toml`, `uv.lock`, `Gemfile`, `Gemfile.lock`.

## What ships

`build.py` packages the loader and `src/ph_composer/` only, skipping dotfiles, `__pycache__` and
`.pyc`, and refuses the archive if any entry is outside the extension folder, has a suffix outside
the shipped set, contains a development part (`_private`, `hostkit`, `examples`, `fixtures`,
`tests`, `starter-library`), names designPH or the predecessor without an allowlist entry, or calls
`alert(`, `confirm(` or `prompt(`. The installed size is checked against the manifest's gates and a
`build.json` records a digest of every shipped file and the source commit. `make ci` runs
`rbz-check` so a stale or non-conforming archive fails the gate. The `__pycache__` folders present in
the working tree are untracked and excluded.

`install_into` removes the previous `ph_composer/` folder and extracts the archive the build just
verified; `extractall` of a self-built archive carries no traversal risk.

## The vendored runtime

`vendor.py` downloads the pinned Pyodide core from the GitHub release URL and each wheel from
`files.pythonhosted.org` by hash-named path, verifies every file against a SHA-256 recorded in the
script, extracts the five runtime files by basename into a freshly created folder (no path from the
tarball is used), and writes the manifest. `--check` runs offline in `make ci` and fails on any byte,
size, MIME, gate or pin drift; `--pins-check` makes the shipped wheels and `pyproject.toml` agree.
Licensing for each wheel is recorded beside its pin.

## CI

One workflow on `pull_request` and `push` to `main`, no secrets, no `pull_request_target`, no
third-party action beyond the five standard ones, each pinned by major tag (F05). Caching uses
`bundler-cache`, `pnpm` cache and `setup-uv` cache keyed on lockfiles.

## Package managers

`.npmrc` sets `minimum-release-age=1440` and `block-exotic-subdeps=true`; the only dependency is
`eslint` at an exact version and nothing from `node_modules` ships. `Gemfile` holds `rubocop` at an
exact version. `uv.lock` pins the Python tooling and the eight translation wheels at the same versions
the manifest ships. `package.json`'s `prepare` script sets `core.hooksPath` to the repository's own
hooks; `.githooks/*` prepend common tool paths and run `tools/githooks/staged_checks.py` with the
system `python3`.

## The host bridge (F10)

`tools/hostkit/host_bridge.rb` is a loopback server that evaluates Ruby on the main thread for any
request carrying the token from `<Plugins>/../ph_composer_host_bridge.json`, tees the Ruby Console to
a log file beside it, and autostarts whenever SketchUp loads it. `make bridge-install` copies it into
the Plugins folder; `make bridge-uninstall` removes it and the state file. The token is 128 bits and
compared with `==`; the state file is written with default permissions. `tools/rbz/build.py` refuses
any `hostkit` path, so it cannot ship. The risk is confined to a developer machine between
`bridge-install` and `bridge-uninstall`, and to the same user.

`agent_access_probe.py` reads the agent token from a file the developer names and masks it in every
transcript line it writes; the committed probe transcript shows `Bearer <matches probe token>`.

## UI preview

`make ui-preview` and `make ui-checks` serve the repository root on `127.0.0.1:8765` with Python's
`http.server` for Playwright, which is installed outside the repository. Development only; the
Makefile refuses to start if the port is already serving.

## Repository hygiene

- No secret pattern (API keys, private keys, tokens) in the full history.
- No `.env`, credentials or key files tracked.
- `_private/`, `.venv/`, `dist/`, `node_modules/`, `vendor/bundle/`, `.playwright-mcp/` and the
  predecessor screenshots are ignored.
- Tracked evidence logs and `results.jsonl` carry session UUIDs, fixture hashes and `_private/`
  relative fixture names, which identify nothing outside the repository. Five planning files carry
  the maintainer's `/Users/<name>` home path, one of them a `.rbenv` interpreter path (F07).
- No `SECURITY.md` (F06).
