# 02 Runtime: the Pyodide asset server and the runtime page

Files: `src/ph_composer/runtime/{asset_server,http,runtime_host,runtime_gate,runtime_manifest}.rb`,
`html/runtime/{index.html,runtime.js}`, `vendor/manifest.json`.

## What runs and when

Nothing listens until an export task (or the development probe) builds a `RuntimeHost`. It starts an
`AssetServer` on `127.0.0.1` port 0, opens an HtmlDialog at
`http://127.0.0.1:<port>/<token>/html/runtime/index.html?session=<id>`, and stops both when the task
finishes or the dialog closes. The server exists for the length of one export.

## Path handling

`parse` splits the request line, strips the query, requires the `/<token>/` prefix, percent-decodes
the remainder and looks it up as an exact key in the manifest's asset table. A key that is not
declared is a 404. There is no filesystem lookup by request path: `File.join(@root, relative)` runs
only after the key matched, and `RuntimeManifest.validate_entry` has already refused any declared
path whose expanded form leaves the extension folder. Traversal has no route.

The token is 128 bits from `SecureRandom.hex(16)`, generated per server. A wrong token answers
`403` before any asset lookup.

## Integrity

Every asset's size and SHA-256 are checked against the manifest when the server is constructed;
`RuntimeHost#start` refuses to open the page if any differs. On each read the size is checked again
(the hash is not recomputed per request; a replaced file of equal size after construction would
serve). That window is the length of one export on the user's own disk, and the user's own
permissions are needed to write there. Not a finding.

## Headers

Every response carries `Cross-Origin-Opener-Policy: same-origin`,
`Cross-Origin-Embedder-Policy: require-corp`, `Cross-Origin-Resource-Policy: same-origin`,
`X-Content-Type-Options: nosniff`, `Cache-Control: no-store` and `Connection: close`. No CORS
header is sent, so a page on any other origin cannot read a response even with the token. MIME types
come from the manifest, which the vendoring tool assigns by extension.

## The runtime page

`runtime.js` fetches only `vendor/manifest.json`, `vendor/pyodide/pyodide.js`, the translation
modules the manifest lists and the wheels it lists, all relative to its own origin. It writes the
modules into Pyodide's in-memory filesystem and runs two fixed Python strings; the document to
translate is passed as a JSON string through `pyodide.globals.set`, never interpolated into code.
It reports back only through `sketchup.ph_composer_runtime` with a session id the host checks.

`RuntimeHost#receive` accepts three message types, requires an object payload and a matching session
id, and logs anything else by exception class. `deliver_to` builds its script with `JSON.generate`
into a fixed call.

The page is loaded from an `http://127.0.0.1` origin so Pyodide's isolation headers apply. It has no
CSP (F08). The `<link rel="icon" href="data:,">` avoids a `/favicon.ico` request outside the token
path.

## Development probe

`tools/hostkit/runtime_probe.rb` is loaded by hand through the bridge and never ships.
