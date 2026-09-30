# Licensing

**DATE:** 2026-09-29

PH-Composer is copyright BLDGTYP, LLC and its contributors and is released under the GNU
Affero General Public License, version 3 or later (`AGPL-3.0-or-later`). The full text is in
[`LICENSE`](../LICENSE). The license applies to the extension code and product documentation in
this repository.

PH-Composer is a foundation, like OpenPH. It is not a revenue generator and BLDGTYP sells no
commercial license for it. Products such as PassivSure or PH-Navigator may connect to it and build
on it under the terms below.

## Why AGPL

Export runs honeybee and ladybug inside SketchUp through a Pyodide payload, and the planned METr
exporter adds PHX to it. The predecessor
shipped Pyodide under MPL-2.0 and CPython under PSF-2.0, with wheels declaring AGPL-3.0 for
honeybee-core, honeybee-energy, ladybug-core, ladybug-geometry and ladybug-geometry-polyskel,
GPL-3.0-or-later for honeybee-ph, and GPL-3.0 for honeybee-standards. PHX is GPL-3.0-or-later.
Shipping that payload is conveying, and AGPL-3.0-or-later is the license that matches it.

The predecessor's manifest recorded no license for the ph-units wheel. The wheel does declare
`GPL-3.0-or-later`, in its `License-Expression` field, which that manifest's reader did not read.

Exact versions, source URLs, hashes and declared licenses live in the runtime manifest,
`src/ph_composer/vendor/manifest.json`, and the shipped notice,
`src/ph_composer/vendor/THIRD_PARTY_NOTICES.md`. The current build ships the Pyodide 0.24.1 core,
which embeds CPython 3.11.3, and eight pinned pure-Python translation wheels. Full upstream
license texts travel with the build. Pyodide's pinned `LICENSE` says MPL-2.0 while its
`src/js/package.json` says Apache-2.0. honeybee-standards 2.0.7 declares GPL-3.0 in its
metadata classifier and carries an MIT license file. The shipped notice preserves both
discrepancies and links the exact sources. Public distribution remains a separate gate.

## What it means in practice

- **Install and use freely.** Core authoring and export require no account or subscription.
- **Modify and redistribute: keep it open.** A modified build handed to other people, or run for
  them over a network, must come with its source under the same license.
- **Connecting is free.** A product that reads PH-Composer's HBJSON or METr output, or serves
  it a library through the provider contract over HTTPS, is a separate program. AGPL places no
  obligation on it.
- **Building in is copyleft.** A product that ships PH-Composer's Ruby, JavaScript or Python
  inside itself, or links to it in one process, is a derivative work and must itself be AGPL. A
  team that wants the UI kit inside a closed product cannot have it under this license.
- **Licensed documents.** No PHPP workbooks, designPH files, or PHI- or Phius-derived data enter
  this repository. Use synthetic fixtures and the private corpus conventions in `AGENTS.md`.

## The UI kit

The panel JavaScript and CSS carry no honeybee dependency, but D5 confirms that the UI kit remains
AGPL for the MVP. It is reusable with source, including by an open sibling. Closed or differently
licensed products do not embed it. If a real adopter later needs that use, reconsider a separate
permissive or weak-copyleft package with a boundary free of the AGPL stack; do not pre-build that
boundary now.

## Library providers

A library file is data. A vendor or a firm that publishes one, or runs a server that answers the
connection protocol, writes no PH-Composer code and the license does not reach them. A firm's
intranet or company library is an intended use.

A provider written as a SketchUp extension that registers in-process with PH-Composer is code
loaded into the AGPL host and closed-source in-process providers are not an MVP requirement.
Closed systems use the library file or HTTPS connection protocol. Almost no provider should need
to be code.

## Icons

The drawing toolbar glyphs are adapted from [Lucide](https://lucide.dev) under the ISC License,
Copyright (c) 2026 Lucide Icons and Contributors. The notice travels with the glyphs.

## Contributions

Decided 2026-09-18: no dual licensing, no Contributor License Agreement. Contributors keep their
copyright and license their work under the repository license by signing off each commit under
the [Developer Certificate of Origin](https://developercertificate.org) (`git commit -s`). A pull
request whose commits lack a sign-off is not merged. The DCO text ships in this repository as
[`DCO.md`](DCO.md).

A contributor also certifies that the contribution contains no data derived from PHI, Phius, PHPP,
WUFI-Passive, METr or any other licensed source they are not entitled to redistribute. That is
the one addition to the standard DCO text. It belongs in the pull request template rather than in
the certificate; that template is not in the repository yet.

Nothing here is legal advice. The license choice and the DCO process have not been reviewed by
counsel.
