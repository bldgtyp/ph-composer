# Evidence

DATE: 2026-10-21
BASELINE: `main` at `9e5282171e133229be44e20d408f0037596183b6`, working tree clean.

All commands ran from the repository root. Results are summarized; where a grep is the evidence for
a "checked and sound" claim, the pattern is given so it can be rerun after a change.

## Files read in full

`src/ph_composer.rb`, `src/ph_composer/extension.rb`; every file under `agent_access/`, `runtime/`,
`export/` (except `report.css`); `shell/{api,dispatch,request_checks,handler_request,operation_context,
panel,panel_messages,preferences,support_dialog,support_report,native_approval,approved_locations,
location_commands,commands,snapshot,context_commands,capture_command,record_queries,declarations}.rb`
and the first 60 lines of `pages.rb`; `core/{json_schema,json_value,json_walk,canonical_json,deep_copy,
coerce,dictionaries,model_settings,build_identity,diagnostics}.rb`, `core/records/{dictionary_store,
metadata,extension}.rb`; `session/{caller_registry,outcome_store,sessions,model_session}.rb`;
`library/` every file; `features/{zones,zones/faces,assemblies,windows,spaces}/export.rb`,
`features/assemblies/source_report.rb`, `features/windows/{export_assessment,library_imports}.rb`;
`html/{index,runtime/index,agent_access/index}.html`, `html/{panel,request,module,dom}.js`,
`html/sections/export.js`, `html/agent_access/page.js`, `html/runtime/runtime.js`;
`python/ph_composer_translation/{stack,entry,result,conformance,exporters,coordinator,composition,
material_sources}.py`; `tools/rbz/build.py`, `tools/rbz/shipping_allowlist.json`,
`tools/runtime/vendor.py`, `tools/hostkit/host_bridge.rb`, `tools/hostkit/.index.md`;
`.github/workflows/ci.yml`, `.github/ISSUE_TEMPLATE/config.yml`, `.githooks/*`, `Makefile`,
`package.json`, `.npmrc`, `pyproject.toml`, `Gemfile`, `.gitignore`; `context/AGENT_INTERFACE.md`,
`context/TECH_STACK.md` (first 200 lines), `planning/STATUS.md`, `planning/.instructions.md`,
`planning/archive/code-review/README.md`.

## Sweeps

Ruby, dangerous APIs (no hits outside the ones listed):

