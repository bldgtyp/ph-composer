# Findings register

DATE: 2026-10-21
BASELINE: `main` at `9e5282171e133229be44e20d408f0037596183b6`

Severity follows the house rubric: High is directly exploitable for code execution, data breach or
an authentication bypass; Medium needs specific conditions but has significant impact; Low is
defense in depth. Confidence is the reviewer's, 1 to 10. Under the rubric's reporting bar (confidence
8 and above, Medium or above), **no finding qualifies**. Everything here is filed for Ed's
consideration, not as a vulnerability report.

`Action` is the recommendation: `fix before release` (before the public-distribution gate),
`fix when convenient`, or `accept and document`.

## Register

### F01 Token setup forms leave the secret in shell history and client settings

- Severity: Low. Confidence: 9. Category: secrets handling.
- Where: `src/ph_composer/agent_access/client_config.rb:36-51, 63-64`.
- What: the first Claude Code form is `claude mcp add ... --header "Authorization: Bearer <token>"`,
  which stores the token in `~/.claude.json` and in the shell's history file. The shared
  `export PH_COMPOSER_TOKEN=<token>` form writes it into `~/.zshrc`. The third Codex form writes it
  into `~/.codex/config.toml`. The docs say "the token is the only secret"; the setup then puts it in
  two or three plaintext files beyond PH-Composer's control.
- Scenario: a dotfiles backup, a synced home folder, or a screen share of a terminal leaks the token;
  it stays valid until the user revokes it in SketchUp. Same-user access only.
- Recommendation: make the `add-json` with `${PH_COMPOSER_TOKEN}` form primary and the header form
  the fallback; say in the dialog and in `docs/AGENT_ACCESS.md` where each form stores the token;
  consider telling the user to run the `export` line in the terminal only and keep it out of the
  profile. Action: fix when convenient.

### F02 Fixed default port lets another local user squat the listener

- Severity: Low. Confidence: 8. Category: authentication.
- Where: `src/ph_composer/agent_access/server.rb:48`, `listener.rb:66-68`.
- What: the MCP server binds `127.0.0.1:46110` by default. On a multi-user host, a different OS user
  can bind that port while SketchUp is not listening (before launch, after the last revoke). An agent
  configured earlier connects to the squatter and sends `Authorization: Bearer <token>`; the squatter
  replays it against the real server once it binds. The dialog refuses to issue a token while the port
  is taken, which covers first issue but not a token issued earlier.
- Scenario: shared lab or studio Mac with several accounts. Single-user machines are unaffected.
- Recommendation: document the shared-machine caveat; when the per-connection packet resumes,
  consider a per-token random port written into the client config, or a path segment derived from
  the token id so a squatter cannot complete the handshake. Action: accept and document now.

### F03 Material `color` is an unvalidated string reaching a CSS property

- Severity: Low. Confidence: 7. Category: input validation.
- Where: `src/ph_composer/features/assemblies/materials/schema.rb:66`;
  `src/ph_composer/html/inventory_forms.js:152, 342`; `html/column_menu.js:72`.
- What: the material `color` field is `{"type": "string"}` with no pattern, while Zone option
  colours have one. The panel assigns it to `style.backgroundColor`. A CSS property assignment is
  not a script sink and the browser rejects anything that is not a colour, so the effect is a blank
  swatch at worst. A library file or crafted SKP controls the value.
- Recommendation: add the same hex pattern the Zone option colour uses, and have the panel ignore a
  value that does not match. Action: fix when convenient.

### F04 Report interpolates one value without the shared escaper

- Severity: Low. Confidence: 9. Category: consistency, not exploitable.
- Where: `src/ph_composer/features/windows/export.rb:123-125`.
- What: `row.fetch('g_value')` is interpolated into a `<p>` without `ReportHtml.h`, while the
  construction id beside it is escaped. The value is schema-bound to a number between 0 and 1 on the
  Ruby side and emitted by the Python section only when it equals 0 or 1, so no string can reach it
  today. The pattern is the risk: a later contributor copying this line with a string field would
  create a stored XSS in the report, which the panel also renders in a sandboxed iframe.
