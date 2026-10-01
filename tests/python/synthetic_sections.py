"""Synthetic translation sections for the coordinator's tests. Development only.

A reads frames. B reads panels that name their frame by durable id and need A's typed object. C reads
tags and needs nothing, so it proves one section's failures do not reach another.
"""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from typing import Any, ClassVar

from ph_composer_translation.contract import JSONValue, RecordError, as_number, as_text
from ph_composer_translation.sections import Inputs, Requirement, Section


@dataclass(frozen=True)
class Frame:
    id: str
    width_m: float


@dataclass(frozen=True)
class Panel:
    id: str
    frame: Frame
    area_m2: float


@dataclass(frozen=True)
class Tag:
    id: str
    text: str


@dataclass(frozen=True)
class FrameRecord:
    id: str
    width_m: float


@dataclass(frozen=True)
class PanelRecord:
    id: str
    frame_id: str
    height_m: float


class SectionA(Section[FrameRecord, Frame]):
    id = "synthetic.a"
    versions = frozenset({1})
    object_type = Frame

    def read(self, raw: Mapping[str, object]) -> FrameRecord:
        return FrameRecord(as_text(raw.get("id"), "id"), as_number(raw.get("width_m"), "width_m"))

    def translate(self, record: FrameRecord, inputs: Inputs) -> Frame:
        if record.width_m <= 0:
            raise RecordError("width_m must be positive")
        return Frame(record.id, record.width_m)


FRAMES = Requirement("synthetic.a", Frame)


class SectionB(Section[PanelRecord, Panel]):
    id = "synthetic.b"
    versions = frozenset({1, 2})
    object_type = Panel
    requires: ClassVar[tuple[Requirement[Any], ...]] = (FRAMES,)

    def read(self, raw: Mapping[str, object]) -> PanelRecord:
        return PanelRecord(
            as_text(raw.get("id"), "id"), as_text(raw.get("frame_id"), "frame_id"), as_number(raw.get("height_m"), "h")
        )

    def translate(self, record: PanelRecord, inputs: Inputs) -> Panel:
        frame = inputs.get(FRAMES, record.frame_id)
        return Panel(record.id, frame, frame.width_m * record.height_m)

    def result_fields(self, objects: Mapping[str, Panel]) -> Mapping[str, JSONValue]:
        return {
            "synthetic_panels": {"count": len(objects), "area_m2": sum(panel.area_m2 for panel in objects.values())}
        }


class SectionC(Section[Tag, Tag]):
    id = "synthetic.c"
    versions = frozenset({1})
    object_type = Tag
    required_for_export: ClassVar[bool] = False

    def read(self, raw: Mapping[str, object]) -> Tag:
        return Tag(as_text(raw.get("id"), "id"), as_text(raw.get("text"), "text"))

    def translate(self, record: Tag, inputs: Inputs) -> Tag:
        return record


def document(**sections: object) -> dict[str, object]:
    """An extraction with the three sections' default records, overridden by keyword (`synthetic_a=`)."""
    defaults: dict[str, object] = {
        "synthetic.a": {"version": 1, "records": [{"id": "a1", "width_m": 2.0}, {"id": "a2", "width_m": 3.0}]},
        "synthetic.b": {
            "version": 1,
            "records": [
                {"id": "b1", "frame_id": "a1", "height_m": 1.5},
                {"id": "b2", "frame_id": "a2", "height_m": 1.0},
            ],
        },
        "synthetic.c": {"version": 1, "records": [{"id": "c1", "text": "north"}]},
    }
    for key, value in sections.items():
        name = key.replace("_", ".")
        if value is None:
            defaults.pop(name)
        else:
            defaults[name] = value
    return {"schema_version": 1, "run_id": "run-1", "sections": defaults}
