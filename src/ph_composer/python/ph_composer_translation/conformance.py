"""Reload the exact canonical HBJSON and reconcile identifiers and reciprocal Surface targets."""

from __future__ import annotations

import json
from collections.abc import Mapping, Sequence
from typing import Any

from . import stack


def check(canonical: Mapping[str, Any], window_schema_exceptions: Sequence[Mapping[str, Any]] = ()) -> None:
    stack.load("honeybee_energy._extend_honeybee")
    stack.load("honeybee_ph")
    model = stack.load("honeybee.model").Model.from_dict(json.loads(canonical["hbjson"]))
    if model.units != "Meters":
        raise ValueError("canonical geometry must use meters")
    rooms = {room.identifier: room for room in model.rooms}
    faces = {face.identifier: face for room in model.rooms for face in room.faces}
    owners = {face.identifier: room.identifier for room in model.rooms for face in room.faces}
    if len(rooms) != len(model.rooms) or len(faces) != sum(len(room.faces) for room in model.rooms):
        raise ValueError("canonical identifiers repeat")
    if len(rooms) != canonical["rooms"] or len(faces) != canonical["faces"]:
        raise ValueError("canonical object counts disagree")
    if not rooms or not faces:
        raise ValueError("canonical model has no usable geometry")
    surfaces = 0
    for face in faces.values():
        boundary = face.boundary_condition
        if boundary.name != "Surface":
            continue
        surfaces += 1
        target_id, room_id = boundary.boundary_condition_objects[:2]
        target = faces.get(target_id)
        if target is None or room_id not in rooms or target not in rooms[room_id].faces:
            raise ValueError("canonical Surface has no emitted counterpart")
        if target.boundary_condition.name != "Surface":
            raise ValueError("canonical Surface counterpart is not Surface")
        if tuple(target.boundary_condition.boundary_condition_objects[:2]) != (
            face.identifier,
            owners[face.identifier],
        ):
            raise ValueError("canonical Surface is not reciprocal")
    omitted = canonical["omitted"]
    if isinstance(omitted, bool) or not isinstance(omitted, int) or omitted < 0:
        raise ValueError("canonical omission count must be a nonnegative integer")
    if surfaces != 2 * canonical["surface_pairs"]:
        raise ValueError("canonical Surface accounting disagrees")

    apertures = [aperture for face in faces.values() for aperture in face.apertures]
    if len({aperture.identifier for aperture in apertures}) != len(apertures):
        raise ValueError("canonical Aperture identifiers repeat")
    expected_endpoints: dict[str, float] = {}
    for face in faces.values():
        if face.apertures:
            if face.boundary_condition.name != "Outdoors" or face.type.name not in ("Wall", "RoofCeiling"):
                raise ValueError("canonical aperture has an ineligible parent")
            face.check_apertures_valid(tolerance=1e-6, angle_tolerance=0.001)
            face.check_sub_faces_overlapping(tolerance=1e-6)
        for aperture in face.apertures:
            aperture.check_planar(tolerance=1e-6)
            construction = aperture.properties.energy.construction
            g = construction.properties.ph.ph_glazing.g_value
            if construction.materials[0].shgc != g:
                raise ValueError("canonical PH glazing and Energy SHGC disagree")
            if g in (0, 1):
                expected_endpoints[construction.identifier] = g
            installs = aperture.properties.ph.install_types
            if any(getattr(installs, side) is not None for side in ("top", "right", "bottom", "left")):
                raise ValueError("canonical aperture must not carry install overrides")
    declared: dict[str, float] = {}
    for row in window_schema_exceptions:
        if set(row) != {"construction_id", "g_value"}:
            raise ValueError("unsupported Window schema exception")
        identifier, g = row["construction_id"], row["g_value"]
        if not isinstance(identifier, str) or isinstance(g, bool) or g not in (0, 1) or identifier in declared:
            raise ValueError("invalid Window schema exception")
        declared[identifier] = g
    if declared != expected_endpoints:
        raise ValueError("Window schema exceptions do not match exact canonical endpoint values")
