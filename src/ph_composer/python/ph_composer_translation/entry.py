"""The call the runtime page makes: extraction JSON text in, result document JSON text out."""

from __future__ import annotations

import json
import traceback
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


PACKAGE = "/ph_composer_translation/"
MAX_FRAMES = 20


def export_report_json(text: str, sections: Sequence[Section[Any, Any]] = SECTIONS) -> str:
    """What the runtime page sends on: `{"result": ...}`, or `{"failure": ...}` built from the exception's
    class and traceback, never its message, which can carry Model content."""
    try:
        return json.dumps({"result": json.loads(export_json(text, sections))})
    except Exception as error:  # noqa: BLE001 - every failure is reported, by class and frames only
        return json.dumps({"failure": failure_report(error)})


def failure_report(error: BaseException) -> dict[str, Any]:
    """Where a failure stopped, its class, and this package's own frames, innermost first."""
    from .conformance import ConformanceError

    frames: list[dict[str, Any]] = []
    chain: BaseException | None = error
    while chain is not None and len(frames) < MAX_FRAMES:
        for frame in reversed(traceback.extract_tb(chain.__traceback__)):
            if PACKAGE in frame.filename:
                relative = "ph_composer_translation/" + frame.filename.split(PACKAGE, 1)[1]
                frames.append({"file": relative, "line": frame.lineno or 0, "method": frame.name})
        chain = chain.__cause__
    stage = "conformance" if isinstance(error, ConformanceError) else "translation"
    return {"stage": stage, "error_class": type(error).__name__, "frames": frames[:MAX_FRAMES]}
