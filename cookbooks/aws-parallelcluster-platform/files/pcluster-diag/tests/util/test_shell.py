# Copyright 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

"""Unit tests for the shell command-runner utility."""

import logging
import subprocess

from pcluster_diag.util import shell
from pcluster_diag.util.shell import run_command


def test_run_command_runs_without_shell_logs_and_returns_result(monkeypatch, caplog):
    captured = {}

    def fake_run(command, **kwargs):
        captured["command"] = command
        captured["kwargs"] = kwargs
        return subprocess.CompletedProcess(command, 0, stdout="out", stderr="err")

    monkeypatch.setattr(shell.subprocess, "run", fake_run)

    with caplog.at_level(logging.INFO, logger="pcluster_diag.util.shell"):
        result = run_command(["echo", "hi"])

    # The command is captured and never run through a shell nor raised on a non-zero exit.
    assert captured["command"] == ["echo", "hi"]
    assert "shell" not in captured["kwargs"]
    # A default 60s timeout is applied.
    assert captured["kwargs"] == {"capture_output": True, "text": True, "check": False, "timeout": 60}
    # The CompletedProcess is returned unchanged.
    assert result.returncode == 0
    assert result.stdout == "out"
    # The outcome is logged to stderr.
    assert any("Executed command" in record.getMessage() for record in caplog.records)


def test_run_command_uses_caller_supplied_timeout(monkeypatch):
    captured = {}

    def fake_run(command, **kwargs):
        captured["kwargs"] = kwargs
        return subprocess.CompletedProcess(command, 0, stdout="", stderr="")

    monkeypatch.setattr(shell.subprocess, "run", fake_run)

    run_command(["echo", "hi"], timeout=5)

    # The caller's timeout overrides the default.
    assert captured["kwargs"]["timeout"] == 5


class _FakeAccount:
    def __init__(self, uid, gid):
        self.pw_uid = uid
        self.pw_gid = gid


def test_run_command_as_user_prepends_setpriv_prefix(monkeypatch):
    captured = {}

    def fake_run(command, **kwargs):
        captured["command"] = command
        return subprocess.CompletedProcess(command, 0, stdout="", stderr="")

    monkeypatch.setattr(shell.subprocess, "run", fake_run)
    monkeypatch.setattr(shell.pwd, "getpwnam", lambda name: _FakeAccount(1001, 2002))

    run_command(["curl", "http://example"], as_user="pcluster-admin")

    # The command runs as the user's uid/gid via setpriv (no PAM session), with the original argv appended.
    assert captured["command"] == [
        "setpriv",
        "--reuid",
        "1001",
        "--regid",
        "2002",
        "--clear-groups",
        "curl",
        "http://example",
    ]


def test_run_command_without_as_user_leaves_command_unchanged(monkeypatch):
    captured = {}

    def fake_run(command, **kwargs):
        captured["command"] = command
        return subprocess.CompletedProcess(command, 0, stdout="", stderr="")

    monkeypatch.setattr(shell.subprocess, "run", fake_run)

    run_command(["curl", "http://example"])

    # No privilege dropping when as_user is omitted.
    assert captured["command"] == ["curl", "http://example"]


def test_time_command_returns_timing_for_completed_command(monkeypatch):
    def fake_run(command, **kwargs):
        return subprocess.CompletedProcess(command, 0, stdout="out", stderr="")

    monkeypatch.setattr(shell.subprocess, "run", fake_run)

    timed = shell.time_command(["getent", "passwd", "alice"], timeout=5)

    assert timed.timed_out is False
    assert timed.returncode == 0
    assert timed.stdout == "out"
    assert timed.succeeded is True
    assert timed.elapsed_seconds >= 0


def test_time_command_marks_nonzero_exit_as_not_succeeded(monkeypatch):
    monkeypatch.setattr(
        shell.subprocess,
        "run",
        lambda command, **kwargs: subprocess.CompletedProcess(command, 2, stdout="", stderr="not found"),
    )

    timed = shell.time_command(["getent", "passwd", "ghost"])

    assert timed.timed_out is False
    assert timed.returncode == 2
    assert timed.succeeded is False


def test_time_command_treats_timeout_as_data_not_exception(monkeypatch):
    def fake_run(command, **kwargs):
        raise subprocess.TimeoutExpired(cmd=command, timeout=kwargs["timeout"], output="partial", stderr=None)

    monkeypatch.setattr(shell.subprocess, "run", fake_run)

    timed = shell.time_command(["id", "alice"], timeout=1)

    # A timeout is returned as a TimedCommand, never raised.
    assert timed.timed_out is True
    assert timed.returncode is None
    assert timed.succeeded is False
    # Partial output captured on timeout is normalized to a string.
    assert timed.stdout == "partial"
    assert timed.stderr == ""


def test_time_command_decodes_bytes_output_on_timeout(monkeypatch):
    def fake_run(command, **kwargs):
        raise subprocess.TimeoutExpired(
            cmd=command, timeout=kwargs["timeout"], output=b"bytes-out", stderr=b"bytes-err"
        )

    monkeypatch.setattr(shell.subprocess, "run", fake_run)

    timed = shell.time_command(["id", "alice"], timeout=1)

    assert timed.stdout == "bytes-out"
    assert timed.stderr == "bytes-err"
