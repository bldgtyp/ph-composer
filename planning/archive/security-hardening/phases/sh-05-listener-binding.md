# SH-05 Listener binding against port squatting

DATE: 2026-10-21
STATUS: Deferred
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#292](https://github.com/bldgtyp/ph-composer/issues/292)
FINDINGS: F02 (structural)
DEPENDS ON: the agent connection and access-grant packet named in `context/AGENT_INTERFACE.md`
("binding an approval to a named connection waits for the unscheduled agent connection and
access-grant packet"), which has no folder yet
ONE PR: not planned

## The problem

MCP's HTTP transport authenticates the client to the server with a bearer token and gives the
client no way to authenticate the server. On a computer with several user accounts, a process in
another account can bind the fixed port while SketchUp is not listening, accept the agent's
connection, and read the token from its `Authorization` header. SH-02 documents the caveat; this
stage records what a structural fix would take, so the owning packet can decide.

## Options

| Option | What it does | Why not now |
| --- | --- | --- |
| Random port per token, written into the client config | A squatter must guess the port while SketchUp is down | Weak: ports are few, and a client config names it in plaintext |
| Per-token path (`/mcp/<token id>`) | Nothing: the squatter still receives the header | No protection |
| Server-side challenge before the bearer is sent | Not expressible in the MCP HTTP transport the two clients speak | Would need a client-side shim |
| TLS on loopback with a per-install self-signed certificate, pinned in the client config | The client refuses a server without the pinned certificate | Neither client pins a certificate today; a self-signed loopback cert needs the user to trust it or the client to pin it; adds certificate lifecycle to a tool with no update channel |
| Unix domain socket | No port to squat; the socket file carries file permissions | Neither client speaks MCP over a Unix socket; a local shim process would be needed, which the product boundary rules out |

None closes the gap without a client-side component. The honest position is the documented caveat
plus short-lived tokens on shared machines, which the user controls today by revoking.

## When to revisit

When the agent connection and access-grant packet binds a grant to a named connection, it will
decide how a connection is identified. If it introduces a client-side component or a client with
certificate pinning, this stage becomes a row there and this file is withdrawn.
