# Licensing

**DATE:** 2026-09-18

PassiveBuilder is copyright BLDGTYP, LLC and its contributors and is released under the GNU
Affero General Public License, version 3 or later (`AGPL-3.0-or-later`). The full text is in
[`LICENSE`](../LICENSE). The license applies to the extension code and product documentation in
this repository.

PassiveBuilder is a foundation, like OpenPH. It is not a revenue generator and BLDGTYP sells no
commercial license for it. Products such as PassivSure or PH-Navigator may connect to it and build
on it under the terms below.

## Why AGPL

Export runs honeybee, ladybug and PHX inside SketchUp through a Pyodide payload. The predecessor
shipped Pyodide under MPL-2.0 and CPython under PSF-2.0, with wheels declaring AGPL-3.0 for
honeybee-core, honeybee-energy, ladybug-core, ladybug-geometry and ladybug-geometry-polyskel,
GPL-3.0-or-later for honeybee-ph, and GPL-3.0 for honeybee-standards. PHX is GPL-3.0-or-later.
Shipping that payload is conveying, and AGPL-3.0-or-later is the license that matches it.

The ph-units wheel declared no license metadata in the predecessor's manifest. ph-units is a
PH-Tools package, so the fix is a classifier in that repository.

Exact versions, source URLs, hashes and declared licenses will live in the runtime manifest once
the payload is assembled.

## What it means in practice

- **Install and use freely.** Core authoring and export require no account or subscription.
- **Modify and redistribute: keep it open.** A modified build handed to other people, or run for
  them over a network, must come with its source under the same license.
- **Connecting is free.** A product that reads PassiveBuilder's HBJSON or METr output, or serves
  it a library through the provider contract over HTTPS, is a separate program. AGPL places no
  obligation on it.
- **Building in is copyleft.** A product that ships PassiveBuilder's Ruby, JavaScript or Python
  inside itself, or links to it in one process, is a derivative work and must itself be AGPL. A
  team that wants the UI kit inside a closed product cannot have it under this license.
- **Licensed documents.** No PHPP workbooks, designPH files, or PHI- or Phius-derived data enter
  this repository. Use synthetic fixtures and the private corpus conventions in `AGENTS.md`.

## The UI kit and the open question

The panel JavaScript and CSS carry no honeybee dependency. Under AGPL they are reusable with
source, which serves an open sibling such as an AGPL PassivSure build. If the goal is instead
that closed or differently licensed products embed the kit, the kit needs a permissive or weak
copyleft license of its own (MIT, MPL-2.0 or LGPL) and a package boundary that keeps it free of
the AGPL stack. That is a decision for Ed, and it only stays available while the kit imports
nothing from honeybee, ladybug or PHX. It is recorded in the founding brief as open.

## Library providers and the open question

A library file is data. A vendor or a firm that publishes one, or runs a server that answers the
connection protocol, writes no PassiveBuilder code and the license does not reach them. A firm's
intranet or company library is an intended use.

A provider written as a SketchUp extension that registers with PassiveBuilder is code loaded into
an AGPL host. Whether a closed-source provider of that kind is compatible with the license is an
open question for Ed, recorded beside the UI kit question above. The file format and the
connection protocol exist so that almost no provider needs to be code.

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
the one addition to the standard DCO text, stated in the pull request template rather than in
the certificate.

Nothing here is legal advice. The license choice and the DCO process have not been reviewed by
counsel.
