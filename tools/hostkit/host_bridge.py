# /// script
# requires-python = ">=3.11"
# ///
"""Drive the real SketchUp host from a terminal through the development bridge.

The bridge (tools/hostkit/host_bridge.rb, installed with `make bridge-install`) evaluates Ruby inside
the running SketchUp on the main thread. This client wraps it with the lifecycle steps that need
care on macOS: launching with one document, quitting without a save dialog, saving past the Purge
Unused prompt, and waiting for deferred work.

    uv run tools/hostkit/host_bridge.py launch <model.skp> [--fresh-from <accepted.skp>]
    uv run tools/hostkit/host_bridge.py eval 'PhComposerHost.state'
    uv run tools/hostkit/host_bridge.py eval --file scenario.rb
    uv run tools/hostkit/host_bridge.py state
    uv run tools/hostkit/host_bridge.py save
    uv run tools/hostkit/host_bridge.py shot <name> --dir <evidence-dir>
    uv run tools/hostkit/host_bridge.py key 53            # Escape, through System Events
    uv run tools/hostkit/host_bridge.py console --tail 40  # what the Ruby Console showed
    uv run tools/hostkit/host_bridge.py quit

`eval` prints captured stdout, then the result (JSON when the value serializes, else `inspect`).
Exit status 1 on a Ruby error, 2 when the bridge is unreachable.
"""

from __future__ import annotations

import argparse
import json
import os
import signal
import socket
import subprocess
import sys
import time
from collections.abc import Callable
from pathlib import Path
from typing import Any

SUPPORT = Path.home() / "Library" / "Application Support"
APP = Path("/Applications/SketchUp {version}/SketchUp.app")
HELPERS = Path(__file__).resolve().parent / "host_helpers.rb"
ESCAPE_KEY_CODE = 53


class BridgeError(RuntimeError):
    pass


# ----------------------------------------------------------------------------- transport


def state_path(version: str) -> Path:
    return SUPPORT / f"SketchUp {version}" / "SketchUp" / "ph_composer_host_bridge.json"


def read_state(version: str) -> dict[str, Any] | None:
    path = state_path(version)
    if not path.is_file():
        return None
    state = json.loads(path.read_text())
    try:
        os.kill(int(state["pid"]), 0)
    except (OSError, ValueError):
        return None
    return state


def request(state: dict[str, Any], payload: dict[str, Any], timeout: float) -> dict[str, Any]:
    payload = dict(payload, token=state["token"])
    with socket.create_connection(("127.0.0.1", int(state["port"])), timeout=timeout) as sock:
        sock.sendall((json.dumps(payload) + "\n").encode("utf-8"))
        chunks: list[bytes] = []
        while True:
            chunk = sock.recv(65536)
            if not chunk:
                break
            chunks.append(chunk)
    line = b"".join(chunks).decode("utf-8").strip()
    if not line:
        raise ConnectionError("empty reply from the bridge")
    return json.loads(line)


def wait(version: str, timeout: float) -> dict[str, Any]:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        state = read_state(version)
        if state is not None:
            try:
                answer = request(state, {"ping": True}, timeout=5.0)
                if answer.get("ok"):
                    return state
            except OSError:
                pass
        time.sleep(1.0)
    raise TimeoutError(f"no host bridge within {timeout:.0f}s")


def reply(version: str, code: str, timeout: float = 300.0) -> dict[str, Any]:
    """Send Ruby to the live bridge and return its whole reply document, error replies included.
    The `eval` command needs the document (stdout, backtrace, ok); `evaluate` needs the value."""
    state = read_state(version)
    if state is None:
        raise BridgeError("host bridge is not running (no live state file)")
    return request(state, {"code": code}, timeout=timeout)


def evaluate(version: str, code: str, timeout: float = 300.0) -> Any:
    """Evaluate Ruby and return its JSON value (or `inspect` text). Raises BridgeError on a Ruby error."""
    answer = reply(version, code, timeout=timeout)
    if not answer.get("ok"):
        trace = "\n  ".join(answer.get("backtrace", [])[:6])
        raise BridgeError(f"{answer.get('error')}\n  {trace}".rstrip())
    value = answer.get("value")
    return value if value is not None else answer.get("result")


