# Using PH-Composer with your agent

DATE: 2026-10-18
STATUS: The in-process public interface and agent tokens are implemented. No external connection
endpoint or client setup is available yet.

PH-Composer will let users' agents inspect and edit building models through documented public
operations. Users choose their agent. No built-in LLM, model-provider account or AI subscription is
required by PH-Composer, and ordinary hand authoring remains complete.

The intended workflow is to discover the installed capabilities and target model, read relevant
records or visual context, propose changes where appropriate, apply validated operations, and
read back the result. Writes use the same domain rules and native Undo as the application UI.
The interface reports conflicts when the model changed after the agent inspected it.

Agent access will be explicit and revocable. The user controls which model and file operations
the connection may perform. The public interface will return structured results and diagnostics
without requiring access to private implementation code.

## Available now

The public interface an agent will use already exists inside SketchUp, as `PhComposer::API`. A
Ruby script running in SketchUp can discover the registered operations, describe each one's
parameters and results, read Zones and Faces in bounded pages, preview a change and apply it with a
conflict check, and run, poll and cancel an export, all with the panel closed. The
[API quickstart](API_QUICKSTART.md) walks one session from discovery to a verified edit and runs as
an automated test; the [API reference](API_REFERENCE.md) is generated from the registered
operations. A caller connects with only the grants it needs: `read`, `view`, `model_write`, `setup`
and `export`. Exporting a library file or an HBJSON model and adding a library file or folder need
a location only the user can choose. The user approves it once in the Libraries dialog or the
Libraries menu, and a script then names it by id; a path never passes through the interface. The
user sees, renames and revokes approved locations in the same dialog. A script that names no
approved location is refused with `access.user_required`.

### Agent tokens

An agent connects with a token you issue in SketchUp: Extensions > PH-Composer > Agent Access opens
the Agent Access window, separate from the panel, so a change you are making there is left alone.
New token asks for a name and the access the token holds. Read is always included: it reads the
open Models, their Zones, Spaces, Assemblies and Window Types and the values PH-Composer calculates,
and changes nothing. The token is shown once; copy it then, because it is not shown again. The
token is the only secret: anyone holding it has its access until you revoke it in the same window.
Revoking keeps the token in the list with the date it was revoked. Up to eight tokens can be live
at once. No connection serves tokens yet, so the window says agents cannot connect.

## Not yet available

A local MCP adapter is the recommended first integration. The application contract remains usable
by scripts and other clients. Transport and installation details are still design work; no current
agent client is claimed as supported. Arbitrary Ruby evaluation bridges remain development tools.

When the external connection lands, this page will provide its tested installation steps and
client configurations.
The engineering requirements and acceptance checks are in
[AGENT_INTERFACE.md](../context/AGENT_INTERFACE.md).
