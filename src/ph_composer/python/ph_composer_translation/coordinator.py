"""Orders sections by their declared requirements and runs them.

The contract is context/CONTRACTS.md, "Translation sections and artifacts".

Three kinds of failure, kept apart:

- Structural: a missing or mistyped requirement, a cycle, a duplicate section, a section version no
  translator reads. Found before any record is read; nothing translates.
- Contract (`payload.contract`): the document or a whole section is unreadable. Nothing translates.
- Object: one record cannot be read or translated, or needs an object that did not translate. That
  record emits a finding and produces no object; independent records continue.

The coordinator names no section. Sections with no requirement between them run in id order, so a run
is reproducible. Once every section has run, the model assembly attaches what the sections declared
(assembly.py), and then each section reports its own result fields.
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from typing import Any

from . import DOCUMENT_SCHEMA_VERSION
from .assembly import assemble
from .contract import ContractError, RecordError
from .result import DEPENDENCY_UNAVAILABLE, OBJECT_UNAVAILABLE, Failure, Finding, SectionResult, Translation
from .sections import DependencyUnavailable, Inputs, Section

# Every document names these; a section id may not reuse them, since a section's fields sit under its id.
SHELL_FIELDS = frozenset(
    {"schema_version", "run_id", "state", "summary", "sections", "findings", "failure", "canonical_model"}
)


def order(sections: Sequence[Section[Any, Any]]) -> list[Section[Any, Any]]:
    """The sections in an order where each runs after every section it requires. Raises `ContractError`
    with a `section.*` code for a structural problem."""
    by_id: dict[str, Section[Any, Any]] = {}
    for section in sections:
        if section.id in by_id:
            raise ContractError("section.duplicate", f"two sections declare {section.id}")
        by_id[section.id] = section
    for section in sections:
        for requirement in section.requires:
            provider = by_id.get(requirement.section)
            if provider is None:
                raise ContractError("section.missing_dependency", f"{section.id} requires {requirement.section}")
            if not issubclass(provider.object_type, requirement.object_type):
                raise ContractError(
                    "section.missing_dependency",
                    f"{section.id} requires {requirement.object_type.__name__} objects from {requirement.section}, "
                    f"which produces {provider.object_type.__name__}",
                )
    ordered: list[Section[Any, Any]] = []
    waiting = dict(by_id)
    while waiting:
        ready = sorted(
            section_id
            for section_id, section in waiting.items()
            if all(requirement.section not in waiting for requirement in section.requires)
        )
        if not ready:
            raise ContractError("section.cycle", "sections require each other: " + ", ".join(sorted(waiting)))
        for section_id in ready:
            ordered.append(waiting.pop(section_id))
    return ordered


def translate(document: object, sections: Sequence[Section[Any, Any]]) -> Translation:
    """Translates an extraction document. Never raises for a structural, contract or object failure:
    each is reported in the returned `Translation`."""
    run_id = document.get("run_id") if isinstance(document, Mapping) else None
    translation = Translation(run_id=run_id if isinstance(run_id, str) else "")
    try:
        ordered = order(sections)
    except ContractError as error:
        translation.failure = Failure("planning", error.code, error.detail)
        return translation
    try:
        inputs = read_document(document, ordered)
    except ContractError as error:
        translation.failure = Failure("reading", error.code, error.detail)
        return translation
    objects: dict[str, dict[str, object]] = {}
    for section in ordered:
        result = run_section(section, inputs[section.id], objects, translation.findings)
        translation.results[section.id] = result
        objects[section.id] = result.objects
        translation.findings.extend(section.findings(result.objects))
    assemble(translation, ordered)
    for section in ordered:
        add_fields(translation, section, translation.results[section.id])
    return translation


def read_document(
    document: object, sections: Sequence[Section[Any, Any]]
) -> dict[str, list[tuple[str, Mapping[str, object]]]]:
    """Each section's records as (durable id, raw record), or `ContractError` for an unreadable document."""
    if not isinstance(document, Mapping):
        raise ContractError("payload.contract", "the extraction is not an object")
    if document.get("schema_version") != DOCUMENT_SCHEMA_VERSION:
        raise ContractError("payload.contract", f"extraction schema {document.get('schema_version')!r} is not read")
    if not isinstance(document.get("run_id"), str) or not document["run_id"]:
        raise ContractError("payload.contract", "the extraction has no run id")
    raw_sections = document.get("sections")
    if not isinstance(raw_sections, Mapping):
        raise ContractError("payload.contract", "the extraction has no sections object")
    known = {section.id for section in sections}
    if unread := sorted(set(raw_sections) - known):
        raise ContractError("payload.contract", "no translator reads section " + ", ".join(map(str, unread)))
    return {section.id: read_section(section, raw_sections.get(section.id)) for section in sections}


def read_section(section: Section[Any, Any], raw: object) -> list[tuple[str, Mapping[str, object]]]:
    if not isinstance(raw, Mapping):
        raise ContractError("payload.contract", f"section {section.id} is missing or not an object")
    version = raw.get("version")
    if isinstance(version, bool) or not isinstance(version, int):
        raise ContractError("payload.contract", f"section {section.id} has no version")
    if version not in section.versions:
        raise ContractError("section.version_unsupported", f"section {section.id} version {version} is not read")
    records = raw.get("records")
    if isinstance(records, (str, bytes)) or not isinstance(records, Sequence):
        raise ContractError("payload.contract", f"section {section.id} records are not a list")
    identified: list[tuple[str, Mapping[str, object]]] = []
    seen: set[str] = set()
    for record in records:
        record_id = record.get("id") if isinstance(record, Mapping) else None
        # A record nothing can name cannot be reported on; that is a document defect, not a record one.
        if not isinstance(record, Mapping) or not isinstance(record_id, str) or not record_id:
            raise ContractError("payload.contract", f"section {section.id} has a record without an id")
        # One id names one object; a second record under it would silently replace or contradict it.
        if record_id in seen:
            raise ContractError("payload.contract", f"section {section.id} names record {record_id} twice")
        seen.add(record_id)
        identified.append((record_id, record))
    return identified


def run_section(
    section: Section[Any, Any],
    records: list[tuple[str, Mapping[str, object]]],
    objects: Mapping[str, Mapping[str, object]],
    findings: list[Finding],
) -> SectionResult:
    result = SectionResult(section.id)
    inputs = Inputs(section.requires, objects)
    for record_id, raw in records:
        try:
            translated = section.translate(section.read(raw), inputs)
        except RecordError as error:
            findings.append(Finding(OBJECT_UNAVAILABLE, section.id, record_id, str(error), section.required_for_export))
        except DependencyUnavailable as error:
            message = f"needs {error.section} object {error.object_id}, which did not translate"
            if error.context:
                message = f"{error.context}: {message}"
            findings.append(
                Finding(DEPENDENCY_UNAVAILABLE, section.id, record_id, message, section.required_for_export)
            )
        else:
            if not isinstance(translated, section.object_type):
                raise TypeError(
                    f"{section.id} produced {type(translated).__name__}, not {section.object_type.__name__}"
                )
            result.objects[record_id] = translated
            continue
        result.unavailable.append(record_id)
    return result


def add_fields(translation: Translation, section: Section[Any, Any], result: SectionResult) -> None:
    if fields := dict(section.result_fields(result.objects)):
        if section.id in SHELL_FIELDS:
            raise ValueError(f"section id {section.id} is a result document field")
        translation.fields[section.id] = fields
