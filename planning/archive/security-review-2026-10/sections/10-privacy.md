# 10 Privacy: a data-handling map

What PH-Composer stores, where, in what form, and who can see it. `docs/PRODUCT.md` promises
authoring and export "without an account or network service"; this section checks that promise
against the code at the baseline.

## What leaves the machine

Nothing, by code. The shipping tree makes no outbound request: no `Net::HTTP`, `URI.open`, `fetch`
or `XMLHttpRequest`; `UI.openURL` opens three fixed GitHub or SketchUp URLs and a local folder, only
when the user clicks. The two listeners bind `127.0.0.1`. `vendor.py` downloads at development time
only. The claim holds, but it is observed rather than enforced (no CSP, F08).

## Where data is stored

| Data | Store | Form | Visibility |
| --- | --- | --- | --- |
| Records, settings, `user_data`, extension envelopes | The SKP's attribute dictionaries under `ph_composer.*` | JSON strings | Anyone with the file; travels with the Model |
| Agent tokens | SketchUp defaults, `ph_composer.agent_access/tokens` | base64 JSON of id, label, capabilities, dates, SHA-256 digest, optional bound Model path | The user's preferences file; the secret itself is shown once and never stored |
| Listener port | SketchUp defaults, `ph_composer/agent_access.port` | Integer | Same |
| Approved locations | SketchUp defaults, `ph_composer.locations/approved` | base64 JSON with plaintext paths | Same; the API returns ids and labels only |
| Library configuration | SketchUp defaults, `ph_composer.library/file_providers` | base64 JSON with plaintext paths | Same; the API returns ids and labels only |
| Display preferences | SketchUp defaults, `ph_composer/*` | Enumerated values and base64 JSON maps | Same |
| Diagnostics log | `<Plugins parent>/PH-Composer/logs/ph-composer.log` and `.1` | JSON lines, allowlisted fields, paths redacted, 512 KiB, 7 days | The user; Help & Diagnostics |
| Support report | A path the user chooses | Plain text: version, build, host, log health, sanitized log lines | The user, to share by choice |
| Viewport captures | `<tmpdir>/ph_composer/captures/<session>/cap_*.png` | PNG, geometry only, newest four, 15 minutes | The user; the `capture` token holder is told the path |
| Export pair | A destination the user chose or approved | HBJSON and HTML | The user; the starting caller is told the paths |
| Library export | A `.json` destination the user chose or approved | JSON | The user |
| Host bridge state (development only) | `<Plugins parent>/ph_composer_host_bridge.json` and `.console.log` | Plaintext token, port, pid; a full console transcript | The developer's machine |

On macOS, SketchUp's defaults are a preferences plist in the user's Library; on Windows, the
registry. Both are per-user.

## What each capability lets a token holder reach

| Capability | Reads | Writes or effects | Paths it sees |
| --- | --- | --- | --- |
| `read` (always) | Every registered query: Zones, Faces, Spaces, Assemblies, Materials, Window Types, Units, settings, library catalogs, approved-location labels, the Model context including its file path | None | The Model's own path (`context`) |
| `view` | | Selection, camera, edit path, Colour-by mode; may trigger Volume protection | None |
| `model_write` | | Every registered action, each one Undo step, revision-checked | None |
| `setup` | | Library add (via approved file or folder id, once each), remove, reset; location rename, revoke, reset; catalog load | None |
| `export` | | HBJSON export and library export to an approved destination; replace only with reviewed state | The written pair's paths, for its own tasks |
| `capture` | | Writes a PNG of the view | The PNG's temp path |

A token never: lists, issues or revokes tokens; names a path; opens a dialog; reaches another
Model when bound to one.

## What export carries and refuses

Carries: declared record values, geometry in metres, the user's own `user_data` where a contributor
passes it (counted in a finding), each contributor's declared result fields, a run id, and the
report's figures. Refuses: any undeclared field, `extension_data`, `path`, `source_path`,
`file_path`, `model_path`, `username`, any absolute-path string, `user_data` under a reserved
namespace, and an extension envelope whose relevance is unknown or required but not understood.
Library export additionally omits `source` snapshots beyond the mapped fields and reports every
omitted field by name.

The report's embedded JSON is the full result document minus the HBJSON text, so a report carries
every Zone, Space, Assembly and Window Type name and the finding messages that name them. That is
the document's purpose; a user sharing a report shares those names.

## What the log and support report hold

Fields: timestamp, schema, event, extension version, build, severity, status, code, operation,
stage, effect, session id, request id, run id, incident, error class, extension-relative frames,
duration, SketchUp version, manifest digest. No Model names, record values, params, paths, tokens or
exception messages. The support report header lists what is omitted so a reader can see the policy.
`panel.diagnostic` frames from the page are kept only under `html/`.

## Public-repository exposure

The repository is public. Tracked content was swept for tokens, key patterns, client names and
absolute paths. Found: the maintainer's `/Users/<name>` home path in five planning files, one of
them a `.rbenv` interpreter path in an evidence log (F07); `_private/` fixture names in
`results.jsonl` (synthetic fixtures, no client data). Issue
templates ask for a support report, which carries no paths by construction.

## Recommendations specific to privacy

- State in `docs/AGENT_ACCESS.md` that `context` and the export artifacts answer file paths to the
  agent, and that the agent client, not PH-Composer, decides what it does with them.
- State where each client setup form stores the token (F01).
- Add the CSP meta so "no network" is enforced (F08).
