"""Render two review reading aids with Pillow; Mermaid in ARCHITECTURE.md holds detailed flows.

Run with the bundled workspace Python, which supplies Pillow. No network or host automation.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent.parent / "diagrams"
FONT = Path("/System/Library/Fonts/Supplemental/Arial.ttf")
BOLD = Path("/System/Library/Fonts/Supplemental/Arial Bold.ttf")
INK = "#203443"
MUTED = "#586B77"
TEAL = "#177A79"
BG = "#F7F9FA"


@dataclass(frozen=True)
class Box:
    x: int
    y: int
    w: int
    h: int
    title: str
    detail: str = ""
    fill: str = "#FFFFFF"

    @property
    def center(self) -> tuple[int, int]:
        return self.x + self.w // 2, self.y + self.h // 2


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(BOLD if bold else FONT), size)


def canvas(title: str, subtitle: str) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    picture = Image.new("RGB", (1800, 1100), BG)
    draw = ImageDraw.Draw(picture)
    draw.text((80, 45), title, font=font(42, True), fill=INK)
    draw.text((80, 105), subtitle, font=font(24), fill=MUTED)
    draw.line((80, 155, 1720, 155), fill="#D5DFE4", width=2)
    return picture, draw


def box(draw: ImageDraw.ImageDraw, value: Box) -> None:
    draw.rounded_rectangle((value.x, value.y, value.x + value.w, value.y + value.h), radius=16,
                           fill=value.fill, outline="#8AA5AF", width=2)
    draw.text((value.x + 22, value.y + 19), value.title, font=font(28, True), fill=INK)
    draw.multiline_text((value.x + 22, value.y + 61), value.detail, font=font(23), fill=MUTED, spacing=8)


def arrow(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], label: str = "",
          at: tuple[int, int] | None = None, color: str = TEAL) -> None:
    draw.line(points, fill=color, width=4, joint="curve")
    end = points[-1]
    prev = points[-2]
    if end[0] > prev[0]:
        wings = [(end[0] - 13, end[1] - 8), end, (end[0] - 13, end[1] + 8)]
    elif end[0] < prev[0]:
        wings = [(end[0] + 13, end[1] - 8), end, (end[0] + 13, end[1] + 8)]
    elif end[1] > prev[1]:
        wings = [(end[0] - 8, end[1] - 13), end, (end[0] + 8, end[1] - 13)]
    else:
        wings = [(end[0] - 8, end[1] + 13), end, (end[0] + 8, end[1] + 13)]
    draw.line(wings, fill=color, width=4)
    if label and at:
        bounds = draw.textbbox(at, label, font=font(22))
        draw.rectangle((bounds[0] - 7, bounds[1] - 5, bounds[2] + 7, bounds[3] + 5), fill=BG)
        draw.text(at, label, font=font(22), fill=color)


def dependency_map() -> None:
    picture, draw = canvas("PH-Composer: current Ruby dependencies",
                           "Arrows mean calls / depends on. Boxes are responsibilities, not separate packages.")
    root = Box(640, 200, 520, 120, "Composition root", "extension.rb lists concrete features")
    assemblies = Box(140, 415, 420, 150, "Assemblies", "Materials and Assemblies\nPortable definition rules", "#E9F4F0")
    zones = Box(690, 415, 420, 150, "Zones", "Zones, Faces and adjacency\nRequires Assemblies", "#E9F4F0")
    windows = Box(1240, 415, 420, 150, "Windows", "Products, Types and Units\nRequires Zones and Library", "#E9F4F0")
    foundation = Box(220, 660, 1360, 120, "Shared application foundation",
                     "Registration  /  public operations  /  proposals  /  record engine  /  sessions")
    pure = Box(220, 885, 610, 120, "Pure common values and rules", "JSON, schema, identity, references, vectors")
    host = Box(970, 885, 610, 120, "Common native adapters", "Dictionaries, capture, scopes, SketchUp IO")
    for feature in (assemblies, zones, windows):
        arrow(draw, [(900, 320), (900, 360), (feature.center[0], 360), (feature.center[0], 415)])
        arrow(draw, [(feature.center[0], 565), (feature.center[0], 660)])
    arrow(draw, [(690, 470), (560, 470)], "reads", (585, 435))
    arrow(draw, [(1240, 470), (1110, 470)], "hosts", (1130, 435))
    arrow(draw, [(525, 780), (525, 885)])
    arrow(draw, [(1275, 780), (1275, 885)])
    for value in (root, assemblies, zones, windows, foundation, pure, host):
        box(draw, value)
    draw.text((590, 810), "core/ mixes pure values and native adapters.", font=font(23), fill=MUTED)
    draw.text((80, 1040), "Layering exception: Windows definition CRUD calls placed-Unit repair internals (RF-02).",
              font=font(24, True), fill="#A15E32")
    picture.save(OUT / "ruby-dependencies.png")


def data_flow() -> None:
    picture, draw = canvas("PH-Composer: authoring and export data flow",
                           "Arrows show information flow. Ruby owns business rules; the SKP owns working data.")
    client = Box(80, 240, 460, 155, "Clients", "JavaScript panel / native tools\nRuby scripts / company automation", "#E9F4F0")
    dispatch = Box(670, 240, 460, 155, "Public operations", "Session + capability + revision\nValidate named action and proposal")
    skp = Box(1260, 240, 460, 155, "SketchUp Model / SKP", "Apply one guarded Undo operation\nDefinitions + entity dictionaries", "#E9F4F0")
    snapshot = Box(670, 520, 460, 150, "Authoritative reads", "Query-backed snapshot + outcome\nDetached values, SI, explicit references")
    extraction = Box(1260, 520, 460, 150, "Ruby export contributors", "Coherent geometry / record snapshot\nVersioned JSON sections")
    translation = Box(1260, 820, 460, 150, "Python in Pyodide", "Typed sections and attachments\nCanonical HBJSON + findings")
    artifacts = Box(670, 820, 460, 150, "Guarded output files", "Privacy + conformance + report\nReplace HBJSON / report pair together")
    library = Box(80, 820, 460, 150, "Optional library provider", "Detached catalog definitions\nCopy through owner operations")
    arrow(draw, [(540, 300), (670, 300)], "invoke", (560, 263))
    arrow(draw, [(1130, 300), (1260, 300)], "apply", (1155, 263))
    arrow(draw, [(1490, 395), (1490, 520)], "read", (1500, 438))
    arrow(draw, [(1260, 315), (1185, 315), (1185, 595), (1130, 595)], "queries", (1175, 438))
    arrow(draw, [(670, 595), (310, 595), (310, 395)], "snapshot + correlated result", (130, 535))
    arrow(draw, [(1490, 670), (1490, 820)], "translate", (1500, 715))
    arrow(draw, [(1260, 895), (1130, 895)], "result", (1150, 853))
    arrow(draw, [(540, 895), (590, 895), (590, 440), (850, 440), (850, 395)],
          "copy via owner operations", (590, 710))
    for value in (client, dispatch, skp, snapshot, extraction, translation, artifacts, library):
        box(draw, value)
    draw.text((80, 1040), "Exporters are a later consumer of HBJSON; no production exporter is registered yet.",
              font=font(24), fill=MUTED)
    picture.save(OUT / "data-flow.png")


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    dependency_map()
    data_flow()
    print("Rendered two architecture reading aids.")
