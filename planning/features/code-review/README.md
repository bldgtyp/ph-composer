# Security and privacy review

DATE: 2026-10-21
STATUS: In review
AUTHOR: Claude (Fable 5.1), requested by Ed May
ISSUE: none (local review requested by Ed)
BASELINE: `main` at `9e5282171e133229be44e20d408f0037596183b6`

A whole-tree security and privacy review of the shipping extension, its development tooling and
its public repository, read module by module. It is a reading review against the source at the
baseline, not a penetration test: nothing was run against a live SketchUp, and no finding below was
exploited.

## Verdict

**No high-confidence, high-impact vulnerability was found.** The attack surfaces that matter, the
loopback MCP listener, the Pyodide asset server, the HtmlDialog transports, file reads and writes
through approved locations, and the export artifact pair, each hold up under the threat model in
[THREAT_MODEL.md](THREAT_MODEL.md). The design choices that carry risk are recorded as such, with
Ed's own decision ids where one exists.

The findings that need a decision are small and mostly about where the agent token ends up on the
user's machine, not about PH-Composer's own handling of it:

1. **F01** The Agent Access window's first setup form puts the token on a shell command line and
   into the agent client's settings file; its shell-profile form puts it in a dotfile. Recommend
   making the environment-variable form primary and saying where the token lands.
2. **F02** The listener's fixed default port on a shared workstation lets another local user bind it
   first and receive tokens from a misdirected agent. Low on a single-user Mac; worth one sentence in
   the docs and, later, a token bound to a per-token path or a random port in the client config.
3. **F05, F06** Release hygiene before public distribution: pin GitHub Actions by SHA and add a
   `SECURITY.md` with a disclosure route.

Everything else is informational. The register is [FINDINGS.md](FINDINGS.md).

## Decision Ed needs to make

Which of F01 to F11 become issues or packets now, and which wait for the public-distribution gate.
The recommendation in the register marks each as `fix before release`, `fix when convenient` or
`accept and document`. Nothing here blocks current development.

## Read in this order

1. [THREAT_MODEL.md](THREAT_MODEL.md): who can reach what, and the trust boundaries the code draws.
2. [FINDINGS.md](FINDINGS.md): the register, then the design choices accepted as-is, then what was
   checked and found sound.
3. The module sections, each a security reading of one layer:
   [01 agent access](sections/01-agent-access.md),
   [02 runtime and asset server](sections/02-runtime-asset-server.md),
   [03 shell, panel and dialogs](sections/03-shell-panel-dialogs.md),
   [04 locations, library and the filesystem](sections/04-locations-library-filesystem.md),
   [05 export and artifacts](sections/05-export-artifacts.md),
   [06 core, session and records](sections/06-core-session-records.md),
   [07 panel JavaScript](sections/07-panel-javascript.md),
   [08 Python translation](sections/08-python-translation.md),
   [09 development tooling, build and supply chain](sections/09-dev-tooling-build-supply-chain.md).
4. [10 privacy](sections/10-privacy.md): a data-handling map, what leaves the machine, what is
   stored where, and what each capability lets a token holder see.
5. [EVIDENCE.md](EVIDENCE.md): the commands and greps behind the sections, and what was not read.

## Method

The review used the house security rubric (input validation, authentication and authorization,
crypto and secrets, injection and code execution, data exposure) with its false-positive bar: a
finding is reported as a vulnerability only with a concrete path from an attacker-controlled input
to a sensitive effect. Everything below that bar is filed as a hardening note or a design
observation so the coverage is still on record.

Each module was read in full where it owns a trust boundary (`agent_access/`, `runtime/`, `shell/`,
`export/`, `library/`, `core/` JSON and records primitives, `session/` callers and outcomes, the
panel transport JavaScript, the Python entry points, the build and vendoring tools, CI). Feature
domain code under `features/` was read where it builds report HTML, reads files or handles
extension data, and swept by grep elsewhere. The sweep patterns and their results are in
[EVIDENCE.md](EVIDENCE.md).

## Scope notes

- Ed named this folder. It is kept here as named rather than under a phase group; when it archives,
  it goes under a slug other than `code-review`, which the archive already holds for the
  October architecture review (`archive/code-review/`). Suggested: `archive/security-review-2026-10/`.
- Documentation-only; no code was changed and nothing was committed.
