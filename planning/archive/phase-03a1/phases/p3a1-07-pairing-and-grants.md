# P3a1-07: Access tokens, the access dialog and grants

DATE: 2026-10-17
STATUS: Read-scope slice merged to main (#224); write-scope slice Scoped (V5).
ISSUE: [#221](https://github.com/bldgtyp/ph-composer/issues/221)

## Entry and ownership

Workstream: W3. Order: read-scope slice in V2, write-scope slice in V5. Depends on: P3a1-06 receipt; the write-scope slice is V5, after V4.
Review findings: A02. Acceptance: C07 in [ACCEPTANCE](../ACCEPTANCE.md).
Behavior: [PRD](../PRD.md). Proposed boundaries: [CONTRACTS](../CONTRACTS.md) section 4.
Decisions: [DECISIONS](../DECISIONS.md) D3a1-05, 06, 08, 12, 13. Delivery rules: [PLAN](../PLAN.md).

A token carries a label, a capability set and a revoke control. Sessions are discovered and named
explicitly by the agent, as the API already requires. Nothing pairs, expires on reopen or binds to a
Model by default.

## Source and intended change surface

Existing files changed:

- [extension.rb](../../../../src/ph_composer/extension.rb): `FOUNDATION_DIRECTORIES` gains `agent_access`; `FOUNDATION_FEATURES` gains the access feature that declares the menu item
- [shell/commands.rb](../../../../src/ph_composer/shell/commands.rb): unchanged in code; the menu item arrives through the registry as every feature menu does
- [shell/preferences.rb](../../../../src/ph_composer/shell/preferences.rb): the `agent_access.port` preference, read and written like `unit_system`
- [html/index.html](../../../../src/ph_composer/html/index.html) and the panel manifest: the new page is listed and `make panel-manifest` refreshed

Existing files read, not changed: [shell/approved_locations.rb](../../../../src/ph_composer/shell/approved_locations.rb)
(the storage shape to copy: base64 JSON in `Sketchup.write_default`, a byte cap, tombstones,
`unreadable` reported and never silently replaced),
[session/caller_registry.rb](../../../../src/ph_composer/session/caller_registry.rb) (`CAPABILITIES`),
[shell/panel.rb](../../../../src/ph_composer/shell/panel.rb) (how an HtmlDialog is built, callbacks
registered before `show`), the UI kit under [html/](../../../../src/ph_composer/html/).

New files, named here and linked when the stage merges: `src/ph_composer/agent_access/tokens.rb`
(the store), `agent_access/dialog.rb` (the HtmlDialog host and its callbacks),
`agent_access/install.rb` (the foundation feature: menu item, reset registration, server hooks),
`html/agent_access/index.html`, `agent_access.js` and `agent_access.css` (the page, built from the
UI kit), `tests/agent_access_tokens_test.rb`, `tests/agent_access_dialog_test.js`.

## The token record and the dialog

A token row: `id` (`Records::Identity.mint("token")`), `label` (1 to 80 characters, the user's or
"Agent token N"), `token_sha256`, `capabilities` (a subset of `CallerRegistry::CAPABILITIES` that
always contains `read`), `created_at`, `last_used_at`, and from the write-scope slice an optional
`model_file` for "this Model only". Revoked rows become tombstones with `revoked_at`. The store
holds at most 8 live tokens (D3a1-12) and 64 KiB; a token has no expiry, only revoke. The token itself is never stored, logged or returned by
any public operation; nothing about tokens is registered with `PhComposer::API`, so no grant lets
an agent list, issue or revoke one. The dialog reaches the store through its own HtmlDialog
callbacks, which run on the main thread.

One HtmlDialog, "PH-Composer Agent Access", opened from the Extensions submenu entry "Agent
Access…" and separate from the panel, so issuing or revoking never touches an open draft. Its
screens:

- The list: label, capabilities, created, last used, a Revoke button per row, and a server status
  line (listening on port N, stopped because no token is live, or port in use with a field to change
  it, from 11).
- New token: label; capability checkboxes with one line of consent copy each. In the read-scope
  slice only `read` is offered, checked and fixed. The write-scope slice adds `view` (changes what the host shows: camera, selection and edit
  context, never authored data; leaving a Volume may lock it, as each command declares under
  D3a1-13), `model_write` (edits the Model, each action one Undo step), `setup` (changes this
  machine's libraries and settings for every Model, not just this one) and `export` (writes to
  approved destinations and, from 13, reads back that run's files), and "this Model only". V8 adds
  `capture` (a geometry-only image of the current view, D3a1-08) when 15 lands.
- Created: the token shown once beside the client snippets 11 generates, each with a copy button,
  and "I have copied it", after which the token is never shown again.
- Revoke: one confirmation; the row moves to revoked with its time; from the write-scope slice the
  acknowledgment lists the work 09 reports as completed and stopped.

## Implementation steps

Read-scope slice (V2):

1. Implement the store with issue, list, revoke, `live?` and a frozen `snapshot` of SHA-256 to
   public row for the ingress; register its reset; validate rows as approved locations do; refuse
   over the live-token and byte caps with a coded message the dialog shows.
2. Register the foundation feature: one menu item under its own "Agent Access" submenu that opens
   the dialog; the dialog is reachable with the panel closed and with a draft open in the panel.
3. Build the page from the UI kit (page header, fields, notices); apply the UI polish skill; keep
   callbacks registered before `show`; refresh the panel manifest.
4. Call the server hooks on every store write: start the listener when the first live token exists,
   stop it after the last revoke, refresh the ingress snapshot. Until 08 lands the hooks are no-ops
   recorded as such.
5. Write the user-facing copy once, in the dialog, and reuse it in `docs/AGENT_ACCESS.md` at
   docs-pass; the token is the only secret and the copy says so.

Write-scope slice (V5):

6. Offer the four remaining capabilities with the consent copy above; `setup` names its
   machine-wide effect; `view` names the lock a navigation command declares (D3a1-13).
7. Add "this Model only": the token records the open Model's file path at issue time (plaintext in
   SketchUp's defaults, as approved locations already are) and `discover` through that token lists
   only sessions whose Model path matches; a Model never saved cannot be bound.
8. Show the revoke acknowledgment summary 09 produces.

## Acceptance checks

- Store: issue, list, revoke, tombstone, unreadable store, byte and count caps, capabilities checked
  against `CallerRegistry::CAPABILITIES` with `read` always present; the token appears once and neither
  its hash nor a Model-only token's file path appears in a public row, an outcome, `discover`'s
  `connection` object or `Diagnostics`.
- Dialog: create, copy, revoke, narrow width, revoked state visible, draft in the panel untouched;
  `API.discover` lists the feature id under `features` and no token operation, row or value.
- Write-scope slice: each capability's consent text matches what dispatch enforces; a Model-only
  token's `discover` omits other sessions and equal-basename Models in other folders.

## Native/client gate

Current host: open the dialog from the menu with the panel closed and again with an unsaved draft
in the panel; issue a token; revoke it; restart SketchUp and see the list and server status
restored. The write-scope slice repeats this with two tokens of different capability sets and FX4's
equal-basename Models.

## Cleanup and documentation

CL06: the token store is the one authority; no provisional grant map remains in the ingress or the
dialog. Existing approved locations and provider setup are untouched.
Record affected context/docs, exact checks and evidence in [STATUS](../STATUS.md) through docs-pass.
Shipping source/tests cite durable context rather than this plan. Preserve unrelated dirty work.

## Done when

Read-scope slice: C07's store and dialog checks pass offline and in the browser checks, the native
gate above is recorded, and the review passes. Write-scope slice: the same for the four capabilities,
"this Model only" and the acknowledgment summary.
Applicable full gates, review level, manifest handling and DCO/hook rules are in [PLAN](../PLAN.md).
A planning document or unexecuted check is not implementation evidence.

## Out of scope

Feature business changes, the listener itself (08), the snippet text (11), account or provider
sign-in, pairing nonces and session-bound grants (the listed alternative), and any grant that
survives a token's revocation.
