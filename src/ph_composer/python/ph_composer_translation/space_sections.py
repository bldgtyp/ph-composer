"""Spaces, translated through the pinned honeybee-ph stack and attached to their Zone's Room.

One honeybee-ph `Space` per record, with a `SpaceVolume` per Volume (its prism as `geometry`) and a
`SpaceFloorSegment` per Floor Segment (its projected loops as `geometry`, both factors as stored). Identifiers
are the record ids. Each object carries its record's `user_data`; PH-Composer writes no reserved entry on them.
The Zones section names nothing here."""

from __future__ import annotations

import math
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from typing import Any

from . import stack
from .contract import JSONValue, RecordError
from .contract.space_records import AIRFLOWS, Polygon, SpaceRecord
from .model_sections import ZONE_SECTION_ID, TranslatedZone
from .sections import ROOM, Attachment, Inputs, Requirement, Section

SPACE_SECTION_ID = "ph_composer.spaces.export.spaces"
ZONES = Requirement(ZONE_SECTION_ID, TranslatedZone)
#: Each stored rate (m3/h) and the honeybee-ph property it sets (m3/s).
RATES = dict(zip(AIRFLOWS, ("_v_sup", "_v_eta", "_v_tran"), strict=True))
SECONDS_PER_HOUR = 3600.0
#: The quantities summed per Zone and per Building-Segment, and the honeybee-ph property each reads.
TOTALS = {"floor_area_m2": "floor_area", "weighted_area_m2": "weighted_floor_area", "net_volume_m3": "net_volume"}


@dataclass(frozen=True)
class TranslatedSpace:
    source: SpaceRecord
    building_segment: str
    space: Any

    @property
    def zone_id(self) -> str:
        return self.source.zone_id


def airflow_rates(record: SpaceRecord) -> dict[str, float | None]:
    """The any-set rule, in one place: a Space with no rate set inherits its Zone's airflow and writes none;
    a Space with any rate set writes all three, 0 for an unset one. Converted from m3/h to m3/s here only."""
    if not record.airflows:
        return dict.fromkeys(RATES.values())
    return {name: record.airflows.get(key, 0.0) / SECONDS_PER_HOUR for key, name in RATES.items()}


class SpaceSection(Section[SpaceRecord, TranslatedSpace]):
    id = SPACE_SECTION_ID
    versions = frozenset({1})
    object_type = TranslatedSpace
    requires = (ZONES,)
    attaches = Attachment(ROOM, lambda item: item.zone_id)

    def read(self, raw: Mapping[str, object]) -> SpaceRecord:
        return SpaceRecord.read(raw)

    def translate(self, record: SpaceRecord, inputs: Inputs) -> TranslatedSpace:
        zone = inputs.get(ZONES, record.zone_id)
        space_module = stack.load("honeybee_ph.space")
        try:
            space = space_module.Space()
            space.identifier, space.name, space.number, space.quantity = record.id, record.name, record.number, 1
            if record.user_data:
                space.user_data = dict(record.user_data)
            volumes = []
            for source in record.volumes:
                volume = space_module.SpaceVolume()
                volume.identifier, volume.avg_ceiling_height = source.id, source.avg_ceiling_height_m
                if source.display_name:
                    volume.display_name = source.display_name
                if source.user_data:
                    volume.user_data = dict(source.user_data)
                volume.floor.identifier = source.floor_id
                for item in source.floor_segments:
                    segment = space_module.SpaceFloorSegment()
                    segment.identifier = item.id
                    if item.display_name:
                        segment.display_name = item.display_name
                    segment.geometry = face(item.loops_m[0], item.loops_m[1:])
                    segment.reference_point = segment.geometry.center
                    segment.weighting_factor, segment.net_area_factor = item.weighting_factor, item.net_area_factor
                    if item.user_data:
                        segment.user_data = dict(item.user_data)
                    volume.floor.add_floor_segment(segment)
                volume.geometry = [face(polygon, ()) for polygon in source.geometry]
                volumes.append(volume)
            space.add_new_volumes(volumes)
            for name, rate in airflow_rates(record).items():
                setattr(space.properties.ph, name, rate)
        except (AssertionError, ValueError) as error:
            raise RecordError(f"space {record.id} could not be built: {error}") from error
        return TranslatedSpace(record, zone.source.building_segment, space)

    def attach(self, host: Any, objects: Sequence[TranslatedSpace]) -> None:
        for item in objects:
            item.space.host = host
            host.properties.ph.add_new_space(item.space)

    def result_fields(self, objects: Mapping[str, TranslatedSpace]) -> Mapping[str, JSONValue]:
        zones: dict[str, dict[str, float]] = {}
        segments: dict[str, dict[str, float]] = {}
        for item in objects.values():
            for totals in (
                zones.setdefault(item.zone_id, dict.fromkeys(TOTALS, 0.0)),
                segments.setdefault(item.building_segment, dict.fromkeys(TOTALS, 0.0)),
            ):
                for key, attribute in TOTALS.items():
                    totals[key] += float(getattr(item.space, attribute))
        zone_rows: list[JSONValue] = [{"zone_id": zone_id, **totals} for zone_id, totals in sorted(zones.items())]
        segment_rows: list[JSONValue] = [
            {"building_segment": name, **totals} for name, totals in sorted(segments.items())
        ]
        return {"space_zone_totals": zone_rows, "space_segment_totals": segment_rows}

    def conformance(self, model: Any, fields: Mapping[str, JSONValue]) -> None:
        """The reloaded model's Spaces sum, per Room, to the totals the run reported, and no identifier
        repeats."""
        spaces = [space for room in model.rooms for space in room.properties.ph.spaces]
        identifiers = [space.identifier for space in spaces] + [
            item.identifier for space in spaces for volume in space.volumes for item in (volume, *volume.floor_segments)
        ]
        if len(set(identifiers)) != len(identifiers):
            raise ValueError("canonical Space, Volume or Floor Segment identifiers repeat")
        reported_rows = fields.get("space_zone_totals", [])
        expected = {
            str(row["zone_id"]): row
            for row in (reported_rows if isinstance(reported_rows, list) else [])
            if isinstance(row, dict)
        }
        for room in model.rooms:
            row = expected.get(room.identifier)
            room_spaces = list(room.properties.ph.spaces)
            if row is None:
                if room_spaces:
                    raise ValueError(f"Room {room.identifier} carries Spaces the run did not report")
                continue
            for key, attribute in TOTALS.items():
                actual = sum(float(getattr(space, attribute)) for space in room_spaces)
                value = row.get(key)
                if isinstance(value, bool) or not isinstance(value, (int, float)):
                    raise ValueError(f"Room {room.identifier} {key} was not reported as a number")
                reported = float(value)
                if not math.isclose(actual, reported, rel_tol=1e-9, abs_tol=1e-9):
                    raise ValueError(f"Room {room.identifier} {key} is {actual}, the run reported {reported}")


def face(boundary: Polygon, holes: Sequence[Polygon]) -> Any:
    lb_face = stack.load("ladybug_geometry.geometry3d.face")
    lb_point = stack.load("ladybug_geometry.geometry3d.pointvector")
    points = [lb_point.Point3D(*point) for point in boundary]
    inner = [[lb_point.Point3D(*point) for point in hole] for hole in holes]
    return lb_face.Face3D(points, holes=inner or None)
