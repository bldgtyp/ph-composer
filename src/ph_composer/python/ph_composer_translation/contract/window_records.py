"""Detached, finite Window extraction values. No authoring or provider metadata crosses this seam."""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field

from . import JSONObject, RecordError, as_number, as_text, user_data

SIDES = ("top", "right", "bottom", "left")


def number(row: Mapping[str, object], key: str, minimum: float = 0) -> float:
    value = as_number(row.get(key), key)
    if value < minimum:
        raise RecordError(f"{key} must be at least {minimum:g}")
    return value


def mapping(value: object, label: str) -> Mapping[str, object]:
    if not isinstance(value, Mapping):
        raise RecordError(f"{label} must be an object")
    return value


@dataclass(frozen=True)
class Glazing:
    id: str
    name: str
    ug_w_m2k: float
    g_value: float

    @classmethod
    def read(cls, value: object) -> Glazing:
        row = mapping(value, "glazing")
        g = number(row, "g_value")
        if g > 1:
            raise RecordError("g_value must be between 0 and 1 inclusive")
        return cls(
            as_text(row.get("id"), "glazing id"), as_text(row.get("name"), "glazing name"), number(row, "ug_w_m2k"), g
        )


@dataclass(frozen=True)
class Side:
    id: str
    name: str
    width_m: float
    uf_w_m2k: float
    psi_g_w_mk: float
    install_id: str | None
    psi_install_w_mk: float
    install_name: str | None

    @classmethod
    def read(cls, value: object) -> Side:
        row = mapping(value, "side")
        frame = mapping(row.get("frame"), "frame")
        install = row.get("install_id")
        if install is not None:
            install = as_text(install, "install_id")
        psi_install = as_number(row.get("psi_install_w_mk"), "psi_install_w_mk")
        if install is None and psi_install != 0:
            raise RecordError("a shared side without an install id must have zero psi_install")
        install_name = row.get("install_name")
        if install is None:
            if install_name is not None:
                raise RecordError("a shared side must not name an install")
        else:
            install_name = as_text(install_name, "install_name")
        return cls(
            as_text(frame.get("id"), "frame id"),
            as_text(frame.get("name"), "frame name"),
            number(frame, "width_m"),
            number(frame, "uf_w_m2k"),
            as_number(frame.get("psi_g_w_mk"), "psi_g_w_mk"),
            install,
            psi_install,
            install_name,
        )


@dataclass(frozen=True)
class WindowConstructionRecord:
    id: str
    name: str
    uw_w_m2k: float
    glazing: Glazing
    sides: tuple[Side, ...]

    @classmethod
    def read(cls, raw: Mapping[str, object]) -> WindowConstructionRecord:
        sides = mapping(raw.get("sides"), "sides")
        if set(sides) != set(SIDES):
            raise RecordError("sides must name exactly top, right, bottom and left")
        uw_w_m2k = number(raw, "uw_w_m2k")
        if not 0 < uw_w_m2k <= 12:
            raise RecordError("uw_w_m2k must be positive and no greater than the pinned Energy material limit of 12")
        return cls(
            as_text(raw.get("id"), "construction id"),
            as_text(raw.get("name"), "construction name"),
            uw_w_m2k,
            Glazing.read(raw.get("glazing")),
            tuple(Side.read(sides[side]) for side in SIDES),
        )

    def signature(self) -> tuple[object, ...]:
        """Every translated thermal property and product id; labels are presentation only."""
        return (
            self.uw_w_m2k,
            0.6,
            self.glazing.id,
            self.glazing.ug_w_m2k,
            self.glazing.g_value,
            tuple(
                (side.id, side.width_m, side.uf_w_m2k, side.psi_g_w_mk, side.install_id, side.psi_install_w_mk)
                for side in self.sides
            ),
        )


@dataclass(frozen=True)
class ApertureRecord:
    id: str
    unit_id: str
    type_id: str
    element_id: str
    name: str
    host_face_id: str
    zone_id: str
    construction_id: str
    polygon: tuple[tuple[float, float, float], ...]
    variant_type: str
    install_depth: float
    is_operable: bool
    user_data: JSONObject = field(default_factory=dict)

    @classmethod
    def read(cls, raw: Mapping[str, object]) -> ApertureRecord:
        polygon = raw.get("polygon_m")
        if isinstance(polygon, (str, bytes)) or not isinstance(polygon, Sequence) or len(polygon) < 3:
            raise RecordError("polygon_m must have at least three points")
        points: list[tuple[float, float, float]] = []
        for point in polygon:
            if isinstance(point, (str, bytes)) or not isinstance(point, Sequence) or len(point) != 3:
                raise RecordError("polygon point must have three coordinates")
            points.append(
                (
                    as_number(point[0], "polygon coordinate"),
                    as_number(point[1], "polygon coordinate"),
                    as_number(point[2], "polygon coordinate"),
                )
            )
        operable = raw.get("is_operable")
        if not isinstance(operable, bool):
            raise RecordError("is_operable must be boolean")
        return cls(
            id=as_text(raw.get("id"), "id"),
            unit_id=as_text(raw.get("unit_id"), "unit_id"),
            type_id=as_text(raw.get("type_id"), "type_id"),
            element_id=as_text(raw.get("element_id"), "element_id"),
            name=as_text(raw.get("name"), "name"),
            host_face_id=as_text(raw.get("host_face_id"), "host_face_id"),
            zone_id=as_text(raw.get("zone_id"), "zone_id"),
            construction_id=as_text(raw.get("construction_id"), "construction_id"),
            polygon=tuple(points),
            variant_type=as_text(raw.get("variant_type"), "variant_type"),
            install_depth=number(raw, "install_depth_m"),
            is_operable=operable,
            user_data=user_data(raw.get("user_data"), f"aperture {raw.get('id')}"),
        )
