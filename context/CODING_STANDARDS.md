# Coding standards: PassiveBuilder

**DATE:** 2026-09-18

This file holds what is specific to this repository. Cross-repo rules live in the shared skills.
Rules about the product and its language live in `../docs/` and this folder, chiefly
[UBIQUITOUS_LANGUAGE.md](UBIQUITOUS_LANGUAGE.md), which governs names in code as well as in copy.
Read [TECH_STACK.md](TECH_STACK.md) before work that touches observers, transactions, the pinned
runtime or the real-host loop.

The lint rule sets that will enforce part of this are `.rubocop.yml`, `eslint.config.mjs` and
`[tool.ruff.lint]` in `pyproject.toml`, carried over with the tooling transplant. Everything below
that a linter cannot express is here because a reader has to apply it.

## Layering

Four layers, one dependency direction. The founding brief names them; this is what each may do.

- **JavaScript is the interface and UI layer.** The panel derives, formats and routes. It does not
  calculate domain values. A number the user reads as a Passive House quantity was computed in
  Ruby, travelled through the message contract, and the panel chose how to show it. This decides
  where a new calculation goes before the question of which file is more convenient. The UI kit
  depends on the request channel contract and nothing else, so it carries no honeybee dependency.
- **Ruby is the Model layer and the business logic.** Attribute dictionaries, the record engine,
  sessions, transactions, Undo, observers and every domain calculation the panel shows.
- **The Python translation package owns only the HBJSON translation.** It reads the export
  contract and writes honeybee objects. It does not read the Model.
- **Exporters consume HBJSON.** The METr exporter reads the HBJSON artifact and runs PHX. An
  exporter never reads the export contract or the Model, so a second exporter needs nothing from
  the layers above it.

## Ruby

- **The support floor is Ruby 2.7.** SketchUp 2023 embeds it. `Struct.new(keyword_init: true)` is
  available; pattern matching, endless methods, `Hash#except` and `Data` are not. The offline suite
  runs on 2.7.2 and 3.2.2, and a loop on one of them proves nothing about the other.
- **`fetch` for a required key, `dig` for an optional path.** `[]` on a shape the code requires
  turns a missing key into a `nil` that surfaces three frames away. One reader for a path every
  caller walks, `fetch` at each step, because a row missing any of them is unreadable and the
  readability check has already refused it. Where a shape carries rules, a small typed value reads
  it once inside the feature; the hash stays the contract at the persistence and panel edges.
- **Sequenced statements do not share a line.** `Style/Semicolon` enforces it. The one shape it
  allows is a whole method on one line for pure delegation: `def space?(entity); Scan.space?(entity); end`.
  A body that does anything gets its own lines.
- **Errors carry their taxonomy**, defined in `core/errors.rb`: `UserError` for a message the
  panel may show verbatim, `CodedError` when the panel has to key behaviour on a stable code and
  read structured `detail`, and `InternalError` for what belongs in the log. Never raise a bare
  `Error` at a user-facing edge.
- **A refusal that wrote nothing says so**, with the sentence ending `Nothing was written.` The
  user's next question is always whether the Model changed.
- **Value objects at module boundaries.** A module that hands another module a bare Hash hands it
  a shape nothing declares. `core/records/schema.rb`'s `RecordSchema` is the pattern.

## JavaScript

- **The floor is Chromium 88**, the HtmlDialog engine in SketchUp 2023, so `ecmaVersion: 2020`.
  The panel files are scripts loaded by the dialog, not modules. The whole floor lives in
  `eslint.config.mjs`: the parser refuses newer syntax, `no-undef` against the declared globals
  refuses a newer global, and the `AFTER_CHROMIUM_88_*` lists refuse a method that arrived after
  88 on a type the parser already knew. Adding a name to either list is a floor decision.
- **ES2020 is the level; a file is one era.** `const`, arrows and template literals are legal.
  Files transplanted from the predecessor are ES5 and may stay so. A file that mixes the two is
  not acceptable: a reader should be able to tell a file's era from its first screen.
- **`Array.prototype.forEach.call` over `NodeList.forEach`.** The panel's own collections are not
  all real `NodeList`s, and the borrowed call works on both.
- **Sequenced statements do not share a line.** eslint cannot express this. A one-line function
  expression is fine. `a(); b();` is not.
- **Panel files are found by glob, never by a list.** A file left off a list is a file that
  nothing verifies.

## Python

- Fully typed, `from __future__ import annotations`, dataclasses at the seams.
  `disallow_untyped_defs` covers the translation package, the exporters and their tests.
- honeybee, ladybug and PHX are imported only through one module each, on first use and in the
  runtime's load order, so every other module of the package imports without the stack.
- The tool scripts under `tools/` are `uv run` entry points with a PEP 723 block each.

## Comments

A comment states the rule and cites the evidence that fixed it. It never cites the phase that
happened to discover it. "Phase 3b found this" tells a later reader nothing they can check; a
path into `context/`, `planning/` or the predecessor's archive does. A comment that only restates
the line below it is noise, and a comment carrying a measured host fact is the most valuable
thing in the file.

## Tests

- **One focused test per stated behaviour**, sized like its neighbours, named for what it proves.
- **Assert behaviour directly.** A golden file is for a registry or a contract shape, where the
  whole shape must be stable and a reviewer wants to read the diff. Exactly one test owns each
  golden.
- **A stub that deviates from the host says so in a comment and cites the host evidence.** The
  SketchUp API stub and the DOM stub are deliberate approximations, and the places they diverge are
  where an offline pass can hide a host failure.
- **The offline suite has no dependencies.** `make test` runs on a checkout with no bundler and no
  `node_modules`. Lint tooling is separate and skips when absent.

## Line and size limits

The predecessor carried two burn-down registers for files that exceeded its limits before the
limits existed. This repository starts without them. The ceiling is 120 characters a line and the
default rubocop method and class lengths, for every file from the first commit, transplanted files
included. A transplanted file that does not meet the ceiling is reformatted as it lands.
