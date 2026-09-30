"""The sections and exporters this build carries, listed by hand like the Ruby composition root.

A feature that translates adds its section here; a new exporter adds its registration. Nothing else in
the package changes. The foundation carries neither.
"""

from __future__ import annotations

from typing import Any

from .exporters import Exporter
from .model_sections import FaceSection, ZoneSection
from .sections import Section

SECTIONS: tuple[Section[Any, Any], ...] = (FaceSection(), ZoneSection())
EXPORTERS: tuple[Exporter, ...] = ()
