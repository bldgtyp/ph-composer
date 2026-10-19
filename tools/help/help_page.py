# /// script
# requires-python = ">=3.11"
# ///
"""Write the shipped offline help page from docs/HELP.md, or check that it is current.

docs/HELP.md is the one source. The extension ships `ph_composer/help/index.html`, which Help &
Diagnostics opens with no internet connection. This converts the small Markdown subset that file uses:
headings, paragraphs, bullet and numbered lists, inline code and bare https links.
"""

from __future__ import annotations

import argparse
import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "docs" / "HELP.md"
TARGET = ROOT / "src" / "ph_composer" / "help" / "index.html"
LINK = re.compile(r"https://[^\s)]+[^\s).,]")
CODE = re.compile(r"`([^`]+)`")

PAGE = """<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>PH-Composer help</title>
    <!-- Generated from docs/HELP.md by tools/help/help_page.py; edit that file instead. -->
    <style>
      body {{ max-width: 720px; margin: 0 auto; padding: 24px 20px 48px; color: #1e2931;
        font: 14px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }}
      h1 {{ font-size: 22px; }} h2 {{ margin-top: 28px; font-size: 16px; }}
      code {{ font-family: ui-monospace, Menlo, monospace; font-size: 12px; }}
      a {{ color: #0f5c66; overflow-wrap: anywhere; }}
    </style>
  </head>
  <body>
{body}
  </body>
</html>
"""


def inline(text: str) -> str:
    """Escapes text, then marks code spans and links; a link inside a code span is left as text."""
    parts = CODE.split(text)
    out = []
    for index, part in enumerate(parts):
        if index % 2:
            out.append(f"<code>{html.escape(part)}</code>")
        else:
            escaped = html.escape(part, quote=False)
            out.append(LINK.sub(lambda match: f'<a href="{match.group(0)}">{match.group(0)}</a>', escaped))
    return "".join(out)


def render(markdown: str) -> str:
    blocks: list[str] = []
    paragraph: list[str] = []
    items: list[str] = []
    kind = ""

    def flush() -> None:
        nonlocal kind
        if paragraph:
            blocks.append(f"<p>{inline(' '.join(paragraph))}</p>")
            paragraph.clear()
        if items:
            rows = "".join(f"<li>{inline(item)}</li>" for item in items)
            blocks.append(f"<{kind}>{rows}</{kind}>")
            items.clear()

    for line in markdown.splitlines():
        stripped = line.strip()
        bullet = re.match(r"^(-|\d+\.) (.*)$", stripped)
        if not stripped:
            flush()
        elif stripped.startswith("#"):
            flush()
            level = len(stripped) - len(stripped.lstrip("#"))
            blocks.append(f"<h{level}>{inline(stripped[level:].strip())}</h{level}>")
        elif bullet and not paragraph:
            if items and kind != ("ul" if bullet.group(1) == "-" else "ol"):
                flush()
            kind = "ul" if bullet.group(1) == "-" else "ol"
            items.append(bullet.group(2))
        elif items and line.startswith("  "):
            items[-1] += " " + stripped
        else:
            if items:
                flush()
            paragraph.append(stripped)
    flush()
    return PAGE.format(body="\n".join(f"    {block}" for block in blocks))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    page = render(SOURCE.read_text(encoding="utf-8"))
    if args.check:
        if not TARGET.exists() or TARGET.read_text(encoding="utf-8") != page:
            print("help page is stale; run make help", file=sys.stderr)
            return 1
        print("Help page up to date")
        return 0
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text(page, encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
