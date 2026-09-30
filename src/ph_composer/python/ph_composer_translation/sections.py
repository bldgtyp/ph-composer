"""What a translation section declares (CONTRACTS.md C6).

A section reads one section of the extraction, one record at a time, into typed objects keyed by the
record's durable id. It names the other sections whose objects it needs, and the type it expects from
each; the coordinator orders sections by those requirements and hands each one only what it declared.

    class Parts(Section[PartRecord, Part]):
        id = "example.foundation.parts"
        versions = frozenset({1})
        object_type = Part
        requires = (DEFINITIONS,)          # Requirement("example.foundation.definitions", Definition)

        def read(self, raw):               # raise RecordError for a bad record
            ...
        def translate(self, record, inputs):
            definition = inputs.get(DEFINITIONS, record.definition_id)   # typed, or DependencyUnavailable
            ...

A section never reads another section's records, and the coordinator names no section.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from typing import Any, ClassVar, Generic, TypeVar

from .contract import JSONValue
from .result import Finding

RecordT = TypeVar("RecordT")
ObjectT = TypeVar("ObjectT")


@dataclass(frozen=True)
class Requirement(Generic[ObjectT]):
    """The objects of section `section`, which must be instances of `object_type`."""

    section: str
    object_type: type[ObjectT]


class DependencyUnavailable(Exception):
    """A required object did not translate. The requiring record emits its own finding and produces no
    object: nothing stands in for the missing one."""

    def __init__(self, section: str, object_id: str) -> None:
        super().__init__(f"{section} object {object_id} is unavailable")
        self.section = section
        self.object_id = object_id


class Inputs:
    """The objects a section declared it needs, from sections that have already run."""

    def __init__(self, declared: tuple[Requirement[Any], ...], objects: Mapping[str, Mapping[str, object]]) -> None:
        self._declared = declared
        self._objects = objects

    def get(self, requirement: Requirement[ObjectT], object_id: str) -> ObjectT:
        if requirement not in self._declared:
            raise LookupError(f"{requirement.section} is not a declared requirement of this section")
        found = self._objects.get(requirement.section, {}).get(object_id)
        if not isinstance(found, requirement.object_type):
            raise DependencyUnavailable(requirement.section, object_id)
        return found


class Section(ABC, Generic[RecordT, ObjectT]):
    """One translation section. Subclasses set the class attributes and implement `read` and `translate`."""

    id: ClassVar[str]
    #: The versions of this section's extraction the section can read.
    versions: ClassVar[frozenset[int]]
    object_type: ClassVar[type]
    requires: ClassVar[tuple[Requirement[Any], ...]] = ()
    #: Whether an object that fails to translate blocks the canonical artifact. Translation continues
    #: either way, for diagnostics; continuing never grants permission to publish.
    required_for_export: ClassVar[bool] = True

    @abstractmethod
    def read(self, raw: Mapping[str, object]) -> RecordT:
        """One record, typed. Raise `RecordError` when this record cannot be read."""

    @abstractmethod
    def translate(self, record: RecordT, inputs: Inputs) -> ObjectT:
        """One object. Raise `RecordError`, or let `DependencyUnavailable` from `inputs` propagate."""

    def findings(self, objects: Mapping[str, ObjectT]) -> Sequence[Finding]:
        """Non-fatal information about translated objects, including deliberate omissions."""
        return ()

    def result_fields(self, objects: Mapping[str, ObjectT]) -> Mapping[str, JSONValue]:
        """Top-level fields this section adds to the result document. Each must be declared by the
        feature's export contributor, or the export's privacy check refuses the result."""
        return {}