def evaluate_in_background(version: str, code: str) -> subprocess.Popen[bytes]:
    """Start an eval in a child process so this process can dismiss a dialog it triggers."""
    return subprocess.Popen(
        [sys.executable, str(Path(__file__).resolve()), "--sketchup-version", version, "eval", code],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


# ----------------------------------------------------------------------------- macOS control


def sketchup_running() -> bool:
    return subprocess.run(["pgrep", "-x", "SketchUp"], capture_output=True, check=False).returncode == 0


def send_key(key_code: int) -> None:
    """Send a key to SketchUp through System Events (needs Accessibility for the terminal app)."""
    subprocess.run(
        [
            "osascript",
            "-e",
            f'tell application "System Events" to tell process "SketchUp" to key code {key_code}',
        ],
        capture_output=True,
        check=False,
        timeout=15,
    )


def run_with_dialog_guard(version: str, code: str, timeout: float = 120.0, escape_after: float = 3.0) -> str:
    """Run `code`; if the reply has not returned after `escape_after` seconds, send Escape to
    dismiss a modal dialog (the SketchUp 2026 Purge Unused prompt on save) and keep waiting."""
    child = evaluate_in_background(version, code)
    started = time.monotonic()
    while child.poll() is None:
        time.sleep(1.0)
        if time.monotonic() - started > escape_after:
            send_key(ESCAPE_KEY_CODE)
        if time.monotonic() - started > timeout:
            child.kill()
            raise BridgeError("the guarded eval did not return; a dialog may still be open in SketchUp")
    out, err = child.communicate()
    if child.returncode != 0:
        raise BridgeError(err.decode("utf-8", "replace").strip() or out.decode("utf-8", "replace"))
    return out.decode("utf-8", "replace").strip()


def quit_sketchup(version: str) -> str:
    """Quit without a save dialog: discard-save a modified Model to a scratch path, then terminate."""
    if not sketchup_running():
        return "SketchUp not running"
    state = read_state(version)
    if state is not None:
        try:
            run_with_dialog_guard(
                version,
                'm = Sketchup.active_model; m.save("/private/tmp/ph_composer_discard.skp") if m.modified?; :ok',
                timeout=60.0,
            )
            request(state, {"code": 'Sketchup.send_action("terminate:")'}, timeout=10.0)
        except (BridgeError, OSError, TimeoutError):
            pass
    for _ in range(30):
        if not sketchup_running():
            Path("/private/tmp/ph_composer_discard.skp").unlink(missing_ok=True)
            return "SketchUp quit cleanly"
        time.sleep(1.0)
    subprocess.run(["pkill", "-9", "-x", "SketchUp"], capture_output=True, check=False)
    return "SketchUp did not quit within 30s; killed (its documents may be restored on the next launch)"


def launch(version: str, model: Path, fresh_from: Path | None, timeout: float) -> dict[str, Any]:
    """Quit any running SketchUp, open `model` as the only document, wait for the bridge, load helpers."""
    if fresh_from is not None:
        model.write_bytes(fresh_from.read_bytes())
    print(quit_sketchup(version))
    for _ in range(20):
        if not sketchup_running():
            break
        time.sleep(1.0)
    state_path(version).unlink(missing_ok=True)
    app = Path(str(APP).format(version=version))
    for _attempt in range(5):
        done = subprocess.run(["open", "-a", str(app), str(model)], capture_output=True, check=False)
        if done.returncode == 0:
            break
        time.sleep(3.0)
    else:
        raise BridgeError(f"could not open {model} with {app}")
    state = wait(version, timeout)
    evaluate(version, f"load {json.dumps(str(HELPERS))}")
    opened = evaluate(version, "File.basename(Sketchup.active_model.path.to_s)")
    if opened != model.name:
        raise BridgeError(f"SketchUp restored another document ({opened}); quit cleanly and launch again")
    return state


def save(version: str) -> str:
    return run_with_dialog_guard(version, "Sketchup.active_model.save; :saved")


def tail(path: Path, lines: int) -> str:
    if not path.is_file():
        return f"(no file at {path})"
    return "\n".join(path.read_text(errors="replace").splitlines()[-lines:])


# ----------------------------------------------------------------------------- commands

# One entry per command: how it extends the subparser, and what it does. A new command is one
# entry, not another branch in a chain that had grown to 82 lines and a second copy of `evaluate`.


def takes_nothing(parser: argparse.ArgumentParser) -> None:
    pass


def run_wait(args: argparse.Namespace, version: str) -> None:
    state = wait(version, args.timeout)
    print(f"bridge ready on port {state['port']} (pid {state['pid']})")


def run_ping(args: argparse.Namespace, version: str) -> None:
    print(evaluate(version, ":pong"))


def run_quit(args: argparse.Namespace, version: str) -> None:
    print(quit_sketchup(version))


def configure_launch(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("model")
    parser.add_argument("--fresh-from")


def run_launch(args: argparse.Namespace, version: str) -> None:
    state = launch(
        version,
        Path(args.model).resolve(),
        Path(args.fresh_from).resolve() if args.fresh_from else None,
        min(args.timeout, 180.0),
    )
    print(f"launched {args.model}; bridge on port {state['port']} (pid {state['pid']}); helpers loaded")


def configure_eval(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("code", nargs="?")
    parser.add_argument("--file")
    parser.add_argument("--json", action="store_true")


def run_eval(args: argparse.Namespace, version: str) -> int:
    code = Path(args.file).read_text() if args.file else args.code
    if code is None:
        raise BridgeError("eval needs code or --file")
    answer = reply(version, code, timeout=args.timeout)
    if args.json:
        print(json.dumps(answer, indent=2))
        return 0 if answer.get("ok") else 1
    if answer.get("stdout"):
        text = answer["stdout"]
        sys.stdout.write(text if text.endswith("\n") else text + "\n")
    if not answer.get("ok"):
        print(f"ERROR {answer.get('error')}", file=sys.stderr)
        for line in answer.get("backtrace", []):
            print(f"  {line}", file=sys.stderr)
        return 1
    value = answer.get("value")
    print(json.dumps(value) if value is not None else answer.get("result"))
    return 0


def run_state(args: argparse.Namespace, version: str) -> None:
    print(json.dumps(evaluate(version, "PhComposerHost.state"), indent=2))


def run_save(args: argparse.Namespace, version: str) -> None:
    print(save(version))


def configure_shot(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("name")
    parser.add_argument("--dir", required=True)


def run_shot(args: argparse.Namespace, version: str) -> None:
    name = json.dumps(args.name)
    directory = json.dumps(str(Path(args.dir).resolve()))
    print(evaluate(version, f"PhComposerHost.shot({name}, {directory})"))


def configure_key(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("key_code", type=int)


def run_key(args: argparse.Namespace, version: str) -> None:
    send_key(args.key_code)
    print(f"sent key code {args.key_code} to SketchUp")


def configure_tail(default: int) -> Callable[[argparse.ArgumentParser], None]:
    def configure(parser: argparse.ArgumentParser) -> None:
        parser.add_argument("--tail", type=int, default=default)

    return configure


def run_console(args: argparse.Namespace, version: str) -> None:
    state = read_state(version)
    path = (
        Path(state["console_log"])
        if state and state.get("console_log")
        else state_path(version).with_suffix(".console.log")
    )
    print(tail(path, args.tail))


COMMANDS: dict[str, tuple[Callable[[argparse.ArgumentParser], None], Callable[..., Any]]] = {
    "wait": (takes_nothing, run_wait),
    "ping": (takes_nothing, run_ping),
    "quit": (takes_nothing, run_quit),
    "launch": (configure_launch, run_launch),
    "eval": (configure_eval, run_eval),
    "state": (takes_nothing, run_state),
    "save": (takes_nothing, run_save),
    "shot": (configure_shot, run_shot),
    "key": (configure_key, run_key),
    "console": (configure_tail(40), run_console),
}


# ----------------------------------------------------------------------------- CLI


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--sketchup-version", default="2026")
    parser.add_argument("--timeout", type=float, default=300.0, help="seconds to wait for a reply or a completion")
    sub = parser.add_subparsers(dest="command", required=True)
    for name, (configure, _run) in COMMANDS.items():
        configure(sub.add_parser(name))
    args = parser.parse_args()

    try:
        return COMMANDS[args.command][1](args, args.sketchup_version) or 0
    except BridgeError as error:
        print(f"ERROR {error}", file=sys.stderr)
        return 1
    except (OSError, TimeoutError) as error:
        print(f"host bridge unreachable: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    sys.exit(main())
