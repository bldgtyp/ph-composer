"""Exercise the bridge client's transport and dialog guard without SketchUp, a port or a clock.

The client is what every host gate runs through, so a defect here reads as a host defect. The
socket, the child process, System Events and the clock are all replaced: what is under test is
the client's own decisions, not the machine it usually talks to.
"""

from __future__ import annotations

import contextlib
import json
import os
import shutil
import socket
import subprocess
import threading
import time
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import ClassVar, Self
from unittest.mock import patch

import host_bridge as hb


class FakeSocket:
    """A connection that answers once, in as many chunks as the test asks for."""

    def __init__(self, chunks: list[bytes]) -> None:
        self.chunks = list(chunks)
        self.sent = b""

    def __enter__(self) -> Self:
        return self

    def __exit__(self, *_exception: object) -> None:
        self.chunks = []

    def sendall(self, payload: bytes) -> None:
        self.sent += payload

    def settimeout(self, _seconds: float) -> None:
        pass

    def recv(self, _size: int) -> bytes:
        return self.chunks.pop(0) if self.chunks else b""


class FakeChild:
    """A child process that stays alive for `alive_polls` polls, then exits with `returncode`."""

    def __init__(self, alive_polls: int, returncode: int = 0, out: bytes = b"saved\n") -> None:
        self.alive_polls = alive_polls
        self.returncode = returncode
        self.out = out
        self.killed = False

    def poll(self) -> int | None:
        if self.alive_polls > 0:
            self.alive_polls -= 1
            return None
        return self.returncode

    def communicate(self) -> tuple[bytes, bytes]:
        return self.out, b""

    def kill(self) -> None:
        self.killed = True


class FakeClock:
    """A clock that only advances when the code under test sleeps."""

    def __init__(self) -> None:
        self.now = 1000.0

    def monotonic(self) -> float:
        return self.now

    def sleep(self, seconds: float) -> None:
        self.now += seconds


