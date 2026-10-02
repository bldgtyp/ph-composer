"""Source attribution is an allowlisted report record, including unassigned local copies."""

from __future__ import annotations

import pytest

from ph_composer_translation.contract import RecordError
from ph_composer_translation.material_sources import MaterialSource, MaterialSourcesSection
from ph_composer_translation.sections import Inputs


def test_report_projection_omits_snapshot_private_configuration_and_unknown_fields() -> None:
    raw = {
        "id": "mat_000000000001",
        "name": "<Synthetic>",
        "provider_kind": "example.file",
        "library_id": "synthetic",
        "record_id": "one",
        "private_path": "/private/fixture.json",
        "snapshot": {"notes": "local"},
    }
    section = MaterialSourcesSection()
    typed = section.read(raw)
    assert section.translate(typed, Inputs((), {})) is typed
    fields = section.result_fields({typed.id: typed})
    assert fields == {"material_sources": [dict(list(raw.items())[:5])]}
    assert not section.required_for_export
    assert not section.requires


@pytest.mark.parametrize("key", ["id", "name", "provider_kind", "library_id", "record_id"])
def test_missing_required_attribution_is_unavailable_instead_of_invented(key: str) -> None:
    raw = {field: "synthetic" for field in MaterialSource.__dataclass_fields__}
    del raw[key]
    with pytest.raises(RecordError):
        MaterialSourcesSection().read(raw)
