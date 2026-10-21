# SH-04 Repository hygiene and the context fold

DATE: 2026-10-21
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#292](https://github.com/bldgtyp/ph-composer/issues/292)
FINDINGS: F07, F09, F10, F11, and the review's "Accepted by design" table
DEPENDS ON: nothing. Touches `docs/DEVELOPMENT.md` beside SH-01's edit; rebase whichever lands second.
ONE PR: yes

## Scope

Remove the maintainer's home path from the public tree and keep it out; make the development
bridge's state file owner-only; record in the durable docs the choices the review accepted so the
planning packets can archive without losing them.

## Verified at the baseline

- `git grep -lE '/Users/em' -- planning` lists five files:
  `planning/archive/agent-access-review/evidence/dispatch-original-results.log`,
  `planning/archive/phase-00-foundation/PLAN.md`,
  `planning/archive/phase-01-faces-and-zones-refactor/review/MODEL-REVIEW.md`,
  `planning/archive/phase-01-faces-and-zones/D7-GATE-HANDOFF.md`,
  `planning/archive/ruby-readability/review-2026-10-17.md`.
  `/Users/example` appears legitimately in `planning/native-acceptance/results.jsonl` and in tests.
- `Makefile` `lint-citations` greps `src` and `tests` for planning references; `lint` runs
  `lint-ruby lint-js lint-python lint-citations`.
- `tools/hostkit/host_bridge.rb` `write_state` uses `File.write`; `PhComposerHostBridge.start`
  runs at load unless `PHC_HOST_BRIDGE_NO_AUTOSTART` is set; `handle` compares the token with `==`.
  `tools/hostkit/tests/all.rb` runs the Ruby tests against the stub.
- `library/file_provider.rb` `candidate_files` selects `File.file?` children; `file_writer.rb`
  `state` refuses `File.symlink?`.
- `docs/DEVELOPMENT.md` "Build, install and reload" describes `build.json` as what Help &
  Diagnostics and the log name.
- `context/AGENT_INTERFACE.md` "User-controlled local access" records the listener's bounds and
  the token store but not the accepted choices.

## Steps

### 1. Scrub and lint home paths (F07)

1. In each of the five planning files replace `/Users/<account>/...` with `~/...`; in the `.log`
   replace the `.rbenv` interpreter path with `<ruby 3.2.2>`. These are archived documents; the
   edit changes no substance (PLAN.md decisions). The sixth file is shipped source:
   `src/ph_composer/core/diagnostics.rb` explains its path patterns in two comments with the
   maintainer's account name; rewrite them with `/Users/example`. The review's F07 counted the
   planning files only; the same commit corrects its "Where" line.
2. Add a `lint-paths` target to the Makefile and to `lint`, scoped to the paths that must stay
   clean and leaving `tests/` out, because the diagnostics, metadata, export and library tests use
   home paths as the thing they redact:

   ```make
   # A home path names a person and a machine; neither belongs in a public tree. /Users/example is
   # the synthetic account evidence uses; tests/ keeps its own synthetic paths and is not linted.
   PATH_LINT_PATHS = src docs context planning tools README.md AGENTS.md .github
   lint-paths:
   	@if git grep $(CITATION_FLAGS) -nP '/Users/(?!example\b)[a-z][a-z0-9_-]*|C:\\\\Users\\\\(?!example\b)' -- \
   	    $(PATH_LINT_PATHS) ':!src/ph_composer/vendor'; then \
   	  echo "lint-paths: replace the home path with ~ or <repo>"; exit 1; \
   	else echo "lint-paths: ok"; fi
   ```

   Run it before the scrub to see every hit, after it to see none.
3. `tools/githooks/staged_checks.py`: if it runs lint targets per staged file, add `lint-paths`
   for every staged text file; otherwise leave the hook alone and rely on `make lint`.

### 2. Bridge state file (F10)

1. `host_bridge.rb` `write_state`: after `File.write`, `File.chmod(0o600, @state_path)`. The
   console log beside it gets the same in `install_console_tee` and `log_eval_output`'s first write
   (`File.open(..., "a")` then chmod once).
2. Replace `request["token"] == @token` with a byte-wise compare that does not short-circuit
   (copy `Server#same?` from `agent_access/server.rb` rather than requiring the extension, which the
   bridge must not depend on).
3. `tools/hostkit/tests/`: a case asserting `File.stat(state_path).mode & 0o777 == 0o600` after
   `start` against the stub timer. Skip on Windows.
4. `tools/hostkit/.index.md`: one line in the `host_bridge.rb` row: the state file is owner-only;
   `make bridge-uninstall` before a release build (the checklist is SH-01's).

### 3. Comments and docs (F09, F11)

1. `library/file_provider.rb` `candidate_files`: extend the comment: a child that is a symlink to a
   regular file is read; the parse and size bounds apply to it as to any file, and a non-library
   file fails the envelope check with no text leaving. The writer refuses symlinked destinations
   because it would replace the link's target.
2. `docs/DEVELOPMENT.md` "Build, install and reload": add after the `build.json` paragraph: the
   identity is informational. Nothing verifies the installed tree against it at load; a file
   changed or added under the extension folder runs as the extension, with the user's own
   permissions, as any extension in the Plugins folder does.

### 4. The context fold

In `context/AGENT_INTERFACE.md`, under "User-controlled local access", add a subsection
"Security posture" that records, as decided and implemented:

- The listener binds loopback only; there is no TLS, because loopback traffic is unreadable
  without root and a certificate would add handling with no gain.
- Every request carrying an `Origin` header is refused, so no browser-based client can connect
  and no cross-site request can reach the endpoint; the supported clients are native processes.
- The store keeps only a token's SHA-256; the secret exists once, in the issuing dialog. Tokens
  do not expire; revocation is explicit and dated.
- The port is fixed per preference. On a computer with several accounts, another account can bind
  it while SketchUp is not listening and receive a token from an agent that connects then; the
  user documentation says to revoke tokens on such a computer (SH-02). A per-connection binding is
  the agent connection and access-grant packet's.
- Any caller holding a grant may use any approved location (D3a1-05); a path reaches a caller only
  as the written export pair, and only the caller that started the task.
- The Model's own file path is answered by the context read; it is the user's document, not an
  approved destination.

Cite nothing in `planning/` from the subsection: `make lint-citations` checks only `src` and
`tests`, but `context/CODING_STANDARDS.md` applies the same rule to `context/` by convention, and the
planning packets this records will be archived.

## Tests and gate

`make ci` (with the new `lint-paths` in `lint`); `make hostkit-test`. Show `lint-paths` failing on
a scratch file in the PR, then remove the file (SH-04-A2).

## Acceptance

SH-04-A1 to SH-04-A6.

## Decisions

| Decision | Who |
| --- | --- |
| Editing archived files | Ed (default yes) |
| Gating bridge autostart on an opt-in variable instead of opt-out | Ed; default keeps opt-out, since `launch` relies on autostart |

## Out of scope

Verifying the installed tree at load (F09 accepted). Changing the file provider's symlink
behaviour (F11 accepted).
