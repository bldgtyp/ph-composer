"""An outside section attaches a sub-face to a Face it does not own, through the attachment contract alone:
the product composition plus the example's section, and no edit to the Zones sections or the assembly."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, cast

from example_doors import ID, Doors
from ph_composer_translation import stack
from ph_composer_translation.composition import SECTIONS
from ph_composer_translation.coordinator import translate

FIXTURE = Path(__file__).resolve().parents[1] / "fixtures" / "phase_one" / "two_zones_extraction.json"
WALL = "fac_A00000000003"


def extraction(*doors: dict[str, Any]) -> dict[str, Any]:
    value: dict[str, Any] = json.loads(FIXTURE.read_text())
    value["sections"].update(
        {
            "ph_composer.windows.export.window_constructions": {"version": 1, "records": []},
            "ph_composer.windows.export.apertures": {"version": 1, "records": []},
            ID: {"version": 1, "records": list(doors)},
        }
    )
    return value


def door(host: str = WALL) -> dict[str, Any]:
    return {"id": "door_1", "host_face_id": host, "polygon_m": [[0, 1, 0.1], [0, 1, 2], [0, 2, 2], [0, 2, 0.1]]}


def test_a_door_section_attaches_to_its_host_face_in_the_canonical_model() -> None:
    result = cast(dict[str, Any], translate(extraction(door()), (*SECTIONS, Doors())).to_document())

    assert result["summary"]["publishable"] is True
    model = stack.load("honeybee.model").Model.from_dict(json.loads(result["canonical_model"]["hbjson"]))
    hosts = [face for room in model.rooms for face in room.faces if face.doors]
    assert [(face.identifier, [item.identifier for item in face.doors]) for face in hosts] == [(WALL, ["door_1"])]


def test_a_door_whose_host_face_was_not_emitted_is_a_blocking_finding() -> None:
    result = cast(dict[str, Any], translate(extraction(door("fac_Missing00001")), (*SECTIONS, Doors())).to_document())

    assert result["summary"]["publishable"] is False
    assert "canonical_model" not in result
    finding = next(row for row in result["findings"] if row["section"] == ID)
    assert finding["code"] == "object.unavailable" and finding["object_id"] == "door_1" and finding["blocks_export"]
