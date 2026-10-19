"""The call the runtime page makes: extraction JSON text in, result document JSON text out."""

from __future__ import annotations

import json
from collections.abc import Sequence
from typing import Any

from .composition import SECTIONS
from .coordinator import translate
from .result import Failure, Translation
from .sections import Section


def translate_json(text: str, sections: Sequence[Section[Any, Any]] = SECTIONS) -> str:
    """Never raises for an unreadable document: the result says `failed` with `payload.contract`."""
    try:
        document = json.loads(text)
    except ValueError as error:
        translation = Translation(run_id="", failure=Failure("reading", "payload.contract", f"not JSON: {error}"))
        return json.dumps(translation.to_document())
    return json.dumps(translate(document, sections).to_document())


def probe_json(text: str) -> str:
    """Exercise the contract shell without loading feature stacks or their wheels."""
    return translate_json(text, ())


def export_json(text: str, sections: Sequence[Section[Any, Any]] = SECTIONS) -> str:
    """Translate, then reload and reconcile the exact canonical bytes before returning them."""
    result = json.loads(translate_json(text, sections))
    canonical = result.get("canonical_model")
    if not result["summary"]["publishable"] or canonical is None:
        return json.dumps(result)
    from .conformance import ConformanceError, check

    try:
        check(canonical, result, sections)
    except ValueError as error:
        raise ConformanceError(str(error)) from error
    return json.dumps(result)