- Recommendation: wrap it in `h`, and add a test or lint that every `#{...}` inside report HTML
  passes through `ReportHtml`. Action: fix when convenient.

### F05 GitHub Actions pinned by tag, not commit SHA

- Severity: Low. Confidence: 10. Category: supply chain.
- Where: `.github/workflows/ci.yml` (`actions/checkout@v4`, `ruby/setup-ruby@v1`,
  `pnpm/action-setup@v4`, `actions/setup-node@v4`, `astral-sh/setup-uv@v5`).
- What: a moving major tag resolves to whatever the action's maintainer publishes next. The workflow
  runs on `pull_request` (not `pull_request_target`), uses no secrets and only installs and tests,
  so the blast radius is CI integrity, not the user's machine. The RBZ a release ships is built
  locally, not by CI.
- Recommendation: pin each action to a full commit SHA with the tag in a comment, and let
  Dependabot or a periodic check bump them. Action: fix before release.

### F06 No security policy or disclosure route

- Severity: Low. Confidence: 10. Category: process.
- Where: repository root; `.github/ISSUE_TEMPLATE/config.yml` offers only a help link.
- What: a public repository with a loopback listener has no `SECURITY.md`, so a reporter's only
  route is a public issue. GitHub's private vulnerability reporting is off (verified with
  `gh api repos/bldgtyp/ph-composer/private-vulnerability-reporting` on 2026-10-21).
- Recommendation: add `SECURITY.md` naming a private contact and the supported versions line, and
  enable private vulnerability reporting. Action: fix before release.

### F07 Home-directory paths and a username in tracked planning files

- Severity: Low. Confidence: 10. Category: data exposure (public repository).
- Where: six tracked planning files carry a `/Users/<name>` home path
  (`git grep -lE '/Users/[a-z]+' -- planning`); five of them the maintainer's own account name,
  the sixth a synthetic `/Users/example` in `native-acceptance/results.jsonl`, which is fine. One
  of the five is a `.rbenv` interpreter path in
  `planning/archive/agent-access-review/evidence/dispatch-original-results.log`.
- What: the repository has been public since 2026-10-15. These reveal the maintainer's macOS
  account name and a local layout, nothing more. Client names, project data and tokens were swept
  for and not found (EVIDENCE.md).
- Recommendation: replace with `~` or `<repo>` in the archived evidence; add a citation-lint
  pattern for `/Users/` under `planning/` and `docs/`. Action: fix when convenient.

### F08 HtmlDialog pages carry no Content Security Policy

- Severity: Low. Confidence: 9. Category: hardening.
- Where: `src/ph_composer/html/index.html`, `agent_access/index.html`, `support/index.html`,
  `runtime/index.html`, `help/index.html`.
- What: the panel loads scripts from its own folder and no page loads anything remote, but nothing
  prevents a future script from fetching out, and nothing limits where an injected script could
  send data if one of the DOM sinks above were ever misused. A `<meta http-equiv="Content-Security-Policy">`
  with `default-src 'self'; connect-src 'none'` (and the loopback origin for the runtime page) would
  make the "no network" claim enforceable rather than observed.
- Recommendation: add the meta to each page and a test that it is present. Check the runtime page
  under CEF with COEP first. Action: fix when convenient.

### F09 Foundation directories glob-load any `.rb` file

- Severity: Informational. Confidence: 10. Category: code loading.
- Where: `src/ph_composer/extension.rb:56-58`.
- What: every `.rb` under `core/`, `session/`, `shell/`, `runtime/`, `export/`, `colour_by/`,
  `library/` and `agent_access/` is required at load. A file dropped there runs as the extension.
  Writing there needs the user's own permissions, which already allow installing any extension, so
  this adds no privilege. It does mean the RBZ's build identity is the only integrity check and it
  is informational, not enforced.
- Recommendation: none required. If an integrity check is ever wanted, compare the installed tree to
  `build.json` at load and log a mismatch. Action: accept and document.

