"""Exporters: a second consumer of the canonical HBJSON (context/TECH_STACK.md, "The exporter seam").

An exporter receives the HBJSON text and the user's explicit options, and nothing else: not the
extraction, not the result document, not the Model. It returns one output and its own findings.
"""

from __future__ import annotations

import copy
import json
from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass, field

from .contract import JSONValue


@dataclass(frozen=True)
class ExporterOutput:
    content: bytes
    findings: tuple[str, ...] = ()


@dataclass(frozen=True)
class Exporter:
    """`run(hbjson, options)` writes one file of `format`, named with `suffix`."""

    name: str
    format: str
    suffix: str
    run: Callable[[str, Mapping[str, JSONValue]], ExporterOutput]
    #: Option names the exporter accepts; anything else is refused before it runs.
    options: frozenset[str] = field(default_factory=frozenset)


def run_exporter(exporter: Exporter, hbjson: str, options: Mapping[str, JSONValue]) -> ExporterOutput:
    """Runs one exporter on a copy of its inputs, so it cannot change what the next exporter sees."""
    if unknown := sorted(set(options) - exporter.options):
        raise ValueError(f"{exporter.name} does not accept options: {', '.join(unknown)}")
    json.loads(hbjson)  # The canonical artifact is JSON; anything else is a caller defect.
    output = exporter.run(hbjson, copy.deepcopy(dict(options)))
    if not isinstance(output, ExporterOutput):
        raise TypeError(f"{exporter.name} returned {type(output).__name__}, not ExporterOutput")
    return output


def by_name(exporters: Sequence[Exporter]) -> dict[str, Exporter]:
    named: dict[str, Exporter] = {}
    for exporter in exporters:
        if exporter.name in named:
            raise ValueError(f"two exporters are named {exporter.name}")
        named[exporter.name] = exporter
    return named
