"""Window products and glazed cells, translated through the pinned Honeybee/PH stack.

Apertures attach to their host Faces in the model assembly. They read the Zones Face specifications, a layer
down, to check their own host before attaching; the Zones sections name nothing here."""

from __future__ import annotations

import hashlib
import json
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from typing import Any

from . import stack
from .contract import JSONValue, RecordError
from .contract.window_records import SIDES, ApertureRecord, WindowConstructionRecord
from .model_sections import FACES
from .sections import FACE, Attachment, Inputs, Requirement, Section

WINDOW_CONSTRUCTION_SECTION_ID = "ph_composer.windows.export.window_constructions"
APERTURE_SECTION_ID = "ph_composer.windows.export.apertures"
#: The Face types an Aperture may sit in.
HOST_FACE_TYPES = ("Wall", "RoofCeiling")


@dataclass(frozen=True)
class TranslatedWindowConstruction:
    source: WindowConstructionRecord
    construction: Any


WINDOW_CONSTRUCTIONS = Requirement(WINDOW_CONSTRUCTION_SECTION_ID, TranslatedWindowConstruction)


@dataclass(frozen=True)
class TranslatedAperture:
    source: ApertureRecord
    aperture: Any
    construction: TranslatedWindowConstruction


APERTURES = Requirement(APERTURE_SECTION_ID, TranslatedAperture)


class WindowConstructionSection(Section[WindowConstructionRecord, TranslatedWindowConstruction]):
    id = WINDOW_CONSTRUCTION_SECTION_ID
    versions = frozenset({1})
    object_type = TranslatedWindowConstruction
    required_for_export = False

    def read(self, raw: Mapping[str, object]) -> WindowConstructionRecord:
        return WindowConstructionRecord.read(raw)

    def translate(self, record: WindowConstructionRecord, inputs: Inputs) -> TranslatedWindowConstruction:
        stack.load("honeybee_energy._extend_honeybee")
        stack.load("honeybee_ph")
        energy_material = stack.load("honeybee_energy.material.glazing")
        energy_window = stack.load("honeybee_energy.construction.window")
        ph_window = stack.load("honeybee_energy_ph.construction.window")
        digest = hashlib.sha256(json.dumps(record.signature(), separators=(",", ":")).encode()).hexdigest()[:32]
        try:
            material = energy_material.EnergyWindowMaterialSimpleGlazSys(
                "wmat_" + digest, record.uw_w_m2k, record.glazing.g_value, 0.6
            )
            material.display_name = record.glazing.name
            construction = energy_window.WindowConstruction("wcon_" + digest, [material])
            construction.display_name = record.name
            glazing = ph_window.PhWindowGlazing("wglz_" + digest)
            glazing.display_name = record.glazing.name
            glazing.u_factor, glazing.g_value = record.glazing.ug_w_m2k, record.glazing.g_value
            frame = ph_window.PhWindowFrame("wfrm_" + digest)
            frame.display_name = record.name
            for name, source in zip(SIDES, record.sides, strict=True):
                side = getattr(frame, name)
                side.identifier = "wfside_" + digest + "_" + name
                side.display_name = source.name
                side.width, side.u_factor = source.width_m, source.uf_w_m2k
                side.psi_glazing, side.psi_install = source.psi_g_w_mk, source.psi_install_w_mk
            construction.properties.ph.ph_glazing = glazing
            construction.properties.ph.ph_frame = frame
        except (AssertionError, ValueError) as error:
            raise RecordError(f"window construction {record.id} could not be built: {error}") from error
        return TranslatedWindowConstruction(record, construction)


