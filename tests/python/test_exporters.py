"""Exporters consume the canonical HBJSON and explicit options, and nothing else (C6)."""

from __future__ import annotations

import json
from collections.abc import Mapping

import pytest

from ph_composer_translation.contract import JSONValue
from ph_composer_translation.exporters import Exporter, ExporterOutput, by_name, run_exporter

HBJSON = json.dumps({"type": "Model", "identifier": "synthetic", "units": "Meters", "rooms": []})


class Recorder:
    """A test-only exporter that keeps what it was given."""

    def __init__(self) -> None:
        self.calls: list[tuple[object, ...]] = []

    def __call__(self, hbjson: str, options: Mapping[str, JSONValue]) -> ExporterOutput:
        self.calls.append((hbjson, options))
        assert isinstance(options, dict)
        options["precision"] = 99  # Must not leak back to the caller.
        return ExporterOutput(b"synthetic output", ("one finding",))


def exporter(run: Recorder) -> Exporter:
    return Exporter("synthetic", "Synthetic text", ".syn.txt", run, frozenset({"precision"}))


def test_an_exporter_receives_the_hbjson_and_a_copy_of_the_options_alone() -> None:
    recorder = Recorder()
    options: dict[str, JSONValue] = {"precision": 3}

    output = run_exporter(exporter(recorder), HBJSON, options)

    assert recorder.calls == [(HBJSON, {"precision": 99})]
    assert options == {"precision": 3}
    assert output == ExporterOutput(b"synthetic output", ("one finding",))


def test_an_option_the_exporter_does_not_accept_is_refused_before_it_runs() -> None:
    recorder = Recorder()
    with pytest.raises(ValueError, match="does not accept options: path"):
        run_exporter(exporter(recorder), HBJSON, {"path": "/tmp/x"})
    assert recorder.calls == []


def test_the_input_must_be_json() -> None:
    with pytest.raises(ValueError):
        run_exporter(exporter(Recorder()), "not json", {})


def test_an_exporter_must_return_its_output_type() -> None:
    wrong = Exporter("wrong", "Wrong", ".txt", lambda hbjson, options: b"bytes")  # type: ignore[arg-type,return-value]
    with pytest.raises(TypeError, match="not ExporterOutput"):
        run_exporter(wrong, HBJSON, {})


def test_exporter_names_are_unique() -> None:
    first = exporter(Recorder())
    assert by_name([first]) == {"synthetic": first}
    with pytest.raises(ValueError, match="two exporters are named synthetic"):
        by_name([first, exporter(Recorder())])