### F10 Development host bridge: eval endpoint that autostarts once installed

- Severity: Low (development only). Confidence: 10. Category: dangerous dev tooling.
- Where: `tools/hostkit/host_bridge.rb`; `make bridge-install` copies it into the Plugins folder.
- What: a loopback server that evaluates arbitrary Ruby for any client presenting the token in
  `ph_composer_host_bridge.json`, compared with `==` rather than a constant-time compare,
  autostarting on every SketchUp launch until `make bridge-uninstall`. The state file is written
  with default mode 0644, but it sits under `~/Library/Application Support`, which macOS creates
  0700, so in practice only the same user reaches it.
  It never ships: `tools/rbz/build.py` refuses any `hostkit` path. The exposure is the maintainer's
  own machine between runs.
- Recommendation: a pre-release checklist line "`make bridge-uninstall` on every machine that
  builds a release candidate"; optionally `chmod 600` the state file and gate autostart on an
  environment variable rather than its absence; `chmod 600` on the state file is belt and braces.
  Action: accept and document.

### F11 File provider reads through symlinks; the writer refuses them

- Severity: Informational. Confidence: 9. Category: consistency.
- Where: `src/ph_composer/library/file_provider.rb:57-63` versus `library/file_writer.rb:15-18`.
- What: a library folder's `.json` entries are read if `File.file?` is true, which follows symlinks;
  `FileWriter.state` refuses a symlinked destination. Reads are bounded (32 MiB per file, 64 MiB
  aggregate) and parse only JSON, so a symlink to another file reads that file as a library and fails
  the envelope check. No secret can leak through it: a parse failure carries no file text.
- Recommendation: none required; mention in the file-provider comment. Action: accept and document.

## Accepted by design

These were examined and are recorded as deliberate, with the decision that owns each.

| Choice | Owner | Why it is acceptable |
| --- | --- | --- |
| Any token holding `export` may write to any approved save destination; any holding `setup` may add any approved file or folder once | D3a1-05 | The user approved the location knowing agents would use it; a per-connection binding is the unscheduled "agent connection and access-grant" packet |
| `ph_composer.context.read` and the `context` tool answer the Model's full file path | `context/AGENT_INTERFACE.md`, Model context | The path is the user's own document, needed to tell two same-named Models apart; it is not an approved destination |
| Approved locations, library paths and a Model-only token's bound path are plaintext in SketchUp's defaults (base64 JSON) | `shell/approved_locations.rb`, `agent_access/tokens.rb` | Same-user storage; the digests are what protect tokens, and paths are never secrets from the user |
| Any `Origin` header is refused, so a browser-based MCP client cannot connect | `context/AGENT_INTERFACE.md`, local access | The two supported clients are native processes; refusing browsers closes the CSRF class entirely |
| Tokens never expire | `agent_access/tokens.rb` | Revocation is explicit and dated; an expiry would be a product decision |
| No TLS on loopback | | Loopback traffic is unreadable without root; TLS on 127.0.0.1 adds certificate handling with no gain |
| The report HTML is rendered inside the panel in an `<iframe sandbox="">` | `html/sections/export.js:193` | An empty sandbox forbids scripts and same-origin access, so even an escaping defect in a report could not reach `sketchup.*` |
| Capture images are written to the system temp folder and kept 15 minutes, four per session | `shell/capture_command.rb` | Per-user temp on macOS; pruning touches only `cap_*.png` in the session's own folder |

## Checked and sound

Coverage the next reviewer need not repeat unless the code changes.

**Agent access** (`agent_access/`): refusal order (read within 5 s, 16 KiB headers, 1 MiB body, POST
to `/mcp`, no Origin, loopback Host, bearer digest, JSON media type, one JSON-RPC request) matches the
documented receipt; presented tokens are constrained to 48 hex characters; the digest compare XORs
every byte of every stored digest so timing does not depend on which entry matches; the tool table is
the allowlist and the executor validates arguments against each tool's closed schema; capabilities
are enforced at the tool and again at dispatch through the caller handle; a Model-only token is
checked against the session's path at every call and filtered out of `discover`; results over 24 KiB
are refused rather than truncated; the call log holds token ids and operation names only; the dialog
callback is bound to its own dialog instance and its inbound payloads are key-allowlisted; the token
secret exists in Ruby only inside `issue` and the dialog's one `access.issued` message.