class ApertureSection(Section[ApertureRecord, TranslatedAperture]):
    id = APERTURE_SECTION_ID
    versions = frozenset({1})
    object_type = TranslatedAperture
    requires = (WINDOW_CONSTRUCTIONS, FACES)
    attaches = Attachment(FACE, lambda item: item.source.host_face_id)

    def read(self, raw: Mapping[str, object]) -> ApertureRecord:
        return ApertureRecord.read(raw)

    def translate(self, record: ApertureRecord, inputs: Inputs) -> TranslatedAperture:
        host = inputs.get(FACES, record.host_face_id)
        if host.zone_id != record.zone_id:
            raise RecordError(f"aperture {record.id} host {host.identifier} is not a Face of Zone {record.zone_id}")
        if host.omission or host.boundary_condition != "Outdoors" or host.face_type not in HOST_FACE_TYPES:
            raise RecordError(
                f"aperture {record.id} host {host.identifier} must be an emitted Outdoors Wall or RoofCeiling"
            )
        translated = inputs.get(WINDOW_CONSTRUCTIONS, record.construction_id)
        construction = translated.construction
        hb_aperture = stack.load("honeybee.aperture")
        lb_face = stack.load("ladybug_geometry.geometry3d.face")
        lb_point = stack.load("ladybug_geometry.geometry3d.pointvector")
        try:
            geometry = lb_face.Face3D([lb_point.Point3D(*point) for point in record.polygon])
            aperture = hb_aperture.Aperture(record.id, geometry, is_operable=record.is_operable)
            aperture.check_planar(tolerance=1e-6)
            if geometry.area <= 1e-10 or geometry.is_self_intersecting:
                raise ValueError("aperture must have positive area and a simple polygon")
            aperture.display_name = record.name
            aperture.properties.energy.construction = construction
            aperture.properties.ph.variant_type = record.variant_type
            aperture.properties.ph.install_depth = record.install_depth
        except (AssertionError, ValueError) as error:
            raise RecordError(f"aperture {record.id} could not be built: {error}") from error
        return TranslatedAperture(record, aperture, translated)

    def attach(self, host: Any, objects: Sequence[TranslatedAperture]) -> None:
        """Adds a host Face's Apertures together, then checks they fit it and do not overlap. Each Aperture
        checked its own host in `translate`; what is left can only be judged for the Face as a whole."""
        try:
            for item in objects:
                host.add_aperture(item.aperture)
            host.check_apertures_valid(tolerance=1e-6, angle_tolerance=0.001)
            host.check_sub_faces_overlapping(tolerance=1e-6)
        except (AssertionError, ValueError) as error:
            host.remove_apertures()
            raise RecordError(f"aperture host {host.identifier} could not be built: {error}") from error

    def result_fields(self, objects: Mapping[str, TranslatedAperture]) -> Mapping[str, JSONValue]:
        groups: dict[tuple[str, str], list[TranslatedAperture]] = {}
        endpoints: dict[str, float] = {}
        hosts: dict[str, tuple[Any, str]] = {}
        for item in objects.values():
            groups.setdefault((item.source.type_id, item.source.zone_id), []).append(item)
            glazing = item.construction.source.glazing
            if glazing.g_value in (0, 1):
                endpoints[item.construction.construction.identifier] = glazing.g_value
            if (face := item.aperture.parent) is not None:
                hosts[face.identifier] = (face, item.source.zone_id)
        usage: list[JSONValue] = []
        for (type_id, zone_id), items in sorted(groups.items()):
            usage.append(
                {
                    "type_id": type_id,
                    "type_name": items[0].source.variant_type,
                    "zone_id": zone_id,
                    "unit_count": len({item.source.unit_id for item in items}),
                    "aperture_count": len(items),
                    "install_names": list[JSONValue](
                        sorted(
                            {
                                side.install_name
                                for item in items
                                for side in item.construction.source.sides
                                if side.install_name is not None
                            }
                        )
                    ),
                }
            )
        return {
            "window_usage": usage,
            "window_schema_exceptions": [
                {"construction_id": identifier, "g_value": value} for identifier, value in sorted(endpoints.items())
            ],
            # Net opaque area is a fact about a Face and its Apertures, so the Apertures report it.
            "window_face_areas": [
                {
                    "face_id": identifier,
                    "zone_id": zone_id,
                    "gross_area_m2": face.area,
                    "glazed_area_m2": sum(aperture.area for aperture in face.apertures),
                    "net_area_m2": face.area - sum(aperture.area for aperture in face.apertures),
                }
                for identifier, (face, zone_id) in sorted(hosts.items())
            ],
        }

    def conformance(self, model: Any, fields: Mapping[str, JSONValue]) -> None:
        faces = [face for room in model.rooms for face in room.faces]
        apertures = [aperture for face in faces for aperture in face.apertures]
        if len({aperture.identifier for aperture in apertures}) != len(apertures):
            raise ValueError("canonical Aperture identifiers repeat")
        expected_endpoints: dict[str, float] = {}
        for face in faces:
            if face.apertures:
                if face.boundary_condition.name != "Outdoors" or face.type.name not in HOST_FACE_TYPES:
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
        exceptions = fields.get("window_schema_exceptions", [])
        if not isinstance(exceptions, list):
            raise ValueError("unsupported Window schema exception")
        for row in exceptions:
            if not isinstance(row, Mapping) or set(row) != {"construction_id", "g_value"}:
                raise ValueError("unsupported Window schema exception")
            identifier, g = row["construction_id"], row["g_value"]
            if (
                not isinstance(identifier, str)
                or isinstance(g, bool)
                or not isinstance(g, (int, float))
                or g not in (0, 1)
                or identifier in declared
            ):
                raise ValueError("invalid Window schema exception")
            declared[identifier] = g
        if declared != expected_endpoints:
            raise ValueError("Window schema exceptions do not match exact canonical endpoint values")
