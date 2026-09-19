"""Every translation module imports without honeybee, ladybug or PHX (context/TECH_STACK.md). Each
module is imported in a fresh interpreter that refuses those packages."""

from __future__ import annotations

import importlib
import pkgutil
import subprocess
import sys
from pathlib import Path

import pytest

from ph_composer_translation import stack

PACKAGE = "ph_composer_translation"
SOURCE = Path(__file__).resolve().parents[2] / "src" / "ph_composer" / "python"

CHILD = """
import importlib, sys

BLOCKED = {blocked!r}

class Blocker:
    def find_spec(self, name, path=None, target=None):
        if name.split(".")[0] in BLOCKED:
            raise ImportError("blocked: " + name)
        return None

sys.meta_path.insert(0, Blocker())
importlib.import_module({module!r})
loaded = sorted(name for name in sys.modules if name.split(".")[0] in BLOCKED)
assert not loaded, loaded
"""


def module_names() -> list[str]:
    package = importlib.import_module(PACKAGE)
    return [PACKAGE, *sorted(name for _, name, _ in pkgutil.walk_packages(package.__path__, PACKAGE + "."))]


@pytest.mark.parametrize("module", module_names())
def test_the_module_imports_without_the_stack(module: str) -> None:
    script = CHILD.format(blocked=sorted(stack.PACKAGES), module=module)
    completed = subprocess.run([sys.executable, "-c", script], cwd=SOURCE, capture_output=True, text=True, check=False)
    assert completed.returncode == 0, completed.stderr


def test_the_stack_seam_names_what_this_runtime_lacks() -> None:
    with pytest.raises(stack.StackUnavailable, match=r"honeybee\.model is not installed"):
        stack.load("honeybee.model")


def test_the_stack_seam_serves_only_the_stack() -> None:
    with pytest.raises(ValueError, match="json is not served"):
        stack.load("json")
