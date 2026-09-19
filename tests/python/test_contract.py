"""The readers every record is built through: a wrong type is named at the edge."""

from __future__ import annotations

import math

import pytest

from ph_composer_translation.contract import RecordError, as_number, as_text


@pytest.mark.parametrize("value", [True, None, "1.5", math.nan, math.inf, [1]])
def test_only_a_finite_json_number_is_a_number(value: object) -> None:
    with pytest.raises(RecordError, match="length must be a finite number"):
        as_number(value, "length")


def test_integers_and_floats_read_as_floats() -> None:
    assert as_number(2, "n") == 2.0 and isinstance(as_number(2, "n"), float)


@pytest.mark.parametrize("value", ["", "   ", None, 3])
def test_blank_or_missing_text_is_refused(value: object) -> None:
    with pytest.raises(RecordError, match="label must be non-empty text"):
        as_text(value, "label")


def test_text_is_trimmed() -> None:
    assert as_text("  Sill ", "label") == "Sill"
