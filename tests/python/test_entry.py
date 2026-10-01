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


def test_the_product_build_lists_authored_report_face_zone_sections_and_no_exporter() -> None:
    assert [section.id for section in SECTIONS] == [
        "ph_composer.assemblies.export.constructions",
        "ph_composer.assemblies.export.material_sources",
        "ph_composer.zones.faces.export.faces",
        "ph_composer.zones.export.zones",
    ]
    assert EXPORTERS == ()
    empty = {"schema_version": 1, "run_id": "run-0", "sections": {}}
    result = json.loads(translate_json(json.dumps(empty)))
    assert result["state"] == "failed" and result["failure"]["code"] == "payload.contract"
