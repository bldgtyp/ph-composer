"""Window products and glazed cells, translated through the pinned Honeybee/PH stack."""

from __future__ import annotations

import hashlib
import json
from collections.abc import Mapping
from dataclasses import dataclass
from typing import Any

from . import stack
from .contract import JSONValue, RecordError
from .contract.window_records import SIDES, ApertureRecord, WindowConstructionRecord
from .sections import Inputs, Requirement, Section

WINDOW_CONSTRUCTION_SECTION_ID = "ph_composer.windows.export.window_constructions"
APERTURE_SECTION_ID = "ph_composer.windows.export.apertures"


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
                "wmat_" + digest, record.u_w, record.glazing.g, 0.6
            )
            material.display_name = record.glazing.name
            construction = energy_window.WindowConstruction("wcon_" + digest, [material])
            construction.display_name = record.name
            glazing = ph_window.PhWindowGlazing("wglz_" + digest)
            glazing.display_name = record.glazing.name
            glazing.u_factor, glazing.g_value = record.glazing.ug, record.glazing.g
            frame = ph_window.PhWindowFrame("wfrm_" + digest)
            frame.display_name = record.name
            for name, source in zip(SIDES, record.sides, strict=True):
                side = getattr(frame, name)
                side.identifier = "wfside_" + digest + "_" + name
                side.display_name = source.name
                side.width, side.u_factor = source.width, source.uf
                side.psi_glazing, side.psi_install = source.psi_g, source.psi_install
            construction.properties.ph.ph_glazing = glazing
            construction.properties.ph.ph_frame = frame
        except (AssertionError, ValueError) as error:
            raise RecordError(f"window construction {record.id} could not be built: {error}") from error
        return TranslatedWindowConstruction(record, construction)


class ApertureSection(Section[ApertureRecord, TranslatedAperture]):
    id = APERTURE_SECTION_ID
    versions = frozenset({1})
    object_type = TranslatedAperture
    requires = (WINDOW_CONSTRUCTIONS,)

    def read(self, raw: Mapping[str, object]) -> ApertureRecord:
        return ApertureRecord.read(raw)

    def translate(self, record: ApertureRecord, inputs: Inputs) -> TranslatedAperture:
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

    def result_fields(self, objects: Mapping[str, TranslatedAperture]) -> Mapping[str, JSONValue]:
        groups: dict[tuple[str, str], list[TranslatedAperture]] = {}
        endpoints: dict[str, float] = {}
        for item in objects.values():
            groups.setdefault((item.source.type_id, item.source.zone_id), []).append(item)
            glazing = item.construction.source.glazing
            if glazing.g in (0, 1):
                endpoints[item.construction.construction.identifier] = glazing.g
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
        }
