# Using PH-Composer with your agent

DATE: 2026-09-30
STATUS: The in-process public interface is implemented. No external connection endpoint or client
setup is available yet.

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
operations. A caller connects with only the grants it needs: `read`, `view`, `model_write` and
`export`.

## Not yet available

A local MCP adapter is the recommended first integration. The application contract remains usable
by scripts and other clients. Transport and installation details are still design work; no current
agent client is claimed as supported. Arbitrary Ruby evaluation bridges remain development tools.

When the external connection lands, this page will provide its tested installation steps and
client configurations.
The engineering requirements and acceptance checks are in
[AGENT_INTERFACE.md](../context/AGENT_INTERFACE.md).
