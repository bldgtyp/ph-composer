"""What a translation run produced: typed objects per section, findings, and the result document."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass, field

from . import RESULT_SCHEMA_VERSION
from .contract import JSONObject, JSONValue

OBJECT_UNAVAILABLE = "object.unavailable"
DEPENDENCY_UNAVAILABLE = "dependency.unavailable"


@dataclass(frozen=True)
class Finding:
    """Something the user must know about one object. `blocks_export` findings keep the canonical
    artifact from being published, however much else translated."""

    code: str
    section: str
    object_id: str
    message: str
    blocks_export: bool

    def to_json(self) -> JSONObject:
        return {
            "code": self.code,
            "section": self.section,
            "object_id": self.object_id,
            "message": self.message,
            "blocks_export": self.blocks_export,
        }


@dataclass(frozen=True)
class Failure:
    """The run stopped before or while reading: nothing translated."""

    stage: str
    code: str
    detail: str


@dataclass
class SectionResult:
    section: str
    objects: dict[str, object] = field(default_factory=dict)
    unavailable: list[str] = field(default_factory=list)


@dataclass
class Translation:
    run_id: str
    results: dict[str, SectionResult] = field(default_factory=dict)
    findings: list[Finding] = field(default_factory=list)
    #: Each section's own result fields, by section id.
    fields: dict[str, dict[str, JSONValue]] = field(default_factory=dict)
    #: The assembled model's HBJSON and accounting, when it may be published (assembly.py).
    canonical: JSONObject | None = None
    failure: Failure | None = None

    @property
    def publishable(self) -> bool:
        """Whether the canonical artifact may be written from this run."""
        return self.failure is None and not any(finding.blocks_export for finding in self.findings)

    @property
    def state(self) -> str:
        if self.failure:
            return "failed"
        return "complete_with_findings" if self.findings else "complete"

    def objects(self, section: str) -> Mapping[str, object]:
        return self.results[section].objects

    def to_document(self) -> JSONObject:
        """The result document. The report embeds it unchanged, after the privacy check. A section's fields
        sit under its id, `document[section_id][field]`; a section with no fields has no key."""
        document: JSONObject = {
            "schema_version": RESULT_SCHEMA_VERSION,
            "run_id": self.run_id,
            "state": self.state,
            "summary": {
                "objects": sum(len(result.objects) for result in self.results.values()),
                "unavailable": sum(len(result.unavailable) for result in self.results.values()),
                "findings": len(self.findings),
                "publishable": self.publishable,
            },
            "sections": [
                {"id": result.section, "objects": list(result.objects), "unavailable": list(result.unavailable)}
                for result in self.results.values()
            ],
            "findings": [finding.to_json() for finding in self.findings],
            "failure": None
            if self.failure is None
            else {"stage": self.failure.stage, "code": self.failure.code, "detail": self.failure.detail},
        }
        if self.canonical is not None:
            document["canonical_model"] = self.canonical
        return {**document, **self.fields}