**Runtime** (`runtime/`): the manifest validator refuses any declared path outside the extension
folder; the server serves only exact keys of the manifest, after percent-decoding, so `..` cannot
match; every asset's full SHA-256 is checked at construction and its size again on each read; the
path token is 128 bits; responses carry COOP, COEP, CORP, `nosniff` and `no-store`; the page's
`sketchup` callback is key-allowlisted and session-bound; the runtime page loads nothing but the
manifest's assets from its own origin.

**Shell** (`shell/`): `PanelMessages`, `SupportDialog` and `AgentAccess::Dialog` parse only declared
types with declared keys; every outbound script is `JSON.generate` into a fixed call; preferences
accept only enumerated keys, enumerated values and dotted ids; `NativeApproval::Granted` hides its
path from `to_h`, `inspect` and serialization; dispatch resolves the caller handle from the session,
so a serialized context grants nothing; `run_development_script` is reachable only from
`tools/examples`.

**Locations and library** (`shell/approved_locations.rb`, `library/`): location rows validate on
read and are reported unreadable rather than replaced; single-use locations are retired before the
operation runs and restored only if it does not complete; `replace` without `expected_destination`
is refused for every handler; the file writer stages with `O_EXCL` and mode 0600, verifies bytes,
re-checks the destination state and renames; library parsing uses `JSON.parse` defaults (no
`create_additions`, nesting 100) under byte and row caps; provider exceptions never copy their text
into state or outcomes.

**Export** (`export/`): `ReportHtml.h` escapes every table cell, heading and paragraph; the embedded
result JSON escapes `<`, `>` and `&`; `Privacy.validate!` refuses undeclared fields, prohibited keys
(`path`, `username`, `extension_data` and so on) and any string matching the absolute-path patterns;
`HbjsonMetadata` walks keys as keys so a dot cannot hide one; the artifact pair journal accepts only
dotfile basenames containing `.ph-composer-export-` and never a path; a destination must end in
`.hbjson`; artifacts paths are returned only to the caller that started the task.

**Core and session** (`core/`, `session/`): `DeepCopy` is a structural walk, never `Marshal`;
`JsonWalk` detects cycles; `JsonValue` refuses non-string keys, non-finite floats and non-UTF-8
text; `JsonSchema` anchors patterns to the whole string and refuses line anchors; caller handles are
128-bit random and die with the session; retained outcomes are capped at 256 and 15 minutes.

**Panel JavaScript** (`html/`): the only `innerHTML` uses are constant SVG icon strings; every value
from a snapshot reaches the DOM through `textContent`, `setAttribute` or a form field's `value`;
no `eval`, `new Function`, `document.write`, `fetch`, `XMLHttpRequest`, `WebSocket`, `location`
assignment or `window.open`; the Agent Access page clears the token field and the client forms when
its dialog closes.

**Python** (`python/`): the only dynamic import is `stack.load`, gated to a fixed package set; no
`eval`, `exec`, `pickle`, `yaml`, `subprocess` or file IO; failures are reported by class and
package-relative frame, never message; the extraction document is schema-checked before any record
is read.

**Build and supply chain** (`tools/`, CI): the RBZ refuses `_private`, `hostkit`, `examples`,
`fixtures`, `tests`, dotfiles, bytecode, undeclared suffixes, the retired designPH namespace and
blocking browser APIs; `vendor.py` verifies Pyodide and each wheel against recorded SHA-256 values
and extracts tar members by basename into a fresh folder; `pnpm` enforces a 24-hour minimum release
age and blocks exotic subdependencies; lockfiles cover Ruby, Node and Python; no secret pattern
appears anywhere in history; the git hooks run only the repository's own Python.
