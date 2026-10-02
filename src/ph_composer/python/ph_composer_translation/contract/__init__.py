"""The JSON seam. Every value from the extraction is read through these, so a wrong type is found at the
edge and named, never deep inside a translation."""

from __future__ import annotations

import math
from typing import TypeAlias

JSONValue: TypeAlias = bool | int | float | str | list["JSONValue"] | dict[str, "JSONValue"] | None
JSONObject: TypeAlias = dict[str, JSONValue]


class ContractError(Exception):
    """The document, or a whole section of it, cannot be read. The run stops before any translation.

    `code` is one of the translation codes in context/CONTRACTS.md, "Outcomes and codes".
    """

    def __init__(self, code: str, detail: str) -> None:
        super().__init__(detail)
        self.code = code
        self.detail = detail


class RecordError(Exception):
    """One record cannot be read or translated. It costs that record only; the rest continue."""


def as_text(value: object, label: str) -> str:
    """A non-empty string. Blank and whitespace-only are both missing."""
    if not isinstance(value, str) or not value.strip():
        raise RecordError(f"{label} must be non-empty text")
    return value.strip()


def as_number(value: object, label: str) -> float:
    """A finite JSON number. A boolean is not a number, and a numeric string is a misread upstream."""
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
        raise RecordError(f"{label} must be a finite number")
    return float(value)