class ReadStateTest(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        support = Path(self.directory.name)
        patcher = patch.object(hb, "SUPPORT", support)
        patcher.start()
        self.addCleanup(patcher.stop)
        self.path = hb.state_path("2026")
        self.path.parent.mkdir(parents=True)

    def write_state(self, pid: int) -> None:
        self.path.write_text(json.dumps({"pid": pid, "port": 51000, "token": "t"}))

    def test_no_state_file_means_no_bridge(self) -> None:
        self.assertIsNone(hb.read_state("2026"))

    def test_a_state_file_for_a_dead_process_is_not_a_live_bridge(self) -> None:
        # The file outlives the process it describes: SketchUp can be killed, or crash, and the
        # client must not report a bridge that nothing is listening on.
        self.write_state(2_000_000_000)
        self.assertIsNone(hb.read_state("2026"))

    def test_a_state_file_for_a_live_process_is_returned(self) -> None:
        self.write_state(os.getpid())  # this process: alive, and signalable without privileges
        state = hb.read_state("2026")
        assert state is not None
        self.assertEqual(state["port"], 51000)


class RequestTest(unittest.TestCase):
    state: ClassVar[dict[str, object]] = {"pid": 1, "port": 51000, "token": "secret-token"}

    def send(self, chunks: list[bytes]) -> FakeSocket:
        sock = FakeSocket(chunks)
        with patch.object(hb.socket, "create_connection", return_value=sock):
            self.reply = hb.request(self.state, {"code": ":ok"}, timeout=5.0)
        return sock

    def test_the_token_is_added_and_one_newline_terminated_line_is_sent(self) -> None:
        sock = self.send([b'{"ok":true,"value":1}\n'])

        self.assertEqual(sock.sent.count(b"\n"), 1)
        self.assertEqual(json.loads(sock.sent.decode()), {"code": ":ok", "token": "secret-token"})
        self.assertEqual(self.reply, {"ok": True, "value": 1})

    def test_a_reply_split_across_chunks_is_reassembled(self) -> None:
        # The bridge answers with whole result documents, which run past one recv.
        self.send([b'{"ok":true,"val', b'ue":{"a":1}}', b"\n"])

        self.assertEqual(self.reply, {"ok": True, "value": {"a": 1}})

    def test_a_closed_connection_with_no_reply_is_an_error_not_an_empty_result(self) -> None:
        with self.assertRaises(ConnectionError):
            self.send([])


class EvaluateTest(unittest.TestCase):
    def test_without_a_live_state_file_evaluate_refuses_before_connecting(self) -> None:
        with patch.object(hb, "read_state", return_value=None), self.assertRaises(hb.BridgeError):
            hb.evaluate("2026", ":ok")

    def test_a_ruby_error_reply_becomes_a_bridge_error_carrying_the_backtrace(self) -> None:
        answer = {"ok": False, "error": "NoMethodError", "backtrace": ["a.rb:1", "b.rb:2"]}
        with patch.object(hb, "reply", return_value=answer), self.assertRaises(hb.BridgeError) as raised:
            hb.evaluate("2026", "nope")

        self.assertIn("NoMethodError", str(raised.exception))
        self.assertIn("a.rb:1", str(raised.exception))

    def test_inspect_text_is_returned_when_the_value_did_not_serialize(self) -> None:
        with patch.object(hb, "reply", return_value={"ok": True, "result": "#<Sketchup::Model>"}):
            self.assertEqual(hb.evaluate("2026", "m"), "#<Sketchup::Model>")


class WaitReadTest(unittest.TestCase):
    """A wait poll is one eval: a host error is a read failure, a missing bridge is a lost connection."""

    def test_a_ruby_error_reply_is_a_read_error_and_a_value_is_returned(self) -> None:
        read = hb.bridge_read("2026")
        with patch.object(hb, "read_state", return_value={"port": 1, "token": "t"}):
            with (
                patch.object(hb, "request", return_value={"ok": False, "error": "NameError"}),
                self.assertRaises(hb.host_wait.ReadError),
            ):
                read(":x", 1.0)
            with patch.object(hb, "request", return_value={"ok": True, "value": {"busy": None}}) as sent:
                self.assertEqual(read(":x", 2.5), {"busy": None})
        self.assertEqual(sent.call_args.kwargs["timeout"], 2.5, "the socket gets the wait's remaining budget")

    def test_no_live_bridge_is_a_connection_error(self) -> None:
        with patch.object(hb, "read_state", return_value=None), self.assertRaises(ConnectionError):
            hb.bridge_read("2026")(":x", 1.0)

    def test_a_malformed_state_file_or_truncated_reply_is_a_lost_bridge_not_a_crash(self) -> None:
        read = hb.bridge_read("2026")
        with (
            patch.object(hb, "read_state", side_effect=json.JSONDecodeError("partial", "{", 1)),
            self.assertRaises(ConnectionError),
        ):
            read(":x", 1.0)
        with (
            patch.object(hb, "read_state", return_value={"port": 1, "token": "t"}),
            patch.object(hb.socket, "create_connection", return_value=FakeSocket([b'{"ok":tr'])),
            self.assertRaises(ConnectionError),
        ):
            read(":x", 1.0)

    def test_a_whole_request_deadline_bounds_a_slow_multipart_reply(self) -> None:
        # A real loopback socket: the reply arrives in three parts 200 ms apart, so each recv alone would
        # fit a 300 ms per-operation timeout while the request as a whole does not.
        server = socket.socket()
        server.bind(("127.0.0.1", 0))
        server.listen(1)

        def answer() -> None:
            connection, _address = server.accept()
            with connection:
                connection.recv(65536)
                for part in (b'{"ok":true,', b'"value":1', b"}\n"):
                    time.sleep(0.2)
                    with contextlib.suppress(OSError):  # the client has given up by the last part
                        connection.sendall(part)

        thread = threading.Thread(target=answer, daemon=True)
        thread.start()
        state = {"port": server.getsockname()[1], "token": "t"}
        started = time.monotonic()
        with self.assertRaises(TimeoutError):
            hb.request(state, {"code": ":x"}, timeout=0.3, whole=True)
        self.assertLess(time.monotonic() - started, 0.45)
        thread.join(2)
        server.close()


class DialogGuardTest(unittest.TestCase):
    """The guard exists because SketchUp's Purge Unused prompt blocks the save it was asked for."""

    def guard(self, child: FakeChild, **options: float) -> tuple[str, list[int], FakeChild]:
        clock = FakeClock()
        keys: list[int] = []
        with (
            patch.object(hb, "evaluate_in_background", return_value=child),
            patch.object(hb, "send_key", side_effect=keys.append),
            patch.object(hb.time, "monotonic", clock.monotonic),
            patch.object(hb.time, "sleep", clock.sleep),
        ):
            return hb.run_with_dialog_guard("2026", ":ok", **options), keys, child

    def test_a_reply_within_escape_after_never_sends_a_key(self) -> None:
        out, keys, _ = self.guard(FakeChild(alive_polls=2))

        self.assertEqual(out, "saved")
        self.assertEqual(keys, [])

    def test_escape_goes_to_sketchup_once_per_second_after_the_grace_period(self) -> None:
        _out, keys, _ = self.guard(FakeChild(alive_polls=6), escape_after=3.0)

        # Polls at 1s to 6s: the first three are inside the grace period, the last three are not.
        self.assertEqual(keys, [hb.ESCAPE_KEY_CODE] * 3)

    def test_a_child_that_never_returns_is_killed_and_reported_as_an_open_dialog(self) -> None:
        child = FakeChild(alive_polls=100)
        with self.assertRaises(hb.BridgeError) as raised:
            self.guard(child, timeout=10.0)

        self.assertTrue(child.killed)
        self.assertIn("dialog may still be open", str(raised.exception))

    def test_a_failed_child_reports_its_own_error_rather_than_a_guard_timeout(self) -> None:
        with self.assertRaises(hb.BridgeError) as raised:
            self.guard(FakeChild(alive_polls=1, returncode=1, out=b"ERROR RuntimeError\n"))

        self.assertIn("RuntimeError", str(raised.exception))


class QuitTest(unittest.TestCase):
    """Every open document is closed clean before terminate, and no document still means a clean quit."""

    def quit_with(self, replies: list[object]) -> tuple[str, list[str]]:
        calls: list[str] = []
        answers = iter(replies)

        def guard(_version: str, code: str, **_options: float) -> str:
            calls.append(code)
            answer = next(answers)
            if isinstance(answer, Exception):
                raise answer
            return f"console line mentioning none\n{answer}\n"

        running = iter([True, False])
        with (
            patch.object(hb, "sketchup_running", side_effect=lambda: next(running)),
            patch.object(hb, "read_state", return_value={"port": 1, "token": "t"}),
            patch.object(hb, "run_with_dialog_guard", side_effect=guard),
            patch.object(hb, "evaluate", return_value="another-document"),
            patch.object(hb, "request", side_effect=lambda _state, payload, **_kw: calls.append(payload["code"])),
            patch.object(hb.time, "sleep"),
        ):
            return hb.quit_sketchup("2026"), calls

    def test_each_open_document_is_closed_until_none_is_left_then_terminate(self) -> None:
        outcome, calls = self.quit_with(['"phc_closed:g1"', '"phc_closed:g2"', '"phc_no_document"'])
        self.assertEqual(outcome, "SketchUp quit cleanly (closed 2 documents)")
        self.assertIn(hb.DISCARD_PATH.format(index=1), calls[1], "each document saves to its own scratch path")
        self.assertEqual(calls[-1], 'Sketchup.send_action("terminate:")')

    def test_a_failed_or_refused_close_step_is_reported_and_still_terminates(self) -> None:
        outcome, calls = self.quit_with([hb.BridgeError("the close step failed")])
        self.assertEqual(
            outcome, "SketchUp quit cleanly (closed 0 documents; the close step failed: the close step failed)"
        )
        self.assertEqual(calls[-1], 'Sketchup.send_action("terminate:")')
        outcome, _calls = self.quit_with(['"phc_still_dirty"'])
        self.assertIn("still modified after its save", outcome)

    @unittest.skipUnless(shutil.which("ruby"), "needs a ruby to run the close step")
    def test_the_close_step_saves_closes_a_clean_model_refuses_a_dirty_one_and_tolerates_none(self) -> None:
        stub = (
            "class M; def initialize(dirty); @dirty = dirty; end; def modified?; @dirty; end; "
            'def guid; "G"; end; def save(path); $saved = path; true; end; end; '
            "module Sketchup; def self.active_model; $model; end; "
            "def self.send_action(action); $action = action; true; end; end; "
        )
        code = hb.CLOSE_ACTIVE.replace("{path}", "/private/tmp/x.skp")
        cases = (
            ("nil", [":phc_no_document", "nil", "nil"]),
            ("M.new(false)", ['"phc_closed:G"', '"/private/tmp/x.skp"', '"performClose:"']),
            ("M.new(true)", [":phc_still_dirty", '"/private/tmp/x.skp"', "nil"]),
        )
        for model, expected in cases:
            script = f"{stub}$model = {model}; value = ({code}); puts value.inspect, $saved.inspect, $action.inspect"
            result = subprocess.run(["ruby", "-e", script], capture_output=True, text=True, check=True)
            self.assertEqual(result.stdout.split(), expected, model)


class LaunchTest(unittest.TestCase):
    def launch(self, model: Path, wait: object) -> None:
        with (
            patch.object(hb, "quit_sketchup", return_value="SketchUp not running"),
            patch.object(hb, "sketchup_running", return_value=False),
            patch.object(hb.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)),
            patch.object(hb, "wait", side_effect=wait),
            patch.object(hb, "evaluate", side_effect=[None, model.name]),
            patch.object(hb, "open_windows", return_value="Open File"),
            patch.object(hb.time, "sleep"),
            patch("builtins.print"),
        ):
            hb.launch("2026", model, None, 5.0)

    def test_a_scratch_fixtures_recovery_copy_is_removed_before_the_open(self) -> None:
        with TemporaryDirectory() as folder:
            copy = Path(folder) / "a09.skp"
            copy.write_text("autosave")
            with patch.object(hb, "recovery_copy", return_value=copy):
                self.launch(Path("/repo/_private/run/a09.skp"), lambda *_args: {"port": 1, "pid": 2})
            self.assertFalse(copy.exists())

    def test_a_launch_that_never_reaches_the_bridge_names_the_open_windows_and_stays_a_timeout(self) -> None:
        with patch.object(hb, "recovery_copy", return_value=None), self.assertRaises(TimeoutError) as raised:
            self.launch(Path("/repo/_private/run/a09.skp"), TimeoutError("no host bridge within 5s"))
        self.assertIn("Open windows: Open File", str(raised.exception))


