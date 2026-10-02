"""An attaching translation section: Doors on the Faces another feature translates. Development only.

`example.doors.export.doors` reads door records that name their host Face by durable id and declares
`attaches = Attachment(FACE, ...)`. The model assembly finds the host Face in the assembled Model and
hands this section that Face with its Doors. Nothing in the Zones sections, the coordinator or the
assembly names this section; adding it to a composition is the whole change
(tests/python/test_example_doors.py).
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from typing import Any

from ph_composer_translation import stack
from ph_composer_translation.contract import RecordError, as_number, as_text
from ph_composer_translation.sections import FACE, Attachment, Inputs, Section

ID = "example.doors.export.doors"


@dataclass(frozen=True)
class DoorRecord:
    id: str
    host_face_id: str
    polygon_m: tuple[tuple[float, float, float], ...]


@dataclass(frozen=True)
class TranslatedDoor:
    source: DoorRecord
    door: Any


class Doors(Section[DoorRecord, TranslatedDoor]):
    id = ID
    versions = frozenset({1})
    object_type = TranslatedDoor
    attaches = Attachment(FACE, lambda item: item.source.host_face_id)

    def read(self, raw: Mapping[str, object]) -> DoorRecord:
        identifier = as_text(raw.get("id"), "door id")
        polygon = raw.get("polygon_m")
        if isinstance(polygon, (str, bytes)) or not isinstance(polygon, Sequence) or len(polygon) < 3:
            raise RecordError(f"door {identifier} polygon_m must have at least three points")
        points = tuple(
            (as_number(point[0], "x"), as_number(point[1], "y"), as_number(point[2], "z"))
            for point in polygon
            if isinstance(point, Sequence) and len(point) == 3
        )
        if len(points) != len(polygon):
            raise RecordError(f"door {identifier} point must have three coordinates")
        return DoorRecord(identifier, as_text(raw.get("host_face_id"), f"door {identifier} host_face_id"), points)

    def translate(self, record: DoorRecord, inputs: Inputs) -> TranslatedDoor:
        hb_door = stack.load("honeybee.door")
        lb_face = stack.load("ladybug_geometry.geometry3d.face")
        lb_point = stack.load("ladybug_geometry.geometry3d.pointvector")
        geometry = lb_face.Face3D([lb_point.Point3D(*point) for point in record.polygon_m])
        return TranslatedDoor(record, hb_door.Door(record.id, geometry))

    def attach(self, host: Any, objects: Sequence[TranslatedDoor]) -> None:
        try:
            for item in objects:
                host.add_door(item.door)
            host.check_sub_faces_valid(tolerance=1e-6, angle_tolerance=0.001)
        except (AssertionError, ValueError) as error:
            raise RecordError(f"door host {host.identifier} could not be built: {error}") from error
