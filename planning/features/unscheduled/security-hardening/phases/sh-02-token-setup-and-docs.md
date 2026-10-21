# SH-02 Token setup forms and the agent docs

DATE: 2026-10-21
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#292](https://github.com/bldgtyp/ph-composer/issues/292)
FINDINGS: F01, F02 (documentation only), the privacy section's recommendation on paths
DEPENDS ON: nothing
ONE PR: yes

## Scope

Lead the Agent Access window and `docs/AGENT_ACCESS.md` with the client setup that keeps the token
out of files, say where every alternative stores it, and document the shared-computer caveat and
what an agent learns about paths. No change to how tokens are issued, stored or checked.

## Verified at the baseline

`src/ph_composer/agent_access/client_config.rb`:

- `claude_code(port, token)` returns three forms in this order: (1) "Run in a terminal", the
  `claude mcp add ... --header "Authorization: Bearer <token>"` command, which Claude Code writes
  into `~/.claude.json`; (2) "Or, to keep the token out of Claude Code's settings, run this", the
  `claude mcp add-json` command whose JSON reads `${PH_COMPOSER_TOKEN}`; (3) `export_form(token)`,
  "and add this to your shell profile, such as ~/.zshrc, then run it in this terminal too".
- `codex(port, token)` returns: (1) the `[mcp_servers.ph-composer]` block with
  `bearer_token_env_var`; (2) `export_form`; (3) "Or instead of both, this block with the token in
  it" with `http_headers = { Authorization = "Bearer <token>" }`.
- `check` and `remove` commands per client.

`html/agent_access/page.js` `showClients` renders, per client, an `h3`, then each form's title as a
muted paragraph and its text in a read-only textarea with a copy button, then "Check it with ...".
`closeIssued` clears the token field and the client forms.

`tests/agent_access_client_config_test.rb` pins the forms' text and order for both clients and that a
changed port reaches every non-export form. `tests/agent_access_dialog_test.js` renders a synthetic
`access.issued` with one form. `tools/ui-preview/agent_access_checks.cjs` drives the page in a
browser.

`docs/AGENT_ACCESS.md` "Connect your client" describes the header command first, the `add-json`
alternative second, and tells both clients' users to put the `export` line in the shell profile.

## Target

Forms per client, in order, each title naming where the token is kept:

Claude Code:

1. "Run in a terminal. The token stays in the environment and never enters a file.":
   `claude mcp add-json --scope user ph-composer '<json with ${PH_COMPOSER_TOKEN}>'`
2. "Then set the variable in the terminal you start Claude Code from. Putting this line in your
   shell profile keeps the token in that file.": `export PH_COMPOSER_TOKEN=<token>`
3. "Or, one command, with the token kept in Claude Code's settings file and your shell history.":
   `claude mcp add --transport http --scope user ph-composer <url> --header "Authorization: Bearer <token>"`

Codex:

1. "Add to ~/.codex/config.toml. The token stays in the environment and never enters a file.":
   the block with `bearer_token_env_var`
2. The same export form as Claude Code's second.
3. "Or this block instead of both, with the token kept in ~/.codex/config.toml.":
   the block with `http_headers`

The command text itself does not change; only order and titles do. `check` and `remove` are
unchanged.

The issued dialog gains one sentence under its existing "Copy this token now" line: "Each setup
says where the token is kept. Choose the first unless your client cannot read an environment
variable."

## Steps

1. `client_config.rb`: reorder the arrays in `claude_code` and `codex`; rewrite `export_form`'s
   title; rewrite the other titles as above. Keep `TOKEN_VARIABLE`, `SERVER_NAME`, `url`.
2. `tests/agent_access_client_config_test.rb`: update the expected order and titles. Add one
   assertion that the first form of each client contains `PH_COMPOSER_TOKEN` and not the token.
3. `html/agent_access/page.js` `buildIssuedDialog`: add the sentence as a second muted paragraph.
   `tests/agent_access_dialog_test.js`: assert it is present.
4. `tools/ui-preview/agent_access_checks.cjs`: if it asserts the first form's title or text, update
   it; run `make ui-checks UI_CHECKS=tools/ui-preview/agent_access_checks.cjs`.
5. `docs/AGENT_ACCESS.md` "Connect your client": rewrite the two bullets to lead with the
   environment-variable setup and name where each alternative stores the token. Add two short
   paragraphs after them:
   - **Where the token is kept.** The environment-variable setup keeps it in the terminal's
     environment; a shell profile line keeps it in that file; the one-command and inline setups
     keep it in the client's settings file (and, for a command, the shell history). Anyone who can
     read those files has the token until it is revoked.
   - **Shared computers.** PH-Composer listens on one port on this computer. On a computer with
     several user accounts, another account could run a program on that port while SketchUp is not
     listening and receive the token from an agent that connects then. On such a computer, revoke
     tokens when you finish and issue a new one when you start.
   And one sentence in "Agent tokens" after "Read is always included": the agent also learns the
   open Model's file path from its context read, and, for an export it started, the written files'
   paths; what the agent does with them is the agent's client's concern.
6. `docs/AGENT_GUIDE.md`: if it tells the agent how to connect, keep it consistent with the new
   order (read it; change only what names the forms).

## Tests and gate

`make ci`; `make ui-checks UI_CHECKS=tools/ui-preview/agent_access_checks.cjs` (skips by name
without Playwright; then say so in the PR). `tests/agent_access_tokens_test.rb` must be unchanged
and green (SH-02-A4).

## Acceptance

SH-02-A1 to SH-02-A4.

## Decisions

| Decision | Who |
| --- | --- |
| Exact title wording | Agent, in the client-facing register |
| Dropping the one-command form entirely | Ed; default keeps it third |

## Out of scope

Any change to the listener, the port or the token store. The structural port fix is SH-05.
