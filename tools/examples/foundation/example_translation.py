"""The example feature's translation sections. Development only, like the rest of this folder.

`example.foundation.export.definitions` reads definitions. `example.foundation.export.parts` reads parts, each naming
its definition by durable id, and requires the definitions section's typed objects. The Ruby export
contributors in example_foundation.rb build the sections these read; tests/fixtures/foundation/ holds
one extraction and the result it translates to, which the Ruby and Python suites both check.
"""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from typing import Any, ClassVar

from ph_composer_translation.contract import JSONValue, RecordError, as_number, as_text
from ph_composer_translation.sections import Inputs, Requirement, Section

ID = "example.foundation"


@dataclass(frozen=True)
class Definition:
    id: str
    label: str


@dataclass(frozen=True)
class PartRecord:
    id: str
    label: str
    length_mm: float
    definition_id: str
    review_status: str | None


@dataclass(frozen=True)
class Part:
    id: str
    label: str
    length_m: float
    definition: Definition
    checked: bool


class Definitions(Section[Definition, Definition]):
    id = f"{ID}.export.definitions"
    versions = frozenset({1})
    object_type = Definition

    def read(self, raw: Mapping[str, object]) -> Definition:
        return Definition(as_text(raw.get("id"), "id"), as_text(raw.get("label"), "label"))

    def translate(self, record: Definition, inputs: Inputs) -> Definition:
        return record


DEFINITIONS = Requirement(f"{ID}.export.definitions", Definition)


class Parts(Section[PartRecord, Part]):
    id = f"{ID}.export.parts"
    versions = frozenset({1})
    object_type = Part
    requires: ClassVar[tuple[Requirement[Any], ...]] = (DEFINITIONS,)

    def read(self, raw: Mapping[str, object]) -> PartRecord:
        review = raw.get("extensions", {})
        status = review.get(f"{ID}.review", {}).get("review_status") if isinstance(review, Mapping) else None
        if status is not None and status not in ("draft", "checked"):
            raise RecordError("review_status must be draft or checked")
        return PartRecord(
            as_text(raw.get("id"), "id"),
            as_text(raw.get("label"), "label"),
            as_number(raw.get("length_mm"), "length_mm"),
            as_text(raw.get("definition_id"), "definition_id"),
            status,
        )

    def translate(self, record: PartRecord, inputs: Inputs) -> Part:
        if record.length_mm <= 0:
            raise RecordError("length_mm must be positive")
        definition = inputs.get(DEFINITIONS, record.definition_id)
        return Part(record.id, record.label, record.length_mm / 1000.0, definition, record.review_status == "checked")

    def result_fields(self, objects: Mapping[str, Part]) -> Mapping[str, JSONValue]:
        total_mm = round(sum(part.length_m for part in objects.values()) * 1000.0, 6)
        return {"example_parts": {"count": len(objects), "total_length_mm": total_mm}}


SECTIONS = (Definitions(), Parts())
