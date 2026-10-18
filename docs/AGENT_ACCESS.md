# Using PH-Composer with your agent

DATE: 2026-10-18
STATUS: Agent tokens, the local connection and client setup are implemented and checked with Claude
Code 2.1.300 and Codex 0.163.0 on macOS. This is a development build, not a released or supported
product.

PH-Composer lets users' agents inspect and edit building models through documented public
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
and changes nothing. The rest start unchecked, each with what it allows: View changes what SketchUp
shows (the camera, the selection and the open Group, never authored data; leaving a Volume can lock
it again), Edit the Model runs PH-Composer's actions with one Undo step each, Setup changes this
computer's libraries and settings for every Model, and Export writes to the folders you approved.
This Model only limits the token to the Model open now, which must be saved: the agent then sees
and reaches no other Model, not even one with the same file name in another folder. The list shows
each token's access and, for such a token, the Model's file name. The token is shown once; copy it then, because it is not shown again. The
token is the only secret: anyone holding it has its access until you revoke it in the same window.
Revoking keeps the token in the list with the date it was revoked. Up to eight tokens can be live
at once.

While a token is live, PH-Composer listens for agents on this computer only, on port 46110, and the
Agent Access window says so. If another program holds that port, the window says so, offers a field
to choose another and holds New token until one is free, so a token's setup never names a port
nothing listens on. An agent connects over MCP with the token as a bearer header and can read:
list the open Models, describe and run the read operations, and preview a change without making it.
A token holding more can also apply changes (each one Undo step, refused with nothing written if the
Model changed since the agent read it), move the camera, selection and open Group, change library
setup, and run exports to folders you approved. An agent can name each change it sends; if a reply
is lost, sending the same name again returns the first result and never applies the change twice.
Each token's latest call since SketchUp started shows beside it.

### Connect your client

When a token is created, the window shows what to paste for each supported client, with the token
already in it. Checked with Claude Code 2.1.300 and Codex 0.163.0 on macOS:

- Claude Code: run the `claude mcp add --transport http --scope user ph-composer ...` command it
  shows. To keep the token out of Claude Code's settings, run the `claude mcp add-json ...` command
  instead, which reads it from `PH_COMPOSER_TOKEN`, and put the `export` line it shows in your shell
  profile and run it in the terminal you start Claude Code from. Check it with
  `claude mcp get ph-composer`, which should say Connected.
- Codex: paste the `[mcp_servers.ph-composer]` block it shows into `~/.codex/config.toml`, and the
  `export PH_COMPOSER_TOKEN=...` line into your shell profile, such as `~/.zshrc`, and run it in the
  terminal you start Codex from (a profile only reaches terminals opened after it changes); or paste
  the other block, which carries the token itself, instead of both. Check it with
  `codex mcp get ph-composer`. Edit the file by hand rather than with `codex mcp add`, which
  rewrites the whole file and drops its comments.

To disconnect an agent, revoke its token in the Agent Access window. To remove the entry from a
client as well, run `claude mcp remove ph-composer`, or delete the `[mcp_servers.ph-composer]`
block from `~/.codex/config.toml`. PH-Composer itself is removed with SketchUp's Extension Manager.

## Working with an agent

Give your agent [AGENT_GUIDE.md](AGENT_GUIDE.md) before it starts: it is the operating guide for
the connection, from finding the Model to reading back what changed, with recipes and what to do
when a request is refused or a reply is lost. Both clients above completed its core scenario
against a SketchUp Model: reading, a change with a replayed key, recovery from a stale revision, and
an export whose file they read and checked.

## Not yet available

Taking an image of the view is offered as a separate permission and is not yet supported for agent
use. The connection serves agents on this computer only; a remote or hosted connector is not
planned. Arbitrary Ruby evaluation bridges remain development tools. The engineering requirements
and acceptance checks are in [AGENT_INTERFACE.md](../context/AGENT_INTERFACE.md).
