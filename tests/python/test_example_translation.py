"""The example feature end to end on the Python side: the extraction its Ruby contributors build
(tests/fixtures/foundation/extraction.json, which tests/export_test.rb also checks) translates to the
result document the Ruby report is checked against (result.json). Both fixtures are hand-reviewed
contract examples, not generated goldens."""

from __future__ import annotations

import copy
import json
from pathlib import Path
from typing import Any

from example_translation import SECTIONS, Part
from ph_composer_translation.coordinator import translate

FIXTURES = Path(__file__).resolve().parents[1] / "fixtures" / "foundation"


def load(name: str) -> Any:
    return json.loads((FIXTURES / name).read_text())


def test_the_example_extraction_translates_to_the_shared_result() -> None:
    translation = translate(load("extraction.json"), SECTIONS)

    assert translation.to_document() == load("result.json")
    part = translation.objects("example.foundation.export.parts")["exp_000000000002"]
    assert isinstance(part, Part) and part.checked and part.definition.label == "Frame"


def test_a_part_with_an_unknown_review_status_costs_that_part() -> None:
    extraction = copy.deepcopy(load("extraction.json"))
    extraction["sections"]["example.foundation.export.parts"]["records"][0]["extensions"] = {
        "example.foundation.review": {"review_status": "maybe"}
    }

    result = translate(extraction, SECTIONS).to_document()

    assert result["findings"] == [
        {
            "code": "object.unavailable",
            "section": "example.foundation.export.parts",
            "object_id": "exp_000000000002",
            "message": "review_status must be draft or checked",
            "blocks_export": True,
        }
    ]
    parts = result["example.foundation.export.parts"]
    assert isinstance(parts, dict) and parts["example_parts"] == {"count": 1, "total_length_mm": 1231.9}
