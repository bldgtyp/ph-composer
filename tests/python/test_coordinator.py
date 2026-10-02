"""Typed section ordering, structural failures before translation, contract failures that stop the
run, and object failures that cost one record (context/CONTRACTS.md, "Translation sections and
artifacts")."""

from __future__ import annotations

from collections.abc import Mapping
from typing import Any

import pytest

from ph_composer_translation.contract import RecordError
from ph_composer_translation.coordinator import order, translate
from ph_composer_translation.sections import Inputs, Requirement, Section
from synthetic_sections import FRAMES, Frame, Panel, SectionA, SectionB, SectionC, Tag, document

ALL = (SectionC(), SectionB(), SectionA())


def failure(sections: tuple[Section[Any, Any], ...], doc: object = None) -> tuple[str, str, str]:
    result = translate(document() if doc is None else doc, sections)
    assert result.failure is not None and result.results == {}
    return result.failure.stage, result.failure.code, result.failure.detail


def test_sections_run_after_what_they_require_and_otherwise_in_id_order() -> None:
    assert [section.id for section in order(ALL)] == ["synthetic.a", "synthetic.c", "synthetic.b"]


def test_a_dependent_section_receives_the_typed_object_named_by_durable_id() -> None:
    result = translate(document(), ALL)

    assert result.state == "complete" and result.publishable
    panel = result.objects("synthetic.b")["b1"]
    assert isinstance(panel, Panel)
    assert panel.frame is result.objects("synthetic.a")["a1"]
    assert panel.area_m2 == 3.0


def test_a_missing_required_section_is_structural_and_nothing_translates() -> None:
    assert failure((SectionB(), SectionC())) == (
        "planning",
        "section.missing_dependency",
        "synthetic.b requires synthetic.a",
    )


def test_a_requirement_of_the_wrong_object_type_is_structural() -> None:
    class WantsTags(SectionB):
        id = "synthetic.d"
        requires = (Requirement("synthetic.a", Tag),)

    stage, code, detail = failure((SectionA(), WantsTags()))
    assert (stage, code) == ("planning", "section.missing_dependency")
    assert "requires Tag objects from synthetic.a, which produces Frame" in detail


def test_a_cycle_is_structural() -> None:
    class CyclicA(SectionA):
        requires = (Requirement("synthetic.b", Panel),)

    assert failure((CyclicA(), SectionB(), SectionC())) == (
        "planning",
        "section.cycle",
        "sections require each other: synthetic.a, synthetic.b",
    )


def test_two_sections_with_one_id_are_structural() -> None:
    assert failure((SectionA(), SectionA()))[:2] == ("planning", "section.duplicate")


@pytest.mark.parametrize(
    ("doc", "code", "detail"),
    [
        ([], "payload.contract", "the extraction is not an object"),
        ({**document(), "schema_version": 2}, "payload.contract", "extraction schema 2 is not read"),
        ({**document(), "run_id": ""}, "payload.contract", "the extraction has no run id"),
        ({**document(), "sections": []}, "payload.contract", "the extraction has no sections object"),
        (document(synthetic_a=None), "payload.contract", "section synthetic.a is missing or not an object"),
        (document(synthetic_a={"records": []}), "payload.contract", "section synthetic.a has no version"),
        (document(synthetic_a={"version": 7, "records": []}), "section.version_unsupported", "version 7 is not read"),
        (document(synthetic_a={"version": 1, "records": {}}), "payload.contract", "records are not a list"),
        (document(synthetic_a={"version": 1, "records": [{"width_m": 1}]}), "payload.contract", "without an id"),
        (
            document(synthetic_a={"version": 1, "records": [{"id": "a1", "width_m": 1}, {"id": "a1", "width_m": -1}]}),
            "payload.contract",
            "names record a1 twice",
        ),
        ({**document(), "sections": {**document()["sections"], "other.x": {}}}, "payload.contract", "other.x"),  # type: ignore[dict-item]
    ],
)
def test_a_malformed_document_or_section_stops_the_run(doc: object, code: str, detail: str) -> None:
    stage, found_code, found_detail = failure(ALL, doc)
    assert (stage, found_code) == ("reading", code)
    assert detail in found_detail