```
grep -rnE '\b(eval|instance_eval|class_eval|module_eval|Marshal|YAML|Psych|system\(|IO\.popen|Open3|spawn\(|exec\(|Kernel\.open|URI\.open|openURL|open_url|Net::HTTP|const_get|public_send|\.send\(|instance_variable_set|define_method)\b|`' src/ph_composer --include='*.rb'
```

Hits: `support_dialog.rb` (`UI.openURL` on fixed URLs), `registry.rb:245,317` and
`colour_by/readout_output.rb:17` (`public_send` with internal symbols), `preferences.rb:238`
(`Open3.capture3` with fixed absolute command and arguments). No `eval`, `Marshal`, `YAML`,
backticks or `system`.

Ruby, file and directory IO:

```
grep -rnE 'File\.(write|open|binwrite|rename|delete|unlink|symlink|readlink|realpath|read|binread)\(|FileUtils|Dir\.(glob|entries|children|each_child|mkdir|\[)|Tempfile|Dir\.tmpdir|Dir\.mktmpdir|write_image|write_default' src/ph_composer --include='*.rb'
```

Every hit is in `extension.rb` (bootstrap log), `core/diagnostics.rb`, `shell/{capture_command,
support_dialog}.rb`, `export/artifact_pair.rb`, `export/report.rb` (stylesheet), `library/{file_provider,
file_writer,setup_commands}.rb`, `runtime/{asset_server,runtime_manifest}.rb`, `core/build_identity.rb`,
`features/zones/faces/classify_tool.rb` (cursor file) and `features/zones/zone/occurrences.rb`
(`File.basename` of the Model path for a name). Each is discussed in its section.

Ruby, environment: `grep -rn 'ENV\[' src/ph_composer` has no hits.

Ruby, navigation and URLs: only `support_dialog.rb`.

JavaScript sinks:

```
grep -rnE 'innerHTML|outerHTML|insertAdjacentHTML|document\.write|\beval\(|new Function|setTimeout\(\s*["'"'"']|\.html\(|srcdoc|javascript:' src/ph_composer/html src/ph_composer/help --include='*.js' --include='*.html'
```

Hits: five `innerHTML` with constant icon SVG, one `srcdoc` with `sandbox=""`.

JavaScript network and navigation:

```
grep -rnE '\bfetch\(|XMLHttpRequest|WebSocket|navigator\.sendBeacon|setAttribute\("href"|\.href\s*=|\.src\s*=' src/ph_composer/html --include='*.js' | grep -v runtime/
```

No hits. Style sinks (`\.style\.[a-zA-Z]+\s*=|setProperty\(`) listed in section 07.

CSP: `grep -rn 'Content-Security-Policy' src/ph_composer/html src/ph_composer/help` has no hits.

Python sinks:

```
grep -rnE '\b(eval|exec|pickle|marshal|yaml|subprocess|os\.system|__import__|importlib|open\(|input\()\b' src/ph_composer/python --include='*.py'
```

Hit: `stack.py` `importlib.import_module`, gated by a fixed package set.

Secrets in history:

```
git log --all -p | grep -nEi '(sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY|xox[baprs]-[A-Za-z0-9-]{10,}|api[_-]?key\s*[:=]\s*["'"'"'][A-Za-z0-9]{16,})'
git grep -nE 'Bearer [0-9a-f]{48}|\b[0-9a-f]{48}\b|PH_COMPOSER_TOKEN=[0-9a-f]' -- planning tests docs tools
```

No hits for secrets; the 48-hex grep matched only SHA-256 fixture digests and a masked probe
transcript.

Tracked files and paths:

```
git ls-files | grep -iE 'pycache|DS_Store|\.coverage|\.pyc$|_private|\.env|secret|token'
git ls-files | grep -E '\.(log|jsonl|png|zip|pdf)$'
git grep -nE '/Users/[a-z]+|C:\\\\Users' -- ':!src/ph_composer/vendor' | grep -v '^planning/'
git grep -cE '/Users/[a-z]+' -- planning
```

Only `tokens.rb` and its test match the name sweep; the tracked logs, PNGs and JSONL are archived
evidence and mockups; `/Users/` hits outside planning are in `diagnostics.rb` comments and tests
using `/Users/example`; six planning files carry a `/Users/<name>` path, five of them the
maintainer's account and one a synthetic `/Users/example`.

Schema and storage spot checks:

```
grep -rnE 'JSON\.parse\([^)]*(create_additions|max_nesting)' src/ph_composer    # none: defaults
grep -rnE 'write_default\(' src/ph_composer --include='*.rb'                     # five stores, all listed
grep -nE 'g_value' src/ph_composer/python/ph_composer_translation/window_sections.py
grep -rnE '"g_value"' src/ph_composer/features/windows/products/schema.rb         # number, 0..1
```

Repository settings: `gh api repos/bldgtyp/ph-composer/private-vulnerability-reporting` answered
`{"enabled":false}` on 2026-10-21 (F06).

## Not reviewed, or reviewed by sweep only

- Feature domain modules under `features/` other than the export, source report, export assessment
  and library import files: geometry, placement, adjacency, spaces reconciliation, colour modes,
  menus and tools. They were covered by the Ruby sweeps above (no file IO except a cursor and a
  basename, no dangerous API) and not read line by line.
- `colour_by/` entirely, and `session/{host_observers,edit_context,deferred_work,container_watch,timer}.rb`:
  host behaviour, no trust boundary.
- `core/records/{engine,entity_store,catalog,change_set,descriptor,fields,identity,projected_engine,
  reference_resolution,reference_target,record_kind,authoring_fields}.rb` and `core/operations/*`:
  read only where a section cites them.
- `shell/{registry,registry_validation,refusals,outcome,pages (after line 60),panel_diagnostics,
  panel_history,panel_presence,panel_requests,participant_invocation,host_follow_up}.rb`: skimmed.
- Panel feature JavaScript under `html/features/`, `html/library/` and the shared widgets beyond
  the files listed: covered by the sink sweeps only.
- Python geometry and thermal sections, as section 08 says.
- `tests/`, `tools/ui-preview/`, `tools/examples/`, `tools/spikes/`, `tools/hostkit/*.py` beyond the
  probe's token handling, `docs/` beyond the privacy and agent access claims.
- No host run, no network capture, no fuzzing. Nothing was executed against SketchUp.

## Limits of a reading review

The CEF version SketchUp 2023 embeds, and whether its `file://` HtmlDialog pages enforce the same
`sandbox` and origin rules as current Chromium, were not measured. The Windows preferences store and
its permissions were not checked. Both belong to the platform gates already tracked in
`planning/STATUS.md`.
