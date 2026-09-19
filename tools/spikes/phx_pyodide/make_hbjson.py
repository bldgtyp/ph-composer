"""Synthetic two-Room HBJSON for the B1 spike: two adjacent boxes, explicit simple constructions, stable ids."""

import json
import re
import sys

from honeybee.boundarycondition import boundary_conditions
from honeybee.model import Model
from honeybee.room import Room
from honeybee_energy.construction.opaque import OpaqueConstruction
from honeybee_energy.construction.window import WindowConstruction
from honeybee_energy.material.glazing import EnergyWindowMaterialSimpleGlazSys
from honeybee_energy.material.opaque import EnergyMaterial
from honeybee_ph.bldg_segment import BldgSegment
from ladybug_geometry.geometry3d import Point3D

UUID = re.compile(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")


def material(identifier: str, thickness: float, conductivity: float) -> EnergyMaterial:
    return EnergyMaterial(identifier, thickness, conductivity, 1000.0, 1000.0)


def sort_resources(node: object) -> None:
    """honeybee collects shared resources in sets, so their list order changes between runs."""
    if isinstance(node, dict):
        for value in node.values():
            sort_resources(value)
    elif isinstance(node, list):
        for value in node:
            sort_resources(value)
        if node and all(isinstance(item, dict) and "identifier" in item for item in node):
            node.sort(key=lambda item: item["identifier"])


def main(out: str) -> None:
    wall = OpaqueConstruction("b1_wall", [material("b1_board", 0.02, 0.2), material("b1_insulation", 0.3, 0.04)])
    roof = OpaqueConstruction("b1_roof", [material("b1_deck", 0.02, 0.15), material("b1_roof_ins", 0.4, 0.035)])
    floor = OpaqueConstruction("b1_floor", [material("b1_slab", 0.2, 1.8), material("b1_floor_ins", 0.2, 0.035)])
    inner = OpaqueConstruction("b1_partition", [material("b1_stud", 0.1, 0.5)])
    window = WindowConstruction("b1_window", [EnergyWindowMaterialSimpleGlazSys("b1_glazing", 0.8, 0.5)])

    rooms = [
        Room.from_box("b1_room_west", 5.0, 4.0, 3.0, origin=Point3D(0, 0, 0)),
        Room.from_box("b1_room_east", 4.0, 4.0, 3.0, origin=Point3D(5.0, 0, 0)),
    ]
    segment = BldgSegment()
    segment.identifier = "b1_segment"
    segment.display_name = "b1_segment"
    for room in rooms:
        room.display_name = room.identifier
        room.properties.ph.ph_bldg_segment = segment
        for index, face in enumerate(room.faces):
            face.identifier = f"{room.identifier}_face_{index}"
            kind = str(face.type)
            face.properties.energy.construction = {"Wall": wall, "RoofCeiling": roof, "Floor": floor}[kind]
            if kind == "Floor":
                face.boundary_condition = boundary_conditions.ground
    Room.solve_adjacency(rooms, 0.01)
    for room in rooms:
        for face in room.faces:
            if str(face.boundary_condition) == "Surface":
                face.properties.energy.construction = inner
    south = next(face for face in rooms[0].faces if face.normal.y < -0.9)
    south.apertures_by_ratio(0.3, 0.01)
    for index, aperture in enumerate(south.apertures):
        aperture.identifier = f"b1_window_{index}"
        aperture.properties.energy.construction = window

    model = Model("b1_two_rooms", rooms, units="Meters", tolerance=0.01, angle_tolerance=1.0)
    data = model.to_dict()
    sort_resources(data)
    text = json.dumps(data, indent=2, sort_keys=True)
    # honeybee-ph gives its default site, climate and team objects random UUIDs; number them in order.
    for index, found in enumerate(dict.fromkeys(UUID.findall(text))):
        text = text.replace(found, f"b1_uuid_{index}")
    with open(out, "w") as handle:
        handle.write(text)


if __name__ == "__main__":
    main(sys.argv[1])
