from __future__ import annotations

import json
from pathlib import Path
from types import SimpleNamespace

import pytest

from ph_composer_translation.composition import SECTIONS
from ph_composer_translation.contract import RecordError
from ph_composer_translation.coordinator import translate
from ph_composer_translation.model_sections import FaceSection, ZoneSection

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests" / "fixtures" / "phase_one" / "two_zones_extraction.json"


def test_normal_composition_cannot_activate_the_development_construction() -> None:
    result = translate(json.loads(FIXTURE.read_text()), SECTIONS).to_document()

    assert result["state"] == "complete_with_findings"
    assert result["summary"] == {"objects": 12, "unavailable": 2, "findings": 2, "publishable": False}
    assert "canonical_model" not in result
    findings = result["findings"]
    assert isinstance(findings, list)
    assert {finding["message"] for finding in findings if isinstance(finding, dict)} == {
        "no authored construction provider is installed"
    }


class FakeFace:
    def __init__(self, identifier: str, geometry: object, face_type: object, boundary: object) -> None:
        self.identifier = identifier
        self.geometry = geometry
        self.type = face_type
        self.boundary_condition = boundary
        self.properties = SimpleNamespace(energy=SimpleNamespace(construction=None))

    def set_adjacency(self, other: FakeFace) -> None:
        self.boundary_condition = SimpleNamespace(target=other.identifier)
        other.boundary_condition = SimpleNamespace(target=self.identifier)


class FakeRoom:
    def __init__(self, identifier: str, faces: list[FakeFace]) -> None:
        self.identifier = identifier
        self.faces = faces
        self.display_name = identifier
        self.user_data: dict[str, object] = {}
        self.properties = SimpleNamespace(
            ph=SimpleNamespace(ph_bldg_segment=SimpleNamespace(identifier="", display_name=""))
        )


class FakeModel:
    def __init__(self, identifier: str, rooms: list[FakeRoom], units: str) -> None:
        self.identifier = identifier
        self.rooms = rooms
        self.units = units

    def to_dict(self) -> dict[str, object]:
        return {
            "identifier": self.identifier,
            "rooms": [room.identifier for room in self.rooms],
            "units": self.units,
        }


class FakeConstructionProvider:
    def resolve(self, assembly_id: str | None) -> object:
        return {"assembly_id": assembly_id}


def fake_stack(name: str) -> object:
    outdoors = SimpleNamespace(name="Outdoors")
    boundaries = SimpleNamespace(outdoors=outdoors, ground=SimpleNamespace(name="Ground"), adiabatic=object())
    modules = {
        "honeybee.face": SimpleNamespace(Face=FakeFace),
        "honeybee.room": SimpleNamespace(Room=FakeRoom),
        "honeybee.facetype": SimpleNamespace(
            face_types=SimpleNamespace(wall=object(), roof_ceiling=object(), floor=object(), air_boundary=object())
        ),
        "honeybee.boundarycondition": SimpleNamespace(boundary_conditions=boundaries),
        "ladybug_geometry.geometry3d.face": SimpleNamespace(Face3D=lambda boundary, holes=None: (boundary, holes)),
        "ladybug_geometry.geometry3d.pointvector": SimpleNamespace(Point3D=lambda *point: point),
        "honeybee.model": SimpleNamespace(Model=FakeModel),
        "honeybee_energy._extend_honeybee": SimpleNamespace(),
        "honeybee_ph": SimpleNamespace(),
    }
    return modules[name]


def test_model_sections_build_rooms_then_resolve_surface_pairs(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr("ph_composer_translation.model_sections.stack.load", fake_stack)
    result = translate(
        json.loads(FIXTURE.read_text()),
        (FaceSection(), ZoneSection(FakeConstructionProvider())),
    ).to_document()

    assert result["state"] == "complete"
    canonical = result["canonical_model"]
    assert canonical == {
        "hbjson": '{"identifier":"ph_composer_model","rooms":["zon_AAAAAAAAAAAA","zon_BBBBBBBBBBBB"],"units":"Meters"}',
        "rooms": 2,
        "faces": 12,
        "surface_pairs": 1,
        "omitted": 0,
    }


def test_invalid_face_vocabulary_becomes_a_record_error(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr("ph_composer_translation.model_sections.stack.load", fake_stack)
    document = json.loads(FIXTURE.read_text())
    document["sections"]["ph_composer.face_assignment.export.faces"]["records"][0]["face_type"] = "Ceiling"
    result = translate(document, (FaceSection(), ZoneSection(FakeConstructionProvider()))).to_document()

    assert result["state"] == "complete_with_findings"
    summary = result["summary"]
    findings = result["findings"]
    assert isinstance(summary, dict) and summary["unavailable"] == 1
    assert isinstance(findings, list)
    messages = [finding.get("message") for finding in findings if isinstance(finding, dict)]
    assert any("could not be built" in message for message in messages if isinstance(message, str))


@pytest.mark.parametrize("failure", ["missing", "nonreciprocal"])
def test_surface_requires_an_available_reciprocal_counterpart(monkeypatch: pytest.MonkeyPatch, failure: str) -> None:
    monkeypatch.setattr("ph_composer_translation.model_sections.stack.load", fake_stack)
    document = json.loads(FIXTURE.read_text())
    faces = document["sections"]["ph_composer.face_assignment.export.faces"]["records"]
    surfaces = [face for face in faces if face["boundary_condition"] == "Surface"]
    if failure == "missing":
        faces.remove(surfaces[1])
    else:
        surfaces[1]["adjacency"]["counterpart"]["entity_id"] = surfaces[1]["id"]

    result = translate(document, (FaceSection(), ZoneSection(FakeConstructionProvider()))).to_document()

    assert result["state"] == "complete_with_findings"
    summary = result["summary"]
    assert isinstance(summary, dict) and summary["publishable"] is False
    assert "canonical_model" not in result


def test_face_reader_rejects_malformed_nested_geometry() -> None:
    section = FaceSection()
    base = {
        "id": "fac_A00000000001",
        "zone_id": "zon_AAAAAAAAAAAA",
        "face_type": "Wall",
        "boundary_condition": "Outdoors",
        "assembly_id": None,
        "adjacency": None,
    }
    malformed_geometry: tuple[object, ...] = (
        None,
        {"loops_m": []},
        {"loops_m": [[0, 1]]},
        {"loops_m": [[[0, 0]]]},
    )
    for geometry in malformed_geometry:
        with pytest.raises(RecordError):
            section.read({**base, "geometry": geometry})