class RecoveryCopyTest(unittest.TestCase):
    def test_only_a_scratch_fixture_has_its_recovery_copy_cleared(self) -> None:
        working = hb.SUPPORT / "SketchUp 2026" / "SketchUp" / "working"
        self.assertEqual(hb.recovery_copy("2026", Path("/repo/_private/host/run/a09.skp")), working / "a09.skp")
        self.assertEqual(hb.recovery_copy("2026", Path("/private/tmp/scratch.skp")), working / "scratch.skp")
        self.assertIsNone(hb.recovery_copy("2026", Path("/Users/someone/Projects/house.skp")))


class TailTest(unittest.TestCase):
    def test_tail_names_a_missing_file_instead_of_printing_nothing(self) -> None:
        with TemporaryDirectory() as directory:
            absent = Path(directory) / "console.log"
            self.assertIn(str(absent), hb.tail(absent, 10))

    def test_tail_returns_the_last_lines_and_survives_undecodable_bytes(self) -> None:
        with TemporaryDirectory() as directory:
            path = Path(directory) / "console.log"
            path.write_bytes(b"one\ntwo\n" + b"\xff\xfe" + b"\nfour\n")

            self.assertEqual(hb.tail(path, 2).splitlines()[-1], "four")


class CommandRegistryTest(unittest.TestCase):
    def test_the_registry_is_exactly_the_documented_command_set(self) -> None:
        # Exact, not a subset: a command silently dropped from the registry is a command the
        # usage block still promises.
        self.assertEqual(
            set(hb.COMMANDS),
            {"wait", "ping", "quit", "launch", "eval", "state", "save", "shot", "key", "console", "wait-for"},
        )
        for name, (configure, run) in hb.COMMANDS.items():
            self.assertTrue(callable(configure), name)
            self.assertTrue(callable(run), name)


if __name__ == "__main__":
    unittest.main()
