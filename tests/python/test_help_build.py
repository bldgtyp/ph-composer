"""The shipped offline help page is generated from docs/HELP.md; this checks the Markdown it converts."""

from __future__ import annotations

import help_page


def test_headings_lists_code_and_links_convert_and_text_is_escaped() -> None:
    page = help_page.render("# Help\n\nUse `a<b` at https://example.com/x.\n\n- one\n  continued\n- two\n\n1. first\n")

    assert "<h1>Help</h1>" in page
    assert '<p>Use <code>a&lt;b</code> at <a href="https://example.com/x">https://example.com/x</a>.</p>' in page
    assert "<ul><li>one continued</li><li>two</li></ul>" in page
    assert "<ol><li>first</li></ol>" in page
