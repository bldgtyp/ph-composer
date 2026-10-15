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


# The example's face-review section joins the shipping sections: the claimed Face payload reaches the
# canonical HBJSON on its own Face and survives Honeybee's reload.
PHASE_ONE = Path(__file__).resolve().parents[1] / "fixtures" / "phase_one" / "two_zones_extraction.json"
REVIEWS = "example.foundation.export.face_reviews"


def reviewed(records: list[dict[str, Any]]) -> dict[str, Any]:
    document = json.loads(PHASE_ONE.read_text())
    document["sections"][REVIEWS] = {"version": 1, "records": records}
    document["sections"]["example.foundation.export.definitions"] = {"version": 1, "records": []}
    document["sections"]["example.foundation.export.parts"] = {"version": 1, "records": []}
    for section in ("ph_composer.windows.export.window_constructions", "ph_composer.windows.export.apertures"):
        document["sections"][section] = {"version": 1, "records": []}
    return document


def exported(document: dict[str, Any]) -> dict[str, Any]:
    from ph_composer_translation.composition import SECTIONS as SHIPPING
    from ph_composer_translation.entry import export_json

    return json.loads(export_json(json.dumps(document), (*SHIPPING, *SECTIONS)))


def test_a_claimed_face_review_reaches_its_face_in_the_canonical_hbjson_and_reloads() -> None:
    from ph_composer_translation import stack

    output = exported(reviewed([{"id": "fac_A00000000001", "review_status": "checked"}]))

    assert output["summary"]["publishable"], output["findings"]
    model = stack.load("honeybee.model").Model.from_dict(json.loads(output["canonical_model"]["hbjson"]))
    faces = {face.identifier: face for room in model.rooms for face in room.faces}
    assert faces["fac_A00000000001"].user_data == {"example": {"foundation": {"face_review": "checked"}}}
    assert all(not (face.user_data or {}).get("example") for key, face in faces.items() if key != "fac_A00000000001")
    assert all(room.user_data["ph_composer"] for room in model.rooms)


def test_a_face_review_missing_its_required_field_refuses_the_export() -> None:
    output = exported(reviewed([{"id": "fac_A00000000001"}]))

    assert not output["summary"]["publishable"]
    assert any(row["section"] == REVIEWS and row["blocks_export"] for row in output["findings"])