def test_one_bad_record_costs_that_object_and_its_dependents_only() -> None:
    bad_a = {"version": 1, "records": [{"id": "a1", "width_m": -1}, {"id": "a2", "width_m": 3.0}]}
    result = translate(document(synthetic_a=bad_a), ALL)

    assert result.state == "complete_with_findings"
    assert [(f.code, f.section, f.object_id) for f in result.findings] == [
        ("object.unavailable", "synthetic.a", "a1"),
        ("dependency.unavailable", "synthetic.b", "b1"),
    ]
    assert "b1" not in result.objects("synthetic.b"), "no substitute stands in for the missing frame"
    assert set(result.objects("synthetic.b")) == {"b2"}
    assert set(result.objects("synthetic.c")) == {"c1"}
    assert result.results["synthetic.a"].unavailable == ["a1"]
    assert not result.publishable


def test_an_unreadable_record_is_an_object_failure() -> None:
    bad_c = {"version": 1, "records": [{"id": "c1", "text": " "}, {"id": "c2", "text": "south"}]}
    result = translate(document(synthetic_c=bad_c), ALL)

    assert [(f.code, f.object_id, f.message) for f in result.findings] == [
        ("object.unavailable", "c1", "text must be non-empty text")
    ]
    assert set(result.objects("synthetic.c")) == {"c2"}
    assert result.publishable, "C is not required for export, so its finding does not block"


def test_a_record_that_names_a_frame_that_does_not_exist_is_a_dependency_finding() -> None:
    orphan = {"version": 2, "records": [{"id": "b9", "frame_id": "a404", "height_m": 1.0}]}
    result = translate(document(synthetic_b=orphan), ALL)

    assert [(f.code, f.object_id) for f in result.findings] == [("dependency.unavailable", "b9")]


def test_a_section_reaches_only_the_requirements_it_declared() -> None:
    inputs = Inputs((), {"synthetic.a": {"a1": Frame("a1", 1.0)}})
    with pytest.raises(LookupError, match="not a declared requirement"):
        inputs.get(FRAMES, "a1")


def test_a_translate_returning_the_wrong_type_is_a_translator_defect() -> None:
    class Wrong(SectionA):
        def translate(self, record: Any, inputs: Inputs) -> Any:
            return "frame"

    with pytest.raises(TypeError, match="produced str, not Frame"):
        translate(document(synthetic_b=None, synthetic_c=None), (Wrong(),))


def test_the_result_document_names_every_object_and_the_sections_own_fields() -> None:
    bad_a = {"version": 1, "records": [{"id": "a1", "width_m": 0}, {"id": "a2", "width_m": 3.0}]}
    doc = translate(document(synthetic_a=bad_a), ALL).to_document()

    assert doc["state"] == "complete_with_findings" and doc["run_id"] == "run-1"
    assert doc["summary"] == {"objects": 3, "unavailable": 2, "findings": 2, "publishable": False}
    assert doc["sections"][0] == {"id": "synthetic.a", "objects": ["a2"], "unavailable": ["a1"]}  # type: ignore[index]
    assert doc["synthetic.b"] == {"synthetic_panels": {"count": 1, "area_m2": 3.0}}
    assert "synthetic.a" not in doc, "a section with no fields has no key"
    assert doc["failure"] is None


def test_a_section_with_fields_may_not_take_a_shell_field_as_its_id() -> None:
    class Greedy(SectionC):
        id = "state"

        def result_fields(self, objects: Mapping[str, Tag]) -> Mapping[str, Any]:
            return {"value": "complete"}

    raw = {"schema_version": 1, "run_id": "run-1", "sections": {"state": {"version": 1, "records": []}}}
    with pytest.raises(ValueError, match="section id state is a result document field"):
        translate(raw, (Greedy(),))


def test_record_errors_raised_while_translating_are_object_failures() -> None:
    class Refuses(SectionC):
        def translate(self, record: Tag, inputs: Inputs) -> Tag:
            raise RecordError("refused")

    result = translate(document(synthetic_a=None, synthetic_b=None), (Refuses(),))
    assert [f.message for f in result.findings] == ["refused"]


@pytest.mark.parametrize("context", [None, "Face fac_A00000000001"])
def test_dependency_context_preserves_identity_and_legacy_message(context: str | None) -> None:
    from ph_composer_translation.sections import DependencyUnavailable

    class ContextPanel(SectionB):
        def translate(self, record: Any, inputs: Inputs) -> Panel:
            raise DependencyUnavailable("synthetic.a", "a1", context)

    result = translate(document(), (SectionA(), ContextPanel(), SectionC()))
    finding = next(f for f in result.findings if f.section == "synthetic.b")
    expected = "needs synthetic.a object a1, which did not translate"
    assert finding.message == (f"{context}: {expected}" if context else expected)
    assert finding.object_id == "b1" and finding.blocks_export
    assert result.results["synthetic.b"].unavailable == ["b1", "b2"]
