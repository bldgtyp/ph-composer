"""Report-only Material attribution. These records do not contribute Honeybee geometry or values."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass

from .contract import JSONValue, as_text
from .sections import Inputs, Section


@dataclass(frozen=True)
class MaterialSource:
    id: str
    name: str
    provider_kind: str
    library_id: str
    record_id: str

    @classmethod
    def read(cls, raw: Mapping[str, object]) -> MaterialSource:
        return cls(*(as_text(raw.get(key), f"material source {key}") for key in cls.__dataclass_fields__))

    def values(self) -> dict[str, JSONValue]:
        return {key: getattr(self, key) for key in self.__dataclass_fields__}


class MaterialSourcesSection(Section[MaterialSource, MaterialSource]):
    id = "ph_composer.assemblies.export.material_sources"
    versions = frozenset({1})
    object_type = MaterialSource
    required_for_export = False

    def read(self, raw: Mapping[str, object]) -> MaterialSource:
        return MaterialSource.read(raw)

    def translate(self, record: MaterialSource, inputs: Inputs) -> MaterialSource:
        return record

    def result_fields(self, objects: Mapping[str, MaterialSource]) -> Mapping[str, JSONValue]:
        return {"material_sources": [value.values() for value in objects.values()]}
