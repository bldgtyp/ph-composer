# P3a1-11: Client configuration snippets and diagnostics

DATE: 2026-10-17
STATUS: Scoped. Planning only; execution requires separate implementation authorization. Rewritten 2026-10-17 to accepted D3a1-01 and D3a1-11: no installer, no companion; the RBZ is the installation and the dialog shows the client configuration.
ISSUE: none (local planning draft)

## Entry and ownership

Workstream: W4. Order: V2, last piece. Depends on: P3a1-07, 08 and 10 read-scope slices; D3a1-11 accepted.
Review findings: A01 installation. Acceptance: C11 in [ACCEPTANCE](../ACCEPTANCE.md).
Behavior: [PRD](../PRD.md). Proposed boundaries: [CONTRACTS](../CONTRACTS.md) section 9.
Decisions: [DECISIONS](../DECISIONS.md) D3a1-01, 11. Delivery rules: [PLAN](../PLAN.md).

07 owns the dialog and the token's lifetime; this stage owns what the dialog shows the user to
paste, verified against the two CLIs at exact versions, and the diagnostics a user needs when the
client does not connect. Until public distribution opens its own gate, "Ed installs the RBZ from the
repository with `make rbz`" is the installation.

## Source and intended change surface

Existing files changed:

- [docs/AGENT_ACCESS.md](../../../../docs/AGENT_ACCESS.md): a "Connect your client" section with the two snippets and the check commands, written at docs-pass to what the gate proved
- [docs/DEVELOPMENT.md](../../../../docs/DEVELOPMENT.md): one paragraph separating the development bridge from agent access

Existing files read, not changed: [tools/rbz/shipping_allowlist.json](../../../../tools/rbz/shipping_allowlist.json)
and the `rbz-check` target in the [Makefile](../../../../Makefile) (the `agent_access` folder ships
with no allowlist entry because it is under `src/ph_composer/`),
[context/SKETCHUP_HOST_BEHAVIOR.md](../../../../context/SKETCHUP_HOST_BEHAVIOR.md) (the process
facts headless runs depend on). From 07: `agent_access/dialog.rb` and `html/agent_access/` render
what this stage generates.

New files, named here and linked when the stage merges: `src/ph_composer/agent_access/client_config.rb`
(a pure function of port, token and label to each client's snippet), `tests/agent_access_client_config_test.rb`
(golden text per client at the pinned versions), and `tools/hostkit/agent_access_probe.py`
(development only: runs `claude -p` and `codex exec` with a fixed prompt against the configured
server and keeps the transcript for the acceptance receipt; never shipped).

## The snippets

Claude Code, the command form the dialog shows first, and the JSON form for a user who keeps the
token in an environment variable:

```
claude mcp add --transport http --scope user ph-composer http://127.0.0.1:46110/mcp \
  --header "Authorization: Bearer <token>"
```

Codex, a block for `~/.codex/config.toml` with the token in an environment variable, and the
inline `http_headers` form beside it:

```
[mcp_servers.ph_composer]
url = "http://127.0.0.1:46110/mcp"
bearer_token_env_var = "PH_COMPOSER_TOKEN"
```

The check commands shown with them: `claude mcp get ph-composer` and `codex mcp list`. The
removal commands: `claude mcp remove ph-composer` and deleting the TOML block. The exact flag names
come from the pinned client versions D3a1-11 names; a flag that changes between versions is a
golden-test failure, not a silent edit.

## Implementation steps

1. Implement `client_config` with golden tests for both clients, including the environment-variable
   forms, a label with spaces, and a changed port.
2. Render the snippets and check commands in 07's created-token screen with copy buttons, and the
   removal commands in the dialog's help text.
3. Server status in the dialog list: listening on the port, stopped because no token is live, or
   `EADDRINUSE` with the port field; changing the port restarts the listener. Per token: last
   request time and its status from 08's diagnostics ring. Nothing else is a doctor.
4. Confirm against the exact CLIs: `claude mcp get` reports the server connected; `codex mcp list`
   shows it; `codex exec` with a prompt that calls `discover` returns the session list, which
   answers the open point in D3a1-11.
5. Write the headless acceptance probe and use it for the V2 gate; its transcript is the receipt's
   client evidence.
6. Document uninstall as revoking every token in the dialog plus the two removal commands; the RBZ
   is removed through Extension Manager as any extension is.

## Acceptance checks

- Golden snippets per client at the pinned versions; the token appears in a snippet only on the
  created-token screen and never in a log, a test fixture committed to the repository, or docs.
- Port conflict: a test binds the port first; the dialog state reports it; a changed port binds.
- The diagnostics line shows no params, paths or token; a token never used shows "never".
- The two CLI checks and the `codex exec` confirmation are recorded with versions.

## Native/client gate

On the proving host, from the installed RBZ: issue a token, paste each snippet into its client
without editing, run the two check commands, then run the headless probe for a `discover` and one
`query`. Record client versions, the RBZ hash, the port and the probe transcript. Then remove the
entries with the documented commands and confirm each client no longer lists the server.

## Cleanup and documentation

CL08: after acceptance, the test entries are removed from the real client configurations with the
documented commands and the test tokens revoked; the snapshot of each configuration taken before
the run is compared after. The review's companion recommendation in
[CLIENT_INTEGRATION](../../../code-review/CLIENT_INTEGRATION.md) stays as evidence and is superseded
by the receipt; `docs/AGENT_ACCESS.md` says what is proved and nothing more.
Record affected context/docs, exact checks and evidence in [STATUS](../STATUS.md) through docs-pass.
Shipping source/tests cite durable context rather than this plan. Preserve unrelated dirty work.

## Done when

C11's golden, port and diagnostics checks pass; both CLIs connect from the pasted snippets on the
recorded host; the exact supported surfaces (the two CLIs at their versions) are written in the
receipt. No public release claim.
Applicable full gates, review level, manifest handling and DCO/hook rules are in [PLAN](../PLAN.md).
A planning document or unexecuted check is not implementation evidence.

## Out of scope

An installer, uninstaller or doctor command, editing a user's client configuration from Ruby,
desktop client surfaces (claimed separately under D3a1-11), marketplace submission, signing,
notarization and public distribution.
