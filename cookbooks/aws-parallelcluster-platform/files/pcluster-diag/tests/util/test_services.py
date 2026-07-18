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

"""Unit tests for the supervisord service-state helpers."""

import subprocess

import pytest

from pcluster_diag.util import services
from pcluster_diag.util.services import _program_state, _resolve_supervisorctl, is_supervisord_program_running

_SUPERVISORCTL = "/opt/parallelcluster/pyenv/versions/3.14.2/envs/cookbook_virtualenv/bin/supervisorctl"


@pytest.mark.parametrize(
    "status_output, expected",
    [
        ("cfn-hup                          RUNNING   pid 3926, uptime 5:58:33", "RUNNING"),
        ("cfn-hup                          STOPPED   Not started", "STOPPED"),
        ("cfn-hup                          FATAL     Exited too quickly", "FATAL"),
        ("cfn-hup                          STARTING", "STARTING"),
        ("cfn-hup: ERROR (no such process)", "ERROR"),  # status token parsed as-is
        ("cfn-hup", None),  # name only, no status token -> unparseable
        ("clustermgtd                      RUNNING   pid 1, uptime 1:00:00", None),  # different program -> absent
        ("\ncfn-hup                          RUNNING   pid 3926", "RUNNING"),  # leading blank line is skipped
        ("", None),  # no output -> unparseable
    ],
)
def test_program_state_parses_status_column(status_output, expected):
    assert _program_state("cfn-hup", status_output) == expected


@pytest.mark.parametrize(
    "returncode, stdout, expected",
    [
        (0, "cfn-hup    RUNNING   pid 3926, uptime 5:58:33", True),
        (3, "cfn-hup    STOPPED", False),
    ],
    ids=["running", "stopped"],
)
def test_is_supervisord_program_running_reflects_status(monkeypatch, returncode, stdout, expected):
    monkeypatch.setattr(services, "_resolve_supervisorctl", lambda: _SUPERVISORCTL)
    captured = {}

    def fake_run_command(command):
        captured["command"] = command
        return subprocess.CompletedProcess(command, returncode, stdout=stdout, stderr="")

    monkeypatch.setattr(services, "run_command", fake_run_command)

    assert is_supervisord_program_running("cfn-hup") is expected
    # Always invokes supervisorctl with the resolved binary.
    assert captured["command"] == [_SUPERVISORCTL, "status", "cfn-hup"]


@pytest.mark.parametrize(
    "stdout",
    ["", "cfn-hup", "unix:///var/run/supervisor.sock refused connection"],
    ids=["empty", "name-without-status", "connection-error"],
)
def test_is_supervisord_program_running_raises_when_status_undeterminable(monkeypatch, stdout):
    monkeypatch.setattr(services, "_resolve_supervisorctl", lambda: _SUPERVISORCTL)
    monkeypatch.setattr(
        services,
        "run_command",
        lambda command: subprocess.CompletedProcess(command, 1, stdout=stdout, stderr=""),
    )

    with pytest.raises(RuntimeError):
        is_supervisord_program_running("cfn-hup")


@pytest.mark.parametrize(
    "glob_result, expected",
    [
        ([_SUPERVISORCTL], _SUPERVISORCTL),
        ([], FileNotFoundError),
    ],
    ids=["match-found", "no-match-raises"],
)
def test_resolve_supervisorctl(monkeypatch, glob_result, expected):
    monkeypatch.setattr(services.glob, "glob", lambda _pattern: glob_result)

    if isinstance(expected, type) and issubclass(expected, Exception):
        with pytest.raises(expected):
            _resolve_supervisorctl()
    else:
        assert _resolve_supervisorctl() == expected


@pytest.mark.parametrize(
    "stdout, expected",
    [
        ("cfn-hup    RUNNING   pid 3926, uptime 5:58:33", "RUNNING"),
        ("cfn-hup    STOPPED", "STOPPED"),
        ("cfn-hup    FATAL     Exited too quickly", "FATAL"),
    ],
)
def test_get_supervisord_program_state_returns_state_token(monkeypatch, stdout, expected):
    monkeypatch.setattr(services, "_resolve_supervisorctl", lambda: _SUPERVISORCTL)
    monkeypatch.setattr(
        services,
        "run_command",
        lambda command: subprocess.CompletedProcess(command, 0, stdout=stdout, stderr=""),
    )

    assert services.get_supervisord_program_state("cfn-hup") == expected


def test_get_supervisord_program_state_raises_when_undeterminable(monkeypatch):
    monkeypatch.setattr(services, "_resolve_supervisorctl", lambda: _SUPERVISORCTL)
    monkeypatch.setattr(
        services,
        "run_command",
        lambda command: subprocess.CompletedProcess(command, 1, stdout="", stderr=""),
    )

    with pytest.raises(RuntimeError):
        services.get_supervisord_program_state("cfn-hup")
