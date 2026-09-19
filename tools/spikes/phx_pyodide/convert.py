"""The B1 conversion, shared by the native reference run and the Pyodide run: HBJSON text in, METr JSON text out."""

import json
import sys
import time
from pathlib import Path


def convert(hbjson_text: str) -> dict:
    started = time.perf_counter()
    from PHX.from_HBJSON import create_project, read_HBJSON_file
    from PHX.to_METr_JSON import metr_builder

    imported = time.perf_counter()
    hb_model = read_HBJSON_file.convert_hbjson_dict_to_hb_model(json.loads(hbjson_text))
    project = create_project.convert_hb_model_to_PhxProject(hb_model)
    metr_text = metr_builder.generate_metr_json_text(project)
    done = time.perf_counter()
    heavy = sorted(
        {m.split(".")[0] for m in sys.modules} & {"xlwings", "pydantic", "lxml", "rich", "openpyxl", "numpy"}
    )
    return {
        "metr_text": metr_text,
        "import_ms": round((imported - started) * 1000, 1),
        "convert_ms": round((done - imported) * 1000, 1),
        "heavy_modules": heavy,
        "python": sys.version.split()[0],
    }


def summary(metr_text: str) -> dict:
    """What the comparison checks: Room identities and counts, representative geometry and construction values."""
    data = json.loads(metr_text)

    def walk(node, path=""):
        if isinstance(node, dict):
            for key, value in node.items():
                yield from walk(value, f"{path}.{key}")
        elif isinstance(node, list):
            for value in node:
                yield from walk(value, f"{path}[]")
        else:
            yield path, node

    leaves = list(walk(data))
    return {
        "top_keys": sorted(data) if isinstance(data, dict) else type(data).__name__,
        "leaf_count": len(leaves),
        "strings_with_b1": sorted({v for _, v in leaves if isinstance(v, str) and "b1_" in v}),
    }


_first: dict = {}


def run_first(hbjson_text: str) -> str:
    """The Pyodide page's first call: imports and converts, and keeps the result for `run_warm`."""
    _first.update(convert(hbjson_text))
    return json.dumps(_first)


def run_warm(hbjson_text: str) -> str:
    started = time.perf_counter()
    again = convert(hbjson_text)
    warm_ms = round((time.perf_counter() - started) * 1000, 1)
    return json.dumps({"warm_ms": warm_ms, "same_as_first": again["metr_text"] == _first["metr_text"]})


if __name__ == "__main__":
    source, target = Path(sys.argv[1]), Path(sys.argv[2])
    result = convert(source.read_text())
    target.write_text(result.pop("metr_text"))
    print(json.dumps(result))
