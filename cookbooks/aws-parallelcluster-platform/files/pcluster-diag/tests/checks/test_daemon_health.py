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

"""Unit tests for the daemon-liveness and clustermgtd heartbeat (stuck-detection) checks."""

from datetime import datetime, timedelta, timezone

import pytest

from pcluster_diag.checks import daemon_health
from pcluster_diag.checks.daemon_health import ClusterDaemonsAreRunning, ClustermgtdHeartbeatIsHealthy
from pcluster_diag.core.constants import (
    CLUSTERMGTD_HEARTBEAT_STALE_THRESHOLD_SECONDS,
    CLUSTERMGTD_HEARTBEAT_TIMESTAMP_FORMAT,
)
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import Status
from pcluster_diag.util.shell import TimedCommand
from tests.sample_data import sample_context


def _timed(returncode=0, stdout="", stderr="", timed_out=False, elapsed=0.01):
    return TimedCommand(
        command=["cat"],
        returncode=returncode,
        stdout=stdout,
        stderr=stderr,
        elapsed_seconds=elapsed,
        timed_out=timed_out,
    )


def _heartbeat_timestamp(age_seconds):
    """Return a heartbeat timestamp string that is ``age_seconds`` old relative to now."""
    moment = datetime.now(timezone.utc) - timedelta(seconds=age_seconds)
    return moment.strftime(CLUSTERMGTD_HEARTBEAT_TIMESTAMP_FORMAT)


# --- ClusterDaemonsAreRunning ---------------------------------------------------------


def test_daemons_description():
    assert ClusterDaemonsAreRunning().description == (
        "Verify that the ParallelCluster management daemons for this node type are running."
    )


@pytest.mark.parametrize(
    "node_type, expected",
    [(NodeType.HEAD, True), (NodeType.COMPUTE, True), (NodeType.LOGIN, True)],
)
def test_daemons_should_run_on_node_types_with_expected_daemons(node_type, expected):
    assert ClusterDaemonsAreRunning().should_run(sample_context(node_type)) is expected


@pytest.mark.parametrize(
    "node_type, expected_programs",
    [
        (NodeType.HEAD, ["clustermgtd", "clusterstatusmgtd"]),
        (NodeType.COMPUTE, ["computemgtd"]),
        (NodeType.LOGIN, ["loginmgtd"]),
    ],
)
def test_daemons_all_running_passes_and_queries_expected_programs(monkeypatch, node_type, expected_programs):
    queried = []

    def fake_state(program):
        queried.append(program)
        return "RUNNING"

    monkeypatch.setattr(daemon_health, "get_supervisord_program_state", fake_state)

    result = ClusterDaemonsAreRunning().run(sample_context(node_type))

    assert result.status is Status.PASSED
    assert queried == expected_programs
    assert result.errors is None


def test_daemons_reports_not_running_program_as_failure(monkeypatch):
    monkeypatch.setattr(
        daemon_health,
        "get_supervisord_program_state",
        lambda program: "FATAL" if program == "clustermgtd" else "RUNNING",
    )

    result = ClusterDaemonsAreRunning().run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert [error.code for error in result.errors] == [ClusterDaemonsAreRunning.DAEMONS_NOT_RUNNING.code]
    assert "clustermgtd is FATAL" in result.errors[0].message


def test_daemons_propagates_when_state_cannot_be_determined(monkeypatch):
    def _raise(_program):
        raise RuntimeError("cannot determine status")

    monkeypatch.setattr(daemon_health, "get_supervisord_program_state", _raise)

    with pytest.raises(RuntimeError):
        ClusterDaemonsAreRunning().run(sample_context(NodeType.HEAD))


# --- ClustermgtdHeartbeatIsHealthy ----------------------------------------------------


def test_heartbeat_description():
    assert ClustermgtdHeartbeatIsHealthy().description == (
        "Verify that the clustermgtd heartbeat is fresh (clustermgtd is not stalled)."
    )


@pytest.mark.parametrize(
    "node_type, expected",
    [(NodeType.HEAD, True), (NodeType.COMPUTE, True), (NodeType.LOGIN, False)],
)
def test_heartbeat_should_run_excludes_login_node(node_type, expected):
    assert ClustermgtdHeartbeatIsHealthy().should_run(sample_context(node_type)) is expected


def test_heartbeat_path_defaults_and_honors_install_dir():
    check = ClustermgtdHeartbeatIsHealthy()
    default_ctx = sample_context(NodeType.HEAD)
    assert check._heartbeat_path(default_ctx) == ("/opt/slurm/etc/pcluster/.slurm_plugin/clustermgtd_heartbeat")

    custom_ctx = sample_context(NodeType.HEAD)
    custom_ctx.dna_json["cluster"]["slurm"] = {"install_dir": "/shared/slurm/"}
    assert check._heartbeat_path(custom_ctx) == ("/shared/slurm/etc/pcluster/.slurm_plugin/clustermgtd_heartbeat")


def test_heartbeat_fresh_passes(monkeypatch):
    monkeypatch.setattr(daemon_health, "time_command", lambda command, timeout: _timed(stdout=_heartbeat_timestamp(10)))

    result = ClustermgtdHeartbeatIsHealthy().run(sample_context(NodeType.HEAD))

    assert result.status is Status.PASSED
    assert result.errors is None


def test_heartbeat_stale_fails_with_stuck_diagnosis(monkeypatch):
    stale_age = CLUSTERMGTD_HEARTBEAT_STALE_THRESHOLD_SECONDS + 100
    monkeypatch.setattr(
        daemon_health, "time_command", lambda command, timeout: _timed(stdout=_heartbeat_timestamp(stale_age))
    )

    result = ClustermgtdHeartbeatIsHealthy().run(sample_context(NodeType.COMPUTE))

    assert result.status is Status.FAILURE
    assert [error.code for error in result.errors] == [ClustermgtdHeartbeatIsHealthy.HEARTBEAT_STALE.code]
    assert "stale" in result.errors[0].message
    assert "self-terminate" in result.errors[0].message


def test_heartbeat_read_timeout_fails_pointing_at_wedged_filesystem(monkeypatch):
    monkeypatch.setattr(
        daemon_health, "time_command", lambda command, timeout: _timed(returncode=None, timed_out=True, elapsed=30.0)
    )

    result = ClustermgtdHeartbeatIsHealthy().run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert [error.code for error in result.errors] == [ClustermgtdHeartbeatIsHealthy.HEARTBEAT_READ_TIMED_OUT.code]
    assert "wedged" in result.errors[0].message


def test_heartbeat_unreadable_file_fails(monkeypatch):
    monkeypatch.setattr(
        daemon_health, "time_command", lambda command, timeout: _timed(returncode=1, stderr="No such file or directory")
    )

    result = ClustermgtdHeartbeatIsHealthy().run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert [error.code for error in result.errors] == [ClustermgtdHeartbeatIsHealthy.HEARTBEAT_UNREADABLE.code]
    assert "Could not read" in result.errors[0].message


def test_heartbeat_unparseable_timestamp_raises(monkeypatch):
    # An unparseable timestamp means the check cannot complete, so it raises and the Runner records
    # a CHECK_ERROR (mirroring how cfn-hup handles an undeterminable state).
    monkeypatch.setattr(daemon_health, "time_command", lambda command, timeout: _timed(stdout="not-a-timestamp"))

    with pytest.raises(ValueError, match="parse"):
        ClustermgtdHeartbeatIsHealthy().run(sample_context(NodeType.HEAD))
