# PassiveBuilder

A free, open-source Passive House authoring environment that runs inside SketchUp, for Phius
passive building projects.

You define the building while you work on its geometry. Envelope faces, assemblies, materials,
windows, thermal bridges and spaces all live in the SKP file. The extension exports HBJSON and,
from that, the model METr reads.

**Status: founding.** There is no code in this repository yet. The founding brief, the product
documents and the engineering authorities are written; the foundation transplants from
[PH-Navigator for SketchUp](https://github.com/bldgtyp/ph-navigator-sketchup) next.

## What it will do

- **Envelope.** Classify faces by type and boundary condition and assign assemblies, with
  assignments stable through Undo, save and nested components.
- **Assemblies.** Build layered opaque assemblies in a graphical editor that reports U-value as you
  work, in SI or IP.
- **Windows.** Define Window Types from frame segments, glazings and Psi-Install Types, and place
  them on walls.
- **Thermal bridges.** Identify junctions on the model and assign psi-values.
- **Spaces.** Author the Space hierarchy and iCFA floors against the model geometry.
- **Libraries.** Optional. Point the sidebar at a folder of files, a firm server or a vendor
  catalog and copy definitions into the model, where you can edit the local copy.
- **Export.** Write HBJSON through honeybee-ph, and the METr model through PHX, both running in a
  Pyodide payload the extension ships. Anything the export cannot represent is reported.

No account, subscription, hosted project or database is needed.

## For contributors

The project is built to be extended. Four seams need no change to the core: a feature folder, a
library provider, an exporter, a Colour-by mode. Start with [planning/FOUNDING_BRIEF.md](planning/FOUNDING_BRIEF.md), then
[docs/](docs/.index.md) for the product and [context/](context/.index.md) for the engineering
rules. Point a coding agent at [AGENTS.md](AGENTS.md).

Contributions are welcome once the foundation lands. There is no CLA: sign off each commit under
the [Developer Certificate of Origin](docs/DCO.md). [docs/LICENSING.md](docs/LICENSING.md) explains
what AGPL means for products that connect to or build on PassiveBuilder.

## License

AGPL-3.0-or-later. The full text is in [LICENSE](LICENSE).

Started by [BLDGTYP, LLC](https://www.bldgtyp.com), a Passive House consultancy in Brooklyn, NY.
