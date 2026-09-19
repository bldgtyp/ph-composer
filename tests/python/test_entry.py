"""The runtime page's call: JSON text in, a result document out, never an exception for bad input."""

from __future__ import annotations

import json

from ph_composer_translation.composition import EXPORTERS, SECTIONS
from ph_composer_translation.entry import translate_json
from synthetic_sections import SectionA, SectionB, SectionC, document


def test_text_that_is_not_json_is_a_contract_failure() -> None:
    result = json.loads(translate_json("{"))
    assert result["state"] == "failed"
    assert result["failure"]["stage"] == "reading" and result["failure"]["code"] == "payload.contract"


def test_a_document_translates_with_the_given_sections() -> None:
    result = json.loads(translate_json(json.dumps(document()), (SectionA(), SectionB(), SectionC())))
    assert result["state"] == "complete" and result["summary"]["objects"] == 5


def test_the_foundation_build_carries_no_section_or_exporter() -> None:
    assert SECTIONS == () and EXPORTERS == ()
    empty = {"schema_version": 1, "run_id": "run-0", "sections": {}}
    assert json.loads(translate_json(json.dumps(empty)))["state"] == "complete"
