# 07 Panel JavaScript: DOM sinks and the host bridge

Files: `src/ph_composer/html/**/*.js`, `html/*.html`, `help/index.html`.

## DOM sinks

A sweep for `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write`, `eval`,
`new Function`, string `setTimeout`, `srcdoc` and `javascript:` found:

- `icons.js:89, 101`, `table.js:30, 333`, `features/assemblies/stage.js:56`: `innerHTML` set to
  SVG strings from the icon table, constants in the shipped file. No data path.
- `sections/export.js:195`: `frame.srcdoc = html` for the blocked-run report, with
  `sandbox=""` set first. Scripts and same-origin access are off inside it.

Every other value from a snapshot, a result or a notice reaches the DOM through `dom.element`'s
`textContent`, `setAttribute` (tooltips, aria labels), or a form field's `value`. The Agent Access
page shows the token and the client forms in read-only `input` and `textarea` values and clears both
when the dialog closes.

Style sinks: `inventory_forms.js:152, 342` and `column_menu.js:72` assign a colour string to
`style.backgroundColor`; `face_words.js:44` and `record_edits.js:79` set a CSS custom property. A CSS
property assignment is not a script sink. Material `color` is unvalidated on the Ruby side (F03);
Zone option colours have a schema pattern.

## Network and navigation

No `fetch`, `XMLHttpRequest`, `WebSocket`, `sendBeacon`, `location` assignment, `window.open`, or
`href` assignment in the panel, dialog or support pages. The runtime page fetches only from its own
loopback origin. The help page has two `https://` links to GitHub and SketchUp's help, opened by the
user. No page carries a CSP meta (F08).

## The bridge

Four callbacks exist: `ph_composer_message` (panel), `ph_composer_agent_access`,
`ph_composer_support` and `ph_composer_runtime`. Each page calls only its own, each message is
`JSON.stringify({type, payload})`, and the Ruby side parses with declared types and keys. The page
never receives a path, token digest or approved location path; the host sends the panel file names
and edit-path names only.

## Module loading

`module.js` is a registry; `index.html`'s script list is generated from the declarations and checked
by `make panel-manifest-check`, so a stray script tag fails the gate. Nothing loads cross-origin.

## Diagnostics from the page

`panel.js` reports failures as `event`, `section`, `error_class` and `frames`; `errorClass` names only
the language's own error types and `stackFrames` keeps frames under `html/` only. Ruby's
`Diagnostics.accepted` filters them again. A page cannot write free text into the log.
