# Threat model

DATE: 2026-10-21
BASELINE: `main` at `9e5282171e133229be44e20d408f0037596183b6`

PH-Composer runs inside SketchUp as the user, on the user's machine, with no account, no hosted
service and no outbound network call. Every attacker below is therefore either someone who hands the
user a file, something that reaches a loopback port, or something that reaches the repository and
its build inputs. The product boundary in `AGENTS.md` makes this explicit: the SKP owns the data,
providers are optional files, and the only listener is the one the user turns on by issuing a token.

## What is worth protecting

| Asset | Where it lives | Who may reach it |
| --- | --- | --- |
| The user's Models (geometry, names, `user_data`, extension data) | Open SketchUp documents | The user; a token holding `read`; export under `export` |
| Agent tokens | SketchUp defaults, as SHA-256 only; the secret once in the dialog | The user in the Agent Access window; nothing registered with the API |
| Approved locations and library paths | SketchUp defaults, base64 JSON, plaintext paths | Handlers only; public rows carry id and label |
| Exported HBJSON and report | A destination the user chose | The caller that started the task reads paths; others read labels |
| The viewport image | A per-session temporary folder | A token holding `capture` |
| The diagnostics log and support report | `<Plugins>/../PH-Composer/logs/` | The user; Help & Diagnostics |
| The host process itself (Ruby in SketchUp) | | Any loaded extension; the development bridge when installed |

## Attackers and their reach

### 1. A crafted SKP file

The most ordinary attacker: a model from a client, a colleague or a download, with attribute
dictionaries under the `ph_composer` prefix written by hand or by a hostile tool. Its inputs are
JSON strings in attribute dictionaries, native Group and Component names, and `user_data` maps.

Where it lands: `Records::DictionaryStore.read` and `GeometrySnapshot::Entry#record` parse the JSON;
every kind validates against its declared schema (`JsonSchema`, `JsonValue`) before use; names reach
the panel through `textContent` and the report through `CGI.escapeHTML`; `DeepCopy` never uses
`Marshal`. The record engine refuses an unreadable record rather than repairing it. See
[06](sections/06-core-session-records.md) and [05](sections/05-export-artifacts.md).

What it could still do: make an export refuse, make a read report a record as unreadable, or carry a
`user_data` map the user then exports. None of these runs code or reaches a file outside the Model.

### 2. A crafted library JSON file or folder

A file the user adds as a library provider, or a folder of them. Inputs: up to 32 MiB of JSON per
file, 64 MiB aggregate, 20,000 rows; file names in a folder.

Where it lands: `Library::LibraryFile.parse` checks the envelope, each row against the adapter's
wire schema, and admission relabels every row. Only immediate children with a `.json` extension are
read; nothing recurses. Error text from the filesystem never reaches an outcome. See
[04](sections/04-locations-library-filesystem.md).

What it could still do: fill the catalog with rows the user then copies into a Model, which is the
feature working as intended, and nothing beyond.

### 3. An agent holding a token

A local MCP client the user configured, or any local process that obtained the token. Its reach is
exactly its capabilities (`read`, and any of `view`, `model_write`, `setup`, `export`, `capture`),
enforced twice: once in the tool allowlist (`Executor.reaches?`) and once at dispatch against the
caller handle issued by `API.connect`. It cannot list, issue or revoke tokens. It cannot name a
path: file operations take an approved location id, and the only path it ever receives is the
written export pair, and only when it started the task.

The agent is the user's own and is trusted to the extent of its grant. Model names, notes and
`user_data` are data to the agent, not instructions; that rule is the agent's client's to enforce,
and PH-Composer documents it in `docs/AGENT_GUIDE.md`. See [01](sections/01-agent-access.md).

### 4. A web page in the user's browser, against the loopback servers

Two loopback listeners exist: the MCP server on a fixed port while a token is live, and the asset
server on an ephemeral port while an export runs. A page cannot set `Authorization`, so it cannot
pass the MCP server's bearer check; it always sends `Origin` on a cross-origin POST, which the server
refuses with 403 before authentication; a `Host` other than `127.0.0.1:<port>` or `localhost:<port>`
is refused, so DNS rebinding does not help. The asset server needs a 128-bit path token the page
never learns, and the assets it serves are public files in any case. See
[01](sections/01-agent-access.md) and [02](sections/02-runtime-asset-server.md).

### 5. Another local user or process on the same machine

A different OS user on a shared workstation, or malware running as the same user. The second is out
of scope: a process running as the user can already read SketchUp's defaults, the user's documents
and the agent client's configuration, and no extension-level control changes that. The first has one
concrete move: bind the fixed MCP port before SketchUp does and receive the bearer token from an
agent that connects to it (F02). Loopback traffic itself is not readable without root.

### 6. The repository and its build inputs

A public repository with CI, a pinned Pyodide payload, eight vendored wheels, one Ruby gem and one
npm package for linting. `tools/runtime/vendor.py` verifies every download against a recorded
SHA-256; `pnpm` has a 24-hour minimum release age and refuses exotic subdependencies; `uv.lock` and
`Gemfile.lock` pin the rest. GitHub Actions are pinned by major tag, not SHA (F05). The build refuses
development material, the host bridge and a few blocking browser APIs (`tools/rbz/build.py`). See
[09](sections/09-dev-tooling-build-supply-chain.md).

## Trust boundaries the code draws

- **Main thread versus worker threads.** The MCP server's workers read, authenticate and parse only;
  every SketchUp or API call runs on the main thread through a timer pump. The asset server's workers
  serve bytes already hashed at construction.
- **Params versus approval.** A path never travels in params. A native client passes the user's
  dialog answer as `NativeApproval::Granted`, whose `to_h` and `inspect` hide the path; a scripted
  client passes an approved location id that dispatch resolves and strips before the handler sees
  params.
- **Declared versus free text.** The diagnostics log accepts only allowlisted fields whose values
  match a regex, redacts anything that looks like a path, and records exceptions by class and
  extension-relative frame, never message. Export refuses any result field no contributor declared
  and any string that looks like an absolute path.
- **Development versus shipping.** The host bridge (arbitrary Ruby eval behind a random token),
  the UI preview server and the examples live under `tools/` and are refused by the RBZ build.

## Out of scope

- SketchUp's own HtmlDialog and CEF, Ruby and Pyodide vulnerabilities.
- Malware running as the user.
- Denial of service, resource exhaustion and timing attacks below the practical bar, which the house
  rubric excludes. Where a cap exists it is noted as coverage, not as a finding.
- The Windows build, which has no host proof yet.
