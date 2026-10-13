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

"""Unit tests for the compute fleet status history check."""

from datetime import datetime, timedelta, timezone

import pytest

from pcluster_diag.checks import compute_fleet_status as check_module
from pcluster_diag.checks.compute_fleet_status import ComputeFleetStatusHistory
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import Status
from tests.sample_data import sample_context
from tests.stubs import stub_raising, stub_returning

_NOW = datetime(2026, 10, 12, 17, 0, 0, tzinfo=timezone.utc)
_PROTECTED_LOG = [
    "2026-10-12 14:30:02,100 - [clustermgtd:x] - INFO - Placing bootstrap failure partitions to INACTIVE: ['queue']",
    "2026-10-12 14:30:02,118 - [clustermgtd:y] - INFO - Updating compute fleet status from RUNNING to PROTECTED",
]


def _context():
    context = sample_context()
    context.dna_json = {"cluster": {"node_type": "HeadNode", "region": "us-east-1", "ddb_table": "parallelcluster-c"}}
    return context


def _patch(monkeypatch, status, updated, log=None):
    # The log lines are clustermgtd ones: the clusterstatusmgtd log is empty.
    monkeypatch.setattr(
        check_module.log_files,
        "read_rotated_log",
        lambda path: ((log or []) if path == check_module.CLUSTERMGTD_LOG_PATH else [], [path]),
    )
    monkeypatch.setattr(check_module.fleet_status, "get_compute_fleet_status", stub_returning((status, updated)))
    monkeypatch.setattr(check_module, "_now", lambda: _NOW)


def test_should_run_only_on_the_head_node():
    assert ComputeFleetStatusHistory().should_run(sample_context(NodeType.HEAD)) is True
    assert ComputeFleetStatusHistory().should_run(sample_context(NodeType.LOGIN)) is False


def test_running_fleet_passes_and_reports_the_history(monkeypatch):
    _patch(monkeypatch, "RUNNING", _NOW - timedelta(hours=1), log=_PROTECTED_LOG)

    result = ComputeFleetStatusHistory().run(_context())

    assert result.status == Status.PASSED
    current, history = result.infos
    assert current.message == "Current compute fleet status: RUNNING (since 2026-10-12T16:00:00+00:00)."
    assert history.message == (
        "1 compute fleet status changes since 2026-10-12 14:30:02,100 "
        "(oldest entry in the clusterstatusmgtd and clustermgtd logs)."
    )
    assert history.details == [
        {"time": "2026-10-12 14:30:02,118", "from": "RUNNING", "to": "PROTECTED", "partitions": ["queue"]}
    ]


def test_protected_fleet_is_a_warning_naming_the_partitions(monkeypatch):
    _patch(monkeypatch, "PROTECTED", _NOW - timedelta(hours=2), log=_PROTECTED_LOG)

    result = ComputeFleetStatusHistory().run(_context())

    assert result.status == Status.WARNING
    assert result.warnings[0].message == (
        "The compute fleet is PROTECTED since 2026-10-12T15:00:00+00:00: bootstrap failures put partitions "
        "['queue'] in INACTIVE."
    )


@pytest.mark.parametrize(
    "status, minutes, stuck",
    [
        ("STOP_REQUESTED", 4, False),
        ("STOP_REQUESTED", 47, True),
        ("STARTING", 15, False),
        ("STARTING", 23, True),
    ],
)
def test_stuck_fleet_is_a_warning(monkeypatch, status, minutes, stuck):
    _patch(monkeypatch, status, _NOW - timedelta(minutes=minutes))

    result = ComputeFleetStatusHistory().run(_context())

    if stuck:
        assert result.warnings[0].message == "The compute fleet is in {} since {} ({} minutes).".format(
            status, (_NOW - timedelta(minutes=minutes)).isoformat(), minutes
        )
    else:
        assert result.warnings is None


def test_unreadable_status_is_a_check_error_and_keeps_the_history(monkeypatch):
    _patch(monkeypatch, None, None, log=_PROTECTED_LOG)
    monkeypatch.setattr(check_module.fleet_status, "get_compute_fleet_status", stub_raising("AccessDenied"))

    result = ComputeFleetStatusHistory().run(_context())

    assert result.status == Status.CHECK_ERROR
    assert result.errors[0].message == (
        "Could not read the compute fleet status from the DynamoDB table parallelcluster-c: AccessDenied."
    )
    assert [info.code for info in result.infos] == ["I2"]


def test_no_change_in_the_logs(monkeypatch):
    _patch(monkeypatch, "RUNNING", _NOW)

    result = ComputeFleetStatusHistory().run(_context())

    assert (
        result.infos[1].message == "No compute fleet status change found in the clusterstatusmgtd and clustermgtd logs."
    )
